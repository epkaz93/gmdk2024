@icon("res://component/destruction/DestructableRigidBody3D.svg")

extends RigidBody3D
class_name DestructableRigidBody3D

var undestroyed_node: Node3D

var destroyed_node: Node3D

var is_destroyed: bool = false
var destroy_timeout: float = 0.02

var initial_child_linear_velocity: Vector3 = Vector3.ZERO
var initial_child_angular_velocity: Vector3 = Vector3.ZERO

@export var destroyed_scene: PackedScene

@export var strength: float = 0.0

signal destroyed


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
	if force.length() > strength:
		initial_child_linear_velocity = velocity
		initial_child_angular_velocity = angular_velocity
		var timer: SceneTreeTimer = get_tree().create_timer(destroy_timeout)
		timer.timeout.connect(set_destroyed)


func set_destroyed() -> void:
	if not is_destroyed:
		is_destroyed = true
		destroyed.emit()


func _destroy() -> void:
	remove_child(undestroyed_node)
	for node in find_children("*", "CollisionShape3D", false):
		node.disabled = true
	undestroyed_node.queue_free()
	destroyed_node = destroyed_scene.instantiate()
	add_child(destroyed_node)
	for child in destroyed_node.find_children("*", "RigidBody3D"):
		child.linear_velocity = initial_child_linear_velocity
		child.angular_velocity = initial_child_angular_velocity
