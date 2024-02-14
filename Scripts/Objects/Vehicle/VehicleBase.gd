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
	pass


func _process(delta):
	pass
