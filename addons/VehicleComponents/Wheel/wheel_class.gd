@tool
extends Node3D

# public / settable
@export var offset: Vector3 = Vector3(0, 0, 0)
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
@export var maxDriveForce: float = 1400 * 9.8 # m * g; this is a default
@export_flags_3d_physics var colMask

# local
var target: Vector3 = Vector3.ZERO
var normal: Vector3 = Vector3.ZERO
var previousPosition: Vector3 = Vector3.ZERO
var previousVelocity: Vector3 = Vector3.ZERO
var previousForwardVelocity: Vector3 = Vector3.ZERO
var isGrounded: bool = false
var currentRPM: float = 0
var slip: float = 1
var grip: float = 1
var suspensionForce: float = 1
var appliedWeight: float = 1
var currentDrive: float = 0
var tractionTorque: float = 0
var brakingTorque: float = 0
var angularAcceleration: float = 0
var angularVelocity: float = 0
var appliedAcceleration: float = 0

# custom functions
func initModel():
	#if model:
		# perform check to flip wheel if on left side of car using export var
		#var temp_model = model.instantiate()
		#if flipModel:
			#temp_model.rotate(Vector3(0, 1, 0), deg_to_rad(180))
		#add_child(temp_model)
	position = offset + Vector3.DOWN * suspensionRange

func updateWheelPosition(parent):
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(\
		global_position + parent.basis.y * radius,\
		global_position - parent.basis.y * radius,\
		colMask)
	var result = space.intersect_ray(query)
	
	if result:
		target = result.position + parent.basis.y * radius
		normal = result.normal
		isGrounded = true
	else:
		target = position
		normal = parent.basis.y
		isGrounded = false

func calculateSuspensionForce(parent) -> Vector3:
	var suspensionOffset = target - global_position
	var springForce = suspensionOffset * suspensionStrength
	return springForce
