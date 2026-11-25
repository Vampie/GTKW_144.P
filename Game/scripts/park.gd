class_name Park
extends Node3D

## Builds the city park: pond, paths, trees, benches, lamps and flowers,
## and around it the streets, parked cars and buildings.
## Everything placed at random uses a fixed seed, so the park is the same every run.

const SEED := 144
const SIZE := 250.0        # the park runs from -SIZE to SIZE on x and z
const POND_R := 30.0
const INNER_R := 50.0      # path ring around the pond
const OUTER_R := 200.0     # big path ring
const ROAD_IN := 255.0     # inner edge of the street around the park
const ROAD_W := 10.0       # street width, also the size of one road tile
const BUILD_LINE := 269.0  # front of the buildings; nobody gets further

# Model scales: Kenney kits are not in metres, people are about 1.7 m.
const TREE_SCALE := Vector2(4.5, 6.5)
const BENCH_SCALE := 2.3
const LAMP_SCALE := 7.4
const BUILDING_SCALE := 8.0
const SKYLINE_SCALE := 11.0
const CAR_SCALE := 1.4

# Extra turn when a model's front is not on its +Z side.
const BENCH_TURN := 0.0
const LAMP_TURN := 0.0
const ROAD_TURN := 0.0
const BUILDING_TURN := 0.0
const SEAT_FORWARD := -0.25  # seat position relative to the middle of the bench
const SEAT_HEIGHT := 0.55    # the sit animation sits on the ground, the bench seat is higher

const TREES := ["tree_default", "tree_oak", "tree_detailed", "tree_fat", "tree_simple",
	"tree_tall", "tree_default_dark", "tree_oak_dark", "tree_pineRoundA", "tree_pineTallA"]
const FLOWERS := ["flower_redA", "flower_yellowA", "flower_purpleA"]
const BUSHES := ["plant_bush", "plant_bushLarge", "plant_bushDetailed"]
const GRASS := ["grass", "grass_large"]
const SHOPS := ["building-a", "building-b", "building-c", "building-d", "building-e", "building-f",
	"building-g", "building-h", "building-i", "building-j", "building-k", "building-l"]
const HOUSES := ["building-type-a", "building-type-b", "building-type-c", "building-type-d",
	"building-type-e", "building-type-f", "building-type-j", "building-type-k", "building-type-l",
	"building-type-n", "building-type-o", "building-type-r", "building-type-s", "building-type-u"]
const TALL := ["building-l", "building-m", "building-n", "building-f", "building-g", "building-i"]
const CARS := ["sedan", "suv", "taxi", "van", "police", "hatchback-sports", "delivery", "truck"]

var points := PackedVector3Array()       # nodes of the path network
var links: Array[PackedInt32Array] = []  # neighbours of each node
var segments: Array[Vector3i] = []       # path pieces: x and y are node indexes, z is the width in m
var trees := PackedVector3Array()
var seats: Array[Transform3D] = []       # two per bench; the basis turns +Z to where the sitter looks
var spots: Array[Transform3D] = []       # places to stand in a group, facing its middle
var rng := RandomNumberGenerator.new()
var _body := StaticBody3D.new()          # holds the colliders of everything in the park
var _batches := {}                       # model path -> transforms, drawn as one MultiMesh each


func _ready() -> void:
	rng.seed = SEED
	add_child(_body)
	_make_graph()
	_ground()
	_pond()
	_paths()
	_trees()
	_benches()
	_lamps()
	_plants()
	_streets()
	_buildings()
	_cars()
	_groups()
	for path: String in _batches:
		var small := path.contains("flower") or path.contains("grass")
		add_child(Assets.multimesh(path, _batches[path], not small))


## Distance from p to the edge of the nearest path; negative when p is on a path.
func path_clearance(p: Vector3) -> float:
	var best := INF
	for s in segments:
		var c := Geometry3D.get_closest_point_to_segment(p, points[s.x], points[s.y])
		best = minf(best, p.distance_to(c) - s.z / 2.0)
	return best


