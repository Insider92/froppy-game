class_name SpitGoal
extends Area3D

signal completed

## UI element shown when a pullable object reaches the goal.
@export var win_screen: Control

## Pauses the game after the goal is completed.
@export var pause_on_win: bool = true

var is_completed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if win_screen != null:
		win_screen.hide()


func _on_body_entered(body: Node3D) -> void:
	if is_completed or not body.is_in_group("tongue_pullable"):
		return

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

