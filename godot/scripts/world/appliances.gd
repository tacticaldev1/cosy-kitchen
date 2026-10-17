## Cute kitchen appliances built from the mesh toolkit. Each builder returns a Node3D
## whose origin sits on the surface the appliance stands on (counter top or floor), facing +z.
## Moving parts are named children (Knife, Whisk, Jug, Dial, Turntable...).
class_name Appl
extends RefCounted

const PLUM := Color("3B2340")

static func _mi(mb: MB, name := "Body") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = FoodArt.finish(mb)
	return mi

static func _face(parent: Node3D, pos: Vector3, s: float, rot := Vector3.ZERO) -> Face:
	var f := Face.new(s)
	f.name = "Face"
	f.position = pos
	f.rotation = rot
	parent.add_child(f)
	return f

## A plain toon material that can be recoloured (water, batter, liquids).
static func tint_mat(c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = Toon.SHADER
	m.set_shader_parameter("use_vertex_color", false)
	m.set_shader_parameter("albedo", c)
	m.set_shader_parameter("base_gloss", 0.6)
	var o := ShaderMaterial.new()
	o.shader = Toon.OUTLINE
	o.set_shader_parameter("use_uv2_width", false)
	o.set_shader_parameter("width_px", 1.4)
	m.next_pass = o
	return m

static func label3d(text: String, size := 48, col := Color("8FF0C8")) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
	l.font_size = size
	l.pixel_size = 0.0006
	l.modulate = col
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	return l

# ---------------------------------------------------------------- board
static func board() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	mb.col(Color("D29A62")); mb.at(Vector3(0, 0.013, 0)); mb.rbox(Vector3(0.44, 0.026, 0.3), 0.012, 3); mb.pop()
	mb.col(Color("F8DDB2"), 0.0, 0.1); mb.at(Vector3(0, 0.0262, 0)); mb.rbox(Vector3(0.42, 0.002, 0.28), 0.001, 1); mb.pop()
	mb.col(Color("E2B47E"), 0.0)
	for i in 9:
		var z := -0.12 + i * 0.03
		var pts := PackedVector3Array()
		for k in 7: pts.append(Vector3(-0.19 + k * 0.063, 0.0275, z + sin(k * 1.1 + i) * 0.004))
		mb.tube(MB.spline3(pts, 3), 0.0008, 4, Callable(), 0.4, Vector3.UP)
	mb.col(Color("A8703E"), 0.6); mb.at(Vector3(0.18, 0.0275, -0.11)); mb.torus(0.012, 0.004, 16, 6); mb.pop()
	n.add_child(_mi(mb))
	var knife := Node3D.new()
	knife.name = "Knife"
	var kb := MB.new()
	kb.col(Color("E9EEF8"), 1.0, 1.0)
	var blade := PackedVector2Array([Vector2(0, 0), Vector2(0.17, 0), Vector2(0.15, 0.03), Vector2(0.0, 0.045)])
	kb.push(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), Vector3(0, 0.0, 0.002))); kb.extrude(blade, 0.004, 0.0015); kb.pop()
	kb.col(Color("FF9EBB"), 1.0, 0.3); kb.at(Vector3(-0.055, 0.022, 0)); kb.rbox(Vector3(0.11, 0.028, 0.02), 0.009, 2); kb.pop()
	kb.col(PLUM, 0.0)
	for x in [-0.08, -0.03]:
		kb.at(Vector3(x, 0.022, 0.0105)); kb.sphere(0.003, 6, 4); kb.pop()
	var km := _mi(kb, "KnifeMesh")
	km.rotation = Vector3(0, 0, -PI * 0.5)
	knife.add_child(km)
	n.add_child(knife)
	return n

