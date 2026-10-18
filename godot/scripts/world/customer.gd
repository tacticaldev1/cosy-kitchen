## A café customer: walks in, takes a seat, orders, eats what you bring, pays and leaves.
class_name Customer
extends Chibi

var cid := 0
var cname := "Mina"
var ckind := "normal"      # normal | regular | critic | cat
var seat := -1
var state := "enter"       # enter, wait, order, eat, leave, gone
var t := 0.0
var patience := 75.0
var pmax := 75.0
var order := -1
var seat_pos := Vector3.ZERO
var seat_yaw := 0.0
var seat_h := 0.6
var table_y := 0.78         # where the meal goes: table height and distance in front of the seat
var table_d := 0.3
var npc := ""              # townsperson id when a dateable local visits
var bubble: Node3D
var bubble_icon: Sprite3D
var bubble_bg: Sprite3D
var meal: Node3D
var stars := 0
var quick := false

static var _bubble_tex: Texture2D
static var _wait_tex: Texture2D
static var _heart_tex: Texture2D

func setup(info: Dictionary) -> void:
	cid = info.id
	cname = info.name
	ckind = info.get("kind", "normal")
	seat = info.get("seat", -1)
	speed = 1.15
	var lk: Dictionary = info.look.duplicate()
	if ckind == "critic": lk.acc = "critic"
	build(lk, "cat" if ckind == "cat" else "adult")
	bubble = Node3D.new()
	bubble.position = Vector3(0, 0.98 if ckind != "cat" else 0.62, 0)
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

## Head position in world space (for picking and floating text).
func head_pos() -> Vector3:
	return global_position + Vector3(0, 0.55 if ckind != "cat" else 0.32, 0)

static func _svg(svg: String) -> Texture2D:
	var img := Image.new()
	img.load_svg_from_string(svg, 1.0)
	return ImageTexture.create_from_image(img)

static func bubble_texture() -> Texture2D:
	if _bubble_tex == null:
		_bubble_tex = _svg("<svg xmlns='http://www.w3.org/2000/svg' width='140' height='150'><path d='M70 6 C 110 6 134 26 134 62 C 134 98 110 116 82 117 L 70 142 L 58 117 C 30 116 6 98 6 62 C 6 26 30 6 70 6 Z' fill='white' stroke='#3B2340' stroke-width='7' stroke-linejoin='round'/></svg>")
	return _bubble_tex

static func wait_texture() -> Texture2D:
	if _wait_tex == null:
		_wait_tex = _svg("<svg xmlns='http://www.w3.org/2000/svg' width='120' height='120'><rect x='46' y='10' width='28' height='66' rx='14' fill='#FF5C8D' stroke='#3B2340' stroke-width='6'/><circle cx='60' cy='98' r='14' fill='#FF5C8D' stroke='#3B2340' stroke-width='6'/></svg>")
	return _wait_tex

static func heart_texture() -> Texture2D:
	if _heart_tex == null:
		_heart_tex = _svg("<svg xmlns='http://www.w3.org/2000/svg' width='120' height='110'><path d='M60 100 C 20 70 6 48 6 30 C 6 14 20 4 34 4 C 46 4 55 12 60 22 C 65 12 74 4 86 4 C 100 4 114 14 114 30 C 114 48 100 70 60 100 Z' fill='#FF7EA6' stroke='#3B2340' stroke-width='7' stroke-linejoin='round'/></svg>")
	return _heart_tex

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

func tick(dt: float, clock: float) -> void:
	t += dt
	set_eating(state == "eat")
	super(dt, clock)
	if state == "wait" and arm_r and not walking:
		arm_r.rotation.x = -2.6 + sin(clock * 6.0) * 0.3
		arm_r.rotation.z = 0.3
	if bubble.visible:
		bubble.position.y = (0.98 if ckind != "cat" else 0.62) + sin(clock * 3.0 + bob) * 0.01
		bubble.scale = Vector3.ONE * (1.0 + (0.06 * sin(clock * 6.0) if state == "wait" else 0.0))
