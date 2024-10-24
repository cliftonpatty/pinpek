extends Node3D

@onready var skeleton_3d: Skeleton3D = $zombo/Skeleton3D
@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $zombo/Skeleton3D/PhysicalBoneSimulator3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	physical_bone_simulator_3d.physical_bones_start_simulation()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