# ---------------------------------------------------------------- mixing bowl
static func bowl() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	var r := 0.17
	var h := 0.12
	var prof := MB.spline(PackedVector2Array([Vector2(0, 0.002), Vector2(r * 0.4, 0.0), Vector2(r * 0.45, 0.01), Vector2(r * 0.8, h * 0.4), Vector2(r * 0.98, h * 0.85), Vector2(r, h), Vector2(r * 0.97, h + 0.006), Vector2(r * 0.93, h), Vector2(r * 0.76, h * 0.42), Vector2(r * 0.4, 0.016), Vector2(0, 0.014)]), 4)
	mb.col(Color("A9C8FF"), 1.0, 0.5)
	mb.lathe(prof, 48, Callable(), func(_u: float, v: float, p: Vector3) -> Color:
		if v > 0.55: return Color("E8F0FF")
		return Color("A9C8FF") if absf(p.y - h * 0.62) > 0.005 else Color("FFFFFF"), 40)
	n.add_child(_mi(mb))
	_face(n, Vector3(0, h * 0.38, r * 0.86), 2.8, Vector3(-0.35, 0, 0))
	var c := Node3D.new(); c.name = "Contents"; n.add_child(c)
	var whisk := Node3D.new(); whisk.name = "Whisk"
	var wb := MB.new()
	wb.col(Color("FF9EBB"), 1.0, 0.3); wb.at(Vector3(0, 0.13, 0)); wb.rbox(Vector3(0.024, 0.11, 0.024), 0.011, 2); wb.pop()
	wb.col(Color("B8BED8"), 0.7, 0.9)
	for i in 4:
		wb.at(Vector3.ZERO, Vector3(0, i * PI / 4.0, 0))
		var pts := PackedVector3Array()
		for k in 25:
			var a := TAU * k / 24.0
			pts.append(Vector3(0.03 * sin(a) * (0.62 + 0.38 * cos(a)), 0.042 - cos(a) * 0.042, 0))
		wb.tube(pts, 0.0018, 5)
		wb.pop()
	var wm := _mi(wb, "WhiskMesh")
	wm.position = Vector3(0, 0.05, 0)
	whisk.add_child(wm)
	n.add_child(whisk)
	return n

# ---------------------------------------------------------------- blender
static func blender() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	mb.col(Color("C8B6FF")); mb.at(Vector3(0, 0.06, 0)); mb.rbox(Vector3(0.2, 0.12, 0.18), 0.03, 3); mb.pop()
	mb.col(Color("FF9EBB"), 1.0, 0.4); mb.at(Vector3(0.055, 0.055, 0.09), Vector3(PI * 0.5, 0, 0)); mb.puck(0.018, 0.012, 0.005, 18); mb.pop()
	mb.col(Color("9A88E0")); mb.at(Vector3(0, 0.125, 0)); mb.puck(0.075, 0.016, 0.005, 28); mb.pop()
	n.add_child(_mi(mb))
	_face(n, Vector3(-0.03, 0.062, 0.0905), 2.2)
	var jug := Node3D.new(); jug.name = "Jug"; jug.position = Vector3(0, 0.14, 0)
	var jb := MB.new()
	jb.layer(1)
	jb.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.06, 0), Vector2(0.085, 0.24), Vector2(0.08, 0.24), Vector2(0.056, 0.006), Vector2(0, 0.006)]), 36, Callable(), Callable(), 10)
	jb.layer(0)
	jb.col(Color("EAF4FF"), 0.7, 0.6); jb.at(Vector3(0, 0.239, 0)); jb.torus(0.0825, 0.003, 36, 6); jb.pop()
	jb.col(Color("C8B6FF"), 1.0, 0.3)
	var hp := PackedVector3Array()
	for i in 11:
		var a := -PI * 0.5 + PI * i / 10.0
		hp.append(Vector3(0.082 + cos(a) * 0.045, 0.13 - sin(a) * 0.08, 0))
	jb.tube(hp, 0.011, 10)
	jb.col(Color("FF9EBB")); jb.at(Vector3(0, 0.24, 0)); jb.puck(0.09, 0.025, 0.008, 32); jb.pop()
	jb.col(Color("FF7EA6")); jb.at(Vector3(0, 0.262, 0)); jb.puck(0.025, 0.02, 0.006, 16); jb.pop()
	jug.add_child(_mi(jb, "JugMesh"))
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var bb := MB.new()
	bb.col(Color("9AA0B8"), 0.6, 0.8)
	for i in 2:
		bb.at(Vector3(0, 0.014, 0), Vector3(0.25 * (1 if i else -1), i * PI * 0.5, 0)); bb.rbox(Vector3(0.09, 0.003, 0.014), 0.0015, 1); bb.pop()
	blade.mesh = FoodArt.finish(bb)
	jug.add_child(blade)
	var c := Node3D.new(); c.name = "Contents"; jug.add_child(c)
	n.add_child(jug)
	return n

