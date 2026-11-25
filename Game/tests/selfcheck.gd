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

	# mood: three shouts make a curious visitor grumpy, calming down brings it back
	var v := Visitor.new()
	v.park = park
	v.model_path = "res://assets/characters/Casual2_Male.gltf"
	root.add_child(v)
	var shouter := Node3D.new()
	root.add_child(shouter)
	v.hear(shouter, 10.0)
	v.hear(shouter, 10.0)
	check(v.type == Visitor.Type.CURIOUS, "na twee keer roepen al chagrijnig")
	v.hear(shouter, 10.0)
	check(v.type == Visitor.Type.GRUMPY and v.bubble.text == "Nu is het genoeg!", "drie keer roepen maakt niet chagrijnig")
	v.react = 0.0
	v.annoyance = 0.5
	v._physics_process(0.016)
	check(v.type == Visitor.Type.CURIOUS, "kalmeert niet")

	print("selfcheck %s: %d padpunten, %d bomen, %d zitplaatsen" %
		["MISLUKT" if failed else "ok", park.points.size(), park.trees.size(), park.seats.size()])
	quit(1 if failed else 0)
	return true


func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
