class_name Person
extends CharacterBody3D

## Shared body of the player and the park visitors: model, animations and speech bubble.

const SCALE := 0.55          # Quaternius characters are about 3.2 tall; this makes them about 1.75 m
const WALK_ANIM := 0.8       # ground speed in m/s the Quaternius walk animation was made for (measured from the feet)
const RUN_ANIM := 2.3        # same for the run animation
const MAX_ANIM_SPEED := 3.0  # never play a walk or run faster than this; above it the feet slide instead
# What the game asks for -> animation in the models. The Quaternius pack has no wave
# or angry emote, so a jump says hello and a punch in the air says go away.
# Only the player's gnome has "Shout".
const ANIMS := {"idle": "Idle", "walk": "Walk", "sprint": "Run", "jump": "Jump",
	"sit": "SitDown", "wave": "Jump", "angry": "Punch", "scared": "RecieveHit", "shout": "Shout"}
const LOOPS := ["idle", "walk", "sprint"]

var anims: Dictionary = ANIMS  # a model with other clip names sets its own table before setup()
var loops: Array = LOOPS        # and which of them repeat
var walk_anim := WALK_ANIM  # a model with other step lengths sets its own values before setup()
var run_anim := RUN_ANIM
var model: Node3D
var anim: AnimationPlayer
var bubble := Label3D.new()
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _bubble_left := 0.0


## height: of the person in metres after scaling; sets the collision capsule and the speech bubble.
func setup(model_path: String, model_scale := SCALE, height := 1.7) -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = minf(0.35, height / 3.0)
	capsule.height = height
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = height / 2.0
	add_child(shape)
	model = load(model_path).instantiate()  # looks along +Z
	model.scale = Vector3.ONE * model_scale
	add_child(model)
	anim = model.find_child("AnimationPlayer", true, false)
	for n: String in loops:
		anim.get_animation(anims[n]).loop_mode = Animation.LOOP_LINEAR
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = true
	bubble.fixed_size = true
	bubble.pixel_size = 0.0012
	bubble.outline_size = 12
	bubble.position.y = height * 1.4
	bubble.visible = false
	add_child(bubble)


## One-shot animations (sit, jump) hold their last pose; restart plays one again from the start.
## blend 0 jumps straight to the first frame (for clips that start exactly where the last one ended).
func play(what: String, speed := 1.0, restart := false, blend := 0.2) -> void:
	var anim_name: String = anims[what]
	if restart:
		anim.stop(true)
	if restart or anim.assigned_animation != anim_name:
		anim.play(anim_name, blend)
	anim.speed_scale = speed


func play_move(speed: float) -> void:
	if speed < 3.0:
		play("walk", minf(speed / walk_anim, MAX_ANIM_SPEED))
	else:
		play("sprint", minf(speed / run_anim, MAX_ANIM_SPEED))


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