# ---------------------------------------------------------------- bamboo mat
static func mat() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	for i in 26:
		var z := -0.16 + i * 0.0125
		mb.col(Color("DDB874") if i % 2 else Color("D3AB63"), 0.5, 0.1)
		mb.at(Vector3(0, 0.0055, z)); mb.rbox(Vector3(0.34, 0.009, 0.0118), 0.0045, 1); mb.pop()
	mb.col(Color("8E6A35"), 0.0)
	for x in [-0.12, 0.12]:
		mb.tube(PackedVector3Array([Vector3(x, 0.0105, -0.165), Vector3(x, 0.0105, 0.165)]), 0.0012, 4)
	var m := _mi(mb)
	m.name = "Mat"
	n.add_child(m)
	var c := Node3D.new(); c.name = "Contents"; n.add_child(c)
	return n

# ---------------------------------------------------------------- stove top (shared by pot & pan)
static func stove(width := 1.04) -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	mb.col(Color("4B4560")); mb.at(Vector3(0, 0.012, 0)); mb.rbox(Vector3(width, 0.024, 0.5), 0.012, 2); mb.pop()
	mb.col(Color("2B273E"), 0.0, 0.5); mb.at(Vector3(0, 0.0245, -0.01)); mb.rbox(Vector3(width - 0.04, 0.001, 0.44), 0.005, 1); mb.pop()
	for x in [-0.25, 0.25]:
		mb.col(Color("3A3550"), 0.6); mb.at(Vector3(x, 0.026, -0.02)); mb.torus(0.12, 0.006, 32, 6); mb.pop()
		mb.col(Color("3A3550"), 0.6); mb.at(Vector3(x, 0.026, -0.02)); mb.torus(0.075, 0.005, 28, 6); mb.pop()
	for i in 4:
		var x := -0.36 + i * 0.24
		mb.col(Color("FFFFFF"), 1.0, 0.5); mb.at(Vector3(x, 0.03, 0.22), Vector3(PI * 0.5, 0, 0)); mb.puck(0.022, 0.016, 0.006, 20); mb.pop()
		mb.col(Color("FF7EA6"), 0.0); mb.at(Vector3(x, 0.042, 0.236)); mb.rbox(Vector3(0.004, 0.014, 0.004), 0.001, 1); mb.pop()
		mb.col(Color("FF6A6A") if i == 1 else Color("8FF0C8"), 0.0); mb.at(Vector3(x + 0.034, 0.0255, 0.215)); mb.sphere(0.004, 6, 4); mb.pop()
	n.add_child(_mi(mb))
	return n

static func flames(r := 0.12) -> Node3D:
	var n := Node3D.new()
	n.name = "Flames"
	var mb := MB.new()
	for i in 16:
		var a := i * TAU / 16.0
		mb.col(Color("7FD3F7") if i % 2 else Color("FFB86A"), 0.0, 0.0)
		mb.at(Vector3(cos(a) * r, 0.03, sin(a) * r), Vector3(sin(a) * 0.35, 0, -cos(a) * 0.35)); mb.cone(0.012, 0.034, 8); mb.pop()
	var mi := MeshInstance3D.new()
	mi.mesh = FoodArt.finish(mb)
	mi.material_override = Toon.solid(Color.WHITE, 0.0, {"use_vertex_color": true, "emission_amount": 1.4, "emission_color": Color.WHITE})
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	return n

