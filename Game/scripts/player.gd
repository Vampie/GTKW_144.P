class_name Player
extends Person

## The player: walks, runs, jumps and shouts. The camera hangs behind on a spring arm.
## Holding the left mouse button makes the shout louder; a ring on the ground shows how far it reaches.

const WALK := 4.0
const RUN := 8.0
const JUMP := 6.0
const MIN_RADIUS := 6.0
const MAX_RADIUS := 45.0
const FULL_CHARGE := 1.5  # seconds of holding for the loudest shout
const MOUSE_SPEED := 0.003
const MODEL := "res://assets/characters/gnome/gnome.glb"  # made in metres, 1.02 m tall with hat

var pivot := Node3D.new()
var ring := MeshInstance3D.new()
var charge := -1.0      # seconds the shout button is held; below 0 when not shouting
var shout_left := 0.0   # seconds left of the shout animation


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4  # world and visitors
	walk_anim = 0.23  # the gnome takes small steps (measured from its feet)
	run_anim = 3.2    # measured 0.8, but true-to-speed legs look too frantic; now 1.25x when walking, 2.5x when running
	setup(MODEL, 1.0, 1.0)
	pivot.position.y = 1.1
	pivot.rotation.x = -0.3
	add_child(pivot)
	var arm := SpringArm3D.new()
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
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * MOUSE_SPEED, -1.2, 0.3)
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not captured:
			if event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.pressed:
			start_shout()
		else:
			release_shout()


func _physics_process(delta: float) -> void:
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
	if charge >= 0.0:
		charge += delta
		ring.scale = Vector3(radius(), 1.0, radius())
	ring.global_position = global_position + Vector3.UP * 0.15


func radius() -> float:
	return lerpf(MIN_RADIUS, MAX_RADIUS, clampf(charge / FULL_CHARGE, 0.0, 1.0))


func start_shout() -> void:
	charge = 0.0
	ring.visible = true


func release_shout() -> void:
	if charge < 0.0:
		return
	var r := radius()
	var loud := inverse_lerp(MIN_RADIUS, MAX_RADIUS, r)
	say("HÉ!" if loud < 0.6 else "HÉÉÉ!", 1.5, int(lerpf(36.0, 72.0, loud)))
	get_tree().call_group("npc", "hear", self, r)
	play("shout", 1.0, true)
	shout_left = 2.0  # length of the gnome's Shout animation
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
