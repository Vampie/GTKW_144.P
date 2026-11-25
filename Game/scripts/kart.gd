class_name Kart
extends Car

## A small open gnome car, built from boxes, made to fit the gnome's car animations (see
## assets/characters/gnome/AGENT_GIDS.md): a door on the left (+X), the driver's seat on the floor
## (the Drive pose sits with its origin on the ground), the wheel 0.34 m up and 0.20 m in front.
## Looks along +Z. Found friends ride along sitting on the seats, the boot and the bonnet.

const SEAT := Vector3(0.25, 0.0, 0.0)  # driver: the gnome's origin while driving
const DOOR_SIDE := 0.40                 # EnterCar starts and ExitCar ends this far left of the seat
# where riding friends sit: [position of their origin, which way] in kart space
const RIDERS := [Vector3(-0.25, 0.0, 0.0), Vector3(0.25, 0.27, -0.85), Vector3(-0.25, 0.27, -0.85),
	Vector3(0.25, 0.32, 0.8), Vector3(-0.25, 0.32, 0.8)]

var color := Color(0.9, 0.2, 0.15)
var door := Node3D.new()      # hinged at its front edge
var door_open := 0.0          # 0 shut .. 1 open; the player sets it in step with the animation


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	add_to_group("car")
	var paint := _mat(color)
	var dark := _mat(Color(0.15, 0.15, 0.17))
	var seat := _mat(Color(0.95, 0.9, 0.8))
	_box(self, Vector3(1.2, 0.06, 2.2), Vector3(0, 0.0, 0), dark)                 # floor, at ground level
	_box(self, Vector3(1.2, 0.42, 0.6), Vector3(0, 0.23, 0.8), paint)             # bonnet
	_box(self, Vector3(1.2, 0.36, 0.5), Vector3(0, 0.2, -0.85), paint)            # boot
	_box(self, Vector3(0.06, 0.4, 0.7), Vector3(-0.57, 0.22, 0.0), paint)         # right side
	_box(self, Vector3(1.2, 0.4, 0.06), Vector3(0, 0.22, -0.57), paint)           # back of the cabin
	_box(self, Vector3(1.1, 0.3, 0.04), Vector3(0, 0.58, 0.5), _glass())          # windscreen
	for x: float in [0.25, -0.25]:
		_box(self, Vector3(0.4, 0.12, 0.4), Vector3(x, 0.1, -0.1), seat)          # cushion
		_box(self, Vector3(0.4, 0.4, 0.08), Vector3(x, 0.3, -0.33), seat)         # backrest
	var ring := TorusMesh.new()  # steering wheel in front of the driver
	ring.inner_radius = 0.09
	ring.outer_radius = 0.12
	ring.material = dark
	var wheel := MeshInstance3D.new()
	wheel.mesh = ring
	wheel.position = SEAT + Vector3(0, 0.34, 0.2)
	wheel.rotation.x = deg_to_rad(65)
	add_child(wheel)
	for corner in [Vector3(0.66, 0.25, 0.7), Vector3(-0.66, 0.25, 0.7), Vector3(0.66, 0.25, -0.75), Vector3(-0.66, 0.25, -0.75)]:
		var tyre := CylinderMesh.new()
		tyre.top_radius = 0.25
		tyre.bottom_radius = 0.25
		tyre.height = 0.18
		tyre.material = dark
		var mi := MeshInstance3D.new()
		mi.mesh = tyre
		mi.position = corner
		mi.rotation.z = PI / 2
		add_child(mi)
	for x: float in [0.4, -0.4]:
		_box(self, Vector3(0.18, 0.1, 0.04), Vector3(x, 0.32, 1.11), _mat(Color(1, 0.95, 0.7)))  # headlights
	# the door: from its hinge at the front of the cabin, back along the left side
	door.position = Vector3(0.57, 0.02, 0.3)
	add_child(door)
	_box(door, Vector3(0.06, 0.4, 0.6), Vector3(0, 0.2, -0.3), paint)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 0.8, 2.3)
	shape.shape = box
	shape.position.y = 0.4
	add_child(shape)


func _process(_delta: float) -> void:
	door.rotation.y = -1.2 * door_open  # swings outward


func seat_world() -> Vector3:
	return global_transform * SEAT


## Where the player stands to get in, and ends up after getting out: next to the door.
func door_world() -> Vector3:
	return global_transform * (SEAT + Vector3(DOOR_SIDE, 0.0, 0.0))


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	return m


func _glass() -> StandardMaterial3D:
	var m := _mat(Color(0.75, 0.9, 1.0, 0.35))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
