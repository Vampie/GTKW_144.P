class_name Hunt
extends Node

## "Zoek je vriend": five coloured phone booths in the park, each with a yellow arrow above it.
## E at a booth starts a round: five gnome friends, one per colour, hide in the park, and the player
## has to find the one in the booth's colour. The others answer shouts too, but say it is not them.
## A friend that has been found follows the player (Friend.follow), and his booth closes.
## Once all five are found, a huge golden gnome appears in the pond with a pedestal per colour
## around it; O at a pedestal puts that colour's friend on it. With all five placed the giant spews
## confetti from its mouth until the player resets everything at a phone booth (asked yup / nope).
## A round ends within FOUND_DISTANCE of the right friend; Enter goes back to free play.
## Test option "--found" starts a blue round with the blue friend right next to the player.

enum State { FREE, SEARCHING, FOUND, FINALE }

const COLORS := [["blauwe", Color(0.2, 0.45, 0.95)], ["groene", Color(0.2, 0.7, 0.25)],
	["paarse", Color(0.6, 0.3, 0.9)], ["oranje", Color(1.0, 0.55, 0.1)], ["roze", Color(1.0, 0.45, 0.72)]]
# One booth per colour, on the lawn next to a main path; the first is just in front of the player's start.
const BOOTHS := [Vector3(7, 0, 59), Vector3(59, 0, -7), Vector3(-7, 0, -59), Vector3(-59, 0, 7), Vector3(7, 0, 150)]
const START_REACH := 2.5     # from the middle of a phone booth
const ARROW_HEIGHT := 4.2
const MIN_DISTANCE := 80.0   # friends hide at least this far from the player
const FRIEND_SPACING := 30.0 # and this far from each other
const FOUND_DISTANCE := 2.0
const GIANT_SCALE := 22.0      # the golden gnome: about 22 m tall
const PEDESTAL_RING := 36.0    # pedestals stand around the pond, just outside its sand edge
const PEDESTAL_HEIGHT := 1.0
const PEDESTAL_REACH := 3.5
const ACCENT := Color(0.36, 0.62, 1.0)
const PANEL := Color(0.07, 0.09, 0.13, 0.78)
const MUTED := Color(0.7, 0.75, 0.82)
const WALK_CONTROLS := "WASD wandelen  ·  Shift lopen  ·  Ctrl sluipen  ·  Spatie springen  ·  F stompen  ·  G trappen  ·  Linkermuisknop vasthouden: roepen  ·  E: instappen  ·  Esc: muis los"
const CAR_CONTROLS := "W gas  ·  S remmen / achteruit  ·  A D sturen  ·  Linkermuisknop vasthouden: toeteren  ·  E: uitstappen  ·  Esc: muis los"

var park: Park
var player: Player
var friends: Array[Friend] = []
var booths := PackedVector3Array()   # where the booths ended up (moved away from trees)
var target := 0                      # colour index of the friend to find
var done: Array[bool] = [false, false, false, false, false]  # colours found since the last full set
var placed: Array[bool] = [false, false, false, false, false]  # colours standing on their pedestal
var time := 0.0
var state := State.FREE
var rng := RandomNumberGenerator.new()  # not seeded: new hiding places every round

var _time_value := Label.new()
var _shout_value := Label.new()
var _fps := Label.new()
var _controls := Label.new()
var _prompt := Label.new()
var _prompt_panel: PanelContainer
var _top: PanelContainer
var _title := Label.new()
var _head: Label
var _arrows: Array[Node3D] = []
var _giant := Node3D.new()           # golden gnome plus the pedestals; shown once all five are found
var _pedestals := PackedVector3Array()
var _again: Label
var _confetti: Array[GPUParticles3D] = []
var _ask: PanelContainer           # "Alles opnieuw beginnen?  Yup / Nope"
var _ask_yes := false                # the highlighted answer; Nope by default
var _yup: PanelContainer
var _nope: PanelContainer
var _end := Control.new()
var _end_time := Label.new()
var _end_shouts := Label.new()
var _end_annoyed := Label.new()


