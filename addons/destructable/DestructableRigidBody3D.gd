## A destructable rigid body.
## Breaks when the provided newtons are exceeded. This applies to when it hits 
## something or something hits it.
@tool
@icon("res://addons/destructable/DestructableRigidBody3D.svg")
class_name DestructableRigidBody3D extends RigidBody3D

var fragments_node: Node3D

var is_destroyed: bool = false

var initial_child_linear_velocity: Vector3 = Vector3.ZERO
var initial_child_angular_velocity: Vector3 = Vector3.ZERO

## Node that gets swapped out when the object is fragmented.
@export var untarnished_node: Node3D:
	set(value):
		untarnished_node = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

## Scene to be swapped to when the object is fragmented.
@export var fragments_scene: PackedScene :
	set(value):
		fragments_scene = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

## Force required to break the object (in Newtons).
@export var break_force: float = 10.0

@export_group("Physics Fixes")
@export var destroy_timeout: float = 0.02

signal destroyed

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: Array[String] = []
	if not untarnished_node:
		warnings.append("Property \"Undestroyed Node\" not set")
	if not fragments_scene:
		warnings.append("Property \"Destroyed Scene\" not set")
	
	return warnings


func _init() -> void:
	destroyed.connect(_on_destroyed)


func _physics_process(delta: float) -> void:
	var collision = move_and_collide(delta * linear_velocity, true, 0.001, false, 5)
	if collision and not is_destroyed:
		
		for index in range(collision.get_collision_count()):
			var collider = collision.get_collider(index)
			if not collider is RigidBody3D:
				continue
			exert_force(collider.mass, collider.linear_velocity, delta)
		
		exert_force(mass, linear_velocity, delta)


func force(delta: float) -> Vector3:
	return calculate_force(mass, linear_velocity * delta)


func calculate_force(mass_: float, velocity: Vector3) -> Vector3:
	return mass_ * velocity


func exert_force(mass_: float, velocity: Vector3, delta: float) -> void:
	var force: Vector3 = calculate_force(mass_, velocity * delta)
	if force.length() > break_force:
		initial_child_linear_velocity = velocity
		initial_child_angular_velocity = angular_velocity
		var timer: SceneTreeTimer = get_tree().create_timer(destroy_timeout)
		timer.timeout.connect(set_destroyed)


func set_destroyed() -> void:
	if not is_destroyed:
		is_destroyed = true
		destroyed.emit()


func _on_destroyed() -> void:
	remove_child(untarnished_node)
	for node in find_children("*", "CollisionShape3D", false):
		node.disabled = true
	untarnished_node.queue_free()
	fragments_node = fragments_scene.instantiate()
	add_child(fragments_node)
	for child in fragments_node.find_children("*", "RigidBody3D"):
		child.linear_velocity = initial_child_linear_velocity
		child.angular_velocity = initial_child_angular_velocity
