## A chibi café customer: walks in, sits on a stool, orders, eats, pays and leaves.
class_name Customer
extends Node3D

const SKINS := [Color("FFE2D2"), Color("FFE6D6"), Color("F2CDB0"), Color("FFEADF"), Color("FFDCC8"), Color("F6D2BC"), Color("E8B896")]
const HAIRS := [Color("4B2E5A"), Color("E8A04A"), Color("6A4AC8"), Color("3A2A2A"), Color("F2B8C8"), Color("8A4A2A"), Color("2E3A5A"), Color("FFE08A"), Color("9BD8F0")]
const SHIRTS := [Color("8B7BC9"), Color("7FD3B8"), Color("FF9EBB"), Color("FFD24A"), Color("A9C8FF"), Color("B7E3A0"), Color("FFB86A"), Color("F2F2F8")]
const STYLES := ["bob", "buns", "twin", "short", "long", "pony"]

var cid := 0
var cname := "Mina"
var kind := "normal"      # normal | regular | critic | cat
var seat := 0
var state := "enter"      # enter, wait, order, eat, leave
var t := 0.0
var patience := 75.0
var pmax := 75.0
var order := -1
var look := {}
var path: Array[Vector3] = []
var seat_pos := Vector3.ZERO
var face: Face
var body: Node3D
var arm_l: Node3D
var arm_r: Node3D
var bubble: Node3D
var bubble_icon: Sprite3D
var bubble_bg: Sprite3D
var meal: Node3D
var mood_t := 0.0
var bob := 0.0
var _speed := 1.1
var _sat := false
var stars := 0
var quick := false

static var _bubble_tex: Texture2D
static var _wait_tex: Texture2D
static var _heart_tex: Texture2D

func setup(info: Dictionary) -> void:
	cid = info.id
	cname = info.name
	kind = info.get("kind", "normal")
	look = info.look
	seat = info.seat
	bob = randf() * TAU
	_build()

func _build() -> void:
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	if kind == "cat":
		_build_cat()
	else:
		_build_person()
	bubble = Node3D.new()
	bubble.position = Vector3(0, 0.98 if kind != "cat" else 0.62, 0)
	bubble.visible = false
	body.add_child(bubble)
	bubble_bg = Sprite3D.new()
	bubble_bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble_bg.texture = bubble_texture()
	bubble_bg.pixel_size = 0.0016
	bubble_bg.shaded = false
	bubble_bg.render_priority = 2
	bubble.add_child(bubble_bg)
	bubble_icon = Sprite3D.new()
	bubble_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble_icon.pixel_size = 0.0011
	bubble_icon.position = Vector3(0, 0.012, 0.002)
	bubble_icon.shaded = false
	bubble_icon.render_priority = 3
	bubble.add_child(bubble_icon)