# ---------------------------------------------------------------- pot
static func pot() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	var r := 0.13
	var h := 0.15
	mb.col(Color("C5CCE6"), 1.0, 0.6)
	mb.lathe(PackedVector2Array([Vector2(0, 0.0), Vector2(r * 0.92, 0.0), Vector2(r, 0.02), Vector2(r, h), Vector2(r + 0.006, h + 0.006), Vector2(r - 0.006, h + 0.006), Vector2(r - 0.008, 0.012), Vector2(0, 0.012)]), 44, Callable(),
		func(_u: float, v: float, p: Vector3) -> Color: return Color("E8ECF8") if v > 0.55 else (Color("DDE2F4") if absf(p.y - h * 0.62) < 0.006 else Color("C5CCE6")), 16)
	for s in [-1.0, 1.0]:
		mb.col(Color("8E96B8")); mb.at(Vector3(s * (r + 0.025), h * 0.82, 0)); mb.rbox(Vector3(0.05, 0.02, 0.06), 0.009, 2); mb.pop()
	n.add_child(_mi(mb))
	_face(n, Vector3(0, h * 0.42, r + 0.002), 3.0)
	var water := MeshInstance3D.new()
	water.name = "Water"
	var wm := CylinderMesh.new()
	wm.top_radius = r - 0.009; wm.bottom_radius = r - 0.009; wm.height = 0.004; wm.radial_segments = 40
	water.mesh = wm
	water.position = Vector3(0, h * 0.72, 0)
	water.material_override = tint_mat(Color("BFE3F2"))
	n.add_child(water)
	var c := Node3D.new(); c.name = "Contents"; c.position = Vector3(0, h * 0.72, 0); n.add_child(c)
	return n

# ---------------------------------------------------------------- frying pan
static func pan() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	var r := 0.14
	mb.col(Color("3E3E54"), 1.0, 0.7)
	mb.lathe(PackedVector2Array([Vector2(0, 0.0), Vector2(r * 0.85, 0.0), Vector2(r, 0.035), Vector2(r + 0.004, 0.04), Vector2(r - 0.006, 0.04), Vector2(r * 0.84, 0.008), Vector2(0, 0.008)]), 48, Callable(),
		func(_u: float, v: float, _p: Vector3) -> Color: return Color("5A5A74") if v > 0.6 else Color("2A2A38"), 14)
	mb.col(Color("A8734A"), 1.0, 0.2)
	mb.tube(PackedVector3Array([Vector3(r - 0.004, 0.03, 0.0), Vector3(r + 0.08, 0.042, 0.0), Vector3(r + 0.2, 0.05, 0.0)]), 0.014, 12)
	mb.col(Color("6A6A84"), 0.6); mb.at(Vector3(r + 0.03, 0.035, 0)); mb.torus(0.016, 0.004, 16, 6); mb.pop()
	n.add_child(_mi(mb))
	_face(n, Vector3(r + 0.13, 0.062, 0.008), 1.6, Vector3(-PI * 0.42, 0, 0))
	var c := Node3D.new(); c.name = "Contents"; c.position = Vector3(0, 0.008, 0); n.add_child(c)
	var oil := MeshInstance3D.new()
	oil.name = "Oil"
	var om := CylinderMesh.new()
	om.top_radius = r * 0.82; om.bottom_radius = r * 0.82; om.height = 0.0015; om.radial_segments = 40
	oil.mesh = om
	oil.position = Vector3(0, 0.0095, 0)
	oil.material_override = Toon.solid(Color("FFD678"), 0.0, {"emission_amount": 0.25, "base_gloss": 1.0})
	oil.visible = false
	n.add_child(oil)
	return n

