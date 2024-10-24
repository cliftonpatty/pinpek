extends CharacterBody3D

# Movement parameters
var move_speed : float = 10.0
var sprint_multiplier : float = 1.6
var jump_force : float = 10.0
var gravity : float = -20.0
var mouse_sensitivity : float = 0.2

# Dash parameters
var dash_force : float = 30.0
var dash_duration : float = 0.2
var dash_cooldown : float = 0.5
var can_dash : bool = true
var is_dashing : bool = false
var dash_timer : float = 0.0
var dash_cooldown_timer : float = 0.0
var dash_direction : Vector3 = Vector3.ZERO

# Weapon sway parameters
var sway_left_right : float = 0.05
var sway_up_down : float = 0.05
var sway_smoothing : float = 8.0
var sway_threshold : float = 1.0
var sway_inertia : float = 0.3

# Weapon position clamp limits
var pos_limit_x : float = 0.2
var pos_limit_y : float = 0.1
var pos_limit_z : float = 0.1
var rot_limit : float = 0.2

# Weapon bob parameters
var bob_amount : float = 0.03
var bob_speed : float = 10.0
var bob_smoothing : float = 8.0

# Movement state tracking
var jump_count : int = 0
var max_jumps : int = 2
var is_grounded : bool = false
var sprint_pressed : bool = false
var sprint_released : bool = true

# Weapon movement tracking
var mouse_movement : Vector2
var sway_target : Vector3
var sway_current : Vector3
var bob_time : float = 0.0
var last_velocity : Vector3
var velocity_delta : Vector3
var weapon_inertia : Vector3
var last_pos : Vector3
var last_rot : Vector3

# Node references
@onready var head : Node3D = $Head
@onready var weapon : Node3D = $Head/Gun
@onready var initial_weapon_pos : Vector3 = weapon.position
@onready var initial_weapon_rot : Vector3 = weapon.rotation

func _ready() -> void:
	GameManager.player_ref = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	last_pos = weapon.position
	last_rot = weapon.rotation

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Store smoothed mouse movement
		mouse_movement = mouse_movement.lerp(
			Vector2(event.relative.x, event.relative.y), 
			sway_inertia
		)
		
		# Rotate body horizontally
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		
		# Rotate head vertically
		head.rotation_degrees.x = clamp(
			head.rotation_degrees.x - event.relative.y * mouse_sensitivity,
			-89,
			89
		)

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_weapon_movement(delta)
	handle_shooting()
	update_dash_state(delta)
	
	# Store last frame's velocity for inertia calculations
	last_velocity = velocity

func handle_shooting() -> void:
	if Input.is_action_just_pressed("blast"):
		if weapon.has_method("start_firing"):
			weapon.start_firing()
	elif Input.is_action_just_released("blast"):
		if weapon.has_method("stop_firing"):
			weapon.stop_firing()

func update_dash_state(delta: float) -> void:
	# Update dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			can_dash = true
	
	# Update active dash
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			# Only maintain sprint speed if sprint is still held
			if !Input.is_action_pressed("sprint"):
				velocity *= 0.5  # Reduce speed after dash if not sprinting

func handle_movement(delta: float) -> void:
	# Get input direction
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = Vector3.ZERO
	
	# Convert input to world-space direction
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle dash input
	if Input.is_action_just_pressed("sprint") and sprint_released and can_dash and direction.length() > 0:
		is_dashing = true
		can_dash = false
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		dash_direction = direction
		sprint_released = false
		velocity = dash_direction * dash_force
		# Preserve vertical velocity for air dashes
		if !is_on_floor():
			velocity.y = last_velocity.y
	
	# Track sprint release for dash detection
	if Input.is_action_just_released("sprint"):
		sprint_released = true
	
	# Apply movement
	if direction:
		var speed = move_speed
		if is_dashing:
			speed = dash_force
		elif Input.is_action_pressed("sprint"):
			speed *= sprint_multiplier
		
		if !is_dashing:  # Only update horizontal velocity if not dashing
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
	else:
		# Apply friction if not dashing
		if !is_dashing:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	
	# Handle jumping and gravity
	if is_on_floor():
		is_grounded = true
		jump_count = 0
		if !is_dashing:
			velocity.y = 0
	else:
		is_grounded = false
		if !is_dashing:
			velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("jump") and jump_count < max_jumps:
		velocity.y = jump_force
		jump_count += 1
		is_grounded = false
	
	move_and_slide()

func clamp_vector3(vec: Vector3, limits: Vector3) -> Vector3:
	return Vector3(
		clamp(vec.x, -limits.x, limits.x),
		clamp(vec.y, -limits.y, limits.y),
		clamp(vec.z, -limits.z, limits.z)
	)

func handle_weapon_movement(delta: float) -> void:
	# Calculate velocity change for inertia
	velocity_delta = velocity - last_velocity
	
	# Update weapon inertia
	weapon_inertia = weapon_inertia.lerp(velocity_delta * 0.01, delta * sway_smoothing)
	
	# Clamp inertia
	weapon_inertia = clamp_vector3(weapon_inertia, Vector3(pos_limit_x, pos_limit_y, pos_limit_z))
	
	# Calculate sway based on mouse movement
	if mouse_movement.length() > sway_threshold:
		sway_target.x = -mouse_movement.x * sway_left_right
		sway_target.y = -mouse_movement.y * sway_up_down
	else:
		sway_target = Vector3.ZERO
	
	# Clamp sway target
	sway_target = clamp_vector3(sway_target, Vector3(pos_limit_x, pos_limit_y, pos_limit_z))
	
	# Smooth out the sway movement
	sway_current = sway_current.lerp(sway_target, delta * sway_smoothing)
	
	# Calculate weapon bob
	var bob_offset = Vector3.ZERO
	if is_on_floor() and velocity.length_squared() > 0.1:
		bob_time += delta * bob_speed
		bob_offset.y = sin(bob_time) * bob_amount
		bob_offset.x = cos(bob_time * 0.5) * bob_amount * 0.5
	else:
		bob_time = 0.0
		bob_offset = bob_offset.lerp(Vector3.ZERO, delta * bob_smoothing)
	
	# Clamp bob offset
	bob_offset = clamp_vector3(bob_offset, Vector3(pos_limit_x, pos_limit_y, pos_limit_z))
	
	# Combine all movements
	var target_pos = initial_weapon_pos
	target_pos += sway_current
	target_pos += bob_offset
	target_pos -= weapon_inertia
	
	# Clamp final position relative to initial position
	var position_delta = target_pos - initial_weapon_pos
	position_delta = clamp_vector3(position_delta, Vector3(pos_limit_x, pos_limit_y, pos_limit_z))
	target_pos = initial_weapon_pos + position_delta
	
	# Calculate rotation with clamping
	var target_rot = initial_weapon_rot
	target_rot.z = clamp(-sway_current.x * 0.25, -rot_limit, rot_limit)
	target_rot.x = clamp(-sway_current.y * 0.25, -rot_limit, rot_limit)
	
	# Smoothly interpolate to target position and rotation
	weapon.position = weapon.position.lerp(target_pos, delta * sway_smoothing)
	weapon.rotation = weapon.rotation.lerp(target_rot, delta * sway_smoothing)
	
	# Gradually reduce mouse movement influence
	mouse_movement = mouse_movement.lerp(Vector2.ZERO, delta * sway_smoothing)
	
	# Store positions for next frame
	last_pos = weapon.position
	last_rot = weapon.rotation
