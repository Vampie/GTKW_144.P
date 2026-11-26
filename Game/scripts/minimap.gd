class_name Minimap
extends Control

## Map of the middle of the park, north up (as in --top): paths, pond, the player as a triangle pointing where
## the camera looks, and an arrow from the player to every phone booth that has its arrow in the
## park (hunt.gd decides). Hidden by hunt.gd while a friend is being searched for.

const SIZE := 230.0  # width and height of the map in pixels
const RANGE := 110.0  # metres from the middle to the map edge: all booths fit; further out the player sits on the edge
const GROUND := Color(0.3, 0.5, 0.24, 0.85)
const PATH := Color(0.9, 0.82, 0.62)
const WATER := Color(0.3, 0.55, 0.85)

var hunt: Hunt


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	clip_contents = true  # paths further out than RANGE are cut off at the edge
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


## Map position of a point in the park.
func _at(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z) / (2.0 * RANGE) * SIZE + Vector2.ONE * SIZE / 2.0


func _draw() -> void:
	var m := SIZE / (2.0 * RANGE)  # pixels per metre
	draw_rect(Rect2(Vector2.ZERO, Vector2.ONE * SIZE), GROUND)
	var park := hunt.park
	for s in park.segments:
		draw_line(_at(park.points[s.x]), _at(park.points[s.y]), PATH, maxf(s.z * m, 1.5))
	draw_circle(_at(Vector3.ZERO), Park.POND_R * m, Color.GOLD if hunt.giant_shown() else WATER)
	draw_rect(Rect2(Vector2.ZERO, Vector2.ONE * SIZE), Color(1, 1, 1, 0.6), false, 2.0)

	var me := _at(hunt.player.global_position).clamp(Vector2.ONE * 8.0, Vector2.ONE * (SIZE - 8.0))
	for i in hunt.booths.size():
		if not hunt.booth_open(i):
			continue
		var color: Color = Hunt.COLORS[i][1]
		var to := _at(hunt.booths[i])
		draw_circle(to, 6.0, color)
		draw_circle(to, 6.0, Color.WHITE, false, 1.5)
		var d := to - me
		if d.length() > 16.0:  # an arrow from the player to the booth, stopping short of both
			var tip := to - d.normalized() * 9.0
			draw_line(me + d.normalized() * 8.0, tip, color, 2.5)
			draw_colored_polygon(PackedVector2Array([tip, tip - d.normalized().rotated(0.45) * 9.0,
				tip - d.normalized().rotated(-0.45) * 9.0]), color)

	# the player: a triangle pointing where the camera looks (the pivot's -Z)
	var yaw := hunt.player.pivot.rotation.y
	var ahead := Vector2(-sin(yaw), -cos(yaw))
	var tri := PackedVector2Array([me + ahead * 9.0, me + ahead.rotated(2.5) * 7.0, me + ahead.rotated(-2.5) * 7.0])
	draw_colored_polygon(tri, Color.WHITE)
	draw_polyline(tri + PackedVector2Array([tri[0]]), Color.BLACK, 1.5)