func _ready() -> void:
	rng.randomize()
	for c: Array in COLORS:
		var f := Friend.new()
		f.color = c[1]
		friends.append(f)
		add_child(f)
	for i in COLORS.size():
		_build_booth(i)
	_build_giant()
	_build_hud()
	_free_play()
	if "--found" in OS.get_cmdline_user_args():
		start_round(0)
		friends[0].global_position = player.global_position + Vector3(1.0, 0.0, -1.0)


func start_round(colour: int) -> void:
	target = colour
	var taken := PackedVector3Array()
	for i in friends.size():
		var f := friends[i]
		if done[i]:
			continue  # found friends keep following the player
		f.visible = true
		f.collision_layer = 4
		var p := _hiding_place(taken)
		taken.append(p)
		f.global_position = p
		f.model.rotation.y = rng.randf() * TAU
	time = 0.0
	state = State.SEARCHING
	player.shouts = 0
	Visitor.fed_up_total = 0
	var c: Color = COLORS[colour][1]
	_title.text = "Kabouter in het %s" % ["blauw", "groen", "paars", "oranje", "roze"][colour]
	_title.add_theme_color_override("font_color", c.lightened(0.25))
	_head.add_theme_color_override("font_color", c.lightened(0.25))
	_top.visible = true


## No round: the friends are gone and the top panel hidden.
func _free_play() -> void:
	state = State.FREE
	for i in friends.size():
		if done[i]:
			continue  # still following the player
		friends[i].stop_following()
		friends[i].visible = false  # Friend.hear ignores shouts while hidden
		friends[i].collision_layer = 0
	_top.visible = false
	_end.visible = false


## Index of the booth the player stands at in free play, or -1.
func _at_booth() -> int:
	if state not in [State.FREE, State.FINALE] or player.car or _ask.visible:
		return -1
	for i in booths.size():
		if player.global_position.distance_to(booths[i]) < START_REACH:
			return i
	return -1


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: Key = event.physical_keycode
		if _ask.visible:  # the reset question takes the keys while it is open
			if key in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D]:
				_ask_yes = not _ask_yes
				_show_answer()
			elif key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
				_close_ask()
				if _ask_yes:
					_start_over()
			get_viewport().set_input_as_handled()
			return
		if key == KEY_E and _at_booth() >= 0 and state == State.FINALE:
			_open_ask()
		elif key == KEY_E and _at_booth() >= 0 and not done[_at_booth()]:
			start_round(_at_booth())
		elif key in [KEY_ENTER, KEY_KP_ENTER] and state == State.FOUND:
			_free_play()
		elif event.physical_keycode == KEY_O and _at_pedestal() >= 0:
			_place(_at_pedestal())


## Index of a pedestal the player stands at whose friend still follows him, or -1.
func _at_pedestal() -> int:
	if not _giant.visible or player.car or state != State.FREE:
		return -1
	for i in _pedestals.size():
		if not placed[i] and friends[i].following and player.global_position.distance_to(_pedestals[i]) < PEDESTAL_REACH:
			return i
	return -1


func _place(i: int) -> void:
	placed[i] = true
	friends[i].stand_on(_pedestals[i] + Vector3.UP * PEDESTAL_HEIGHT, Vector3.ZERO)
	var slot := 0
	for f in friends:  # close the gap in the row behind the player
		if f.following:
			f.slot = slot
			slot += 1
	if not false in placed:  # all five home: confetti until the player resets at a phone booth
		state = State.FINALE
		for c in _confetti:
			c.emitting = true


## Everyone home, the giant gone, all booths open again.
func _start_over() -> void:
	done.fill(false)
	placed.fill(false)
	_giant.visible = false
	_giant.process_mode = Node.PROCESS_MODE_DISABLED
	for c in _confetti:
		c.emitting = false
	_free_play()


func _open_ask() -> void:
	_ask_yes = false
	_show_answer()
	_ask.visible = true
	player.set_physics_process(false)  # A and D choose an answer instead of walking


func _close_ask() -> void:
	_ask.visible = false
	player.set_physics_process(true)


