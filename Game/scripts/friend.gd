class_name Friend
extends Person

## The gnome friend the player looks for: the player's gnome with a blue hat.
## Stands still and answers every shout that reaches him.

const HEARING := 3.0  # he hears you 3x as far as visitors do: a full shout reaches 135 m


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	setup(Player.MODEL, 1.0, 1.0)
	add_to_group("npc")
	for hat: MeshInstance3D in model.find_children("Hat", "MeshInstance3D", true, false):
		var blue := (hat.mesh.surface_get_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
		blue.albedo_color = Color(0.2, 0.42, 0.95)
		hat.set_surface_override_material(0, blue)
	play("idle")


## Called for everyone when the player shouts.
func hear(from: Node3D, radius: float) -> void:
	if global_position.distance_to(from.global_position) <= radius * HEARING:
		say("Hier!", 3.0, 80)
