extends Node

@export var steerSpeed: float = 5

var parentVehicle: RigidBody3D
var steering: float = 0;

func _ready():
	parentVehicle = get_parent()

func _process(delta):
	gatherInput(delta)
	passInput()

# functions
func gatherInput(delta):
	var inputActive = false
	# keyboard
	if Input.is_action_pressed("steer_left_key"):
		inputActive = true
		steering = lerp(steering, 1.0, steerSpeed * delta)
	if Input.is_action_pressed("steer_right_key"):
		inputActive = true
		steering = lerp(steering, -1.0, steerSpeed * delta)
	if !inputActive:
		steering = lerp(steering, 0.0, steerSpeed * delta)
	
	steering = clamp(steering, -1, 1)
	# joypad

func passInput():
	if parentVehicle.input:
		parentVehicle.input.steer = steering
