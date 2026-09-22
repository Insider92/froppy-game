extends CharacterBody3D

@export_group("Movement")
## Horizontal movement speed in meters per second.
@export_range(0.1, 20.0, 0.1, "suffix:m/s")
var move_speed: float = 3.0

@export_range(0.05, 2.0, 0.05, "suffix:m")
var hop_height: float = 0.25

@export_range(0.0, 0.5, 0.01, "suffix:s")
var hop_landing_pause: float = 0.08

## Maximum turning speed in degrees per second.
## At 360 deg/s, a 180-degree turn takes half a second.
@export_range(45.0, 1080.0, 5.0, "suffix:deg/s")
var turn_speed_degrees: float = 360.0

## Allows Froppy to visually turn while airborne.
@export var allow_turning_while_hopping: bool = false

## Allows changing the actual movement direction while airborne.
@export var allow_steering_while_hopping: bool = false

## How quickly Froppy changes horizontal velocity while steering in the air.
@export_range(0.1, 30.0, 0.1, "suffix:m/s²")
var air_steering_acceleration: float = 6.0

## Allows tongue, spit and mouth-full actions while airborne.
@export var allow_actions_while_hopping: bool = false

@export var camera: Camera3D

@onready var visuals: Node3D = $Visuals
@onready var shake_pivot: Node3D = $Visuals/ShakePivot
@onready var feedback_animation_player: AnimationPlayer = (
	$Visuals/FeedbackAnimationPlayer
)
@onready var tongue: TongueController = $TongueController
@onready var hop_visual_animator: HopVisualAnimator = (
	$Visuals/ShakePivot/HopVisualPivot
)

var action_active: bool = false
var hop_pause_remaining: float = 0.0



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

	var was_on_floor: bool = is_on_floor()

	# Update facing before calculating the next hop direction.
	var can_turn: bool = (
		not action_active
		and (
			is_on_floor()
			or allow_turning_while_hopping
		)
	)

	if can_turn:
		_update_aim(delta)

	hop_pause_remaining = maxf(
		hop_pause_remaining - delta,
		0.0
	)

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	if action_active:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		_update_movement(delta)

	move_and_slide()

	if not was_on_floor and is_on_floor():
		velocity.x = 0.0
		velocity.z = 0.0
		hop_pause_remaining = hop_landing_pause
		
		hop_visual_animator.play_land()


func _handle_action_input() -> void:
	if action_active:
		return

	if not is_on_floor() and not allow_actions_while_hopping:
		return

	if Input.is_action_just_pressed("spit_object"):
		if tongue.has_carried_object():
			tongue.spit()

	elif Input.is_action_just_pressed("use_tongue"):
		if tongue.has_carried_object():
			_play_mouth_full_shake()
		else:
			tongue.use_tongue()


func _update_movement(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	# No input: stop only when standing on the floor.
	# Air momentum remains unchanged.
	if input_direction.is_zero_approx():
		if is_on_floor():
			velocity.x = 0.0
			velocity.z = 0.0

		return

	# Movement is relative to Froppy's current facing direction.
	var right: Vector3 = visuals.global_basis.x
	var backward: Vector3 = visuals.global_basis.z

	right.y = 0.0
	backward.y = 0.0

	right = right.normalized()
	backward = backward.normalized()

	var direction: Vector3 = (
		right * input_direction.x
		+ backward * input_direction.y
	)

	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	# Froppy is already airborne.
	if not is_on_floor():
		if allow_steering_while_hopping:
			var desired_velocity: Vector3 = direction * move_speed
			var steering_step: float = (
				air_steering_acceleration * delta
			)

			velocity.x = move_toward(
				velocity.x,
				desired_velocity.x,
				steering_step
			)

			velocity.z = move_toward(
				velocity.z,
				desired_velocity.z,
				steering_step
			)

		return

	if hop_pause_remaining > 0.0:
		return

	# Start a new hop.
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	var gravity_strength: float = absf(get_gravity().y)
	velocity.y = sqrt(
		2.0 * gravity_strength * hop_height
	)
	
	hop_visual_animator.play_takeoff()


func _update_aim(delta: float) -> void:
	var mouse_position: Vector2 = (
		get_viewport().get_mouse_position()
	)

	var ray_origin: Vector3 = (
		camera.project_ray_origin(mouse_position)
	)

	var ray_direction: Vector3 = (
		camera.project_ray_normal(mouse_position)
	)

	var ground_plane := Plane(
		Vector3.UP,
		global_position.y
	)

	var hit: Variant = ground_plane.intersects_ray(
		ray_origin,
		ray_direction
	)

	if hit == null:
		return

	var target: Vector3 = hit
	target.y = visuals.global_position.y

	var target_direction: Vector3 = (
		target - visuals.global_position
	)

	target_direction.y = 0.0

	if target_direction.length() < 0.05:
		return

	target_direction = target_direction.normalized()

	# Godot's forward direction is negative Z.
	var target_yaw: float = atan2(
		-target_direction.x,
		-target_direction.z
	)

	var maximum_turn: float = (
		deg_to_rad(turn_speed_degrees) * delta
	)

	visuals.rotation.y = rotate_toward(
		visuals.rotation.y,
		target_yaw,
		maximum_turn
	)
	
func _play_mouth_full_shake() -> void:
	if action_active:
		return

	if not feedback_animation_player.has_animation(
		"mouth_full_shake"
	):
		push_warning(
			"Animation 'mouth_full_shake' is missing."
		)
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
