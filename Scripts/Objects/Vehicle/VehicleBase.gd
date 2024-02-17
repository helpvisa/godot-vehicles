extends RigidBody3D

# public / inspector-settable
@export var engine: Resource
@export var transmission: Resource
@export var wheels: Array[Node] # assign child nodes manually here

# debug
var suspensionDebugDisplay: Array[MeshInstance3D]
var steeringDebugDisplay: Array[MeshInstance3D]
@export var suspensionDebugMaterial: StandardMaterial3D
@export var steeringDebugMaterial: StandardMaterial3D

var input = {
	"accel": 0.0,
	"brake": 0.0,
	"steer": 0.0,
}

func _ready():
	suspensionDebugMaterial.no_depth_test = true
	steeringDebugMaterial.no_depth_test = true
	
	for wheel in wheels:
		wheel.initModel()
		var tempSuspensionDebugMesh = MeshInstance3D.new()
		var tempSteeringDebugMesh = MeshInstance3D.new()
		suspensionDebugDisplay.append(tempSuspensionDebugMesh)
		suspensionDebugDisplay[suspensionDebugDisplay.size() - 1].material_override = suspensionDebugMaterial
		add_child(suspensionDebugDisplay[suspensionDebugDisplay.size() - 1])
		steeringDebugDisplay.append(tempSteeringDebugMesh)
		steeringDebugDisplay[steeringDebugDisplay.size() - 1].material_override = steeringDebugMaterial
		add_child(steeringDebugDisplay[steeringDebugDisplay.size() - 1])

func _physics_process(_delta):
	for idx in wheels.size():
		wheels[idx].updateWheelPosition(self)
		# calculate suspension forces and apply them to the rigidbody
		if wheels[idx].isGrounded:
			var suspensionForce = wheels[idx].calculateSuspensionForce(self)
			var wheelPointVelocity = get_point_velocity(wheels[idx].target)
			var suspensionDampingForce = wheelPointVelocity.project(basis.y)
			suspensionDampingForce *= wheels[idx].suspensionDamping
			var totalAppliedForce = suspensionForce - suspensionDampingForce
			apply_force(totalAppliedForce, wheels[idx].position)
			# draw debug meshes
			var tempSuspensionMesh = debugSuspension(\
				wheels[idx].position,\
				wheels[idx].position + totalAppliedForce/1000)
			suspensionDebugDisplay[idx].mesh = tempSuspensionMesh
			# apply steering forces
			var flatPlane = Plane(wheels[idx].normal)
			var planeVelocityAtWheel = flatPlane.project(wheelPointVelocity)
			var steeringForce = planeVelocityAtWheel.project(wheels[idx].basis.x)
			apply_force(-steeringForce * 1000, wheels[idx].position)
			# draw debug meshes
			var tempSteeringMesh = debugSteering(\
				wheels[idx].position,\
				wheels[idx].position - steeringForce)
			steeringDebugDisplay[idx].mesh = tempSteeringMesh
		else:
			suspensionDebugDisplay[idx].mesh = null
			steeringDebugDisplay[idx].mesh = null

# custom functions
func get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - (global_position + center_of_mass))

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
