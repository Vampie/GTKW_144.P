extends Node3D

## Builds the game: sun and sky, the park, the player and the visitors.
## Test options after "--" on the command line:
##   --top    view the whole park from above
##   --demo   the player shouts by itself after half a second
##   --bench  turn the camera for 10 seconds, print the frame rate and quit
##   --cam=x,y,z,tx,ty,tz   look from x,y,z at tx,ty,tz

const PEOPLE := 120
const SITTING := 20
const MODELS := ["Casual_Female", "Casual2_Female", "Casual2_Male", "Casual3_Female", "Casual3_Male",
	"Chef_Female", "Chef_Male", "Doctor_Female_Old", "Doctor_Female_Young", "Doctor_Male_Old",
	"Doctor_Male_Young", "OldClassy_Female", "OldClassy_Male", "Suit_Female", "Worker_Female",
	"Worker_Male", "Cowboy_Female", "Cowboy_Male", "Kimono_Female", "Kimono_Male"]
const TYPES := [Visitor.Type.CURIOUS, Visitor.Type.CURIOUS, Visitor.Type.CURIOUS, Visitor.Type.CURIOUS,
	Visitor.Type.SKITTISH, Visitor.Type.SKITTISH, Visitor.Type.SKITTISH,
	Visitor.Type.GRUMPY, Visitor.Type.GRUMPY, Visitor.Type.HEADPHONES, Visitor.Type.HEADPHONES]
const PLAYER_START := Vector3(0, 0, 64)  # on the south path, close to the benches around the pond

var park := Park.new()
var player := Player.new()
var env := Environment.new()
var hud := Label.new()
var args := OS.get_cmdline_user_args()
var clock := 0.0
var frames := 0
var slowest := 0.0


func _ready() -> void:
	_sky()
	add_child(park)
	player.position = PLAYER_START
	add_child(player)
	_people()
	var layer := CanvasLayer.new()
	add_child(layer)
	hud.position = Vector2(12, 8)
	hud.add_theme_constant_override("outline_size", 6)
	hud.add_theme_color_override("font_outline_color", Color.BLACK)
	layer.add_child(hud)
	if "--demo" in args:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # so a moving mouse doesn't turn the camera
	for a in args:
		if a == "--top":
			_look(Vector3(0, 480, 1), Vector3.ZERO)
			env.fog_enabled = false
		elif a.begins_with("--cam="):
			var v := a.trim_prefix("--cam=").split_floats(",")
			_look(Vector3(v[0], v[1], v[2]), Vector3(v[3], v[4], v[5]))
	if "--bench" in args:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _process(delta: float) -> void:
	hud.text = "%d fps     WASD lopen · Shift rennen · Spatie springen · linkermuisknop vasthouden: roepen · Esc: muis los" \
		% Engine.get_frames_per_second()
	clock += delta
	if "--demo" in args:
		if clock - delta < 0.5 and clock >= 0.5:
			player.start_shout()
		if clock - delta < 2.0 and clock >= 2.0:
			player.release_shout()
	if "--bench" in args and clock > 3.0:
		frames += 1
		slowest = maxf(slowest, delta)
		player.pivot.rotation.y += delta * TAU / 10.0
		if clock > 13.0:
			print("gemiddeld %.1f fps, traagste beeld %.1f ms" % [frames / (clock - 3.0), slowest * 1000.0])
			get_tree().quit()


func _look(from: Vector3, at: Vector3) -> void:
	var cam := Camera3D.new()
	cam.far = 1500.0
	add_child(cam)
	cam.look_at_from_position(from, at)
	cam.make_current()


func _sky() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 35.0, 0.0)  # afternoon sun
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.72, 0.8, 0.9)
	env.fog_density = 0.0025
	env.fog_sky_affect = 0.3
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)


func _people() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = Park.SEED
	var benches := range(park.seats.size() / 2)
	for i in range(benches.size() - 1, 0, -1):  # shuffle with the fixed seed
		var j := rng.randi_range(0, i)
		var t: int = benches[i]
		benches[i] = benches[j]
		benches[j] = t
	for n in PEOPLE:
		var v := Visitor.new()
		v.park = park
		v.model_path = "res://assets/characters/%s.gltf" % MODELS[rng.randi() % MODELS.size()]
		v.type = TYPES[rng.randi() % TYPES.size()]
		if n < SITTING:
			v.mode = Visitor.Mode.SIT
			v.home = park.seats[benches[n] * 2 + rng.randi() % 2]
		elif n < SITTING + park.spots.size():
			v.mode = Visitor.Mode.STAND
			v.home = park.spots[n - SITTING]
		v.position = park.points[rng.randi() % park.points.size()] if v.mode == Visitor.Mode.WANDER else v.home.origin
		add_child(v)
