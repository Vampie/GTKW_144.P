class_name Player
extends Person

## The player: walks, runs, jumps and shouts. The camera hangs behind on a spring arm.
## Holding the left mouse button makes the shout louder; a ring on the ground shows how far it reaches.
## E gets into the nearest parked car and out again; in a car the shout is a honk that carries further.

const WALK := 8.0   # was the running speed
const RUN := 14.0
const JUMP := 6.0
const MIN_RADIUS := 6.0
const MAX_RADIUS := 45.0
const FULL_CHARGE := 1.5  # seconds of holding for the loudest shout
const MOUSE_SPEED := 0.003
const MODEL := "res://assets/characters/gnome/gnome.glb"  # made in metres, 1.02 m tall with hat
const REACH := 3.5        # how close a car must be to get in
const HONK := 1.5         # a honk reaches this much further than a shout

var car: Car              # the car the player drives, or null
var nearby_car: Car       # a car close enough to get into, or null
var pivot := Node3D.new()
var arm := SpringArm3D.new()
var ring := MeshInstance3D.new()
var charge := -1.0      # seconds the shout button is held; below 0 when not shouting
var shout_left := 0.0   # seconds left of the shout animation
var shouts := 0         # shouts this round; the hunt resets it
const LOOK_BACK_MS := 1500  # in a car: ms without mouse movement before the camera follows the car again
var _looked_at := 0         # time of the last mouse movement, in ms


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4  # world and visitors
	walk_anim = 0.23  # the gnome takes small steps (measured from its feet)
	run_anim = 3.2    # measured 0.8, but true-to-speed legs look too frantic; now 1.25x when walking, 2.5x when running
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
	if event is InputEventMouseMotion and captured:
		pivot.rotation.y -= event.relative.x * MOUSE_SPEED
		_looked_at = Time.get_ticks_msec()
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * MOUSE_SPEED, -1.2, 0.3)
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		if car:
			get_out()
		elif nearby_car:
			get_in(nearby_car)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not captured:
			if event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.pressed:
			start_shout()
		else:
			release_shout()


func get_in(c: Car) -> void:
	car = c
	car.driving = true
	model.visible = false
	collision_layer = 0
	collision_mask = 0
	arm.add_excluded_object(car.get_rid())
	arm.spring_length = 9.0
	pivot.position.y = 2.2


func get_out() -> void:
	car.driving = false
	car.speed = 0.0
	arm.remove_excluded_object(car.get_rid())
	global_position = car.global_position + car.global_basis.x * 2.4  # next to the driver's door
	car = null
	model.visible = true
	collision_layer = 2
	collision_mask = 1 | 4
	arm.spring_length = 4.0
	pivot.position.y = 1.1


func _physics_process(delta: float) -> void:
	if charge >= 0.0:
		charge += delta
		ring.scale = Vector3(radius(), 1.0, radius())
	if car:
		global_position = car.global_position
		# look around with the mouse; after a moment without mouse movement the camera
		# swings back in behind the driving car (+Z of the pivot is behind)
		if Time.get_ticks_msec() - _looked_at > LOOK_BACK_MS and absf(car.speed) > 1.0:
			pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-car.forward().x, -car.forward().z), 2.0 * delta)
		ring.global_position = global_position + Vector3.UP * 0.15
		return
	nearby_car = null
	for c: Car in get_tree().get_nodes_in_group("car"):
		if c.global_position.distance_to(global_position) < REACH:
			nearby_car = c
	var input := Vector3(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0.0,
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	var dir := (Basis(Vector3.UP, pivot.rotation.y) * input).normalized()
	var speed := RUN if Input.is_physical_key_pressed(KEY_SHIFT) else WALK
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	fall(delta)
	if is_on_floor() and Input.is_physical_key_pressed(KEY_SPACE):
		velocity.y = JUMP
	move_and_slide()
	face(dir, delta)
	shout_left -= delta
	if not is_on_floor():
		play("jump")
	elif dir != Vector3.ZERO:
		play_move(speed)
	elif shout_left > 0.0:
		play("shout")
	else:
		play("idle")
	ring.global_position = global_position + Vector3.UP * 0.15


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
