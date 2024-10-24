extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $Area3D
@onready var debug_label: Label3D = $Label3D

const SPEED = 3.0
const ROTATION_SPEED = 10.0  # Adjust this to control rotation smoothness
var is_chasing := false

func _ready() -> void:
	# Basic NavigationAgent setup
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	nav_agent.debug_enabled = true  # Helps visualize the path

func _physics_process(delta: float) -> void:
	if not is_chasing:
		debug_label.text = "Not Chasing\nVel: " + str(velocity)
		return
		
	var player = GameManager.player_ref
	if not player:
		debug_label.text = "No Player\nVel: " + str(velocity)
		return
	
	# Set the target position directly to the player's position
	nav_agent.set_target_position(player.global_position)
	
	# Get the next path position
	var next_path_position: Vector3 = nav_agent.get_next_path_position()
	
	# Calculate direction to move
	var direction: Vector3 = (next_path_position - global_position).normalized()
	
	# Set velocity
	velocity = direction * SPEED
	
	# Smooth rotation to face movement direction
	if velocity.length() > 0.1:  # Only rotate if we're actually moving
		var look_direction = direction
		look_direction.y = 0  # Keep rotation only on Y axis
		if look_direction.length() > 0.01:
			# Create the target rotation basis
			var target_basis = Basis.looking_at(look_direction, Vector3.UP)
			# Smoothly interpolate rotation
			transform.basis = transform.basis.slerp(target_basis, delta * ROTATION_SPEED)
	
	# Debug info
	debug_label.text = "Chasing\nNext Pos: " + str(next_path_position) + "\nDirection: " + str(direction) + "\nVel: " + str(velocity)
	
	# Actually move the character
	move_and_slide()

func _on_area_3d_area_entered(area: Area3D) -> void:
	print("Area entered by: ", area)  # Debug print
	# Make sure we're detecting the player
	var potential_player = area.get_parent()
	if potential_player == GameManager.player_ref:
		print("Player detected - starting chase")  # Debug print
		is_chasing = true

func _on_area_3d_area_exited(area: Area3D) -> void:
	print("Area exited by: ", area)  # Debug print
	var potential_player = area.get_parent()
	if potential_player == GameManager.player_ref:
		print("Player left - stopping chase")  # Debug print
		is_chasing = false
