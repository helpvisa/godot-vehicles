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
@export var rollingResistance: float = 1
@export_flags_3d_physics var colMask

# local
var baseRotation: Vector3 = Vector3.ZERO
var offset: Vector3 = Vector3.ZERO
var target: Vector3 = Vector3.ZERO
var normal: Vector3 = Vector3.ZERO
var springLength: float = 0
var previousSpringLength: float = 0
var springForce: float = 0
var springVelocity: float = 0
var suspensionOffset: float = suspensionRange
var steering: float = 0
var isGrounded: bool = false
var currentRPM: float = 0
var slip: float = 1
var grip: float = 1
var maxDriveForce: float = 1400 * 9.8 # m * g; this is a default
var weightAtWheel: float = 0
var instancedModel: Node3D
var pointVelocity: Vector3 = Vector3.ZERO
var previousPointVelocity: Vector3 = Vector3.ZERO
var forwardVelocity: Vector3 = Vector3.ZERO
var angularVelocity: float = 0
var previousAngularVelocity: float = 0

# custom functions
func initModel(parent):
	if model:
		instancedModel = model.instantiate()
		if flipModel:
			instancedModel.rotate(Vector3(0, 1, 0), deg_to_rad(180))
		add_child(instancedModel)
	offset = position
	baseRotation = rotation
	maxDriveForce = parent.mass * 9.8

func updateWheelPosition(parent, delta):
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(\
		global_position + global_basis.y * radius,\
		global_position - global_basis.y * radius - global_basis.y * (suspensionRange - suspensionOffset),\
		colMask)
	var result = space.intersect_ray(query)
	
	if result:
		var distance = result.position.distance_to(global_position + global_basis.y * radius)
		springLength = clamp(distance - radius, 0, suspensionRange)
		target = result.position + global_basis.y * radius
		normal = result.normal
		isGrounded = true
	else:
		suspensionOffset -= delta * (suspensionStrength / 10000)
		suspensionOffset = clamp(suspensionOffset, 0, suspensionRange)
		target = parent.to_global(offset + Vector3.DOWN * (suspensionRange - suspensionOffset))
		normal = Vector3.ZERO
		isGrounded = false
	
	instancedModel.position = to_local(target)

func calculateSuspensionForce(parent, delta) -> Vector3:
	suspensionOffset = suspensionRange - springLength
	springForce = suspensionOffset * suspensionStrength
	springVelocity = (previousSpringLength - springLength) / delta
	previousSpringLength = springLength
	return springForce * global_basis.y

func applyRollingResistance(delta):
	var sign = sign(angularVelocity)
	if (sign > 0):
		angularVelocity -= rollingResistance * delta
	else:
		angularVelocity += rollingResistance * delta

func setSteering(input):
	rotation = baseRotation + Vector3(0, deg_to_rad(30 * input), 0)

func animate(delta):
	instancedModel.rotate_object_local(Vector3(1, 0, 0), -angularVelocity * delta)