# ---------------------------------------------------------------- oven (stands on the floor, in the counter)
static func oven() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	var w := 0.62
	var h := 0.7
	var d := 0.3
	mb.col(PLUM)
	for x in [-w * 0.36, w * 0.36]:
		mb.at(Vector3(x, 0.025, 0)); mb.rbox(Vector3(0.06, 0.05, 0.06), 0.01, 1); mb.pop()
	var y0 := 0.05
	# body as a frame around a window opening, so food inside shows through
	var body := Color("FFB9A6")
	mb.col(body)
	mb.at(Vector3(0, y0 + h * 0.5, -d * 0.5 + 0.02)); mb.rbox(Vector3(w, h, 0.04), 0.02, 2); mb.pop()   # back
	mb.at(Vector3(-w * 0.5 + 0.03, y0 + h * 0.5, 0)); mb.rbox(Vector3(0.06, h, d), 0.025, 2); mb.pop()
	mb.at(Vector3(w * 0.5 - 0.03, y0 + h * 0.5, 0)); mb.rbox(Vector3(0.06, h, d), 0.025, 2); mb.pop()
	mb.at(Vector3(0, y0 + 0.04, 0)); mb.rbox(Vector3(w, 0.08, d), 0.025, 2); mb.pop()
	mb.at(Vector3(0, y0 + h - 0.1, 0)); mb.rbox(Vector3(w, 0.2, d), 0.03, 2); mb.pop()
	# control panel
	mb.col(Color("FFE3D8"), 1.0, 0.3); mb.at(Vector3(0, y0 + h - 0.1, d * 0.5 + 0.002)); mb.rbox(Vector3(w - 0.08, 0.15, 0.012), 0.02, 2); mb.pop()
	mb.col(Color("2E2A40"), 1.0, 0.5); mb.at(Vector3(0.04, y0 + h - 0.1, d * 0.5 + 0.009)); mb.rbox(Vector3(0.16, 0.07, 0.008), 0.012, 2); mb.pop()
	# window frame & inside
	mb.col(Color("FFCFC1"), 1.0, 0.3)
	var wy := y0 + 0.08 + (h - 0.28) * 0.5
	var ww := w - 0.12
	var wh := h - 0.28 - 0.02
	mb.at(Vector3(0, wy + wh * 0.5 + 0.012, d * 0.5)); mb.rbox(Vector3(ww + 0.02, 0.024, 0.02), 0.008, 1); mb.pop()
	mb.at(Vector3(0, wy - wh * 0.5 - 0.012, d * 0.5)); mb.rbox(Vector3(ww + 0.02, 0.024, 0.02), 0.008, 1); mb.pop()
	mb.col(Color("FFF6F0")); mb.at(Vector3(0, wy + wh * 0.5 + 0.035, d * 0.5 + 0.02)); mb.rbox(Vector3(ww * 0.6, 0.022, 0.026), 0.01, 2); mb.pop()
	mb.col(Color("3A3348"), 0.0, 0.2); mb.at(Vector3(0, wy, -d * 0.5 + 0.041)); mb.rbox(Vector3(ww, wh, 0.002), 0.001, 1); mb.pop()
	mb.col(Color("4A3A40"), 0.0); mb.at(Vector3(0, wy - wh * 0.5 + 0.004, 0)); mb.rbox(Vector3(ww, 0.008, d - 0.04), 0.002, 1); mb.pop()
	mb.col(Color("9AA0B8"), 0.5); mb.at(Vector3(0, wy - 0.05, 0)); mb.rbox(Vector3(ww - 0.02, 0.006, d - 0.06), 0.002, 1); mb.pop()
	mb.layer(1); mb.at(Vector3(0, wy, d * 0.5 + 0.004)); mb.rbox(Vector3(ww, wh, 0.006), 0.002, 1); mb.pop(); mb.layer(0)
	n.add_child(_mi(mb))
	_face(n, Vector3(-0.19, y0 + h - 0.1, d * 0.5 + 0.009), 2.4)
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = Color(1.0, 0.6, 0.3)
	glow.light_energy = 0.0
	glow.omni_range = 0.6
	glow.position = Vector3(0, wy, 0.02)
	n.add_child(glow)
	var dial := Node3D.new(); dial.name = "Dial"; dial.position = Vector3(0.22, y0 + h - 0.1, d * 0.5 + 0.012)
	var db := MB.new()
	db.col(Color("FFF6F0"), 1.0, 0.4); db.at(Vector3.ZERO, Vector3(PI * 0.5, 0, 0)); db.puck(0.036, 0.022, 0.008, 24); db.pop()
	db.col(Color("FF5C8D"), 0.0); db.at(Vector3(0, 0.017, 0.023)); db.rbox(Vector3(0.008, 0.03, 0.004), 0.002, 1); db.pop()
	dial.add_child(_mi(db, "DialMesh"))
	n.add_child(dial)
	var temp := label3d("180°", 64)
	temp.name = "Temp"
	temp.position = Vector3(0.04, y0 + h - 0.11, d * 0.5 + 0.0145)
	n.add_child(temp)
	var c := Node3D.new(); c.name = "Contents"; c.position = Vector3(0, wy - 0.047, 0.0); n.add_child(c)
	return n