func _show_answer() -> void:
	for pair in [[_yup, _ask_yes], [_nope, not _ask_yes]]:
		var box: PanelContainer = pair[0]
		var style := box.get_theme_stylebox("panel") as StyleBoxFlat
		style.bg_color = Color(1.0, 0.82, 0.3) if pair[1] else Color(1, 1, 1, 0.08)
		(box.get_child(0) as Label).add_theme_color_override("font_color", Color.BLACK if pair[1] else Color.WHITE)


func _process(delta: float) -> void:
	_fps.text = "%d fps" % Engine.get_frames_per_second()
	_controls.text = CAR_CONTROLS if player.car else WALK_CONTROLS
	for i in _arrows.size():
		_arrows[i].visible = (state == State.FREE and not done[i]) or state == State.FINALE
		_arrows[i].rotation.y += 1.5 * delta
		_arrows[i].position.y = ARROW_HEIGHT + 0.25 * sin(Time.get_ticks_msec() / 400.0 + i)
	var booth := _at_booth()
	if booth >= 0:
		if state == State.FINALE:
			_prompt.text = "E  alles opnieuw beginnen"
		else:
			_prompt.text = ("De %s kabouter is al gevonden" if done[booth] else "E  zoek de %s kabouter") % COLORS[booth][0]
	elif player.nearby_car and not player.car:
		_prompt.text = "E  instappen"
	var pedestal := _at_pedestal()
	if pedestal >= 0:
		_prompt.text = "O  zet de %s kabouter op zijn sokkel" % COLORS[pedestal][0]
	_prompt_panel.visible = booth >= 0 or pedestal >= 0 or (player.nearby_car != null and player.car == null)
	if state != State.SEARCHING:
		return
	time += delta
	_time_value.text = _clock(time)
	_shout_value.text = str(player.shouts)
	for i in friends.size():
		if done[i] or not friends[i].visible or player.global_position.distance_to(friends[i].global_position) >= FOUND_DISTANCE:
			continue
		if i != target:
			if not friends[i].bubble.visible:
				friends[i].say("Ik ben het niet!", 2.0, 48)
				friends[i].play("angry", 1.0, true)
			continue
		state = State.FOUND
		done[target] = true
		friends[target].follow(player, done.count(true) - 1)
		_head.text = "Gevonden!"
		_again.text = "Enter: terug naar het park  ·  een nieuwe ronde start bij een telefooncel"
		if not false in done:  # all five found: they stay with the player and the golden gnome appears
			_head.text = "Alle vijf gevonden!"
			_again.text = "Enter: breng ze naar de gouden kabouter in de vijver en zet ze met O op hun sokkel"
			_giant.visible = true
			_giant.process_mode = Node.PROCESS_MODE_INHERIT
		_end_time.text = _clock(time)
		_end_shouts.text = str(player.shouts)
		_end_annoyed.text = str(Visitor.fed_up_total)
		_end.visible = true
		break


## Near a tree, off the paths, at least MIN_DISTANCE from the player and FRIEND_SPACING from taken.
func _hiding_place(taken: PackedVector3Array) -> Vector3:
	var me := Vector3(player.global_position.x, 0.0, player.global_position.z)
	for i in 2000:
		var p := park.trees[rng.randi() % park.trees.size()] + Vector3(rng.randf_range(-3.0, 3.0), 0.0, rng.randf_range(-3.0, 3.0))
		if p.distance_to(me) >= MIN_DISTANCE and park.path_clearance(p) > 2.0 and not park._near(park.trees, p, 1.2) \
				and not park._near(taken, p, FRIEND_SPACING):
			return p
	return park.trees[rng.randi() % park.trees.size()] + Vector3(2.0, 0.0, 0.0)  # practically never reached


