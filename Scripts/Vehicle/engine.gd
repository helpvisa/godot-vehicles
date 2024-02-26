extends Node3D

# public / settable
@export var torqueCurve: Curve
@export var maxRPM: float = 7000 # used for damaging engine, NOT for clamping
@export var minRPM: float = 1000

# local
var throttle: float = 0
var currentRPM: float = 0
var torque: float = 0
var appliedTorque: float = 0

func updateRPM(transmission) -> float:
	currentRPM = transmission.updateRPM() * transmission.gears[transmission.currentGear] * transmission.finalDrive
	currentRPM = max(minRPM, currentRPM)
	return currentRPM

func updateTorque() -> float:
	torque = torqueCurve.sample_baked((currentRPM) / maxRPM)
	appliedTorque = torque * throttle
	return appliedTorque
