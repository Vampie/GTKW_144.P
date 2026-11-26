class_name Player
extends Person

## The player: the gnome. Walks, sprints, sneaks, jumps, punches, kicks and shouts. The camera hangs
## behind on a spring arm. Holding the left mouse button makes the shout louder; a ring on the ground
## shows how far it reaches. E gets into a gnome car (Kart) with the EnterCar animation and out again
## with ExitCar, or bails out with BailOut when the car goes fast. In a car the shout is a honk.
## Controls: WASD, Shift sprint, Ctrl sneak, Space jump (a leap when moving), F punch, G kick, E car.

const WALK := 8.0
const RUN := 14.0
const SNEAK := 2.5
const JUMP := 6.0
const MIN_RADIUS := 6.0
const MAX_RADIUS := 45.0
const FULL_CHARGE := 1.5  # seconds of holding for the loudest shout
const MOUSE_SPEED := 0.003
const MODEL := "res://assets/characters/gnome/gnome.glb"  # made in metres, 1.02 m tall with hat
const REACH := 2.5        # how close a gnome car must be to get in
const HONK := 1.5         # a honk reaches this much further than a shout
const BAIL_SPEED := 6.0   # getting out faster than this is a bail-out
const HIT_REACH := 1.3    # punches and kicks reach visitors this close in front
const ZOOM_MIN := 0.35       # mouse wheel: camera distance as a factor of the normal distance
const ZOOM_MAX := 3.0
const LOOK_BACK_MS := 1500  # in a car: ms without mouse movement before the camera follows the car again
# The gnome's clips (see assets/characters/gnome/AGENT_GIDS.md); the keys are what the code asks for.
const GNOME := {"idle": "Idle", "walk": "Walk", "sprint": "Run", "dash": "Sprint", "jump": "Jump",
	"leap": "Leap", "fall": "Fall", "land": "Land", "crouch": "Crouch", "crouchwalk": "CrouchWalk",
	"shout": "Shout", "punch": "Punch", "kick": "Kick", "enter": "EnterCar", "drive": "Drive",
	"exit": "ExitCar", "bail": "BailOut", "sit": "Sit", "angry": "Angry", "scared": "Hit", "wave": "Jump"}
const GNOME_LOOPS := ["idle", "walk", "sprint", "dash", "jump", "fall", "crouch", "crouchwalk", "drive", "sit"]

enum Ride { NONE, ENTER, DRIVE, EXIT, BAIL }