func _build_person() -> void:
	var skin: Color = look.skin
	var hair: Color = look.hair
	var shirt: Color = look.shirt
	var style: String = look.style
	var mb := MB.new()
	# legs
	for s in [-1.0, 1.0]:
		mb.col(Color("5A4A70") if kind != "critic" else Color("3A3048"))
		mb.tube(PackedVector3Array([Vector3(s * 0.05, 0.05, 0.0), Vector3(s * 0.05, 0.2, 0.0)]), 0.032, 10)
		mb.col(Color("FFFFFF") if kind != "critic" else Color("6A3E20"), 1.0, 0.3); mb.at(Vector3(s * 0.05, 0.035, 0.02)); mb.ellipsoid(0.038, 0.03, 0.05, 12, 8); mb.pop()
	# body: a soft rounded cone
	mb.col(shirt, 1.0, 0.1)
	mb.lathe(MB.spline(PackedVector2Array([Vector2(0, 0.18), Vector2(0.11, 0.185), Vector2(0.125, 0.22), Vector2(0.105, 0.35), Vector2(0.07, 0.42), Vector2(0, 0.43)]), 4), 24)
	mb.col(Color.WHITE, 1.0); mb.at(Vector3(0, 0.405, 0.035), Vector3(-0.6, 0, 0)); mb.ellipsoid(0.05, 0.012, 0.035, 12, 6); mb.pop()
	if kind == "critic":
		mb.col(Color("E8404A"), 1.0, 0.4); mb.at(Vector3(0, 0.37, 0.085)); mb.ellipsoid(0.022, 0.016, 0.01, 10, 6); mb.pop()
	else:
		mb.col(Color("FF7EA6"), 0.8, 0.4); mb.at(Vector3(0, 0.36, 0.095)); mb.sphere(0.012, 8, 6); mb.pop()
	var bm := FoodArt.mesh_node(FoodArt.finish(mb))
	body.add_child(bm)
	# arms
	arm_l = _arm(shirt, skin, -1.0)
	arm_r = _arm(shirt, skin, 1.0)
	# head
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.55, 0)
	body.add_child(head)
	var hb := MB.new()
	hb.col(skin, 1.0, 0.1); hb.at(Vector3(0, 0, 0)); hb.ellipsoid(0.15, 0.14, 0.14, 28, 16); hb.pop()
	for s in [-1.0, 1.0]:
		hb.col(skin); hb.at(Vector3(s * 0.148, -0.01, 0)); hb.ellipsoid(0.022, 0.03, 0.02, 10, 6); hb.pop()
	_hair(hb, style, hair)
	if kind == "critic":
		hb.col(Color("3B2340"), 1.0, 0.3); hb.at(Vector3(0.01, 0.135, -0.01), Vector3(0.0, 0, 0.18)); hb.ellipsoid(0.15, 0.035, 0.14, 24, 8); hb.pop()
		hb.col(Color("3B2340"), 1.0, 0.3); hb.at(Vector3(0.03, 0.17, -0.01)); hb.sphere(0.016, 8, 6); hb.pop()
	head.add_child(FoodArt.mesh_node(FoodArt.finish(hb)))
	face = Face.new(3.6)
	face.position = Vector3(0, -0.02, 0.138)
	head.add_child(face)
	if kind == "critic":
		var gb := MB.new()
		gb.col(Color("3B2340"), 0.0, 0.8)
		for s in [-1.0, 1.0]:
			gb.at(Vector3(s * 0.032, -0.02, 0.15), Vector3(PI * 0.5, 0, 0)); gb.torus(0.024, 0.004, 20, 6); gb.pop()
		gb.tube(PackedVector3Array([Vector3(-0.009, -0.016, 0.152), Vector3(0.009, -0.016, 0.152)]), 0.003, 5)
		head.add_child(FoodArt.mesh_node(FoodArt.finish(gb)))

func _arm(shirt: Color, skin: Color, s: float) -> Node3D:
	var a := Node3D.new()
	a.position = Vector3(s * 0.1, 0.39, 0)
	var mb := MB.new()
	mb.col(shirt); mb.tube(PackedVector3Array([Vector3(0, 0, 0), Vector3(s * 0.04, -0.1, 0.02)]), 0.03, 10)
	mb.col(skin); mb.at(Vector3(s * 0.045, -0.13, 0.025)); mb.sphere(0.03, 10, 8); mb.pop()
	a.add_child(FoodArt.mesh_node(FoodArt.finish(mb)))
	body.add_child(a)
	return a

static func _hair(mb: MB, style: String, c: Color) -> void:
	mb.col(c, 1.0, 0.35)
	# back of the head & top cap
	mb.at(Vector3(0, 0.03, -0.035)); mb.ellipsoid(0.16, 0.15, 0.135, 28, 16); mb.pop()
	# fringe: little rounded locks over the forehead
	for i in 7:
		var x := -0.11 + i * 0.037
		var y := 0.07 - absf(x) * 0.25
		mb.at(Vector3(x, y, 0.118 - absf(x) * 0.3), Vector3(-0.35, 0, x * 1.4)); mb.ellipsoid(0.03, 0.045, 0.022, 12, 8); mb.pop()
	mb.col(c.lightened(0.45), 0.0)
	mb.tube(PackedVector3Array([Vector3(-0.09, 0.115, 0.08), Vector3(-0.05, 0.135, 0.085), Vector3(-0.01, 0.14, 0.08)]), 0.006, 5)
	mb.col(c, 1.0, 0.35)
	match style:
		"buns":
			for s in [-1.0, 1.0]:
				mb.at(Vector3(s * 0.11, 0.13, -0.04)); mb.sphere(0.055, 16, 10); mb.pop()
		"twin":
			for s in [-1.0, 1.0]:
				mb.tube(MB.spline3(PackedVector3Array([Vector3(s * 0.14, 0.06, -0.04), Vector3(s * 0.2, -0.05, -0.04), Vector3(s * 0.19, -0.2, -0.02)]), 4), func(t: float) -> float: return 0.04 * (1.0 - t * 0.6) + 0.006, 12)
				mb.col(Color("FF7EA6")); mb.at(Vector3(s * 0.15, 0.06, -0.04)); mb.sphere(0.022, 8, 6); mb.pop(); mb.col(c)
		"long":
			mb.at(Vector3(0, -0.07, -0.06)); mb.ellipsoid(0.16, 0.16, 0.11, 22, 12); mb.pop()
		"pony":
			mb.tube(MB.spline3(PackedVector3Array([Vector3(0, 0.12, -0.13), Vector3(0, 0.05, -0.2), Vector3(0, -0.12, -0.18)]), 4), func(t: float) -> float: return 0.045 * (1.0 - t * 0.5), 12)
			mb.col(Color("FFD24A")); mb.at(Vector3(0, 0.12, -0.13)); mb.torus(0.025, 0.01, 12, 6); mb.pop(); mb.col(c)
		"short":
			for i in 5:
				var a := -0.8 + i * 0.4
				mb.at(Vector3(sin(a) * 0.12, 0.13, cos(a) * 0.05 - 0.05), Vector3(0.0, 0, -a * 0.7)); mb.cone(0.035, 0.07, 8); mb.pop()
		_:
			for s in [-1.0, 1.0]:
				mb.at(Vector3(s * 0.135, -0.03, 0.01)); mb.ellipsoid(0.04, 0.09, 0.06, 12, 8); mb.pop()

