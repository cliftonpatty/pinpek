extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var weapon_tip: Node3D = find_child("WeaponTip", true)
@onready var mesh_parent: Node3D = $MeshParent
@onready var mesh_base_transform: Transform3D = mesh_parent.transform if mesh_parent else Transform3D()

# Firing parameters
@export var fire_rate: float = 8
@export var full_auto: bool = false
@export var bullet_range: float = 1000.0
@export var bullet_damage: float = 10.0
@export var bullet_force: float = 5.0

# Recoil parameters
@export var recoil_strength: Vector3 = Vector3(0.1, 0.1, 0.2)
@export var recoil_recovery_speed: float = 5.0
@export var max_recoil: Vector3 = Vector3(0.3, 0.4, 0.3)
@export var weapon_bob_amount: float = 0.002
@export var weapon_bob_speed: float = 10.0

var fire_timer: float = 0.0
var is_firing: bool = false
var current_recoil: Vector3
var recoil_rotation: Vector3
var bob_time: float = 0.0
var can_fire: bool = false

func _ready() -> void:
	if !weapon_tip or !animation_player or !mesh_parent:
		push_error("Required nodes missing in %s: WeaponTip: %s, AnimationPlayer: %s, MeshParent: %s" 
			% [name, weapon_tip != null, animation_player != null, mesh_parent != null])
		return
	can_fire = true

func _process(delta: float) -> void:
	if !can_fire:
		return
		
	fire_timer = max(0, fire_timer - delta)
	
	if mesh_parent:
		mesh_parent.transform = mesh_base_transform
		_process_effects(delta)
	
	if is_firing and fire_timer <= 0 and full_auto:
		fire_weapon()

func _process_effects(delta: float) -> void:
	# Process recoil
	current_recoil = current_recoil.lerp(Vector3.ZERO, recoil_recovery_speed * delta)
	recoil_rotation = recoil_rotation.lerp(Vector3.ZERO, recoil_recovery_speed * delta)
	
	mesh_parent.transform = mesh_parent.transform.translated_local(current_recoil)
	
	# Apply rotation recoil to mesh parent (fixed version)
	mesh_parent.rotate_object_local(Vector3.RIGHT, recoil_rotation.x)
	mesh_parent.rotate_object_local(Vector3.UP, recoil_rotation.y)
	mesh_parent.rotate_object_local(Vector3.FORWARD, recoil_rotation.z)
	
	# Process weapon bob during firing
	if is_firing:
		bob_time += delta * weapon_bob_speed
		mesh_parent.transform = mesh_parent.transform.translated_local(Vector3(
			cos(bob_time * 0.5) * weapon_bob_amount * 0.5,
			sin(bob_time) * weapon_bob_amount,
			0
		))

func fire_weapon() -> void:
	if !can_fire:
		return
		
	# Apply recoil
	var recoil = Vector3(
		randf_range(-recoil_strength.x, recoil_strength.x),
		randf_range(0, recoil_strength.y),
		-recoil_strength.z
	)
	current_recoil = (current_recoil + recoil).clamp(-max_recoil, max_recoil)
	recoil_rotation += Vector3(
		deg_to_rad(randf_range(-1, 1)),
		deg_to_rad(randf_range(-1, 1)),
		deg_to_rad(randf_range(-0.5, 0.5))
	)
	
	# Perform raycast
	var ray = PhysicsRayQueryParameters3D.new()
	ray.from = weapon_tip.global_position
	ray.to = weapon_tip.global_position - weapon_tip.global_transform.basis.z * bullet_range
	
	var collision = get_world_3d().direct_space_state.intersect_ray(ray)
	
	# Handle collision
	if collision:
		GameManager.cur_pmanager.send_col(collision)
		create_debug_effect(collision.position)
		if collision.collider.has_method("take_damage"):
			collision.collider.take_damage(bullet_damage)
		if collision.collider is RigidBody3D:
			collision.collider.apply_impulse(
				(collision.position - weapon_tip.global_position).normalized() * bullet_force,
				collision.position
			)
	
	# Play animation
	if animation_player.has_animation("Fire"):
		animation_player.play("Fire", -1, animation_player.get_animation("Fire").length * fire_rate, false)
		can_fire = false
	else:
		push_error("Fire animation missing in %s" % name)

func create_debug_effect(pos: Vector3) -> void:
	var debug_sphere = CSGSphere3D.new()
	get_tree().root.add_child(debug_sphere)
	debug_sphere.radius = 0.05
	debug_sphere.position = pos
	get_tree().create_timer(0.1).timeout.connect(debug_sphere.queue_free)

func start_firing() -> void:
	is_firing = true
	fire_weapon()

func stop_firing() -> void:
	is_firing = false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'Fire':
		can_fire = true
