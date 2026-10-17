## Particle presets: steam, smoke, bubbles, snow, sparkles, bursts and poofs.
class_name Fx
extends RefCounted

static var _soft_tex: Texture2D
static var _star_tex: Texture2D

static func soft_texture() -> Texture2D:
	if _soft_tex: return _soft_tex
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a * (3.0 - 2.0 * a)))
	_soft_tex = ImageTexture.create_from_image(img)
	return _soft_tex

static func star_texture() -> Texture2D:
	if _star_tex: return _star_tex
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' width='64' height='64' viewBox='-32 -32 64 64'><path d='M0,-28 L7,-7 L28,0 L7,7 L0,28 L-7,7 L-28,0 L-7,-7 Z' fill='white' stroke='#3B2340' stroke-opacity='0.35' stroke-width='3' stroke-linejoin='round'/></svg>"
	var img := Image.new()
	img.load_svg_from_string(svg, 1.0)
	_star_tex = ImageTexture.create_from_image(img)
	return _star_tex

static var _pshader: Shader

static func _billboard_mat(tex: Texture2D, additive := false) -> ShaderMaterial:
	if _pshader == null: _pshader = load("res://shaders/particle.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _pshader
	m.set_shader_parameter("tex", tex)
	m.set_shader_parameter("additive_glow", additive)
	return m

static func _quad(size: float, tex: Texture2D, additive := false) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = _billboard_mat(tex, additive)
	return q

static func steam(spread := 0.12, smoke := false) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.amount = 18
	p.lifetime = 2.0
	p.mesh = _quad(0.12, soft_texture())
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = spread * 0.5
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0, 0.02, 0)
	p.initial_velocity_min = 0.08
	p.initial_velocity_max = 0.16
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var c := Curve.new()
	c.add_point(Vector2(0, 0.4)); c.add_point(Vector2(1, 1.6))
	p.scale_amount_curve = c
	var g := Gradient.new()
	var base := Color(0.44, 0.38, 0.44) if smoke else Color(1, 1, 1)
	g.set_color(0, Color(base, 0.0))
	g.set_color(1, Color(base, 0.0))
	g.add_point(0.25, Color(base, 0.55 if smoke else 0.4))
	p.color_ramp = g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p

static func bubbles() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.amount = 24
	p.lifetime = 0.6
	var s := SphereMesh.new()
	s.radius = 0.006; s.height = 0.012; s.radial_segments = 8; s.rings = 4
	s.material = Toon.solid(Color(1, 1, 1), 0.6)
	p.mesh = s
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.09
	p.direction = Vector3.UP
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.01
	var c := Curve.new()
	c.add_point(Vector2(0, 0.2)); c.add_point(Vector2(0.7, 1.0)); c.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = c
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	return p

static func snow() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.amount = 30
	p.lifetime = 2.4
	p.mesh = _quad(0.03, star_texture())
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.2, 0.3, 0.2)
	p.gravity = Vector3(0, -0.05, 0)
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.02
	p.angular_velocity_min = -90
	p.angular_velocity_max = 90
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0)); g.set_color(1, Color(1, 1, 1, 0)); g.add_point(0.3, Color(0.85, 0.95, 1, 1))
	p.color_ramp = g
	return p

static func sparkles() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.amount = 12
	p.lifetime = 1.2
	p.mesh = _quad(0.035, star_texture())
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 0.2
	p.emission_ring_inner_radius = 0.12
	p.emission_ring_height = 0.05
	p.gravity = Vector3(0, 0.05, 0)
	p.initial_velocity_min = 0.02
	p.initial_velocity_max = 0.06
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.95, 0.6, 0)); g.set_color(1, Color(1, 1, 1, 0)); g.add_point(0.3, Color(1, 0.92, 0.5, 1))
	p.color_ramp = g
	return p

## One-shot burst of stars at a world position.
static func burst(parent: Node, pos: Vector3, cols: Array, n := 10, s := 1.0) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = n
	p.lifetime = 0.8
	p.mesh = _quad(0.035 * s, star_texture())
	p.direction = Vector3.UP
	p.spread = 80.0
	p.gravity = Vector3(0, -1.6, 0)
	p.initial_velocity_min = 0.4 * s
	p.initial_velocity_max = 0.9 * s
	p.angular_velocity_min = -200
	p.angular_velocity_max = 200
	var g := Gradient.new()
	g.set_color(0, cols[0] if cols.size() else Color.WHITE)
	g.set_color(1, Color(1, 1, 1, 0))
	if cols.size() > 1: g.add_point(0.5, cols[1])
	p.color_ramp = g
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)

static func puff(parent: Node, pos: Vector3) -> void:
	var p := steam(0.15)
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 12
	p.lifetime = 0.9
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.6
	p.spread = 70
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
