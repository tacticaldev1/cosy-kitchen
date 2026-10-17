## Lighting presets: the soft "studio" used for thumbnails and contact sheets.
class_name Studio
extends RefCounted

static func environment(bg := Color(1.0, 0.957, 0.925), transparent := false) -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR if transparent else Environment.BG_COLOR
	e.background_color = bg
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.80, 0.70, 0.93)
	e.ambient_light_energy = 0.62
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	e.tonemap_exposure = 1.0
	return e

static func add_lights(parent: Node3D, key_energy := 0.78) -> void:
	var key := DirectionalLight3D.new()
	key.name = "Key"
	key.light_color = Color(1.0, 0.95, 0.88)
	key.light_energy = key_energy
	key.rotation_degrees = Vector3(-52, -38, 0)
	key.shadow_enabled = true
	key.shadow_bias = 0.02
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 4.0
	parent.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "Fill"
	fill.light_color = Color(1.0, 0.8, 0.88)
	fill.light_energy = 0.16
	fill.rotation_degrees = Vector3(-20, 140, 0)
	parent.add_child(fill)