func _build_cat() -> void:
	var c := Color("FFB86A")
	var mb := MB.new()
	mb.col(c, 1.0, 0.1); mb.at(Vector3(0, 0.12, 0)); mb.ellipsoid(0.11, 0.12, 0.13, 22, 12); mb.pop()
	mb.col(Color("FFF2E0")); mb.at(Vector3(0, 0.1, 0.07)); mb.ellipsoid(0.07, 0.08, 0.06, 16, 10); mb.pop()
	for s in [-1.0, 1.0]:
		mb.col(c); mb.at(Vector3(s * 0.06, 0.02, 0.07)); mb.ellipsoid(0.03, 0.025, 0.04, 10, 6); mb.pop()
	mb.col(c); mb.tube(MB.spline3(PackedVector3Array([Vector3(0, 0.06, -0.12), Vector3(0.08, 0.1, -0.2), Vector3(0.1, 0.25, -0.18)]), 4), func(t: float) -> float: return 0.025 * (1.0 - t * 0.4), 10)
	body.add_child(FoodArt.mesh_node(FoodArt.finish(mb)))
	var head := Node3D.new()
	head.position = Vector3(0, 0.3, 0.02)
	body.add_child(head)
	var hb := MB.new()
	hb.col(c, 1.0, 0.1); hb.ellipsoid(0.12, 0.1, 0.1, 24, 14)
	for s in [-1.0, 1.0]:
		hb.col(c); hb.at(Vector3(s * 0.075, 0.075, 0.0), Vector3(0, 0, -s * 0.35)); hb.cone(0.04, 0.07, 10); hb.pop()
		hb.col(Color("FF9EBB"), 0.0); hb.at(Vector3(s * 0.075, 0.09, 0.012), Vector3(0, 0, -s * 0.35)); hb.cone(0.022, 0.04, 8); hb.pop()
		hb.col(Color("3B2340"), 0.0)
		for k in 2:
			hb.tube(PackedVector3Array([Vector3(s * 0.05, -0.02 + k * 0.012, 0.092), Vector3(s * 0.13, -0.025 + k * 0.02, 0.08)]), 0.0015, 4)
	hb.col(Color("FFB52E"), 0.6)
	for i in 3:
		hb.at(Vector3(-0.03 + i * 0.03, 0.09, 0.03)); hb.ellipsoid(0.008, 0.012, 0.03, 8, 6); hb.pop()
	head.add_child(FoodArt.mesh_node(FoodArt.finish(hb)))
	face = Face.new(2.6)
	face.position = Vector3(0, -0.005, 0.098)
	head.add_child(face)
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	body.add_child(arm_l)
	body.add_child(arm_r)

static func bubble_texture() -> Texture2D:
	if _bubble_tex: return _bubble_tex
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' width='140' height='150'><path d='M70 6 C 110 6 134 26 134 62 C 134 98 110 116 82 117 L 70 142 L 58 117 C 30 116 6 98 6 62 C 6 26 30 6 70 6 Z' fill='white' stroke='#3B2340' stroke-width='7' stroke-linejoin='round'/></svg>"
	var img := Image.new()
	img.load_svg_from_string(svg, 1.0)
	_bubble_tex = ImageTexture.create_from_image(img)
	return _bubble_tex

