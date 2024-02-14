@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("CustomWheel", "Node3D", preload("wheel_class.gd"), preload("icon.svg"))


func _exit_tree():
	remove_custom_type("CustomWheel")
