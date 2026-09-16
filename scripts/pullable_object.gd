class_name PullableObject
extends RigidBody3D

@onready var tongue_hitbox := get_node_or_null("TongueHitbox") as Area3D

var _original_parent: Node = null
var _body_layer: int = 0
var _body_mask: int = 0
var _hitbox_layer: int = 0
var _hitbox_mask: int = 0
var _hitbox_monitoring: bool = true
var _hitbox_monitorable: bool = true


func prepare_for_pull() -> void:
	_original_parent = get_parent()
	_store_collision_state()

	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func attach_to(carry_point: Marker3D) -> void:
	_set_collisions_enabled(false)
	reparent(carry_point, true)
	position = Vector3.ZERO
	rotation = Vector3.ZERO


func spit(
	actor: PhysicsBody3D,
	forward: Vector3,
	upward_amount: float,
	impulse: float,
	spin: float,
	collision_grace: float
) -> void:
	var target_parent := _original_parent

	if not is_instance_valid(target_parent):
		target_parent = get_tree().current_scene

	reparent(target_parent, true)
	_set_collisions_enabled(true)

	if actor != null:
		add_collision_exception_with(actor)

	var direction := (
		forward.normalized()
		+ Vector3.UP * upward_amount
	).normalized()

	freeze = false
	sleeping = false
	apply_central_impulse(direction * impulse)
	apply_torque_impulse(Vector3.RIGHT * spin)
	_original_parent = null

	await get_tree().create_timer(collision_grace).timeout

	if is_instance_valid(actor):
		remove_collision_exception_with(actor)


func _store_collision_state() -> void:
	_body_layer = collision_layer
	_body_mask = collision_mask

	if tongue_hitbox != null:
		_hitbox_layer = tongue_hitbox.collision_layer
		_hitbox_mask = tongue_hitbox.collision_mask
		_hitbox_monitoring = tongue_hitbox.monitoring
		_hitbox_monitorable = tongue_hitbox.monitorable


func _set_collisions_enabled(enabled: bool) -> void:
	if enabled:
		collision_layer = _body_layer
		collision_mask = _body_mask
	else:
		collision_layer = 0
		collision_mask = 0

	if tongue_hitbox == null:
		return

	if enabled:
		tongue_hitbox.collision_layer = _hitbox_layer
		tongue_hitbox.collision_mask = _hitbox_mask
		tongue_hitbox.monitoring = _hitbox_monitoring
		tongue_hitbox.monitorable = _hitbox_monitorable
	else:
		tongue_hitbox.collision_layer = 0
		tongue_hitbox.collision_mask = 0
		tongue_hitbox.monitoring = false
		tongue_hitbox.monitorable = false