var car: Car              # the gnome car the player is in (also while getting in or out), or null
var nearby_car: Car       # a gnome car close enough to get into, or null
var ride := Ride.NONE
var pivot := Node3D.new()
var arm := SpringArm3D.new()
var ring := MeshInstance3D.new()
var charge := -1.0      # seconds the shout button is held; below 0 when not shouting
var shout_left := 0.0   # seconds left of the shout animation
var shouts := 0         # shouts this round; the hunt resets it
var _looked_at := 0         # time of the last mouse movement, in ms
var _zoom := 1.0            # set with the mouse wheel; kept when getting in or out of a car
var _distance := 4.0        # normal camera distance: 4 m on foot, 6 m in a car
var _ride_time := 0.0       # seconds into getting in, out or bailing out
var _bail_velocity := Vector3.ZERO
var _action_left := 0.0     # a one-shot (land, punch, kick) is playing; the gnome stands still meanwhile
var _hit_in := -1.0         # seconds until a punch or kick lands; below 0 when there is none
var _air_time := 0.0
var _leaping := false


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4  # world and visitors
	anims = GNOME
	loops = GNOME_LOOPS
	walk_anim = 0.23  # the gnome takes small steps (measured from its feet)
	run_anim = 3.2    # measured 0.8, but true-to-speed legs look too frantic; now 2.5x when walking
	setup(MODEL, 1.0, 1.0)
	pivot.position.y = 1.1
	pivot.rotation.x = -0.3
	add_child(pivot)
	var probe := SphereShape3D.new()
	probe.radius = 0.3
	arm.shape = probe
	arm.spring_length = 4.0
	arm.collision_mask = 1
	pivot.add_child(arm)
	arm.add_excluded_object(get_rid())
	var cam := Camera3D.new()
	cam.far = 900.0
	arm.add_child(cam)
	_make_ring()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if (event is InputEventMouseMotion and captured) or event is InputEventScreenDrag:  # drag: touch.gd
		pivot.rotation.y -= event.relative.x * MOUSE_SPEED
		_looked_at = Time.get_ticks_msec()
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * MOUSE_SPEED, -1.2, 0.3)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_E:
				if ride == Ride.DRIVE:
					get_out()
				elif ride == Ride.NONE and nearby_car:
					get_in(nearby_car)
			KEY_F:
				_strike("punch", 0.5)
			KEY_G:
				_strike("kick", 0.48)
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		zoom(0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not captured:
			if event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.pressed:
			start_shout()
		else:
			release_shout()


## Moves the camera closer (factor below 1) or further away: mouse wheel, or pinching (touch.gd).
func zoom(factor: float) -> void:
	_zoom = clampf(_zoom * factor, ZOOM_MIN, ZOOM_MAX)


# --- the gnome car ---

func get_in(c: Car) -> void:
	car = c
	ride = Ride.ENTER
	_ride_time = 0.0
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	global_position = (car as Kart).door_world()
	model.rotation.y = car.rotation.y
	play("enter", 1.0, true, 0.0)
	arm.add_excluded_object(car.get_rid())
	_distance = 6.0
	pivot.position.y = 1.6


func get_out() -> void:
	car.driving = false
	ride = Ride.EXIT
	_ride_time = 0.0
	if absf(car.speed) > BAIL_SPEED:  # jump out while it rolls on
		ride = Ride.BAIL
		_bail_velocity = car.forward() * car.speed * 0.5 + car.global_basis.x * 4.0
		collision_layer = 2
		collision_mask = 1
		play("bail", 1.0, true, 0.0)
	else:
		car.speed = 0.0
		play("exit", 1.0, true, 0.0)
	global_position = (car as Kart).door_world()


func _ride(delta: float) -> void:
	_ride_time += delta
	var kart := car as Kart
	match ride:
		Ride.ENTER:
			global_position = kart.door_world()
			model.rotation.y = kart.rotation.y
			kart.door_open = _door(_ride_time / _length("enter"))
			if _ride_time >= _length("enter"):  # same pose as the start of Drive: switch without a blend
				ride = Ride.DRIVE
				kart.door_open = 0.0
				kart.driving = true
				play("drive", 1.0, true, 0.0)
		Ride.DRIVE:
			global_position = kart.seat_world()
			model.rotation.y = kart.rotation.y
			# look around with the mouse; after a moment without mouse movement the camera
			# swings back in behind the driving car (+Z of the pivot is behind)
			if Time.get_ticks_msec() - _looked_at > LOOK_BACK_MS and absf(kart.speed) > 1.0:
				pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-kart.forward().x, -kart.forward().z), 2.0 * delta)
		Ride.EXIT:
			global_position = kart.door_world()
			model.rotation.y = kart.rotation.y
			kart.door_open = _door(1.0 - _ride_time / _length("exit"))  # EnterCar played backwards
			if _ride_time >= _length("exit"):
				kart.door_open = 0.0
				_on_foot()
		Ride.BAIL:
			velocity.x = _bail_velocity.x
			velocity.z = _bail_velocity.z
			_bail_velocity *= exp(-2.5 * delta)
			fall(delta)
			move_and_slide()
			if _ride_time >= _length("bail"):
				_on_foot()


## How far the door is open at fraction t of EnterCar: opens at 13-26 %, shuts at 76-88 %.
func _door(t: float) -> float:
	return smoothstep(0.13, 0.26, t) * (1.0 - smoothstep(0.76, 0.88, t))


func _on_foot() -> void:
	arm.remove_excluded_object(car.get_rid())
	car = null
	ride = Ride.NONE
	collision_layer = 2
	collision_mask = 1 | 4
	_distance = 4.0
	pivot.position.y = 1.1
	play("idle")


func _length(what: String) -> float:
	return anim.get_animation(anims[what]).length


# --- on foot ---

