class_name HopVisualAnimator
extends Node3D

@export_group("Takeoff")
## Time spent squashing before the visual stretch.
@export_range(0.01, 0.3, 0.01, "suffix:s")
var takeoff_squash_duration: float = 0.05

## Time spent stretching upward after the squash.
@export_range(0.01, 0.3, 0.01, "suffix:s")
var takeoff_stretch_duration: float = 0.06

## Time required to return to the neutral shape.
@export_range(0.01, 0.3, 0.01, "suffix:s")
var takeoff_recover_duration: float = 0.07

## Relative scale used for the takeoff squash.
@export var takeoff_squash_scale := Vector3(1.08, 0.86, 1.08)

## Relative scale used for the takeoff stretch.
@export var takeoff_stretch_scale := Vector3(0.95, 1.10, 0.95)

## Vertical visual offset during the takeoff squash.
@export_range(-0.5, 0.5, 0.01, "suffix:m")
var takeoff_squash_y: float = -0.04

## Vertical visual offset during the takeoff stretch.
@export_range(-0.5, 0.5, 0.01, "suffix:m")
var takeoff_stretch_y: float = 0.04

@export_group("Landing")
## Time spent squashing immediately after landing.
@export_range(0.01, 0.3, 0.01, "suffix:s")
var landing_squash_duration: float = 0.04

## Time spent rebounding after the landing squash.
@export_range(0.01, 0.3, 0.01, "suffix:s")
var landing_rebound_duration: float = 0.08

## Time required to return to the neutral shape.
@export_range(0.01, 0.3, 0.01, "suffix:s")
var landing_recover_duration: float = 0.08

## Relative scale used when Froppy touches the floor.
@export var landing_squash_scale := Vector3(1.10, 0.82, 1.10)

## Relative scale used for the small landing rebound.
@export var landing_rebound_scale := Vector3(0.97, 1.05, 0.97)

## Vertical visual offset during the landing squash.
@export_range(-0.5, 0.5, 0.01, "suffix:m")
var landing_squash_y: float = -0.05

## Vertical visual offset during the landing rebound.
@export_range(-0.5, 0.5, 0.01, "suffix:m")
var landing_rebound_y: float = 0.02

var _active_tween: Tween
var _neutral_position: Vector3
var _neutral_scale: Vector3


func _ready() -> void:
	_neutral_position = position
	_neutral_scale = scale


func play_takeoff() -> void:
	_reset_visuals()

	_active_tween = create_tween()
	_active_tween.set_trans(Tween.TRANS_QUAD)
	_active_tween.set_ease(Tween.EASE_OUT)

	_tween_transform(
		_neutral_position + Vector3.UP * takeoff_squash_y,
		_neutral_scale * takeoff_squash_scale,
		takeoff_squash_duration
	)
	_tween_transform(
		_neutral_position + Vector3.UP * takeoff_stretch_y,
		_neutral_scale * takeoff_stretch_scale,
		takeoff_stretch_duration
	)
	_tween_transform(
		_neutral_position,
		_neutral_scale,
		takeoff_recover_duration
	)


func play_land() -> void:
	_reset_visuals()

	_active_tween = create_tween()
	_active_tween.set_trans(Tween.TRANS_QUAD)
	_active_tween.set_ease(Tween.EASE_OUT)

	_tween_transform(
		_neutral_position + Vector3.UP * landing_squash_y,
		_neutral_scale * landing_squash_scale,
		landing_squash_duration
	)
	_tween_transform(
		_neutral_position + Vector3.UP * landing_rebound_y,
		_neutral_scale * landing_rebound_scale,
		landing_rebound_duration
	)
	_tween_transform(
		_neutral_position,
		_neutral_scale,
		landing_recover_duration
	)


func _tween_transform(
	target_position: Vector3,
	target_scale: Vector3,
	duration: float
) -> void:
	_active_tween.tween_property(
		self,
		"position",
		target_position,
		duration
	)
	_active_tween.parallel().tween_property(
		self,
		"scale",
		target_scale,
		duration
	)


func _reset_visuals() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()

	position = _neutral_position
	scale = _neutral_scale
