class_name TongueController
extends Node

signal action_started
signal action_finished

@export_group("Scene References")
@export var tongue_origin: Marker3D
@export var tongue_ray: RayCast3D
@export var tongue_mesh: MeshInstance3D
@export var mouth_carry_point: Marker3D

@export_group("Tongue")
## Maximum range of the tongue in meters.
@export_range(0.5, 10.0, 0.1, "suffix:m")
var tongue_range: float = 3.0

## Time required for the tongue to fully extend.
@export_range(0.01, 1.0, 0.01, "suffix:s")
var tongue_extend_duration: float = 0.08

## Time that the tongue remains fully extended.
@export_range(0.0, 1.0, 0.01, "suffix:s")
var tongue_hold_duration: float = 0.4

## Time required for the tongue to fully retract.
@export_range(0.01, 1.0, 0.01, "suffix:s")
var tongue_retract_duration: float = 0.2

@export_group("Spit")
## Strength of the impulse applied to a spat-out object.
@export_range(0.5, 20.0, 0.5)
var spit_impulse: float = 6.0

## Upward component of the spit direction.
@export_range(0.0, 1.0, 0.05)
var spit_upward_amount: float = 0.25

## Rotational impulse applied to the object.
@export_range(0.0, 10.0, 0.5)
var spit_spin: float = 0.0

## Time during which the object ignores collisions with Froppy.
@export_range(0.05, 1.0, 0.05, "suffix:s")
var spit_collision_grace: float = 0.2

var _busy: bool = false
var _carried_object: PullableObject = null


func _ready() -> void:
	var actor := get_parent() as CharacterBody3D

	if tongue_origin == null or tongue_ray == null or tongue_mesh == null:
		push_error("TongueController scene references are incomplete.")
		return

	if actor != null:
		tongue_ray.add_exception(actor)

	tongue_ray.target_position = Vector3(0.0, 0.0, -tongue_range)
	tongue_mesh.visible = false


func has_carried_object() -> bool:
	return is_instance_valid(_carried_object)


func use_tongue() -> void:
	if _busy or has_carried_object():
		return

	_busy = true
	action_started.emit()

	tongue_origin.rotation = Vector3.ZERO
	tongue_ray.force_raycast_update()

	var end_point: Vector3
	var pullable: PullableObject = null

	if tongue_ray.is_colliding():
		end_point = tongue_ray.get_collision_point()
		pullable = _find_pullable(tongue_ray.get_collider())

		if pullable != null:
			var anchor := pullable.get_node_or_null("TongueAnchor") as Node3D
			if anchor != null:
				end_point = anchor.global_position
	else:
		end_point = tongue_ray.to_global(tongue_ray.target_position)

	tongue_origin.look_at(end_point, Vector3.UP)
	var tongue_length := tongue_origin.global_position.distance_to(end_point)

	await _extend_tongue(tongue_length)
	await get_tree().create_timer(tongue_hold_duration).timeout

	if pullable != null:
		pullable.prepare_for_pull()

	await _retract_tongue(pullable)

	if pullable != null:
		pullable.attach_to(mouth_carry_point)
		_carried_object = pullable

	_finish_action()


func spit() -> void:
	if _busy or not has_carried_object():
		return

	_busy = true
	action_started.emit()

	var object := _carried_object
	_carried_object = null

	var actor := get_parent() as PhysicsBody3D
	var forward := -tongue_origin.global_basis.z.normalized()

	await object.spit(
		actor,
		forward,
		spit_upward_amount,
		spit_impulse,
		spit_spin,
		spit_collision_grace
	)

	_busy = false
	action_finished.emit()


func _find_pullable(collider: Object) -> PullableObject:
	var candidate := collider as Node

	if candidate is Area3D:
		candidate = candidate.get_parent()

	if (
		candidate is PullableObject
		and candidate.is_in_group("tongue_pullable")
	):
		return candidate as PullableObject

	return null


func _extend_tongue(tongue_length: float) -> void:
	tongue_mesh.visible = true
	tongue_mesh.position = Vector3.ZERO
	tongue_mesh.scale = Vector3(1.0, 0.01, 1.0)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		tongue_mesh,
		"position:z",
		-tongue_length / 2.0,
		tongue_extend_duration
	)
	tween.tween_property(
		tongue_mesh,
		"scale:y",
		tongue_length,
		tongue_extend_duration
	)
	await tween.finished


func _retract_tongue(pullable: PullableObject) -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		tongue_mesh,
		"position:z",
		0.0,
		tongue_retract_duration
	)
	tween.tween_property(
		tongue_mesh,
		"scale:y",
		0.01,
		tongue_retract_duration
	)

	if pullable != null:
		tween.tween_property(
			pullable,
			"global_position",
			mouth_carry_point.global_position,
			tongue_retract_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween.finished


func _finish_action() -> void:
	tongue_mesh.visible = false
	tongue_origin.rotation = Vector3.ZERO
	_busy = false
	action_finished.emit()

