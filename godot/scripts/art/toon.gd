## Material factory and small scene helpers for the toon look.
class_name Toon
extends RefCounted

const PLUM := Color("3B2340")
const SHADER := preload("res://shaders/toon.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")
const GLASS := preload("res://shaders/glass.gdshader")

static var _cache := {}

## The shared vertex-colour material (outline width per vertex from UV2.x).
static func vc(outline_scale := 1.0) -> ShaderMaterial:
	var key := "vc|%.2f" % outline_scale
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("use_vertex_color", true)
	if outline_scale > 0.0:
		var o := ShaderMaterial.new()
		o.shader = OUTLINE
		o.set_shader_parameter("use_uv2_width", true)
		o.set_shader_parameter("width_px", 2.2 * outline_scale)
		m.next_pass = o
	_cache[key] = m
	return m

## A plain coloured toon material for imported or primitive meshes (no UV2 needed).
static func solid(c: Color, outline := 1.0, opts := {}) -> ShaderMaterial:
	var key := "s|%s|%.2f|%s" % [c.to_html(), outline, str(opts)]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("use_vertex_color", false)
	m.set_shader_parameter("albedo", c)
	for k in opts:
		m.set_shader_parameter(k, opts[k])
	if outline > 0.0:
		var o := ShaderMaterial.new()
		o.shader = OUTLINE
		o.set_shader_parameter("use_uv2_width", false)
		o.set_shader_parameter("width_px", 2.2 * outline)
		m.next_pass = o
	_cache[key] = m
	return m

static func glass(tint := Color(0.86, 0.94, 1.0, 0.16)) -> ShaderMaterial:
	var key := "g|" + tint.to_html()
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = GLASS
	m.set_shader_parameter("tint", tint)
	m.render_priority = 1
	_cache[key] = m
	return m

## Turns an MB into a MeshInstance3D using the shared vertex-colour material.
static func inst(mb: MB, outline_scale := 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mb.build()
	mi.material_override = vc(outline_scale)
	return mi

## Swaps every material on an imported scene for toon materials with the same colour.
## Material names containing "glass" become glass; "glow"/"emit" glow; "noline" skips outlines.
static func apply_to(node: Node, outline := 1.0) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var src := mi.get_active_material(s)
				var c := Color.WHITE
				var nm := ""
				if src:
					nm = src.resource_name.to_lower()
					if src is BaseMaterial3D:
						c = (src as BaseMaterial3D).albedo_color
				var m: Material
				if nm.contains("glass"):
					m = glass(Color(c.r, c.g, c.b, 0.18))
				elif nm.contains("glow") or nm.contains("emit"):
					m = solid(c, 0.0, {"emission_amount": 1.6, "emission_color": Color.WHITE})
				else:
					m = solid(c, 0.0 if nm.contains("noline") else outline)
				mi.set_surface_override_material(s, m)
	for ch in node.get_children():
		apply_to(ch, outline)

## Sets an instance shader parameter on every GeometryInstance3D below node.
static func set_param(node: Node, param: StringName, value) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).set_instance_shader_parameter(param, value)
	for ch in node.get_children():
		set_param(ch, param, value)