## A phone booth in COLORS[i], built from boxes, with a yellow arrow floating above it.
func _build_booth(i: int) -> void:
	var pos: Vector3 = BOOTHS[i]
	var out := Vector3(pos.x, 0.0, pos.z).normalized()
	for n in 10:  # step outward along the path until no tree is in the way
		if not park._near(park.trees, pos, 3.0):
			break
		pos += out * 3.0
	booths.append(pos)
	var booth := StaticBody3D.new()  # layer 1: nobody walks through it
	booth.position = pos
	booth.rotation.y = atan2(-pos.x, -pos.z)  # +Z, the front, looks at the pond
	add_child(booth)
	var frame := _mat(COLORS[i][1])
	var glass := _mat(Color(0.75, 0.9, 1.0, 0.35))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.1
	_box(booth, Vector3(1.2, 0.15, 1.2), Vector3(0, 0.075, 0), frame)          # floor
	for corner in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		_box(booth, Vector3(0.12, 2.3, 0.12), corner * 0.54 + Vector3(0, 1.3, 0), frame)  # posts
	for side in 4:  # glass walls with a frame bar halfway
		var b := Basis(Vector3.UP, side * TAU / 4)
		_box(booth, Vector3(0.96, 2.0, 0.04), b * Vector3(0, 1.3, 0.52), glass, b)
		_box(booth, Vector3(0.96, 0.08, 0.06), b * Vector3(0, 1.3, 0.53), frame, b)
	_box(booth, Vector3(1.3, 0.35, 1.3), Vector3(0, 2.6, 0), frame)            # sign band
	_box(booth, Vector3(1.1, 0.2, 1.1), Vector3(0, 2.87, 0), frame)            # roof
	for side in 4:
		var b := Basis(Vector3.UP, side * TAU / 4)
		var sign := Label3D.new()
		sign.text = "TELEFOON"
		sign.font_size = 40
		sign.pixel_size = 0.005
		sign.outline_size = 0
		sign.transform = Transform3D(b, b * Vector3(0, 2.6, 0.66))
		booth.add_child(sign)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.3, 3.0, 1.3)
	shape.shape = box
	shape.position.y = 1.5
	booth.add_child(shape)

	# the floating arrow: a yellow shaft with a point, pointing down
	var yellow := _mat(Color(1.0, 0.82, 0.1))
	yellow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var arrow := Node3D.new()
	arrow.position = Vector3.UP * ARROW_HEIGHT
	booth.add_child(arrow)
	_arrows.append(arrow)
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.15
	shaft.bottom_radius = 0.15
	shaft.height = 0.7
	shaft.material = yellow
	var tip := CylinderMesh.new()
	tip.top_radius = 0.45
	tip.bottom_radius = 0.0
	tip.height = 0.6
	tip.radial_segments = 4  # a flat-sided point reads better while it turns
	tip.material = yellow
	for part in [[shaft, 0.65], [tip, 0.0]]:
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		mi.position.y = part[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arrow.add_child(mi)


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, basis := Basis()) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = Transform3D(basis, pos)
	parent.add_child(mi)


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m


## The golden gnome on an island in the pond, and a pedestal per colour around the pond.
func _build_giant() -> void:
	add_child(_giant)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.77, 0.25)
	gold.metallic = 1.0
	gold.roughness = 0.25
	gold.emission_enabled = true  # a little shine of its own, so it reads as gold in the shade too
	gold.emission = Color(0.5, 0.35, 0.05)
	var statue: Node3D = load(Player.MODEL).instantiate()
	statue.scale = Vector3.ONE * GIANT_SCALE
	statue.position = Vector3(0, 0.6, 0)  # faces south (+Z), toward the player's start
	_giant.add_child(statue)
	for mi: MeshInstance3D in statue.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = gold
	(statue.find_child("AnimationPlayer", true, false) as AnimationPlayer).play("Idle")
	var island := CylinderMesh.new()
	island.top_radius = 5.0
	island.bottom_radius = 6.0
	island.height = 0.6
	island.material = _mat(Color(0.86, 0.79, 0.6))
	var mi := MeshInstance3D.new()
	mi.mesh = island
	mi.position.y = 0.3
	_giant.add_child(mi)
	for i in COLORS.size():
		var ang := TAU * i / COLORS.size()  # the first (blue) on the south side
		var pos := Vector3(sin(ang), 0.0, cos(ang)) * PEDESTAL_RING
		_pedestals.append(pos)
		var body := StaticBody3D.new()
		body.position = pos
		_giant.add_child(body)
		_box(body, Vector3(1.4, PEDESTAL_HEIGHT, 1.4), Vector3(0, PEDESTAL_HEIGHT / 2.0, 0), _mat(COLORS[i][1]))
		_box(body, Vector3(1.6, 0.12, 1.6), Vector3(0, PEDESTAL_HEIGHT, 0), _mat(Color(0.95, 0.92, 0.85)))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.6, PEDESTAL_HEIGHT, 1.6)
		shape.shape = box
		shape.position.y = PEDESTAL_HEIGHT / 2.0
		body.add_child(shape)
	# confetti from the mouth (gnome mouth at 0.51 m high, 0.135 m in front, times the scale):
	# a steady fountain plus bursts that go off once per cycle
	var mouth := statue.position + Vector3(0, 0.51, 0.135) * GIANT_SCALE
	_confetti.append(_confetti_emitter(mouth, Vector3(0, 1, 0.5), 500, 6.0, 0.0, Vector2(14, 22)))
	_confetti.append(_confetti_emitter(mouth, Vector3(0, 1, 0.5), 900, 2.5, 0.95, Vector2(18, 32)))
	# and out of his bottom (behind the body at hip height), backward and up
	var bottom := statue.position + Vector3(0, 0.3, -0.15) * GIANT_SCALE
	_confetti.append(_confetti_emitter(bottom, Vector3(0, 0.6, -1), 400, 5.0, 0.0, Vector2(12, 20)))
	_confetti.append(_confetti_emitter(bottom, Vector3(0, 0.6, -1), 700, 3.0, 0.95, Vector2(16, 28)))
	_giant.visible = false
	_giant.process_mode = Node.PROCESS_MODE_DISABLED  # no colliders or animation until it appears


