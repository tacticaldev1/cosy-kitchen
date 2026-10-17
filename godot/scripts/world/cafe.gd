## The café room: loads the Blender diorama, applies the toon look, lights it, and exposes
## anchor points (marks) and buyable decorations.
class_name Cafe
extends Node3D

const SCENE := "res://assets/models/cafe.glb"

var marks := {}
var decor := {}
var lamps: Array[OmniLight3D] = []
var env: Environment
var sun: DirectionalLight3D
var window_mat: ShaderMaterial
var _time_of_day := 0.0

func _ready() -> void:
	var packed: PackedScene = load(SCENE)
	var room := packed.instantiate()
	add_child(room)
	Toon.apply_to(room, 1.0)
	_collect(room)
	for k in decor:
		decor[k].visible = false
	_build_environment()
	_build_window()

func _collect(n: Node) -> void:
	var nm := String(n.name)
	if nm.begins_with("mark_"):
		marks[nm.substr(5)] = n
	elif nm.begins_with("decor_"):
		decor[nm.substr(6)] = n
	for c in n.get_children():
		_collect(c)

func mark(name: String) -> Vector3:
	return (marks[name] as Node3D).global_position if marks.has(name) else Vector3.ZERO

func set_decor(key: String, on: bool) -> void:
	if decor.has(key):
		decor[key].visible = on

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
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
	env.adjustment_contrast = 1.02
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.name = "Key"
	sun.light_color = Color(1.0, 0.92, 0.82)
	sun.light_energy = 0.85
	sun.rotation_degrees = Vector3(-58, -28, 0)
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 9.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.75, 0.8, 1.0)
	fill.light_energy = 0.12
	fill.rotation_degrees = Vector3(-15, 160, 0)
	add_child(fill)
	for i in 3:
		if not marks.has("lamp_%d" % i):
			continue
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.78, 0.52)
		l.light_energy = 1.4
		l.omni_range = 2.6
		l.omni_attenuation = 1.4
		l.shadow_enabled = false
		add_child(l)
		l.global_position = mark("lamp_%d" % i)
		lamps.append(l)
	# window glow spilling in
	var wl := OmniLight3D.new()
	wl.light_color = Color(0.6, 0.65, 1.0)
	wl.light_energy = 0.6
	wl.omni_range = 3.0
	add_child(wl)
	wl.global_position = mark("window") + Vector3(0, 0, 0.6)

func _build_window() -> void:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2.6, 1.4)
	q.mesh = qm
	window_mat = ShaderMaterial.new()
	window_mat.shader = load("res://shaders/rain_window.gdshader")
	q.material_override = window_mat
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(q)
	q.global_position = mark("window") + Vector3(0, 0, -0.08)

func set_rain(on: bool) -> void:
	if window_mat:
		window_mat.set_shader_parameter("rain", 1.0 if on else 0.0)

## 0 = afternoon, 1 = late evening. Shifts light and the sky outside.
func set_time_of_day(t: float) -> void:
	_time_of_day = clampf(t, 0.0, 1.0)
	if window_mat:
		window_mat.set_shader_parameter("night", _time_of_day)
	if sun:
		sun.light_energy = lerpf(0.9, 0.55, _time_of_day)
		sun.light_color = Color(1.0, 0.94, 0.85).lerp(Color(1.0, 0.75, 0.6), _time_of_day)
	for l in lamps:
		l.light_energy = lerpf(1.1, 2.0, _time_of_day)
	if env:
		env.ambient_light_energy = lerpf(0.6, 0.45, _time_of_day)