func _make_graph() -> void:
	var inner := _ring(INNER_R, 16, 4)
	var outer := _ring(OUTER_R, 32, 4)
	for k in 4:  # main paths from the pond to the four gates
		_link(inner + k * 4, outer + k * 8, 4)
		_link(outer + k * 8, _point(_dir(k * TAU / 4) * SIZE), 4)
	for k in 4:  # paths to the four corners
		_link(outer + 4 + k * 8, _point(_dir(TAU / 8 + k * TAU / 4) * (SIZE * sqrt(2.0) - 5.0)), 3)
	var free := [1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15]  # inner nodes without a main path
	for n in 4:  # small paths at random places
		var i: int = free.pop_at(rng.randi_range(0, free.size() - 1))
		_link(inner + i, outer + (i * 2 + rng.randi_range(-3, 3) + 32) % 32, 2)


func _ring(radius: float, count: int, width: int) -> int:
	var first := points.size()
	for i in count:
		_point(_dir(TAU * i / count) * radius)
	for i in count:
		_link(first + i, first + (i + 1) % count, width)
	return first


func _point(p: Vector3) -> int:
	points.append(p)
	links.append(PackedInt32Array())
	return points.size() - 1


func _link(a: int, b: int, width: int) -> void:
	links[a].append(b)
	links[b].append(a)
	segments.append(Vector3i(a, b, width))


func _ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * (2.0 * BUILD_LINE + 300.0)
	_mesh(plane, Vector3.ZERO, Color(0.45, 0.66, 0.3))
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = WorldBoundaryShape3D.new()
	_body.add_child(floor_shape)
	for k in 4:  # invisible walls at the building fronts
		var wall := BoxShape3D.new()
		wall.size = Vector3(2.0 * BUILD_LINE + 4.0, 30.0, 2.0)
		_collider(wall, Transform3D(Basis(Vector3.UP, k * TAU / 4), _dir(k * TAU / 4) * (BUILD_LINE + 1.0) + Vector3.UP * 15.0))


func _pond() -> void:
	_mesh(_disc(POND_R + 2.5, 0.08), Vector3(0, 0.04, 0), Color(0.86, 0.79, 0.6))
	var water := _mesh(_disc(POND_R, 0.16), Vector3(0, 0.08, 0), Color(0.25, 0.5, 0.78))
	(water.mesh.surface_get_material(0) as StandardMaterial3D).roughness = 0.1
	var shape := CylinderShape3D.new()
	shape.radius = POND_R
	shape.height = 4.0
	_collider(shape, Transform3D(Basis(), Vector3.UP * 2.0))


func _paths() -> void:
	var pieces: Array[Transform3D] = []
	var joints: Array[Transform3D] = []
	var widest := PackedFloat32Array()
	widest.resize(points.size())
	for s in segments:
		var a := points[s.x]
		var b := points[s.y]
		var d := b - a
		pieces.append(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)) * Basis.from_scale(Vector3(s.z, 0.08, d.length())), (a + b) / 2.0))
		widest[s.x] = maxf(widest[s.x], s.z)
		widest[s.y] = maxf(widest[s.y], s.z)
	for i in points.size():  # round pieces hide the seams where paths meet
		joints.append(Transform3D(Basis.from_scale(Vector3(widest[i], 0.08, widest[i])), points[i]))
	var sand := _material(Color(0.86, 0.77, 0.57))
	var box := BoxMesh.new()
	box.material = sand
	var disc := _disc(0.5, 1.0)
	disc.material = sand
	add_child(Assets.multimesh(box, pieces, false))
	add_child(Assets.multimesh(disc, joints, false))


func _trees() -> void:
	var candidates := PackedVector3Array()
	for g in 30:  # groves
		var c := _random_point(225.0)
		for t in rng.randi_range(5, 14):
			candidates.append(c + Vector3(rng.randfn(0.0, 10.0), 0.0, rng.randfn(0.0, 10.0)))
	for t in 90:  # single trees
		candidates.append(_random_point(240.0))
	for p in candidates:
		if absf(p.x) > 242.0 or absf(p.z) > 242.0 or p.length() < INNER_R + 6.0:
			continue
		if path_clearance(p) < 3.0 or _near(trees, p, 4.0):
			continue
		trees.append(p)
		_place("res://assets/nature/%s.glb" % TREES[rng.randi() % TREES.size()], p, rng.randf() * TAU,
			Vector3.ONE * rng.randf_range(TREE_SCALE.x, TREE_SCALE.y))
		var trunk := CylinderShape3D.new()
		trunk.radius = 0.5
		trunk.height = 6.0
		_collider(trunk, Transform3D(Basis(), p + Vector3.UP * 3.0))