func _confetti_emitter(pos: Vector3, dir: Vector3, amount: int, lifetime: float, burst: float, speed: Vector2) -> GPUParticles3D:
	var pm := ParticleProcessMaterial.new()
	pm.direction = dir
	pm.spread = 40.0
	pm.initial_velocity_min = speed.x
	pm.initial_velocity_max = speed.y
	pm.gravity = Vector3(0, -6.0, 0)
	pm.damping_min = 2.0  # paper slows down in the air
	pm.damping_max = 4.0
	pm.angular_velocity_min = -360.0
	pm.angular_velocity_max = 360.0
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	var rainbow := Gradient.new()  # each piece takes a random colour from this
	rainbow.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	rainbow.colors = PackedColorArray([Color.RED, Color(1, 0.6, 0), Color.YELLOW, Color(0.2, 0.9, 0.3), Color(0.2, 0.5, 1), Color(0.8, 0.3, 1)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = rainbow
	pm.color_initial_ramp = ramp
	var paper := StandardMaterial3D.new()
	paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paper.vertex_color_use_as_albedo = true
	paper.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	var piece := QuadMesh.new()
	piece.size = Vector2(0.35, 0.22)
	piece.material = paper
	var p := GPUParticles3D.new()
	p.process_material = pm
	p.draw_pass_1 = piece
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = burst
	p.emitting = false
	p.position = pos
	p.visibility_aabb = AABB(Vector3(-60, -20, -60), Vector3(120, 60, 120))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_giant.add_child(p)
	return p


func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


# --- HUD ---

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = _theme()
	layer.add_child(root)

	# top: what to do, time and shouts
	_top = _panel(PANEL, 16)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	_top.add_child(row)
	var title := VBoxContainer.new()
	title.add_theme_constant_override("separation", 0)
	title.add_child(_label("ZOEK JE VRIEND", 13, ACCENT))
	_title.add_theme_font_size_override("font_size", 22)
	title.add_child(_title)
	row.add_child(title)
	row.add_child(_divider())
	row.add_child(_stat("TIJD", _time_value, 30))
	row.add_child(_stat("GEROEPEN", _shout_value, 30))
	_at(root, _top, Control.PRESET_CENTER_TOP, Vector2(0, 18))

	# bottom: controls
	var hint := _panel(Color(PANEL, 0.55), 10)
	_controls.add_theme_font_size_override("font_size", 14)
	_controls.add_theme_color_override("font_color", MUTED)
	_controls.text = WALK_CONTROLS
	hint.add_child(_controls)
	_at(root, hint, Control.PRESET_CENTER_BOTTOM, Vector2(0, -16))

	# "E: instappen" when standing next to a car
	_prompt_panel = _panel(PANEL, 12)
	_prompt.text = "E  instappen"
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_color_override("font_color", Color.WHITE)
	_prompt_panel.add_child(_prompt)
	_at(root, _prompt_panel, Control.PRESET_CENTER_BOTTOM, Vector2(0, -80))
	_prompt_panel.visible = false

	_fps.add_theme_font_size_override("font_size", 13)
	_fps.add_theme_color_override("font_color", MUTED)
	_at(root, _fps, Control.PRESET_TOP_RIGHT, Vector2(-16, 12))

	# end of round
	_end.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_end)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end.add_child(dim)
	var card := _panel(Color(PANEL, 0.9), 32)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	card.add_child(col)
	_head = _label("Gevonden!", 56, ACCENT)
	var head := _head
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 40)
	stats.add_child(_stat("TIJD", _end_time, 36))
	stats.add_child(_stat("GEROEPEN", _end_shouts, 36))
	stats.add_child(_stat("CHAGRIJNIG GEMAAKT", _end_annoyed, 36))
	col.add_child(stats)
	_again = _label("", 16, MUTED)
	var again := _again
	again.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(again)
	_at(_end, card, Control.PRESET_CENTER, Vector2.ZERO)

	# the reset question at a phone booth after the finale
	_ask = _panel(Color(PANEL, 0.92), 22)
	var ask_col := VBoxContainer.new()
	ask_col.add_theme_constant_override("separation", 14)
	_ask.add_child(ask_col)
	var q := _label("Alles opnieuw beginnen?", 26, Color.WHITE)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ask_col.add_child(q)
	var answers := HBoxContainer.new()
	answers.alignment = BoxContainer.ALIGNMENT_CENTER
	answers.add_theme_constant_override("separation", 16)
	ask_col.add_child(answers)
	_yup = _panel(Color(1, 1, 1, 0.08), 10)
	_yup.add_child(_label("Yup", 22, Color.WHITE))
	answers.add_child(_yup)
	_nope = _panel(Color(1, 1, 1, 0.08), 10)
	_nope.add_child(_label("Nope", 22, Color.WHITE))
	answers.add_child(_nope)
	var keys := _label("←  →  kiezen   ·   Enter  bevestigen", 13, MUTED)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ask_col.add_child(keys)
	_at(root, _ask, Control.PRESET_CENTER, Vector2.ZERO)
	_ask.visible = false

	for c: Control in root.find_children("*", "Control", true, false):
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE  # clicks go to the game: shouting, capturing the mouse
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _theme() -> Theme:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "Arial"])
	font.font_weight = 600
	var t := Theme.new()
	t.default_font = font
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.6))
	t.set_constant("outline_size", "Label", 4)
	return t


