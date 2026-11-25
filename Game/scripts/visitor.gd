class_name Visitor
extends Person

## A park visitor. Walks along the paths, sits on a bench or stands in a group,
## and reacts to a shout in its own way.

enum Type { CURIOUS, SKITTISH, GRUMPY, HEADPHONES }
enum Mode { WANDER, SIT, STAND }

const WALK := 1.6
const RUN := 6.0
const REACT_TIME := 10.0  # seconds before a visitor goes back to what it was doing
const FED_UP := 3.0       # annoyance at which anyone who hears you turns grumpy
const CALM_DOWN := 20.0   # seconds to forget one shout
const CURIOUS_LINES := ["Ja?", "Hallo?", "Wie roept daar?"]
const GRUMPY_LINES := ["Wat?!", "Niet zo roepen!", "Hou je mond!", "Pfff..."]

var park: Park
var model_path: String
var type := Type.CURIOUS         # how the visitor reacts now; changes with its mood
var personality := Type.CURIOUS  # how the visitor reacts when calm
var annoyance := 0.0             # +1 per shout heard, slowly goes back to 0
var mode := Mode.WANDER
var home := Transform3D()  # seat or group spot; unused while wandering
var target := -1           # path node the visitor walks to
var previous := -1
var lane := Vector3.ZERO   # own offset from the middle of the path, so people don't walk in one line
var pause := 0.0           # seconds to stand still at a crossing
var react := 0.0           # seconds left of the reaction to a shout
var shouter: Node3D
var waved := false
var stuck := 0.0
var detour := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1  # world only: visitors walk through each other instead of jamming the paths
	setup(model_path)
	add_to_group("npc")
	personality = type
	lane = Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(-1.2, 1.2))


## Called for every visitor when the player shouts.
func hear(from: Node3D, radius: float) -> void:
	if global_position.distance_to(from.global_position) > radius:
		return
	if type == Type.HEADPHONES:
		say("La la la...", 2.0)  # hears only music; the default font has no music note glyph
		return
	annoyance += 1.0
	var fed_up := annoyance >= FED_UP and type != Type.GRUMPY
	if fed_up:
		type = Type.GRUMPY
	if mode == Mode.SIT and global_position.distance_to(home.origin) < 0.1:
		global_position = home.origin + home.basis.z * 0.9 - Vector3.UP * home.origin.y  # stand up, off the bench
	shouter = from
	react = REACT_TIME
	waved = false
	match type:
		Type.CURIOUS:
			say(CURIOUS_LINES.pick_random())
		Type.SKITTISH:
			say("Aaah!", 2.0)
			play("scared", 1.0, true)
		Type.GRUMPY:
			say("Nu is het genoeg!" if fed_up else GRUMPY_LINES.pick_random(), 4.0)
			play("angry", 1.0, true)


func _physics_process(delta: float) -> void:
	annoyance = maxf(annoyance - delta / CALM_DOWN, 0.0)
	if type != personality and annoyance < 1.0 and react <= 0.0:
		type = personality  # calmed down
	if react > 0.0:
		react -= delta
		_react(delta)
		if react <= 0.0:
			target = -1
	elif mode == Mode.WANDER:
		_wander(delta)
	else:
		_go_home(delta)


func _react(delta: float) -> void:
	var to := shouter.global_position - global_position
	to.y = 0.0
	match type:
		Type.CURIOUS:
			if not waved and to.length() > 2.5:
				_walk_to(shouter.global_position, WALK * 1.6, delta)
			else:
				_halt(delta)
				face(to, delta)
				if not waved:
					waved = true
					say("Hoi!", 3.0)
					play("wave", 1.0, true)
		Type.SKITTISH:
			if react > REACT_TIME - 0.6:
				_halt(delta)  # the scared animation plays first
			elif react > REACT_TIME - 6.0:
				_walk_to(global_position - to.normalized() * 10.0, RUN, delta)
			else:
				_halt(delta)
				play("idle")
		Type.GRUMPY:
			_halt(delta)
			face(to, delta)
	if not anim.is_playing():  # an emote has ended
		play("idle")


func _wander(delta: float) -> void:
	if target < 0:
		target = _nearest_point()
		previous = -1
	if pause > 0.0:
		pause -= delta
		_halt(delta)
		play("idle")
		return
	if _walk_to(park.points[target] + lane, WALK, delta) < 0.6:
		var options := Array(park.links[target])
		if options.size() > 1:
			options.erase(previous)
		previous = target
		target = options.pick_random()
		if randf() < 0.2:
			pause = randf_range(2.0, 6.0)


func _go_home(delta: float) -> void:
	var to := home.origin - global_position
	to.y = 0.0
	if to.length() > 1.2:
		_walk_to(home.origin, WALK, delta)
		return
	velocity = Vector3.ZERO
	global_position = home.origin
	model.rotation.y = home.basis.get_euler().y
	play("sit" if mode == Mode.SIT else "idle")


## Walks toward goal and returns the distance left.
func _walk_to(goal: Vector3, speed: float, delta: float) -> float:
	var to := goal - global_position
	to.y = 0.0
	var dist := to.length()
	var dir := to / dist if dist > 0.05 else Vector3.ZERO
	if detour > 0.0:
		detour -= delta
		dir = dir.rotated(Vector3.UP, 1.3)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	fall(delta)
	move_and_slide()
	face(dir, delta)
	play_move(speed)
	# shortcut: blocked by a tree or bench means turn aside for a second; use a navmesh if people still get stuck
	var moved := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	if dist > 0.05 and moved < speed * 0.3:
		stuck += delta
		if stuck > 0.5:
			stuck = 0.0
			detour = 1.0
	else:
		stuck = 0.0
	return dist


func _halt(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	fall(delta)
	move_and_slide()


func _nearest_point() -> int:
	var best := 0
	for i in park.points.size():
		if global_position.distance_squared_to(park.points[i]) < global_position.distance_squared_to(park.points[best]):
			best = i
	return best
