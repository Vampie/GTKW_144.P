class_name Car
extends CharacterBody3D

## A parked car the player can drive. Arcade handling: it cannot tip over and only steers while moving.
## It drives through visitors; the ones in front of it jump aside (Visitor.dodge).

const TOP_SPEED := 25.0     # m/s, 90 km/h
const ACCEL := 9.0
const BRAKE := 22.0
const REVERSE := 7.0        # top speed backwards
const ROLL_OUT := 3.0       # slowing down without gas
const STEER := 1.8          # radians per second at full lock
const SCARE_DISTANCE := 12.0  # visitors this far ahead jump aside
const FORWARD := 1.0        # +1 when the model's front is +Z, -1 when it is -Z

var model_path: String
var driving := false
var autopilot := false      # test option: full gas
var speed := 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _scare_left := 0.0


func _ready() -> void:
	collision_layer = 1   # the world: player and visitors bump into parked cars
	collision_mask = 1    # world only: a driving car goes through visitors
	add_to_group("car")
	var mesh := Assets.mesh(model_path)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.scale = Vector3.ONE * Park.CAR_SCALE
	add_child(mi)
	var box := BoxShape3D.new()
	box.size = mesh.get_aabb().size * Park.CAR_SCALE
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = mesh.get_aabb().get_center() * Park.CAR_SCALE
	add_child(shape)


func forward() -> Vector3:
	return global_basis.z * FORWARD


func _physics_process(delta: float) -> void:
	if not driving:
		return
	var gas := 1.0 if autopilot else float(Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_S))
	var steer := float(Input.is_physical_key_pressed(KEY_A)) - float(Input.is_physical_key_pressed(KEY_D))
	if gas > 0.0:
		speed = move_toward(speed, TOP_SPEED, (ACCEL if speed >= 0.0 else BRAKE) * delta)
	elif gas < 0.0:
		speed = move_toward(speed, -REVERSE, (BRAKE if speed > 0.0 else ACCEL) * delta)
	else:
		speed = move_toward(speed, 0.0, ROLL_OUT * delta)
	# steering works like a real car: none when standing still, mirrored when reversing
	rotation.y += steer * STEER * delta * clampf(speed / 6.0, -1.0, 1.0)
	var v := forward() * speed
	velocity.x = v.x
	velocity.z = v.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	move_and_slide()
	if is_on_wall():
		speed *= 0.3  # hit a tree, a wall or a parked car
	_scare_left -= delta
	if _scare_left <= 0.0 and absf(speed) > 3.0:
		_scare_left = 0.2
		var ahead := forward() * signf(speed)
		for v2: Node in get_tree().get_nodes_in_group("npc"):
			var to: Vector3 = (v2 as Node3D).global_position - global_position
			if to.length() < SCARE_DISTANCE and to.normalized().dot(ahead) > 0.5 and v2.has_method("dodge"):
				v2.dodge(self)