func _panel(color: Color, margin: int) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(14)
	style.set_content_margin_all(margin)
	style.content_margin_left = margin + 8
	style.content_margin_right = margin + 8
	style.border_color = Color(ACCENT, 0.5)
	style.border_width_bottom = 3
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style)
	return p


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _stat(caption: String, value: Label, size: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -4)
	var c := _label(caption, 12, MUTED)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(c)
	value.add_theme_font_size_override("font_size", size)
	value.add_theme_color_override("font_color", Color.WHITE)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.text = "0"
	box.add_child(value)
	return box


func _divider() -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(MUTED, 0.3)
	d.custom_minimum_size = Vector2(2, 0)
	return d


## Adds child to parent, anchored at preset, moved by offset; it grows around the anchor.
func _at(parent: Control, child: Control, preset: Control.LayoutPreset, offset: Vector2) -> void:
	parent.add_child(child)
	child.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE)
	child.grow_horizontal = Control.GROW_DIRECTION_BOTH if preset in [Control.PRESET_CENTER_TOP, Control.PRESET_CENTER_BOTTOM, Control.PRESET_CENTER] else Control.GROW_DIRECTION_BEGIN
	child.grow_vertical = Control.GROW_DIRECTION_BEGIN if preset == Control.PRESET_CENTER_BOTTOM else (Control.GROW_DIRECTION_BOTH if preset == Control.PRESET_CENTER else Control.GROW_DIRECTION_END)
	child.position += offset
