extends Node

@export var steerSpeed: float = 2

var parentVehicle: RigidBody3D
var steering: float = 0
var target: float = 0

func _ready():
	parentVehicle = get_parent()

func _process(delta):
	gatherInput(delta)
	passInput()

# functions
func gatherInput(delta):
	# keyboard
	target = Input.get_action_strength("steer_left")
	target -= Input.get_action_strength("steer_right")
	steering = lerp(steering, target, steerSpeed * delta)
	
	steering = clamp(steering, -1, 1)
	# joypad

func passInput():
	if parentVehicle.input:
		parentVehicle.input.steer = steering
