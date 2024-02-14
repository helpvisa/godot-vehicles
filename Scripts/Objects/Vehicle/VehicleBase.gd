extends RigidBody3D

# public / inspector-settable
@export var engine: Resource
@export var transmission: Resource
@export var wheels: Array[Node] # assign child nodes manually here

var input = {
	"accel": 0.0,
	"brake": 0.0,
	"steer": 0.0,
}

func _ready():
	for wheel in wheels:
		wheel.initModel()


func _physics_process(_delta):
	for wheel in wheels:
		wheel.updateWheelPosition(self)
		# calculate suspension forces and apply them to the rigidbody
		if wheel.isGrounded:
			var suspensionForce = wheel.calculateSuspensionForce(self)
			var velocityAtWheel = get_point_velocity(wheel.global_position)
			velocityAtWheel = velocityAtWheel.project(-global_transform.basis.y)
			var suspensionDampingForce = velocityAtWheel * -wheel.suspensionDamping
			var totalAppliedForce = suspensionForce + suspensionDampingForce
			apply_force(totalAppliedForce, wheel.position)

# custom functions
func get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)
