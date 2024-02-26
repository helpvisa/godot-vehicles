extends Node3D

# public / settable
@export var axles: Array[Node]
@export var gears: Array[float]
@export var finalDrive: float = 3.42
@export var transmissionLoss: float = 0.7

# local
var currentGear: int = 1 # 0 is reverse
var currentRPM: float = 0
var maxAllowedAngularVelocity: float = 0

func updateRPM() -> float:
	var averageRPM = 0
	for axle in axles: # will have to update to factor in differential
		averageRPM += axle.updateRPM()
	averageRPM /= axles.size()
	currentRPM = averageRPM
	return currentRPM

func shiftUp():
	currentGear += 1
	currentGear = min(currentGear, gears.size() - 1)

func shiftDown():
	currentGear -= 1
	currentGear = max(currentGear, 0)

func setGear(gear):
	currentGear = gear
	currentGear = clamp(currentGear, 0, gears.size() - 1)
