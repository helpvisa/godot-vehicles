extends Node

@export var steerSpeed: float = 2
@export var throttleSpeed: float = 10
@export var brakeSpeed: float = 10
@export var axles: Array[Node]
@export var engine: Node
@export var transmission: Node
@export var vehicle: Node

var steering: float = 0
var steeringTarget: float = 0
var throttle: float = 0
var throttleTarget: float = 9
var brake: float = 0
var brakeTarget: float = 0

func _process(delta):
	gatherInput(delta)
	passInput()

# functions
func gatherInput(delta):
	# steering
	steeringTarget = Input.get_action_strength("steer_left")
	steeringTarget -= Input.get_action_strength("steer_right")
	steering = lerp(steering, steeringTarget, steerSpeed * delta)
	
	# throttle & brake
	throttleTarget = Input.get_action_strength("accelerate")
	if throttleTarget < throttle:
		throttle = lerp(throttle, throttleTarget, throttleSpeed * delta * 10)
	else:
		throttle = lerp(throttle, throttleTarget, throttleSpeed * delta)
	brakeTarget = Input.get_action_strength("brake")
	if brakeTarget < brake:
		brake = lerp(brake, brakeTarget, brakeSpeed * delta * 10)
	else:
		brake = lerp(brake, brakeTarget, brakeSpeed * delta)
	
	# shifting
	if Input.is_action_just_pressed("shift_up"):
		transmission.shiftUp()
	if Input.is_action_just_pressed("shift_down"):
		transmission.shiftDown()

func passInput():
	for axle in axles:
		axle.steeringInput = steering
	engine.throttle = throttle
	vehicle.brake = brake
