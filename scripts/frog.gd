extends CharacterBody3D

@export_group("Movement")
## Horizontal movement speed in meters per second.
@export_range(0.1, 20.0, 0.1, "suffix:m/s")
var move_speed: float = 5.0

@export var camera: Camera3D

@onready var visuals: Node3D = $Visuals
@onready var shake_pivot: Node3D = $Visuals/ShakePivot
@onready var feedback_animation_player: AnimationPlayer = (
	$Visuals/FeedbackAnimationPlayer
)
@onready var tongue: TongueController = $TongueController

var action_active: bool = false


func _ready() -> void:
	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		push_error("Frog could not find an active Camera3D.")
		
	tongue.action_started.connect(_on_action_started)
	tongue.action_finished.connect(_on_action_finished)


func _physics_process(delta: float) -> void:
	if camera == null:
		return

	_handle_action_input()

	if action_active:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		_update_movement()

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	if not action_active:
		_update_aim()


func _handle_action_input() -> void:
	if action_active:
		return

	if Input.is_action_just_pressed("spit_object"):
		if tongue.has_carried_object():
			tongue.spit()

	elif Input.is_action_just_pressed("use_tongue"):
		if tongue.has_carried_object():
			_play_mouth_full_shake()
		else:
			tongue.use_tongue()


func _update_movement() -> void:
	var input_direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var right: Vector3 = camera.global_basis.x
	var backward: Vector3 = camera.global_basis.z

	right.y = 0.0
	backward.y = 0.0

	right = right.normalized()
	backward = backward.normalized()

	var direction: Vector3 = (
		right * input_direction.x
		+ backward * input_direction.y
	)

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed


func _update_aim() -> void:
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse_position)

	var ground_plane := Plane(Vector3.UP, global_position.y)
	var hit: Variant = ground_plane.intersects_ray(ray_origin, ray_direction)

	if hit == null:
		return

	var target: Vector3 = hit
	target.y = visuals.global_position.y

	if visuals.global_position.distance_to(target) < 0.05:
		return

	visuals.look_at(target, Vector3.UP)


func _play_mouth_full_shake() -> void:
	if action_active:
		return

	if not feedback_animation_player.has_animation("mouth_full_shake"):
		push_warning("Animation 'mouth_full_shake' is missing.")
		return

	action_active = true
	feedback_animation_player.play("mouth_full_shake")
	await feedback_animation_player.animation_finished

	shake_pivot.position = Vector3.ZERO
	shake_pivot.rotation = Vector3.ZERO
	action_active = false


func _on_action_started() -> void:
	action_active = true


func _on_action_finished() -> void:
	action_active = false
