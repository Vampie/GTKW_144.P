class_name Streamers
extends Control

## Carnival streamers that fall over the whole screen, in front of the world (hunt.gd shows them
## when the last friend is put on his pedestal). Each streamer is a wavy ribbon that twists while it
## falls: the line gets thin where the ribbon is seen edge-on. Gone once all are below the screen.

const COUNT := 70
const COLORS := [Color(0.95, 0.2, 0.25), Color(1.0, 0.8, 0.1), Color(0.2, 0.6, 1.0),
	Color(0.25, 0.8, 0.35), Color(0.75, 0.35, 0.95), Color(1.0, 0.5, 0.75), Color(1.0, 0.55, 0.1)]
const PIECES := 14  # line pieces per streamer
const PIECE := 9.0  # length of one piece in pixels

var _ribbons: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func start() -> void:
	_rng.randomize()
	_ribbons.clear()
	for n in COUNT:
		_ribbons.append({
			"x": _rng.randf() * size.x,
			"y": -_rng.randf_range(PIECES * PIECE, size.y * 1.2),  # staggered: they keep coming for a while
			"fall": _rng.randf_range(160.0, 260.0),
			"sway": _rng.randf_range(10.0, 26.0),
			"phase": _rng.randf() * TAU,
			"color": COLORS[n % COLORS.size()],
		})
	set_process(true)


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	var gone := true
	for r in _ribbons:
		r.y += r.fall * delta
		r.phase += 3.0 * delta
		gone = gone and r.y > size.y
	if gone:
		_ribbons.clear()
		set_process(false)
	queue_redraw()


func _draw() -> void:
	for r in _ribbons:
		var last := Vector2.ZERO
		for k in PIECES + 1:
			var p := Vector2(r.x + sin(r.phase + k * 0.7) * r.sway, r.y - k * PIECE)
			if k > 0:
				draw_line(last, p, r.color, 1.5 + 5.0 * absf(cos(r.phase * 1.3 + k * 0.5)))
			last = p
