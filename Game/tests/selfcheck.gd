extends SceneTree

## Quick checks of the park generator.
## Run: Godot_console --headless --path . -s res://tests/selfcheck.gd

var failed := false
var park := Park.new()


func _initialize() -> void:
	root.add_child(park)  # its _ready builds the park before the first frame


func _process(_delta: float) -> bool:
	var seen := {0: true}
	var todo := [0]
	while not todo.is_empty():
		for j in park.links[todo.pop_back()]:
			if not seen.has(j):
				seen[j] = true
				todo.append(j)
	check(seen.size() == park.points.size(), "niet alle paden hangen aan elkaar")

	for t in park.trees:
		check(park.path_clearance(t) >= 3.0, "boom te dicht bij een pad: %s" % t)
		check(t.length() > Park.POND_R + 5.0, "boom in de vijver: %s" % t)
	check(park.trees.size() > 200, "te weinig bomen: %d" % park.trees.size())
	check(park.seats.size() >= 16, "te weinig zitplaatsen: %d" % park.seats.size())
	check(park.spots.size() == 9, "groepjes niet gevonden: %d plekken" % park.spots.size())

	print("selfcheck %s: %d padpunten, %d bomen, %d zitplaatsen" %
		["MISLUKT" if failed else "ok", park.points.size(), park.trees.size(), park.seats.size()])
	quit(1 if failed else 0)
	return true


func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
