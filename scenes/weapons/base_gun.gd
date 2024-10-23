extends Node3D

var animation_player: AnimationPlayer
var weapon_tip : Node3D
@onready var gun_ready : bool = false


@export var fire_rate: float = 0.1  # Time between shots in seconds
var fire_timer: float = 0.0
var is_firing: bool = false  # Track if we're currently in a firing state

# Bullet parameters
@export var bullet_range : float = 1000.0  # How far the bullet travels
@export var bullet_damage : float = 10.0   # How much damage it does
@export var bullet_force : float = 5.0     # Force applied to rigidbodies
@export var full_auto : bool = false

@onready var can_fire : bool = false

func _ready() -> void:
	weapon_tip = find_tippy(self, "WeaponTip")
	if weapon_tip:
		print(weapon_tip)
		gun_ready = true
		can_fire = true
	else:
		print("Tip Not found in ", self.name, " check that shit out")
	if $AnimationPlayer:
		animation_player = $AnimationPlayer
	else:
		print('Gun Needs an Animation Player to function!')

func _process(delta: float) -> void:
	if fire_timer > 0:
		fire_timer -= delta
	
	# If we're in firing state and can fire again
	if is_firing and fire_timer <= 0 and full_auto:
		_perform_fire()

func fire_weapon() -> void:
	if gun_ready && can_fire:
		_perform_fire()
		
	elif fire_timer > 0:
		return
	else:
		return

func _perform_fire() -> void:
	fire_timer = fire_rate
	print(can_fire)
	# Create the raycast
	var ray = PhysicsRayQueryParameters3D.new()
	
	# Set up raycast parameters
	ray.from = weapon_tip.global_position
	ray.to = weapon_tip.global_position - weapon_tip.global_transform.basis.z * bullet_range
	
	# Perform the raycast
	var space = get_world_3d().direct_space_state
	var collision = space.intersect_ray(ray)

	if animation_player:
		if animation_player.has_animation("Fire"):
			animation_player.play("Fire",-1,animation_player.get_animation("Fire").length * fire_rate, false)
			can_fire = false
		else: 
			print('MAKE A FUCKIN FIRE ANIMATION YA LAZY POOP')

	# Handle collision
	if collision:
		create_hit_effect(collision.position)
		
		if collision.collider.has_method("take_damage"):
			collision.collider.take_damage(bullet_damage)
		
		if collision.collider is RigidBody3D:
			var direction = (collision.position - weapon_tip.global_position).normalized()
			collision.collider.apply_impulse(direction * bullet_force, collision.position)
	
	create_debug_line(weapon_tip.global_position, collision.position if collision else ray.to)


# Add these new functions to handle firing state
func start_firing() -> void:
	is_firing = true
	fire_weapon()  # Fire first shot immediately

func stop_firing() -> void:
	is_firing = false

# Visual feedback functions (for debugging)
func create_hit_effect(pos: Vector3) -> void:
	# Create a small visual indicator where the bullet hit
	var mesh = CSGSphere3D.new()
	get_tree().root.add_child(mesh)
	mesh.radius = 0.05
	mesh.position = pos
	
	# Remove it after a short delay
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func(): mesh.queue_free())

func create_debug_line(from: Vector3, to: Vector3) -> void:
	# Create a line showing the bullet path
	var im = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	var material = StandardMaterial3D.new()
	
	material.albedo_color = Color.YELLOW
	material.emission_enabled = true
	material.emission = Color.YELLOW
	material.emission_energy_multiplier = 2
	
	mesh_instance.mesh = im
	mesh_instance.material_override = material
	
	get_tree().root.add_child(mesh_instance)
	
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(from)
	im.surface_add_vertex(to)
	im.surface_end()
	
	# Remove the line after a short delay
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func(): mesh_instance.queue_free())

#Just find the weapon tip.... so i can put it anywhere and be lazy
func find_tippy(node: Node, node_name: String) -> Node:
	# Check all children of the current node
	for child in node.get_children():
		# Check if this child is the node we're looking for
		if child.name == node_name:
			return child
		# If not, recursively check this child's children
		var found = find_tippy(child, node_name)
		if found:
			return found
	# Return null if not found in this branch
	return null

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'Fire':
		can_fire = true
