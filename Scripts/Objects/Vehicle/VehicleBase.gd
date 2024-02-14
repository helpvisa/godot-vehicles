extends Node3D

# public / inspector-settable
@export var engine: Resource
@export var transmission: Resource
@export var wheels: Array[Resource]

var input = {
	"accel": 0.0,
	"brake": 0.0,
	"steer": 0.0,
}

func _ready():
	for wheel in wheels:
		# position wheels based on offsets
		var instanced_node = wheel.model.instantiate()
		instanced_node.position += wheel.offset
		get_node("RigidBody3D").add_child(instanced_node)


func _process(delta):
	pass