# ---------------------------------------------------------------- microwave
const KEYS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "▶"]
static func micro() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	var w := 0.5
	var h := 0.3
	var d := 0.34
	mb.col(PLUM)
	for x in [-w * 0.38, w * 0.38]:
		mb.at(Vector3(x, 0.01, 0.0)); mb.rbox(Vector3(0.05, 0.02, 0.05), 0.008, 1); mb.pop()
	var y0 := 0.02
	var body := Color("A8E6CF")
	mb.col(body)
	mb.at(Vector3(0, y0 + h * 0.5, -d * 0.5 + 0.02)); mb.rbox(Vector3(w, h, 0.04), 0.02, 2); mb.pop()
	mb.at(Vector3(-w * 0.5 + 0.02, y0 + h * 0.5, 0)); mb.rbox(Vector3(0.04, h, d), 0.02, 2); mb.pop()
	mb.at(Vector3(w * 0.5 - 0.075, y0 + h * 0.5, 0)); mb.rbox(Vector3(0.15, h, d), 0.03, 2); mb.pop()
	mb.at(Vector3(0, y0 + 0.02, 0)); mb.rbox(Vector3(w, 0.04, d), 0.02, 2); mb.pop()
	mb.at(Vector3(0, y0 + h - 0.02, 0)); mb.rbox(Vector3(w, 0.04, d), 0.02, 2); mb.pop()
	var wx := -0.07
	var ww := 0.3
	var wy := y0 + h * 0.5
	var wh := h - 0.08
	mb.col(Color("8ED6BC"))
	mb.at(Vector3(wx, wy + wh * 0.5 + 0.005, d * 0.5)); mb.rbox(Vector3(ww + 0.03, 0.02, 0.02), 0.008, 1); mb.pop()
	mb.at(Vector3(wx, wy - wh * 0.5 - 0.005, d * 0.5)); mb.rbox(Vector3(ww + 0.03, 0.02, 0.02), 0.008, 1); mb.pop()
	mb.at(Vector3(wx - ww * 0.5 - 0.005, wy, d * 0.5)); mb.rbox(Vector3(0.02, wh + 0.02, 0.02), 0.008, 1); mb.pop()
	mb.at(Vector3(wx + ww * 0.5 + 0.005, wy, d * 0.5)); mb.rbox(Vector3(0.02, wh + 0.02, 0.02), 0.008, 1); mb.pop()
	mb.col(Color("E8FFF6")); mb.at(Vector3(wx + ww * 0.5 - 0.02, wy, d * 0.5 + 0.018)); mb.rbox(Vector3(0.016, 0.13, 0.016), 0.007, 2); mb.pop()
	mb.col(Color("3A4A50"), 0.0, 0.2); mb.at(Vector3(wx, wy, -d * 0.5 + 0.041)); mb.rbox(Vector3(ww, wh, 0.002), 0.001, 1); mb.pop()
	mb.layer(1); mb.at(Vector3(wx, wy, d * 0.5 + 0.004)); mb.rbox(Vector3(ww, wh, 0.006), 0.002, 1); mb.pop(); mb.layer(0)
	# display & keypad on the right panel
	mb.col(Color("26303A"), 1.0, 0.5); mb.at(Vector3(0.175, y0 + h - 0.06, d * 0.5 + 0.004)); mb.rbox(Vector3(0.11, 0.035, 0.008), 0.008, 2); mb.pop()
	n.add_child(_mi(mb))
	_face(n, Vector3(0.175, y0 + h - 0.1, d * 0.5 + 0.004), 1.5)
	var disp := label3d("0:00", 56)
	disp.name = "Display"
	disp.position = Vector3(0.175, y0 + h - 0.062, d * 0.5 + 0.0085)
	n.add_child(disp)
	var keys := Node3D.new(); keys.name = "Keys"; n.add_child(keys)
	for i in KEYS.size():
		var k := Node3D.new()
		k.name = "Key%d" % i
		k.position = Vector3(0.143 + (i % 3) * 0.032, y0 + 0.155 - (i / 3) * 0.032, d * 0.5 + 0.004)
		var kb := MB.new()
		kb.col(Color("FF9EBB") if KEYS[i] == "▶" else Color("FFE27A") if KEYS[i] == "C" else Color("F2FFF9"), 0.8, 0.3)
		kb.rbox(Vector3(0.026, 0.024, 0.01), 0.006, 2)
		k.add_child(_mi(kb, "Cap"))
		var l := label3d(KEYS[i], 36, PLUM)
		l.position = Vector3(0, -0.001, 0.0055)
		k.add_child(l)
		keys.add_child(k)
	var tt := Node3D.new(); tt.name = "Turntable"; tt.position = Vector3(wx, y0 + 0.045, 0)
	var tb := MB.new()
	tb.col(Color("E8FFF6"), 0.6, 0.8); tb.puck(0.11, 0.008, 0.003, 32)
	tt.add_child(_mi(tb, "Plate"))
	var c := Node3D.new(); c.name = "Contents"; c.position = Vector3(0, 0.008, 0); tt.add_child(c)
	n.add_child(tt)
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = Color(1.0, 0.92, 0.6)
	glow.light_energy = 0.0
	glow.omni_range = 0.5
	glow.position = Vector3(wx, wy, 0.0)
	n.add_child(glow)
	return n