func _benches() -> void:
	for i in 16:  # outside the pond ring, looking at the pond
		_bench(i, -1.0)
	for i in range(0, 32, 4):  # inside the big ring, looking out
		_bench(16 + i, 1.0)


## look: -1 faces the middle of the park, 1 faces away from it.
func _bench(segment: int, look: float) -> void:
	var s := segments[segment]
	var mid := (points[s.x] + points[s.y]) / 2.0
	var face := mid.normalized() * look
	var pos := mid - face * 3.5  # across the path from where the sitters look
	var yaw := atan2(face.x, face.z)
	_place("res://assets/bench/bench.glb", pos, yaw + BENCH_TURN, Vector3.ONE * BENCH_SCALE)
	var side := face.cross(Vector3.UP)
	for k: float in [-0.45, 0.45]:
		seats.append(Transform3D(Basis(Vector3.UP, yaw), pos + side * k + face * SEAT_FORWARD + Vector3.UP * SEAT_HEIGHT))
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.2, 1.0)
	_collider(shape, Transform3D(Basis(Vector3.UP, yaw), pos + Vector3.UP * 0.6))


func _lamps() -> void:
	for i in range(0, 16, 2):  # around the pond
		var out := points[i].normalized()
		_lamp(points[i] + out * 3.2, -out)
	for k in 4:  # along the main paths
		var a := points[k * 4]
		var b := points[16 + k * 8]
		var side := (b - a).normalized().cross(Vector3.UP)
		for n in range(1, 6):
			var sign := 1.0 if n % 2 == 0 else -1.0
			_lamp(a + (b - a) * n / 6.0 + side * 3.2 * sign, -side * sign)


func _lamp(pos: Vector3, toward_path: Vector3) -> void:
	# the lamp's arm points to -Z
	_place("res://assets/roads/light-curved.glb", pos, atan2(-toward_path.x, -toward_path.z) + LAMP_TURN, Vector3.ONE * LAMP_SCALE)
	var pole := CylinderShape3D.new()
	pole.radius = 0.15
	pole.height = 5.0
	_collider(pole, Transform3D(Basis(), pos + Vector3.UP * 2.5))


func _plants() -> void:
	for n in 450:  # flower beds between the pond and the first path
		var p := _dir(rng.randf() * TAU) * rng.randf_range(POND_R + 4.0, INNER_R - 4.5)
		_place("res://assets/nature/%s.glb" % FLOWERS[rng.randi() % FLOWERS.size()], p, rng.randf() * TAU, Vector3.ONE * 2.5)
	for n in 220:  # bushes under the trees
		var p := trees[rng.randi() % trees.size()] + _dir(rng.randf() * TAU) * rng.randf_range(2.0, 4.0)
		if path_clearance(p) > 1.5:
			_place("res://assets/nature/%s.glb" % BUSHES[rng.randi() % BUSHES.size()], p, rng.randf() * TAU,
				Vector3.ONE * rng.randf_range(3.0, 4.5))
	for n in 700:  # tufts of grass
		var p := _random_point(245.0)
		if path_clearance(p) > 0.5 and p.length() > POND_R + 3.0:
			_place("res://assets/nature/%s.glb" % GRASS[rng.randi() % GRASS.size()], p, rng.randf() * TAU, Vector3.ONE * 3.0)


func _streets() -> void:
	var mid := ROAD_IN + ROAD_W / 2.0
	var tile := Vector3(ROAD_W, 1.0, ROAD_W)
	var walks: Array[Transform3D] = []
	for k in 4:
		var d := _dir(k * TAU / 4)  # from the park to this street
		var along := d.cross(Vector3.UP)
		var yaw := k * TAU / 4
		for n in range(-25, 26):
			_place("res://assets/roads/road-straight.glb", d * mid + along * n * ROAD_W, yaw + ROAD_TURN, tile)
		_place("res://assets/roads/road-crossroad.glb", (d + along) * mid, 0.0, tile)
		# pavement on both sides of the street
		walks.append(Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(2.0 * ROAD_IN, 0.08, ROAD_IN - SIZE)), d * (SIZE + ROAD_IN) / 2.0))
		var outer := ROAD_IN + ROAD_W
		walks.append(Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(2.0 * BUILD_LINE + 40.0, 0.08, 40.0)), d * (outer + 20.0)))
	var stone := BoxMesh.new()
	stone.material = _material(Color(0.72, 0.72, 0.7))
	add_child(Assets.multimesh(stone, walks, false))


