extends Node3D

@export var target: Node3D
@export var factor: float = 0.1
var targetVelocity: Vector3 = Vector3.ZERO
var targetBasis: Vector3 = Vector3.ZERO

func _process(delta):
	if Node3D:
		targetVelocity = targetVelocity.lerp(target.linear_velocity, delta)
		var leftBasis = Input.get_action_strength("look_left") * -target.global_basis.x * 10
		var rightBasis = Input.get_action_strength("look_right") * target.global_basis.x * 10
		var newTarget = -target.global_basis.z + leftBasis + rightBasis
		targetBasis = lerp(targetBasis, newTarget, delta * 10)
		global_position = lerp(global_position, target.global_position, delta * 10)
		look_at(target.global_position + targetBasis + (targetVelocity * factor))
