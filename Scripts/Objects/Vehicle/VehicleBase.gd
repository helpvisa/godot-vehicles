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
		var instanced_mesh_container = Node3D.new()
		var instanced_mesh = MeshInstance3D.new()
		instanced_mesh.mesh = wheel.model
		instanced_mesh_container.add_child(instanced_mesh)
		instanced_mesh_container.position += wheel.offset
		instanced_mesh_container.rotate_object_local(Vector3(0, 0, 1), deg_to_rad(90))
		get_node("RigidBody3D").add_child(instanced_mesh_container)


func _process(delta):
	pass
