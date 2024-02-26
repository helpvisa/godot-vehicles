extends RichTextLabel

@export var targetEngine: Node
@export var targetTransmission: Node

func _process(_delta):
	text = str("Engine RPM and Applied Torque: ", int(targetEngine.currentRPM), " | ", int(targetEngine.appliedTorque), \
		"\nTransmission RPM: ", int(targetTransmission.currentRPM), \
		"\nCurrent Gear and Ratio: ", targetTransmission.currentGear, " | ", targetTransmission.gears[targetTransmission.currentGear], \
		"\nSpeed (kmh): ", int((targetTransmission.currentRPM * (2 * PI) / 60 * 0.33) * 3.6))
