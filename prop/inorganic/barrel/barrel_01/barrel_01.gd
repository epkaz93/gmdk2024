extends DestructableRigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	undestroyed_node = get_node("pivot/barrel_01_whole")
