class_name Hunt
extends Node

## "Zoek je vriend": hides the gnome friend, keeps the time and shows the HUD.
## A round ends when the player comes within FOUND_DISTANCE; Enter starts the next one.
## Test option "--found" puts the friend right next to the player.

const MIN_DISTANCE := 80.0   # the friend hides at least this far from the player
const FOUND_DISTANCE := 2.0
const ACCENT := Color(0.36, 0.62, 1.0)  # the friend's blue hat
const PANEL := Color(0.07, 0.09, 0.13, 0.78)
const MUTED := Color(0.7, 0.75, 0.82)

var park: Park
var player: Player
var friend := Friend.new()
var time := 0.0
var found := false
var rng := RandomNumberGenerator.new()  # not seeded: a new hiding place every round

var _time_value := Label.new()
var _shout_value := Label.new()
var _fps := Label.new()
var _end := Control.new()
var _end_time := Label.new()
var _end_shouts := Label.new()
var _end_annoyed := Label.new()


func _ready() -> void:
	rng.randomize()
	add_child(friend)
	_build_hud()
	new_round()
	if "--found" in OS.get_cmdline_user_args():
		friend.global_position = player.global_position + Vector3(1.0, 0.0, -1.0)


func new_round() -> void:
	friend.global_position = _hiding_place()
	friend.model.rotation.y = rng.randf() * TAU
	time = 0.0
	found = false
	player.shouts = 0
	Visitor.fed_up_total = 0
	_end.visible = false


func _process(delta: float) -> void:
	_fps.text = "%d fps" % Engine.get_frames_per_second()
	if found:
		if Input.is_physical_key_pressed(KEY_ENTER) or Input.is_physical_key_pressed(KEY_KP_ENTER):
			new_round()
		return
	time += delta
	_time_value.text = _clock(time)
	_shout_value.text = str(player.shouts)
	if player.global_position.distance_to(friend.global_position) < FOUND_DISTANCE:
		found = true
		_end_time.text = _clock(time)
		_end_shouts.text = str(player.shouts)
		_end_annoyed.text = str(Visitor.fed_up_total)
		_end.visible = true


## Near a tree, off the paths, at least MIN_DISTANCE from the player.
func _hiding_place() -> Vector3:
	var me := Vector3(player.global_position.x, 0.0, player.global_position.z)
	for i in 1000:
		var p := park.trees[rng.randi() % park.trees.size()] + Vector3(rng.randf_range(-3.0, 3.0), 0.0, rng.randf_range(-3.0, 3.0))
		if p.distance_to(me) >= MIN_DISTANCE and park.path_clearance(p) > 2.0 and not park._near(park.trees, p, 1.2):
			return p
	return Vector3(200.0, 0.0, 200.0)  # never reached with ~280 trees


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
	var top := _panel(PANEL, 16)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	top.add_child(row)
	var title := VBoxContainer.new()
	title.add_theme_constant_override("separation", 0)
	title.add_child(_label("ZOEK JE VRIEND", 13, ACCENT))
	title.add_child(_label("Kabouter met de blauwe muts", 22, Color.WHITE))
	row.add_child(title)
	row.add_child(_divider())
	row.add_child(_stat("TIJD", _time_value, 30))
	row.add_child(_stat("GEROEPEN", _shout_value, 30))
	_at(root, top, Control.PRESET_CENTER_TOP, Vector2(0, 18))

	# bottom: controls
	var hint := _panel(Color(PANEL, 0.55), 10)
	hint.add_child(_label("WASD lopen  ·  Shift rennen  ·  Spatie springen  ·  Linkermuisknop vasthouden: roepen  ·  Esc: muis los", 14, MUTED))
	_at(root, hint, Control.PRESET_CENTER_BOTTOM, Vector2(0, -16))

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
	var head := _label("Gevonden!", 56, ACCENT)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 40)
	stats.add_child(_stat("TIJD", _end_time, 36))
	stats.add_child(_stat("GEROEPEN", _end_shouts, 36))
	stats.add_child(_stat("CHAGRIJNIG GEMAAKT", _end_annoyed, 36))
	col.add_child(stats)
	var again := _label("Druk op Enter voor een nieuwe ronde", 16, MUTED)
	again.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(again)
	_at(_end, card, Control.PRESET_CENTER, Vector2.ZERO)

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
