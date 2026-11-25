class_name Friend
extends Person

## A gnome friend the player looks for: the player's gnome with hat and suit in its own colour.
## Stands still and answers every shout that reaches him, in a bubble of his colour.

const HEARING := 3.0  # he hears you 3x as far as visitors do: a full shout reaches 135 m
const RECOLOR := ["Clay_Hat", "Clay_Suit"]  # gnome materials that take the friend's colour

# A glowing shell just outside the body (inverted hull) that swells and fades: the "radioactive" look.
const GLOW_SHADER := """
shader_type spatial;
render_mode unshaded, cull_front, blend_add, shadows_disabled;
uniform vec4 glow : source_color;
uniform float phase = 0.0;
void vertex() {
	float p = 0.5 + 0.5 * sin(TIME * 4.0 + phase);
	VERTEX += NORMAL * (0.015 + 0.03 * p);
}
void fragment() {
	float p = 0.5 + 0.5 * sin(TIME * 4.0 + phase);
	ALBEDO = glow.rgb * (0.6 + 0.9 * p);
}
"""

var color := Color(0.2, 0.45, 0.95)
var following: Player     # set once found: walks behind the player
var slot := 0             # place in the row behind the player
var _light := OmniLight3D.new()
var _phase := randf() * TAU


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	anims = Player.GNOME
	loops = Player.GNOME_LOOPS
	walk_anim = 0.23  # same small steps as the player's gnome
	run_anim = 3.2
	setup(Player.MODEL, 1.0, 1.0)
	add_to_group("npc")
	var shader := Shader.new()
	shader.code = GLOW_SHADER
	var glow := ShaderMaterial.new()
	glow.shader = shader
	glow.set_shader_parameter("glow", color)
	glow.set_shader_parameter("phase", _phase)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if not mat:
				continue
			var own := mat.duplicate() as StandardMaterial3D
			if mat.resource_name in RECOLOR:
				own.albedo_color = color
			own.next_pass = glow
			mi.set_surface_override_material(s, own)
	_light.light_color = color
	_light.omni_range = 3.0
	_light.shadow_enabled = false
	_light.position.y = 0.6
	add_child(_light)
	bubble.modulate = color.lightened(0.35)
	play("idle")


func _process(delta: float) -> void:
	super(delta)
	if not following and not anim.is_playing():  # a one-shot (Angry) has ended
		play("idle")
	_light.light_energy = 0.6 + 1.2 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0 + _phase))  # same beat as the glow


## Called for everyone when the player shouts.
func hear(from: Node3D, radius: float) -> void:
	if visible and not following and global_position.distance_to(from.global_position) <= radius * HEARING:
		say("Hier!", 3.0, 80)


## A found friend walks behind the player, in a row by slot; in a car he rides on the roof.
func follow(who: Player, place: int) -> void:
	following = who
	slot = place
	collision_layer = 0  # the player must not bump into his own followers
	visible = true


## Stops following and stands still at pos, looking toward look_at (the golden gnome).
func stand_on(pos: Vector3, look_at: Vector3) -> void:
	following = null
	collision_layer = 0
	velocity = Vector3.ZERO
	global_position = pos
	var to := look_at - pos
	model.rotation.y = atan2(to.x, to.z)
	play("idle")
	say("Hoera!", 2.0, 60)


func stop_following() -> void:
	following = null
	collision_layer = 4


func _physics_process(delta: float) -> void:
	if not following:
		return
	var car := following.car
	if car:  # ride along, sitting: next to the driver, on the boot and on the bonnet
		global_position = car.global_transform * Kart.RIDERS[slot % Kart.RIDERS.size()]
		model.rotation.y = car.rotation.y
		velocity = Vector3.ZERO
		play("sit")
		return
	var behind := -Vector3(sin(following.model.rotation.y), 0.0, cos(following.model.rotation.y))
	var goal := following.global_position + behind * (1.6 + 1.2 * slot)
	var to := goal - global_position
	to.y = 0.0
	if to.length() > 40.0:  # left far behind (got out of a car somewhere): catch up at once
		global_position = goal
		to = Vector3.ZERO
	var speed := clampf((to.length() - 0.3) * 3.0, 0.0, 16.0)
	var dir := to.normalized() if speed > 0.0 else Vector3.ZERO
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	fall(delta)
	move_and_slide()
	if speed > 0.5:
		face(dir, delta)
		play_move(speed)
	else:
		face(following.global_position - global_position, delta)
		play("idle")
