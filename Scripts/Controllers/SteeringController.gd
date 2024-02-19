extends Node

@export var steerSpeed: float = 10

var parentVehicle: RigidBody3D
var steering = 0;

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
		steering -= steerSpeed * delta
	if Input.is_action_pressed("steer_right_key"):
		inputActive = true
		steering += steerSpeed * delta
	if !inputActive:
		var sign = sign(steering)
		if sign > 0:
			steering -= steerSpeed * delta
		else:
			steering += steerSpeed * delta
	if abs(steering) < 0.01:
		steering = 0
	
	steering = clamp(steering, -1, 1)
	# joypad

func passInput():
	if parentVehicle.input:
		parentVehicle.input.steer = steering
