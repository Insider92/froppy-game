class_name SpitGoal
extends Area3D

signal completed

## UI element shown when a pullable object reaches the goal.
@export var win_screen: Control

## Pauses the game after the goal is completed.
@export var pause_on_win: bool = true

@onready var goal_collision: CollisionShape3D = $CollisionShape3D

var is_completed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if win_screen != null:
		win_screen.hide()


func _on_body_entered(body: Node3D) -> void:
	if (
		is_completed
		or not body.is_in_group("tongue_pullable")
	):
		return

	# Keep checking while the object overlaps the goal.
	while (
		is_instance_valid(body)
		and overlaps_body(body)
		and not is_completed
	):
		if _is_fully_inside_goal(body):
			_complete_goal(body)
			return

		await get_tree().physics_frame


func _is_fully_inside_goal(body: Node3D) -> bool:
	var goal_shape := goal_collision.shape as CylinderShape3D
	var body_collision := (
		body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	)

	if goal_shape == null or body_collision == null:
		return false

	var box_shape := body_collision.shape as BoxShape3D

	if box_shape == null:
		return false

	var half_size: Vector3 = box_shape.size / 2.0

	# Check every corner of the rotated box.
	for x_sign: float in [-1.0, 1.0]:
		for y_sign: float in [-1.0, 1.0]:
			for z_sign: float in [-1.0, 1.0]:
				var local_corner := Vector3(
					half_size.x * x_sign,
					half_size.y * y_sign,
					half_size.z * z_sign
				)

				var world_corner: Vector3 = (
					body_collision.to_global(local_corner)
				)

				var corner_in_goal: Vector3 = (
					goal_collision.to_local(world_corner)
				)

				var horizontal_distance := Vector2(
					corner_in_goal.x,
					corner_in_goal.z
				).length()

				if horizontal_distance > goal_shape.radius:
					return false

	return true


func _complete_goal(body: Node3D) -> void:
	is_completed = true

	if body is RigidBody3D:
		var rigid_body := body as RigidBody3D
		rigid_body.linear_velocity = Vector3.ZERO
		rigid_body.angular_velocity = Vector3.ZERO
		rigid_body.freeze = true

	if win_screen != null:
		win_screen.show()

	completed.emit()

	if pause_on_win:
		get_tree().paused = true
