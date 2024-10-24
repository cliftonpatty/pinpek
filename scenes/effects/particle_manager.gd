extends Node3D

@onready var particle_lib : PackedScene = preload("res://scenes/effects/smoke_puffs.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func send_col(collision) -> void:
	print(collision)
	if collision.collider.is_in_group('static_world'):
		var new_puff = particle_lib.instantiate()
		self.add_child(new_puff)
		new_puff.global_position = collision.position
		pass
	#
