extends Camera3D

@export var target: Node3D
var moveTarget = Vector3.ZERO

func _ready():
	moveTarget = global_position

func _process(delta):
	if Node3D:
		look_at(target.global_position)
		if target.global_position.distance_squared_to(global_position) > 300:
			var movement = (target.global_position - global_position)
			moveTarget += movement.normalized() * 0.1
		global_position = global_position.lerp(moveTarget, delta)