func _buildings() -> void:
	for k in 4:
		var d := _dir(k * TAU / 4)
		var along := d.cross(Vector3.UP)
		var yaw := k * TAU / 4 + PI + BUILDING_TURN  # the front (+Z) looks at the park
		var x := -BUILD_LINE
		while true:
			var shop := rng.randf() < 0.7
			var path := "res://assets/%s/%s.glb" % (["commercial", SHOPS[rng.randi() % SHOPS.size()]] if shop
				else ["suburban", HOUSES[rng.randi() % HOUSES.size()]])
			var size := Assets.mesh(path).get_aabb().size * BUILDING_SCALE
			if x + size.x > BUILD_LINE:
				break
			_place(path, d * (BUILD_LINE + size.z / 2.0) + along * (x + size.x / 2.0), yaw, Vector3.ONE * BUILDING_SCALE)
			x += size.x + rng.randf_range(0.5, 3.0)
		x = -BUILD_LINE - 40.0  # a row of tall buildings behind, for the skyline
		while x < BUILD_LINE + 40.0:
			var path := "res://assets/commercial/%s.glb" % TALL[rng.randi() % TALL.size()]
			var size := Assets.mesh(path).get_aabb().size * SKYLINE_SCALE
			_place(path, d * (BUILD_LINE + 30.0 + size.z / 2.0) + along * (x + size.x / 2.0), yaw, Vector3.ONE * SKYLINE_SCALE)
			x += size.x + rng.randf_range(6.0, 20.0)


func _cars() -> void:
	for k in 4:
		var d := _dir(k * TAU / 4)
		var along := d.cross(Vector3.UP)
		var x := -245.0 + rng.randf_range(0.0, 20.0)
		while x < 245.0:
			var pos := d * (ROAD_IN + ROAD_W - 2.0) + along * x
			_place("res://assets/cars/%s.glb" % CARS[rng.randi() % CARS.size()], pos, atan2(along.x, along.z), Vector3.ONE * CAR_SCALE)
			var shape := BoxShape3D.new()
			shape.size = Vector3(2.2, 2.0, 4.4)
			_collider(shape, Transform3D(Basis(Vector3.UP, atan2(along.x, along.z)), pos + Vector3.UP))
			x += rng.randf_range(8.0, 35.0)


func _groups() -> void:
	var tries := 0
	while spots.size() < 9 and tries < 200:
		tries += 1
		var p := points[16 + rng.randi_range(0, 31)]
		var c := p + p.normalized() * (7.0 if rng.randf() < 0.5 else -7.0)
		if _near(trees, c, 5.0) or path_clearance(c) < 3.0:
			continue
		for m in 3:
			var ang := m * TAU / 3 + rng.randf_range(-0.3, 0.3)
			spots.append(Transform3D(Basis(Vector3.UP, ang + PI), c + _dir(ang) * 1.3))


# --- helpers ---

func _place(path: String, pos: Vector3, yaw: float, scale: Vector3) -> void:
	_batches.get_or_add(path, []).append(Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(scale), pos))


func _collider(shape: Shape3D, xform: Transform3D) -> void:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.transform = xform
	_body.add_child(cs)


func _mesh(mesh: PrimitiveMesh, pos: Vector3, color: Color) -> MeshInstance3D:
	mesh.material = _material(color)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	add_child(mi)
	return mi


func _disc(radius: float, height: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 48
	return c


func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	return m


func _dir(angle: float) -> Vector3:
	return Vector3(sin(angle), 0.0, cos(angle))


func _random_point(half: float) -> Vector3:
	return Vector3(rng.randf_range(-half, half), 0.0, rng.randf_range(-half, half))


func _near(list: PackedVector3Array, p: Vector3, distance: float) -> bool:
	for q in list:
		if p.distance_squared_to(q) < distance * distance:
			return true
	return false