# ---------------------------------------------------------------- freezer (floor)
static func freezer() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	var w := 0.6
	var h := 1.25
	var d := 0.55
	var body := Color("BFE6FF")
	mb.col(body)
	mb.at(Vector3(0, h * 0.5, -d * 0.5 + 0.03)); mb.rbox(Vector3(w, h, 0.06), 0.03, 2); mb.pop()
	mb.at(Vector3(-w * 0.5 + 0.04, h * 0.5, 0)); mb.rbox(Vector3(0.08, h, d), 0.035, 2); mb.pop()
	mb.at(Vector3(w * 0.5 - 0.04, h * 0.5, 0)); mb.rbox(Vector3(0.08, h, d), 0.035, 2); mb.pop()
	mb.at(Vector3(0, 0.12, 0)); mb.rbox(Vector3(w, 0.24, d), 0.035, 2); mb.pop()
	mb.at(Vector3(0, h - 0.17, 0)); mb.rbox(Vector3(w, 0.34, d), 0.05, 2); mb.pop()
	mb.col(Color("E8F6FF"), 1.0, 0.4); mb.at(Vector3(w * 0.5 - 0.06, h * 0.55, d * 0.5 + 0.02)); mb.rbox(Vector3(0.025, 0.3, 0.025), 0.011, 2); mb.pop()
	mb.col(Color("4A6A8A"), 0.0); mb.at(Vector3(0, 0.24 + (h - 0.58) * 0.5, -d * 0.5 + 0.061)); mb.rbox(Vector3(w - 0.16, h - 0.58, 0.002), 0.001, 1); mb.pop()
	mb.col(Color("D8F0FF"), 0.5); mb.at(Vector3(0, 0.245, 0)); mb.rbox(Vector3(w - 0.16, 0.01, d - 0.08), 0.003, 1); mb.pop()
	mb.col(Color("7FD3F7"), 0.6, 0.4)
	for i in 6:
		mb.at(Vector3(0, h - 0.12, d * 0.5 + 0.004), Vector3(0, 0, i * PI / 3.0)); mb.rbox(Vector3(0.006, 0.07, 0.006), 0.002, 1); mb.pop()
	n.add_child(_mi(mb))
	var win := MeshInstance3D.new()
	win.name = "Window"
	var wb := MB.new()
	wb.layer(1); wb.at(Vector3(0, 0.24 + (h - 0.58) * 0.5, d * 0.5 - 0.01)); wb.rbox(Vector3(w - 0.16, h - 0.58, 0.008), 0.004, 1); wb.pop(); wb.layer(0)
	win.mesh = FoodArt.finish(wb)
	n.add_child(win)
	_face(n, Vector3(0, h - 0.2, d * 0.5 + 0.002), 3.2)
	var c := Node3D.new(); c.name = "Contents"; c.position = Vector3(0, 0.25, 0.02); n.add_child(c)
	return n

