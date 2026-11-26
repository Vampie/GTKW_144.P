class_name Touch
extends Control

## On-screen controls for phones and tablets. A floating stick on the left presses W, A, S and D
## (pushed all the way out also Shift, to sprint); round buttons on the right press the other keys,
## so the game reacts exactly as it does to the keyboard. "Roep" shouts as long as it is held, "Sluip"
## switches sneaking on and off. Dragging anywhere else turns the camera (player.gd), pinching with
## two fingers zooms. main.gd adds it on phones, or on the desktop with --touch (to look at it).

const STICK := 90.0  # stick radius at a screen height of 720 px; everything scales with the height
const DEAD := 0.3    # part of the radius before the stick presses a key
const RUN_AT := 0.9  # from this part of the radius it also sprints
# label, keys, centre from the bottom-right corner and radius (at 720 px). No keys: the shout.
const BUTTONS := [
	["Roep", [], Vector2(-110, -110), 62.0],
	["Spring", [KEY_SPACE], Vector2(-250, -80), 44.0],
	["Stomp", [KEY_F], Vector2(-235, -210), 40.0],
	["Trap", [KEY_G], Vector2(-110, -255), 40.0],
	["E", [KEY_E], Vector2(-375, -80), 40.0],
	["Sluip", [KEY_CTRL], Vector2(-60, -365), 34.0],
]

var player: Player


## Whether the game shows these controls: on phones, or on the desktop with --touch.
static func wanted() -> bool:
	return OS.has_feature("mobile") or "--touch" in OS.get_cmdline_user_args()

var _stick_finger := -1
var _stick_from := Vector2.ZERO
var _stick_at := Vector2.ZERO
var _held := {}    # finger -> index in BUTTONS
var _looks := {}   # finger -> position, for fingers that turn the camera or pinch
var _sneak := false


func _init() -> void:  # anchors before entering the tree, as in hunt.gd; later they are not applied
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var i: int = event.index
		if event.pressed:
			var b := _button_at(event.position)
			if b >= 0:
				_held[i] = b
				_press(b, true)
			elif event.position.x < size.x * 0.4 and _stick_finger < 0:
				_stick_finger = i
				_stick_from = event.position
				_stick_at = event.position
			else:
				_looks[i] = event.position
				return
		elif _held.has(i):
			_press(_held[i], false)
			_held.erase(i)
		elif i == _stick_finger:
			_stick_finger = -1
			_steer(Vector2.ZERO)
		else:
			_looks.erase(i)
			return
	elif event is InputEventScreenDrag:
		var i: int = event.index
		if i == _stick_finger:
			_stick_at = event.position
			_steer((_stick_at - _stick_from) / (STICK * _unit()))
		elif _looks.has(i) and _looks.size() >= 2:  # pinch: the two fingers apart is closer
			var other: Vector2 = _looks[_looks.keys().filter(func(f: int) -> bool: return f != i)[0]]
			var before := other.distance_to(_looks[i])
			_looks[i] = event.position
			player.zoom(before / maxf(other.distance_to(event.position), 1.0))
		elif _looks.has(i):
			_looks[i] = event.position
			return  # one finger: the player turns the camera
	else:
		return
	get_viewport().set_input_as_handled()
	queue_redraw()


func _unit() -> float:
	return size.y / 720.0


func _centre(b: int) -> Vector2:
	return size + BUTTONS[b][2] * _unit()


func _button_at(p: Vector2) -> int:
	for b in BUTTONS.size():
		if p.distance_to(_centre(b)) < BUTTONS[b][3] * _unit() * 1.15:  # a bit bigger than drawn
			return b
	return -1


func _press(b: int, down: bool) -> void:
	var keys: Array = BUTTONS[b][1]
	if keys.is_empty():
		if down:
			player.start_shout()
		else:
			player.release_shout()
	elif keys[0] == KEY_CTRL:
		if down:
			_sneak = not _sneak
			_key(KEY_CTRL, _sneak)
	else:
		for k: Key in keys:
			_key(k, down)


func _steer(v: Vector2) -> void:
	_key(KEY_A, v.x < -DEAD)
	_key(KEY_D, v.x > DEAD)
	_key(KEY_W, v.y < -DEAD)
	_key(KEY_S, v.y > DEAD)
	_key(KEY_SHIFT, v.length() > RUN_AT)


## Presses or lets go of a key as if on a keyboard, also for Input.is_physical_key_pressed.
func _key(key: Key, down: bool) -> void:
	if Input.is_physical_key_pressed(key) == down:
		return
	var e := InputEventKey.new()
	e.physical_keycode = key
	e.keycode = key
	e.pressed = down
	Input.parse_input_event(e)


func _draw() -> void:
	if size.y <= 0.0:  # not laid out yet; resizing draws again
		return
	var u := _unit()
	var from := _stick_from if _stick_finger >= 0 else Vector2(170.0 * u, size.y - 170.0 * u)
	var knob := from + ((_stick_at - from).limit_length(STICK * u) if _stick_finger >= 0 else Vector2.ZERO)
	draw_circle(from, STICK * u, Color(1, 1, 1, 0.15))
	draw_circle(knob, STICK * u * 0.45, Color(1, 1, 1, 0.4))
	var font := ThemeDB.fallback_font
	var fs := int(20.0 * u)
	for b in BUTTONS.size():
		var on: bool = b in _held.values() or (BUTTONS[b][0] == "Sluip" and _sneak)
		draw_circle(_centre(b), BUTTONS[b][3] * u, Color(1, 1, 1, 0.45 if on else 0.2))
		var w := font.get_string_size(BUTTONS[b][0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, _centre(b) + Vector2(-w / 2.0, fs * 0.35), BUTTONS[b][0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
