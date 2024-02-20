extends Camera3D

@export var target: Node3D
@export var factor: float = 0.1
var targetVelocity: Vector3 = Vector3.ZERO

func _process(delta):
	if Node3D:
		targetVelocity = targetVelocity.lerp(target.linear_velocity, delta)
		look_at(target.global_position - target.global_basis.z + (targetVelocity * factor))
