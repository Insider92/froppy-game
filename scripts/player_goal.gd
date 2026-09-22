class_name PlayerGoal
extends Area3D

signal completed


## UI shown after Froppy reaches the goal.
@export var win_screen: Control

## Pauses the game after winning.
@export var pause_on_win: bool = true

## Time Froppy must remain completely inside the goal.
@export_range(0.0, 2.0, 0.05, "suffix:s")
var required_stay_time: float = 0.35

## Additional distance Froppy must keep from the goal's edge.
@export_range(0.0, 0.5, 0.01, "suffix:m")
var edge_margin: float = 0.05


@onready var goal_collision: CollisionShape3D = $CollisionShape3D


var frog_inside: CharacterBody3D = null
var time_fully_inside: float = 0.0
var is_completed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if win_screen != null:
		win_screen.hide()


func _physics_process(delta: float) -> void:
	if is_completed or frog_inside == null:
		return

	if _is_frog_fully_inside(frog_inside):
		time_fully_inside += delta

		if time_fully_inside >= required_stay_time:
			_complete_goal()
	else:
		time_fully_inside = 0.0


func _on_body_entered(body: Node3D) -> void:
	if is_completed:
		return

	# Froppy is currently our only CharacterBody3D.
	if body is CharacterBody3D:
		frog_inside = body as CharacterBody3D
		time_fully_inside = 0.0


func _on_body_exited(body: Node3D) -> void:
	if body == frog_inside:
		frog_inside = null
		time_fully_inside = 0.0


func _is_frog_fully_inside(frog: CharacterBody3D) -> bool:
	var goal_shape: CylinderShape3D = (
		goal_collision.shape as CylinderShape3D
	)

	if goal_shape == null:
		push_warning(
			"PlayerGoal requires a CylinderShape3D."
		)
		return false

	var frog_collision: CollisionShape3D = (
		frog.get_node_or_null("CollisionShape3D") as CollisionShape3D
	)

	if frog_collision == null:
		push_warning(
			"Froppy requires a direct child named CollisionShape3D."
		)
		return false

	var frog_shape: CapsuleShape3D = (
		frog_collision.shape as CapsuleShape3D
	)

	if frog_shape == null:
		push_warning(
			"Froppy's CollisionShape3D requires a CapsuleShape3D."
		)
		return false

	# Position of Froppy relative to the center of the goal.
	var local_frog_position: Vector3 = goal_collision.to_local(
		frog_collision.global_position
	)

	# Only check the horizontal X/Z distance.
	var distance_from_center: float = Vector2(
		local_frog_position.x,
		local_frog_position.z
	).length()

	# Froppy is fully inside when its outer edge remains
	# within the radius of the goal.
	return (
		distance_from_center
		+ frog_shape.radius
		+ edge_margin
		<= goal_shape.radius
	)


func _complete_goal() -> void:
	if is_completed:
		return

	is_completed = true

	if win_screen != null:
		win_screen.show()

	completed.emit()

	if pause_on_win:
		get_tree().paused = true