static func wait_texture() -> Texture2D:
	if _wait_tex: return _wait_tex
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' width='120' height='120'><rect x='46' y='10' width='28' height='66' rx='14' fill='#FF5C8D' stroke='#3B2340' stroke-width='6'/><circle cx='60' cy='98' r='14' fill='#FF5C8D' stroke='#3B2340' stroke-width='6'/></svg>"
	var img := Image.new()
	img.load_svg_from_string(svg, 1.0)
	_wait_tex = ImageTexture.create_from_image(img)
	return _wait_tex

static func heart_texture() -> Texture2D:
	if _heart_tex: return _heart_tex
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' width='120' height='110'><path d='M60 100 C 20 70 6 48 6 30 C 6 14 20 4 34 4 C 46 4 55 12 60 22 C 65 12 74 4 86 4 C 100 4 114 14 114 30 C 114 48 100 70 60 100 Z' fill='#FF7EA6' stroke='#3B2340' stroke-width='7' stroke-linejoin='round'/></svg>"
	var img := Image.new()
	img.load_svg_from_string(svg, 1.0)
	_heart_tex = ImageTexture.create_from_image(img)
	return _heart_tex

# ---------------------------------------------------------------- behaviour
func walk_to(points: Array) -> void:
	path.clear()
	for p in points: path.append(p)

func set_bubble(kind_: String) -> void:
	match kind_:
		"wait":
			bubble.visible = true
			bubble_icon.texture = wait_texture()
			bubble_icon.pixel_size = 0.0011
		"order":
			bubble.visible = true
			bubble_icon.texture = Photo.recipe(order, 160)
			bubble_icon.pixel_size = 0.00085
		"heart":
			bubble.visible = true
			bubble_icon.texture = heart_texture()
			bubble_icon.pixel_size = 0.0008
		_:
			bubble.visible = false

func feel(m: String, hold := 2.5) -> void:
	if face: face.set_mood(m, hold)

func tick(dt: float, clock: float) -> void:
	t += dt
	# walking along the path
	if path.size():
		var target: Vector3 = path[0]
		var d := target - position
		d.y = 0
		if d.length() < 0.03:
			position = Vector3(target.x, position.y, target.z)
			path.remove_at(0)
		else:
			var step := minf(d.length(), _speed * dt)
			position += d.normalized() * step
			var yaw := atan2(d.x, d.z)
			rotation.y = lerp_angle(rotation.y, yaw, minf(1.0, dt * 10.0))
		var w := sin(clock * 12.0)
		body.position.y = absf(w) * 0.03
		body.rotation.z = w * 0.06
		if arm_l: arm_l.rotation.x = w * 0.6
		if arm_r: arm_r.rotation.x = -w * 0.6
	else:
		rotation.y = lerp_angle(rotation.y, 0.0, minf(1.0, dt * 6.0))
		var breathe := sin(clock * 1.6 + bob)
		body.rotation.z = lerpf(body.rotation.z, 0.0, minf(1.0, dt * 8.0))
		var sit_y := 0.0
		if _sat: sit_y = seat_pos.y
		position.y = lerpf(position.y, sit_y, minf(1.0, dt * 10.0))
		body.position.y = breathe * 0.004
		if state == "eat":
			var k := fmod(t, 0.6) < 0.3
			if arm_r: arm_r.rotation.x = -1.2 if k else -0.6
			if arm_l: arm_l.rotation.x = 0.0
			body.position.y += 0.01 * absf(sin(clock * 8.0))
		elif state == "wait":
			if arm_r: arm_r.rotation.x = -2.6 + sin(clock * 6.0) * 0.3
			if arm_r: arm_r.rotation.z = 0.3
		else:
			if arm_l: arm_l.rotation.x = lerpf(arm_l.rotation.x, 0.0, minf(1.0, dt * 6.0))
			if arm_r: arm_r.rotation.x = lerpf(arm_r.rotation.x, 0.0, minf(1.0, dt * 6.0))
			if arm_r: arm_r.rotation.z = 0.0
	if bubble.visible:
		bubble.position.y = (0.98 if kind != "cat" else 0.62) + sin(clock * 3.0 + bob) * 0.01
		var pop := 1.0 + (0.06 * sin(clock * 6.0) if state == "wait" else 0.0)
		bubble.scale = Vector3.ONE * pop

func sit() -> void:
	_sat = true

func stand() -> void:
	_sat = false