func _physics_process(delta: float) -> void:
	if charge >= 0.0:
		charge += delta
		ring.scale = Vector3(radius(), 1.0, radius())
	ring.global_position = global_position + Vector3.UP * 0.15
	arm.spring_length = lerpf(arm.spring_length, _distance * _zoom, 10.0 * delta)  # smooth zoom
	shout_left -= delta
	if ride != Ride.NONE:
		_ride(delta)
		return
	nearby_car = null
	for c: Car in get_tree().get_nodes_in_group("car"):
		if c.global_position.distance_to(global_position) < REACH:
			nearby_car = c
	if _action_left > 0.0:  # landing, punching or kicking: stand still until it is done
		_action_left -= delta
		if _hit_in >= 0.0:
			_hit_in -= delta
			if _hit_in < 0.0:
				_land_hit()
		velocity.x = 0.0
		velocity.z = 0.0
		fall(delta)
		move_and_slide()
		return
	var input := Vector3(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0.0,
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	var dir := (Basis(Vector3.UP, pivot.rotation.y) * input).normalized()
	var sneaking := Input.is_physical_key_pressed(KEY_CTRL)
	var running := Input.is_physical_key_pressed(KEY_SHIFT) and not sneaking
	var speed := SNEAK if sneaking else (RUN if running else WALK)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	fall(delta)
	if is_on_floor() and Input.is_physical_key_pressed(KEY_SPACE) and not sneaking:
		velocity.y = JUMP
		_leaping = dir != Vector3.ZERO  # a running jump: Leap shows take-off, stretch and landing
		play("leap" if _leaping else "jump", 1.0, true)
	var was_flying := not is_on_floor()
	move_and_slide()
	face(dir, delta)
	if not is_on_floor():
		_air_time += delta
		if not _leaping:
			play("fall" if velocity.y < -7.0 else "jump")
		return
	if was_flying:  # just landed
		if _air_time > 0.45 and not _leaping:
			_action("land", 0.8)
			_air_time = 0.0
			return
		_air_time = 0.0
		_leaping = false
	if dir != Vector3.ZERO:
		if sneaking:
			play("crouchwalk")
		elif running:
			play("dash", minf(speed / (run_anim * 1.75), MAX_ANIM_SPEED))
		else:
			play_move(speed)
	elif sneaking:
		play("crouch")
	elif shout_left > 0.0:
		play("shout")
	else:
		play("idle")


## Plays a one-shot clip and keeps the gnome standing for part of it.
func _action(what: String, part := 1.0) -> void:
	play(what, 1.0, true)
	_action_left = _length(what) * part


func _strike(what: String, lands_at: float) -> void:
	if ride != Ride.NONE or _action_left > 0.0 or not is_on_floor():
		return
	_action(what)
	_hit_in = _length(what) * lands_at


func _land_hit() -> void:
	var ahead := Vector3(sin(model.rotation.y), 0.0, cos(model.rotation.y))
	for v: Node in get_tree().get_nodes_in_group("npc"):
		var to: Vector3 = (v as Node3D).global_position - global_position
		to.y = 0.0
		if to.length() < HIT_REACH and to.normalized().dot(ahead) > 0.3 and v.has_method("get_hit"):
			v.get_hit(self)


# --- shouting ---

func radius() -> float:
	return lerpf(MIN_RADIUS, MAX_RADIUS, clampf(charge / FULL_CHARGE, 0.0, 1.0)) * (HONK if car else 1.0)


func start_shout() -> void:
	charge = 0.0
	ring.visible = true


func release_shout() -> void:
	if charge < 0.0:
		return
	var r := radius()
	var loud := clampf(charge / FULL_CHARGE, 0.0, 1.0)
	if car:
		say("TOET!" if loud < 0.6 else "TOEEEET!", 1.5, int(lerpf(36.0, 72.0, loud)))
	else:
		say("HÉ!" if loud < 0.6 else "HÉÉÉ!", 1.5, int(lerpf(36.0, 72.0, loud)))
		if _action_left <= 0.0:
			play("shout", 1.0, true)
			shout_left = 2.0  # length of the gnome's Shout animation
	get_tree().call_group("npc", "hear", self, r)
	shouts += 1
	charge = -1.0
	ring.visible = false


func _make_ring() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.97
	torus.outer_radius = 1.0
	torus.rings = 96
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.85, 0.2, 0.75)
	torus.material = mat
	ring.mesh = torus
	ring.top_level = true
	ring.visible = false
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
