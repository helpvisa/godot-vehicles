@tool
extends Node3D

# public / settable
@export var tire: Resource
@export var model: PackedScene
@export var flipModel: bool = false
@export var radius: float = 0.33
@export var weight: float = 75 # in kg
@export var rollingResistance: float = 100
@export var suspensionStrength: float = 24000
@export var suspensionDamping: float = 1800
@export var suspensionRange: float = 0.6
@export var powered: bool = true
@export var steerable: bool = false
@export var brakes: bool = true
@export var brakeForce: float = 5000
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
var inertia: float = 1
var slip: float = 1
var grip: float = 1
var lateralGrip: float = 1
var maxDriveForce: float = 1400 * 9.8 # m * g; this is a default
var weightAtWheel: float = 0
var instancedModel: Node3D
var collider: RigidBody3D = null
var colliderPoint: Vector3 = Vector3.ZERO
var pointVelocity: Vector3 = Vector3.ZERO
var previousPointVelocity: Vector3 = Vector3.ZERO
var forwardVelocity: Vector3 = Vector3.ZERO
var forwardDirection: Vector3 = Vector3.ZERO
var lateralVelocity: Vector3 = Vector3.ZERO
var dir: int = 0
var angularVelocity: float = 0
var previousAngularVelocity: float = 0

# custom functions
func initModel(parent):
	if model:
		instancedModel = model.instantiate()
		instancedModel.scale *= radius
		if flipModel:
			instancedModel.rotate(Vector3(0, 1, 0), deg_to_rad(180))
		add_child(instancedModel)
	inertia = weight * (radius * radius) / 2
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
		if result.collider is RigidBody3D:
			collider = result.collider
			colliderPoint = result.position
		else:
			collider = null
			colliderPoint = Vector3.ZERO
	else:
		suspensionOffset -= delta * (suspensionStrength / 10000)
		suspensionOffset = clamp(suspensionOffset, 0, suspensionRange)
		target = parent.to_global(offset + Vector3.DOWN * (suspensionRange - suspensionOffset))
		normal = Vector3.ZERO
		isGrounded = false
	
	instancedModel.position = lerp(instancedModel.position, to_local(target), delta * 50)

func calculateSuspensionForce(delta) -> Vector3:
	suspensionOffset = suspensionRange - springLength
	springForce = suspensionOffset * suspensionStrength
	springVelocity = (previousSpringLength - springLength) / delta
	previousSpringLength = springLength
	return springForce * global_basis.y

func getLateralSlip() -> float:
	slip = rad_to_deg(lateralVelocity.angle_to(pointVelocity))
	return slip

func animate(delta):
	if !flipModel:
		instancedModel.rotate_object_local(Vector3(1, 0, 0), -angularVelocity * delta)
	else:
		instancedModel.rotate_object_local(Vector3(1, 0, 0), angularVelocity * delta)
