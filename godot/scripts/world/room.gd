## A Blender-built room or street (GLB): applies the toon look, collects mark_* anchors and
## obs_* obstacles, and can recolour walls and floors for themes.
class_name Room
extends Node3D

var marks := {}
var obstacles: Array = []        # [Rect2 centred rects in x/z]
var _wall_surfs: Array = []      # [[MeshInstance3D, surface]]
var _floor_surfs: Array = []     # [[MeshInstance3D, surface, plank index]]

func load_glb(path: String) -> void:
	var packed: PackedScene = load(path)
	var scene := packed.instantiate()
	add_child(scene)
	_index(scene)
	Toon.apply_to(scene, 1.0)

func _index(n: Node) -> void:
	var nm := String(n.name)
	if nm.begins_with("mark_"):
		marks[nm.substr(5)] = n
	elif nm.begins_with("obs_"):
		# obs_<i>_<w>_<d>; Godot's importer turns the "." in "3.48" into "_", so accept both
		var p := nm.split("_")
		if p.size() >= 4:
			var w := float(p[2]) if p.size() < 6 else float(p[2] + "." + p[3])
			var d := float(p[3]) if p.size() < 6 else float(p[4] + "." + p[5])
			var pos: Vector3 = (n as Node3D).position
			obstacles.append([pos, w, d])
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var m := mi.mesh.surface_get_material(s)
				if m == null: continue
				var mn := m.resource_name.to_lower()
				if mn.begins_with("wall") or mn.begins_with("panel"):
					_wall_surfs.append([mi, s, 1 if mn.begins_with("panel") else 0])
				elif mn.begins_with("floor_d") or mn.begins_with("hfloor"):
					var parts := mn.split("_")
					var k := 0
					for x in parts:
						if x.is_valid_int(): k = int(x)
					_floor_surfs.append([mi, s, k])
	for c in n.get_children():
		_index(c)

## Obstacle positions are in GLB space; this returns them in world space once placed.
func world_obstacles() -> Array:
	var out: Array = []
	for o in obstacles:
		var p: Vector3 = global_transform * (o[0] as Vector3)
		out.append([p, o[1], o[2]])
	return out

func mark(name: String) -> Vector3:
	return (marks[name] as Node3D).global_position if marks.has(name) else Vector3.ZERO

func has_mark(name: String) -> bool:
	return marks.has(name)

func set_wall(hex: String) -> void:
	var c := Color(hex)
	for e in _wall_surfs:
		var col := c if e[2] == 0 else c.darkened(0.12).lerp(Color("F2B9A8"), 0.25)
		(e[0] as MeshInstance3D).set_surface_override_material(e[1], Toon.solid(col, 0.0 if e[2] == 0 else 1.0))

func set_floor(colors: Array) -> void:
	for e in _floor_surfs:
		(e[0] as MeshInstance3D).set_surface_override_material(e[1], Toon.solid(Color(colors[int(e[2]) % colors.size()]), 0.0))

# ---------------------------------------------------------------- lighting helpers
static func interior_environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("2A2440")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.72, 0.92)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.tonemap_white = 4.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.ssao_enabled = true
	env.ssao_radius = 0.6
	env.ssao_intensity = 1.2
	env.ssao_light_affect = 0.15
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	return env

static func key_light(rot := Vector3(-58, -28, 0)) -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.name = "Key"
	sun.light_color = Color(1.0, 0.92, 0.82)
	sun.light_energy = 0.85
	sun.rotation_degrees = rot
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 14.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	return sun

static func rain_window(size := Vector2(3.0, 1.2)) -> MeshInstance3D:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	q.mesh = qm
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/rain_window.gdshader")
	q.material_override = m
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return q
