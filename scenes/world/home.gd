extends Node3D

@onready var p_mnger : Node3D = %ParticleManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if p_mnger:
		GameManager.cur_pmanager = p_mnger
		print("p man assigned!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
