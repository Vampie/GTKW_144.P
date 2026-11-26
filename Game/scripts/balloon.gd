class_name ComicBalloon
extends Control

## A speech balloon on the screen as in a hand-drawn comic strip: white, a thick slightly wobbly
## black outline, black capitals and a pointed tail down to the speaker's head. It hangs above and
## to the right of the speaker and follows him while it is shown. "\n" in the text starts a new line.

const FONT_SIZE := 34
const PAD := Vector2(30, 22)   # room between the text and the outline
const LIFT := 70.0             # how far the balloon hangs above the head
const GAP := 18.0              # the tail stops this far from the head

var speaker: Node3D
var head := 1.3                # height of the speaker's head above his position
var _text := ""
var _left := 0.0
var _font := SystemFont.new()


func _init() -> void:
	set_anchors_preset(PRESET_FULL_RECT)  # before entering the tree, see touch.gd
	mouse_filter = MOUSE_FILTER_IGNORE
	_font.font_names = PackedStringArray(["Comic Sans MS", "Comic Neue", "Chalkboard SE", "Arial"])
	_font.font_weight = 700
	visible = false


func show_text(text: String, seconds: float) -> void:
	_text = text
	_left = seconds
	visible = true


func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	visible = _left > 0.0
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	var at := speaker.global_position + Vector3.UP * head
	if cam == null or cam.is_position_behind(at):
		return
	var mouth := cam.unproject_position(at)
	var text_size := _font.get_multiline_string_size(_text, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE)
	var r := text_size * 0.7 + PAD  # radii of the ellipse; 0.7 instead of 0.5 so the corners of the text fit
	var c := (mouth + Vector2(r.x * 0.5, -r.y - LIFT)).clamp(r + Vector2.ONE * 8.0, size - r - Vector2.ONE * 8.0)
	var tip := mouth + (c - mouth).normalized() * GAP
	var toward := (tip - c).angle()

	# the outline: an ellipse with a little wobble, and where it faces the head, the tail
	var outline := PackedVector2Array()
	var tail_in := false
	for k in 90:
		var t := TAU * k / 90.0
		if absf(wrapf(t - toward, -PI, PI)) < 0.2:
			if not tail_in:
				outline.append(tip)
				tail_in = true
			continue
		var wobble := 1.0 + 0.025 * sin(t * 5.0 + 1.3) + 0.012 * sin(t * 13.0)
		outline.append(c + Vector2(cos(t) * r.x, sin(t) * r.y) * wobble)
	draw_colored_polygon(outline, Color.WHITE)
	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, Color.BLACK, 5.0, true)
	for i in closed.size():  # a second thinner stroke, a bit off: drawn by hand
		closed[i] += Vector2(1.5, -1.0)
	draw_polyline(closed, Color.BLACK, 2.0, true)

	var first_line := c + Vector2(-text_size.x / 2.0, -text_size.y / 2.0 + _font.get_ascent(FONT_SIZE))
	draw_multiline_string(_font, first_line, _text, HORIZONTAL_ALIGNMENT_CENTER, text_size.x, FONT_SIZE, -1, Color.BLACK)
