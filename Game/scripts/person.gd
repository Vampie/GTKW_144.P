class_name Person
extends CharacterBody3D

## Shared body of the player and the park visitors: model, animations and speech bubble.

const SCALE := 2.4           # Kenney mini characters are 0.7 tall; this makes them about 1.7 m
const WALK_ANIM := 2.5       # speed in m/s at which the walk animation plays at normal speed
const RUN_ANIM := 5.5        # same for the sprint animation
const LOOPS := ["idle", "walk", "sprint", "sit", "fall"]

var model: Node3D
var anim: AnimationPlayer
var bubble := Label3D.new()
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _bubble_left := 0.0


func setup(model_path: String) -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	model = load(model_path).instantiate()
	model.scale = Vector3.ONE * SCALE
	add_child(model)
	anim = model.find_child("AnimationPlayer", true, false)
	for n: String in LOOPS:
		anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = true
	bubble.fixed_size = true
	bubble.pixel_size = 0.0012
	bubble.outline_size = 12
	bubble.position.y = 2.4
	bubble.visible = false
	add_child(bubble)


func play(anim_name: String, speed := 1.0) -> void:
	if anim.current_animation != anim_name or not anim.is_playing():
		anim.play(anim_name, 0.2)
	anim.speed_scale = speed


func play_move(speed: float) -> void:
	if speed < 3.0:
		play("walk", speed / WALK_ANIM)
	else:
		play("sprint", speed / RUN_ANIM)


func say(text: String, seconds := 3.0, size := 40) -> void:
	bubble.text = text
	bubble.font_size = size
	bubble.visible = true
	_bubble_left = seconds


## Turns the model smoothly toward dir.
func face(dir: Vector3, delta: float) -> void:
	if Vector2(dir.x, dir.z).length_squared() > 0.0001:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 10.0 * delta)


func fall(delta: float) -> void:
	if is_on_floor():
		velocity.y = minf(velocity.y, 0.0)
	else:
		velocity.y -= gravity * delta


func _process(delta: float) -> void:
	if _bubble_left > 0.0:
		_bubble_left -= delta
		bubble.visible = _bubble_left > 0.0
