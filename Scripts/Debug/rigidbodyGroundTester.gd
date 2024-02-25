extends RigidBody3D

@export var forceStrength: float = 100000


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if Input.get_action_strength("debug_rigidbody") > 0:
		apply_central_force(global_transform.basis.z * forceStrength)