# ---------------------------------------------------------------- fridge (floor)
static func fridge() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	var w := 0.72
	var h := 1.78
	var d := 0.6
	mb.col(Color("CFEFFF")); mb.at(Vector3(0, h * 0.5, 0)); mb.rbox(Vector3(w, h, d), 0.06, 3); mb.pop()
	mb.col(Color("B2E0F8"), 0.0); mb.at(Vector3(0, h * 0.66, d * 0.5 + 0.001)); mb.rbox(Vector3(w - 0.04, 0.012, 0.004), 0.002, 1); mb.pop()
	mb.col(Color("FFFFFF"), 1.0, 0.5)
	mb.at(Vector3(-w * 0.5 + 0.08, h * 0.82, d * 0.5 + 0.03)); mb.rbox(Vector3(0.03, 0.22, 0.03), 0.013, 2); mb.pop()
	mb.at(Vector3(-w * 0.5 + 0.08, h * 0.45, d * 0.5 + 0.03)); mb.rbox(Vector3(0.03, 0.4, 0.03), 0.013, 2); mb.pop()
	# magnets & a cute drawing
	var mags := [[Vector3(0.12, h * 0.5, 0), Color("FF7EA6")], [Vector3(0.22, h * 0.42, 0), Color("FFD24A")], [Vector3(0.05, h * 0.36, 0), Color("9BE38F")]]
	for m in mags:
		mb.col(m[1], 0.8, 0.6); mb.at(m[0] + Vector3(0, 0, d * 0.5 + 0.006), Vector3(PI * 0.5, 0, 0)); mb.puck(0.022, 0.012, 0.005, 16); mb.pop()
	mb.col(Color("FFFFFF"), 0.8); mb.at(Vector3(0.16, h * 0.42, d * 0.5 + 0.003), Vector3(0, 0, 0.08)); mb.rbox(Vector3(0.16, 0.2, 0.004), 0.004, 1); mb.pop()
	mb.col(Color("FF9EBB"), 0.0); mb.at(Vector3(0.16, h * 0.43, d * 0.5 + 0.006), Vector3(PI * 0.5, 0, 0)); mb.puck(0.04, 0.002, 0.001, 20); mb.pop()
	n.add_child(_mi(mb))
	_face(n, Vector3(0.08, h * 0.83, d * 0.5 + 0.002), 4.0)
	return n

# ---------------------------------------------------------------- bin (floor)
static func bin() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	mb.col(Color("B7A6F2"))
	mb.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.15, 0), Vector2(0.17, 0.02), Vector2(0.19, 0.42), Vector2(0.18, 0.42), Vector2(0.0, 0.42)]), 36, Callable(),
		func(u: float, _v: float, p: Vector3) -> Color: return Color("A493E4") if fposmod(u * 12.0, 1.0) < 0.12 and p.y > 0.05 and p.y < 0.38 else Color("B7A6F2"), 10)
	n.add_child(_mi(mb))
	var lid := Node3D.new(); lid.name = "Lid"; lid.position = Vector3(0, 0.42, -0.19)
	var lb := MB.new()
	lb.col(Color("9C88E8")); lb.at(Vector3(0, 0.02, 0.19)); lb.puck(0.205, 0.04, 0.015, 36); lb.pop()
	lb.col(Color("9C88E8")); lb.at(Vector3(0, 0.06, 0.19)); lb.rbox(Vector3(0.09, 0.03, 0.04), 0.012, 2); lb.pop()
	lid.add_child(_mi(lb, "LidMesh"))
	n.add_child(lid)
	_face(n, Vector3(0, 0.25, 0.185), 3.4)
	return n

# ---------------------------------------------------------------- serving plate on the pass + bell
static func pass_plate() -> Node3D:
	var n := Node3D.new()
	var mb := MB.new()
	mb.push(Transform3D(Basis.IDENTITY.scaled(Vector3(1.55, 1.2, 1.55)), Vector3.ZERO))
	DishArt.plate(mb, 0.105)
	mb.pop()
	n.add_child(_mi(mb))
	var bell := Node3D.new(); bell.name = "Bell"; bell.position = Vector3(0.26, 0, 0.04)
	var bb := MB.new()
	bb.col(Color("6A3E20")); bb.puck(0.05, 0.012, 0.004, 24)
	bb.col(Color("FFD24A"), 1.0, 1.0); bb.at(Vector3(0, 0.012, 0)); bb.lathe(MB.spline(PackedVector2Array([Vector2(0, 0), Vector2(0.042, 0.0), Vector2(0.038, 0.012), Vector2(0.026, 0.035), Vector2(0, 0.044)]), 4), 28); bb.pop()
	bb.col(Color("FFD24A"), 1.0, 1.0); bb.at(Vector3(0, 0.058, 0)); bb.sphere(0.008, 10, 6); bb.pop()
	bell.add_child(_mi(bb, "BellMesh"))
	n.add_child(bell)
	var c := Node3D.new(); c.name = "Contents"; c.position = Vector3(0, 0.012, 0); n.add_child(c)
	return n
