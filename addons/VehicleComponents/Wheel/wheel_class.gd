@tool
extends Node3D

# public / settable
@export var pacejkaCurve: Curve
@export var model: PackedScene
@export var flipModel: bool = false
@export var radius: float = 0.33
@export var suspensionStrength: float = 24000
@export var suspensionDamping: float = 1800
@export var suspensionRange: float = 0.6
@export var powered: bool = true
@export var steerable: bool = false
@export var brakes: bool = true
@export_flags_3d_physics var colMask

# local
var offset: Vector3 = Vector3.ZERO
var target: Vector3 = Vector3.ZERO
var normal: Vector3 = Vector3.ZERO
var springLength: float = 0
var previousSpringLength: float = 0
var springForce: float = 0
var springVelocity: float = 0
var steering: float = 0
var isGrounded: bool = false
var currentRPM: float = 0
var slip: float = 1
var grip: float = 1
var maxDriveForce: float = 1400 * 9.8 # m * g; this is a default
var weightAtWheel: float = 0
var instancedModel: Node3D

# custom functions
func initModel(parent):
	if model:
		instancedModel = model.instantiate()
		if flipModel:
			instancedModel.rotate(Vector3(0, 1, 0), deg_to_rad(180))
		add_child(instancedModel)
	offset = position
	maxDriveForce = parent.mass * 9.8

func updateWheelPosition(parent):
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(\
		global_position + global_basis.y * radius,\
		global_position - global_basis.y * radius - global_basis.y * suspensionRange,\
		colMask)
	var result = space.intersect_ray(query)
	
	if result:
		var distance = result.position.distance_to(global_position + global_basis.y * radius)
		springLength = clamp(distance - radius, 0, suspensionRange)
		target = result.position + global_basis.y * radius
		normal = result.normal
		isGrounded = true
	else:
		springLength = suspensionRange
		target = parent.to_global(offset + Vector3.DOWN * suspensionRange)
		normal = Vector3.ZERO
		isGrounded = false
	
	instancedModel.global_position = target

func calculateSuspensionForce(parent, delta) -> Vector3:
	var suspensionOffset = suspensionRange - springLength
	springForce = suspensionOffset * suspensionStrength
	springVelocity = (previousSpringLength - springLength) / delta
	previousSpringLength = springLength
	return springForce * basis.y

func setSteering(input):
	rotate(Vector3(0, 1, 0), deg_to_rad(30 * input))
