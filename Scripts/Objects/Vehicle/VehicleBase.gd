extends RigidBody3D

# public / inspector-settable
@export var engine: Resource
@export var transmission: Resource
@export var wheels: Array[Node] # assign child nodes manually here

# debug
var suspensionDebugDisplay: Array[MeshInstance3D]
var steeringDebugDisplay: Array[MeshInstance3D]
var accelerationDebugDisplay: Array[MeshInstance3D]
@export var suspensionDebugMaterial: StandardMaterial3D
@export var steeringDebugMaterial: StandardMaterial3D
@export var accelerationDebugMaterial: StandardMaterial3D

# local variables
var input = {
	"accel": 0.0,
	"brake": 0.0,
	"steer": 0.0,
}

func _ready():
	suspensionDebugMaterial.no_depth_test = true
	steeringDebugMaterial.no_depth_test = true
	accelerationDebugMaterial.no_depth_test = true
	
	for wheel in wheels:
		wheel.initModel(self)
		var tempSuspensionDebugMesh = MeshInstance3D.new()
		var tempSteeringDebugMesh = MeshInstance3D.new()
		var tempAccelerationDebugMesh = MeshInstance3D.new()
		suspensionDebugDisplay.append(tempSuspensionDebugMesh)
		suspensionDebugDisplay[suspensionDebugDisplay.size() - 1].material_override = suspensionDebugMaterial
		add_child(suspensionDebugDisplay[suspensionDebugDisplay.size() - 1])
		steeringDebugDisplay.append(tempSteeringDebugMesh)
		steeringDebugDisplay[steeringDebugDisplay.size() - 1].material_override = steeringDebugMaterial
		add_child(steeringDebugDisplay[steeringDebugDisplay.size() - 1])
		accelerationDebugDisplay.append(tempAccelerationDebugMesh)
		accelerationDebugDisplay[accelerationDebugDisplay.size() - 1].material_override = accelerationDebugMaterial
		add_child(accelerationDebugDisplay[accelerationDebugDisplay.size() - 1])

func _physics_process(delta):
	calculateSuspension(delta)
	calculateWeightTransfer()
	calculateAcceleration(delta)
	calculateSteering()

func _process(_delta):
	updateSteering()

# physics functions
func calculateSuspension(delta):
	for idx in wheels.size():
		wheels[idx].updateWheelPosition(self, delta)
		if wheels[idx].isGrounded:
			var suspensionForce = wheels[idx].calculateSuspensionForce(self, delta)
			var suspensionDampingForce = wheels[idx].springVelocity * global_basis.y * wheels[idx].suspensionDamping
			var totalAppliedForce = suspensionForce + suspensionDampingForce
			apply_force(totalAppliedForce, wheels[idx].target - global_position)
			# draw debug meshes
			var tempSuspensionMesh = debugSuspension(\
				to_local(wheels[idx].target),\
				to_local(wheels[idx].target) + totalAppliedForce/1000)
			suspensionDebugDisplay[idx].mesh = tempSuspensionMesh
		else:
			suspensionDebugDisplay[idx].mesh = null

func calculateAcceleration(delta):
	for idx in wheels.size():
		if wheels[idx].isGrounded:
			var flatPlane = Plane(wheels[idx].normal)
			var pointVelocity = getPointVelocity(wheels[idx].target)
			wheels[idx].pointVelocity = flatPlane.project(pointVelocity)
			wheels[idx].forwardVelocity = wheels[idx].pointVelocity.project(wheels[idx].basis.z)
			wheels[idx].angularVelocity = wheels[idx].forwardVelocity.length() / wheels[idx].radius
			if (wheels[idx].forwardVelocity.dot(wheels[idx].basis.z) < 0):
				wheels[idx].angularVelocity *= -1
		else:
			wheels[idx].applyRollingResistance(delta)
		# draw debug meshes
		var tempAccelerationMesh = debugAcceleration(\
			to_local(wheels[idx].target),\
			to_local(wheels[idx].target) + wheels[idx].forwardVelocity)
		accelerationDebugDisplay[idx].mesh = tempAccelerationMesh
		wheels[idx].animate(delta)

func calculateSteering():
	for idx in wheels.size():
		if wheels[idx].isGrounded:
			var slip = getLateralSlip(wheels[idx].pointVelocity, idx)
			var slipForceMultiplier = (slip * wheels[idx].maxDriveForce)
			var steeringForce = wheels[idx].pointVelocity.project(wheels[idx].basis.x)
			if slipForceMultiplier > 0:
				apply_force(steeringForce * -slipForceMultiplier, wheels[idx].target - global_position)
			# draw debug meshes
			var tempSteeringMesh = debugSteering(\
				to_local(wheels[idx].target),\
				to_local(wheels[idx].target) - steeringForce)
			steeringDebugDisplay[idx].mesh = tempSteeringMesh
		else:
			steeringDebugDisplay[idx].mesh = null

func getLateralSlip(planeVelocity, idx) -> float:
	var forwardVelocity = planeVelocity.project(wheels[idx].basis.z)
	var slipAngle = rad_to_deg(planeVelocity.angle_to(forwardVelocity))
	wheels[idx].slip = wheels[idx].pacejkaCurve.sample_baked(slipAngle) # divide for max slip angle
	return wheels[idx].slip

func calculateWeightTransfer():
	var totalForce = 0
	# first find total suspension force
	for idx in wheels.size():
		totalForce += wheels[idx].springForce
	# now use it to find percentage of vehicle's weight being applied at wheel
	for idx in wheels.size():
		var percentage = wheels[idx].springForce / totalForce
		wheels[idx].weightAtWheel = mass * percentage
		wheels[idx].maxDriveForce = wheels[idx].weightAtWheel * 9.8

func getPointVelocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - (global_position + center_of_mass))

# input functions
func updateSteering():
	for wheel in wheels:
		if wheel.steerable:
			wheel.setSteering(input.steer)

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

func debugAcceleration(pos1, pos2) -> ImmediateMesh:
	var accelerationDebugMesh = ImmediateMesh.new()
	accelerationDebugMesh.surface_begin(Mesh.PRIMITIVE_LINES)
	accelerationDebugMesh.surface_add_vertex(pos1)
	accelerationDebugMesh.surface_add_vertex(pos2)
	accelerationDebugMesh.surface_end()
	return accelerationDebugMesh
