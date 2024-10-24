extends Node3D

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var animated_sprite_3d_2: AnimatedSprite3D = $AnimatedSprite3D2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if randi_range(-1,1) > 0:
		animated_sprite_3d.play("default")
		animated_sprite_3d_2.play("default")
	else:
		animated_sprite_3d.play("default")
# Called every frame. 'delta' is the elapsed time since the previous frame.
	self.scale = self.scale * randf_range(1.0,1.2)
func _process(delta: float) -> void:
	pass


func _on_animated_sprite_3d_animation_finished() -> void:
	queue_free()

func _exit_tree() -> void:
	print('bye bitch')
