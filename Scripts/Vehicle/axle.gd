extends Node3D

# public / settable (all measurements in meters)
@export var front: bool = true
@export var wheels: Array[Node] # wheels; needs two, 0 is left 1 is right
@export var wheelBase: float = 2.4
@export var rearTrack: float = 1.5
@export var turnRadius: float = 4

# local
var steeringInput: float = 0
var ackermannAngleLeft: float = 0 # for left wheel
var ackermannAngleRight: float = 0 # for right wheel
var currentRPM: float = 0

func _physics_process(_delta):
	if steeringInput > 0: # turning left
		ackermannAngleRight = rad_to_deg(atan(wheelBase / (turnRadius + (rearTrack / 2)))) * steeringInput
		ackermannAngleLeft = rad_to_deg(atan(wheelBase / (turnRadius - (rearTrack / 2)))) * steeringInput
	elif steeringInput < 0: # turning right
		ackermannAngleRight = rad_to_deg(atan(wheelBase / (turnRadius - (rearTrack / 2)))) * steeringInput
		ackermannAngleLeft = rad_to_deg(atan(wheelBase / (turnRadius + (rearTrack / 2)))) * steeringInput
	else:
		ackermannAngleLeft = 0
		ackermannAngleRight = 0
	rotateWheels()

func rotateWheels():
	for idx in wheels.size():
		if idx == 0:
			wheels[idx].rotation = wheels[idx].baseRotation + Vector3(0, deg_to_rad(ackermannAngleLeft), 0)
		else:
			wheels[idx].rotation = wheels[idx].baseRotation + Vector3(0, deg_to_rad(ackermannAngleRight), 0)

func updateRPM() -> float: # will have to update to factor in differential
	var averageRPM = 0
	for wheel in wheels: # will have to update to factor in differential
		averageRPM += wheel.angularVelocity * 60 / (2 * PI)
	averageRPM /= wheels.size()
	currentRPM = averageRPM
	return currentRPM
