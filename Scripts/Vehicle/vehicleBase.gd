extends RigidBody3D

# public / inspector-settable
@export var engine: Node
@export var transmission: Node
@export var wheels: Array[Node] # assign child nodes manually here
@export var drawDebug: bool = true

# local
var brake: float = 0

# debug
var suspensionDebugDisplay: Array[MeshInstance3D]
var steeringDebugDisplay: Array[MeshInstance3D]
var brakingDebugDisplay: Array[MeshInstance3D]
@export var suspensionDebugMaterial: StandardMaterial3D
@export var steeringDebugMaterial: StandardMaterial3D
@export var brakingDebugMaterial: StandardMaterial3D

func _ready():
	suspensionDebugMaterial.no_depth_test = true
	steeringDebugMaterial.no_depth_test = true
	brakingDebugMaterial.no_depth_test = true
	
	for wheel in wheels:
		wheel.initModel(self)
		var tempSuspensionDebugMesh = MeshInstance3D.new()
		var tempSteeringDebugMesh = MeshInstance3D.new()
		var tempBrakingDebugMesh = MeshInstance3D.new()
		suspensionDebugDisplay.append(tempSuspensionDebugMesh)
		suspensionDebugDisplay[suspensionDebugDisplay.size() - 1].material_override = suspensionDebugMaterial
		add_child(suspensionDebugDisplay[suspensionDebugDisplay.size() - 1])
		steeringDebugDisplay.append(tempSteeringDebugMesh)
		steeringDebugDisplay[steeringDebugDisplay.size() - 1].material_override = steeringDebugMaterial
		add_child(steeringDebugDisplay[steeringDebugDisplay.size() - 1])
		brakingDebugDisplay.append(tempBrakingDebugMesh)
		brakingDebugDisplay[brakingDebugDisplay.size() - 1].material_override = brakingDebugMaterial
		add_child(brakingDebugDisplay[brakingDebugDisplay.size() - 1])

func _physics_process(delta):
	calculateSuspension(delta)
	calculateWeightTransfer()
	updateCoreData()
	calculateAcceleration(delta)
	calculateSteering()
	applyTotalForces()

# physics functions
func calculateSuspension(delta):
	for idx in wheels.size():
		wheels[idx].updateWheelPosition(self, delta)
		if wheels[idx].isGrounded:
			var suspensionForce = wheels[idx].calculateSuspensionForce(delta)
			var suspensionDampingForce = wheels[idx].springVelocity * global_basis.y * wheels[idx].suspensionDamping
			var totalAppliedForce = suspensionForce + suspensionDampingForce
			apply_force(totalAppliedForce, wheels[idx].target - global_position)
			# draw debug meshes
			if drawDebug:
				var tempSuspensionMesh = debugSuspension(\
					to_local(wheels[idx].target),\
					to_local(wheels[idx].target + totalAppliedForce/5000))
				suspensionDebugDisplay[idx].mesh = tempSuspensionMesh
		else:
			suspensionDebugDisplay[idx].mesh = null

func updateCoreData():
	for idx in wheels.size():
		if wheels[idx].isGrounded:
			var flatPlane = Plane(wheels[idx].normal)
			wheels[idx].pointVelocity = getPointVelocity(self, wheels[idx].target, wheels[idx].collider, wheels[idx].colliderPoint)
			wheels[idx].forwardVelocity = flatPlane.project(wheels[idx].pointVelocity.project(wheels[idx].global_basis.z))
			wheels[idx].forwardDirection = flatPlane.project(-wheels[idx].global_basis.z)
			wheels[idx].lateralVelocity = flatPlane.project(wheels[idx].pointVelocity.project(wheels[idx].global_basis.x))
			wheels[idx].angularVelocity = wheels[idx].forwardVelocity.length() / wheels[idx].radius
			wheels[idx].dir = sign(wheels[idx].forwardVelocity.dot(wheels[idx].forwardDirection))
			wheels[idx].angularVelocity *= wheels[idx].dir
			
			# update engine RPM
			engine.updateRPM(transmission)

func calculateAcceleration(delta):
	engine.updateTorque() # update engine torque
	for idx in wheels.size():
		var torque = 0
		var factor = min(wheels[idx].forwardVelocity.length_squared(), 1)
		if wheels[idx].powered:
			var maximumAngularVelocity = engine.maxRPM * (2 * PI) / 60 / transmission.gears[transmission.currentGear] / transmission.finalDrive
			if (abs(wheels[idx].angularVelocity) > abs(maximumAngularVelocity)) \
				or (transmission.gears[transmission.currentGear] < 0 and wheels[idx].angularVelocity > 0) \
				or (transmission.gears[transmission.currentGear] > 0 and wheels[idx].angularVelocity < 0):
					torque = (engine.torque * abs(transmission.gears[transmission.currentGear]) * transmission.finalDrive)
					torque *= -wheels[idx].dir
			else:
				torque = (engine.appliedTorque * transmission.gears[transmission.currentGear] * transmission.finalDrive)
		
		if wheels[idx].brakes:
			torque += min((brake * brake) * wheels[idx].brakeForce, abs(wheels[idx].angularVelocity) / wheels[idx].radius) * -wheels[idx].dir * factor
		
		#if wheels[idx].powered:
		wheels[idx].grip = clamp(wheels[idx].grip, -abs(torque), abs(torque))
		wheels[idx].angularVelocity += (torque - wheels[idx].grip / wheels[idx].inertia) * delta
		#else:
			#wheels[idx].angularVelocity += torque * delta
		var slipRatio = ((wheels[idx].angularVelocity * wheels[idx].radius) \
			- (wheels[idx].forwardVelocity.length() * wheels[idx].dir)) \
			/ (wheels[idx].forwardVelocity.length())
		#slipRatio = clamp(slipRatio, -1, 1)
		
		if slipRatio <= -1:
			wheels[idx].angularVelocity = 0
		
		wheels[idx].grip = wheels[idx].tire.calcForce(mass * 9.8, slipRatio * 100, false)
		if is_nan(wheels[idx].grip):
			wheels[idx].grip = 0
		
		#if wheels[idx].isGrounded:
			#apply_force(wheels[idx].grip * wheels[idx].forwardDirection, wheels[idx].target - global_position)
		
		wheels[idx].animate(delta)

func calculateSteering():
	for idx in wheels.size():
		if wheels[idx].isGrounded:
			var slip = wheels[idx].getLateralSlip()
			var lateralForce = wheels[idx].tire.calcForce(mass * 9.8, slip, true)
			if is_nan(lateralForce):
				lateralForce = 0
			wheels[idx].lateralGrip = lateralForce
			#if multiplier > 0:
				#apply_force(steeringForce * -multiplier, wheels[idx].target - global_position)

func applyTotalForces():
	for idx in wheels.size():
		var steeringDirection = wheels[idx].lateralVelocity
		if steeringDirection.length() > 1:
			steeringDirection = steeringDirection.normalized()
		
		var totalForce = abs(wheels[idx].grip) + abs(wheels[idx].lateralGrip)
		var percentLateral = abs(wheels[idx].lateralGrip) / totalForce
		var percentLongitudinal = 1 - percentLateral
		var appliedLateralForce = clamp(wheels[idx].lateralGrip, 0, wheels[idx].maxDriveForce)#wheels[idx].maxDriveForce * percentLateral
		var appliedLongitudinalForce = clamp(wheels[idx].grip, -wheels[idx].maxDriveForce, wheels[idx].maxDriveForce)#wheels[idx].maxDriveForce * percentLongitudinal * sign(wheels[idx].grip)
		
		if !is_nan(appliedLateralForce) && !is_nan(appliedLongitudinalForce):
			wheels[idx].grip = appliedLongitudinalForce
			apply_force(steeringDirection * -appliedLateralForce, wheels[idx].target - global_position)
			apply_force(appliedLongitudinalForce * wheels[idx].forwardDirection, wheels[idx].target - global_position)
		
		if drawDebug:
			var tempSteeringMesh = debugSteering(\
				to_local(wheels[idx].target),\
				to_local(wheels[idx].target + (steeringDirection * -appliedLateralForce / 5000)))
			steeringDebugDisplay[idx].mesh = tempSteeringMesh
			var tempBrakingMesh = debugBraking(\
				to_local(wheels[idx].target),\
				to_local(wheels[idx].target + appliedLongitudinalForce / 5000 * wheels[idx].forwardDirection))
			brakingDebugDisplay[idx].mesh = tempBrakingMesh

func calculateWeightTransfer():
	var totalForce = 0
	# first find total suspension force
	for idx in wheels.size():
		totalForce += wheels[idx].springForce
	# now use it to find percentage of vehicle's weight being applied at wheel
	for idx in wheels.size():
		var percentage = wheels[idx].springForce / totalForce
		wheels[idx].weightAtWheel = mass * percentage
		wheels[idx].maxDriveForce = max(wheels[idx].weightAtWheel * 9.8, 0)

func getPointVelocity(body: RigidBody3D, point: Vector3, otherBody: RigidBody3D = null, otherPoint: Vector3 = Vector3.ZERO) -> Vector3:
	var globalVelocity = body.linear_velocity + body.angular_velocity.cross(point - (body.global_position + body.center_of_mass))
	var otherVelocity = Vector3.ZERO
	if otherBody:
		otherVelocity = otherBody.linear_velocity + otherBody.angular_velocity.cross(otherPoint - (otherBody.global_position + otherBody.center_of_mass))
	return globalVelocity - otherVelocity

# debug functions
func debugSuspension(pos1, pos2) -> ImmediateMesh:
	var suspensionDebugMesh = ImmediateMesh.new()
	suspensionDebugMesh.surface_begin(Mesh.PRIMITIVE_LINES)
	suspensionDebugMesh.surface_add_vertex(pos1)
	suspensionDebugMesh.surface_add_vertex(pos2)
	suspensionDebugMesh.surface_end()
	return suspensionDebugMesh

func debugSteering(pos1, pos2) -> ImmediateMesh:
	var steeringDebugMesh = ImmediateMesh.new()
	steeringDebugMesh.surface_begin(Mesh.PRIMITIVE_LINES)
	steeringDebugMesh.surface_add_vertex(pos1)
	steeringDebugMesh.surface_add_vertex(pos2)
	steeringDebugMesh.surface_end()
	return steeringDebugMesh

func debugBraking(pos1, pos2) -> ImmediateMesh:
	var brakingDebugMesh = ImmediateMesh.new()
	brakingDebugMesh.surface_begin(Mesh.PRIMITIVE_LINES)
	brakingDebugMesh.surface_add_vertex(pos1)
	brakingDebugMesh.surface_add_vertex(pos2)
	brakingDebugMesh.surface_end()
	return brakingDebugMesh
