## A chibi character (player, customer, townsperson, partner, child, cat): a cute toon body
## with swinging legs and arms, a hairstyle, outfit, accessories and a kawaii face.
## It can walk along a path, sit, wave, eat and carry a dish.
class_name Chibi
extends Node3D

signal arrived

const SKINS := [Color("FFE2D2"), Color("FFE6D6"), Color("F2CDB0"), Color("FFEADF"), Color("FFDCC8"), Color("F6D2BC"), Color("E8B896"), Color("C89070"), Color("9A6448")]
const HAIRS := [Color("4B2E5A"), Color("E8A04A"), Color("6A4AC8"), Color("3A2A2A"), Color("F2B8C8"), Color("8A4A2A"), Color("2E3A5A"), Color("FFE08A"), Color("9BD8F0"), Color("F2F2F8"), Color("E8504A"), Color("6BBF89")]
const SHIRTS := [Color("8B7BC9"), Color("7FD3B8"), Color("FF9EBB"), Color("FFD24A"), Color("A9C8FF"), Color("B7E3A0"), Color("FFB86A"), Color("F2F2F8"), Color("E8504A"), Color("3B4A7A")]
const PANTS := [Color("5A4A70"), Color("3B4A7A"), Color("8A6A4A"), Color("2E2A3A"), Color("FFC2D6"), Color("BDEBDD")]
const STYLES := ["bob", "buns", "twin", "short", "long", "pony", "spiky", "curly", "pixie", "braid", "topknot", "afro", "mohawk", "wavy", "sidepart", "buzz", "drills", "bowl",
	"quiff", "slick", "undercut", "manbun", "messy", "curtains", "dreads", "wolf"]
const F_STYLES := ["bob", "buns", "twin", "long", "pony", "curly", "pixie", "braid", "topknot", "afro", "wavy", "drills", "bowl"]
const M_STYLES := ["short", "spiky", "curly", "bob", "afro", "mohawk", "sidepart", "buzz", "topknot", "bowl", "quiff", "slick", "undercut", "manbun", "messy", "curtains", "dreads", "wolf"]
const BOTTOMS := ["pants", "shorts", "skirt", "dress"]

var look := {}
var kind := "adult"      # adult | child | toddler | baby | cat
var face: Face
var body: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var hold: Node3D          # where carried things go
var carried: Node3D
var path: PackedVector3Array = PackedVector3Array()
var speed := 1.25
var bob := 0.0
var sitting := false
var floor_y := 0.0        # standing height (a shopkeeper's step behind the counter)
var sit_height := 0.0
var walking := false
var _walk_t := 0.0
var _wave_t := 0.0
var _eat := false
var _apron: Node3D
var _hat: Node3D

## body: "f" (feminine) or "m" (masculine); empty picks one at random.
static func random_look(rng: RandomNumberGenerator = null, body_ := "") -> Dictionary:
	var r := rng if rng else RandomNumberGenerator.new()
	if rng == null: r.randomize()
	var b := body_ if body_ != "" else ("f" if r.randf() < 0.5 else "m")
	var styles: Array = F_STYLES if b == "f" else M_STYLES
	var bottoms: Array = ["pants", "skirt", "dress", "shorts", "pants"] if b == "f" else ["pants", "pants", "shorts"]
	return {"body": b, "skin": SKINS[r.randi() % 7].to_html(false), "hair": HAIRS[r.randi() % HAIRS.size()].to_html(false), "shirt": SHIRTS[r.randi() % SHIRTS.size()].to_html(false),
		"pants": PANTS[r.randi() % PANTS.size()].to_html(false), "style": styles[r.randi() % styles.size()], "bottom": bottoms[r.randi() % bottoms.size()], "acc": ""}

## Older looks have no body type: guess from the hairstyle.
static func body_of(lk: Dictionary) -> String:
	var b: String = lk.get("body", "")
	if b == "f" or b == "m": return b
	return "m" if String(lk.get("style", "bob")) in ["short", "spiky"] else "f"

static func _c(v, fallback: Color) -> Color:
	if v is Color: return v
	if v is String and v != "": return Color(v)
	return fallback

func build(lk: Dictionary, kind_ := "adult") -> void:
	look = lk
	kind = kind_
	bob = randf() * TAU
	for ch in get_children(): ch.queue_free()
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	hold = Node3D.new()
	hold.name = "Hold"
	body.add_child(hold)
	if kind == "cat": _build_cat()
	else: _build_person()
	match kind:
		"child": scale = Vector3.ONE * 0.72
		"toddler": scale = Vector3.ONE * 0.55
		"baby": scale = Vector3.ONE * 0.42
		_: scale = Vector3.ONE

func _build_person() -> void:
	var skin := _c(look.get("skin"), SKINS[0])
	var hair := _c(look.get("hair"), HAIRS[0])
	var shirt := _c(look.get("shirt"), SHIRTS[0])
	var pants := _c(look.get("pants"), PANTS[0])
	var style: String = look.get("style", "bob")
	var acc: String = look.get("acc", "")
	var fem := body_of(look) == "f"
	var bottom: String = look.get("bottom", "pants")
	if not bottom in BOTTOMS: bottom = "pants"
	# legs on hip pivots so they can swing
	leg_l = _leg(pants, skin, -1.0, bottom)
	leg_r = _leg(pants, skin, 1.0, bottom)
	var mb := MB.new()
	mb.col(shirt, 1.0, 0.1)
	if fem:
		# softer shape: a little waist, rounder shoulders
		mb.lathe(MB.spline(PackedVector2Array([Vector2(0, 0.17), Vector2(0.105, 0.175), Vector2(0.118, 0.205), Vector2(0.093, 0.29), Vector2(0.1, 0.36), Vector2(0.07, 0.42), Vector2(0, 0.43)]), 4), 24)
	else:
		# squarer, broader shoulders
		mb.lathe(MB.spline(PackedVector2Array([Vector2(0, 0.17), Vector2(0.112, 0.175), Vector2(0.122, 0.21), Vector2(0.118, 0.33), Vector2(0.112, 0.385), Vector2(0.075, 0.425), Vector2(0, 0.435)]), 4), 24)
	if bottom == "skirt" or bottom == "dress":
		var sc := shirt if bottom == "dress" else pants
		var low := 0.07 if bottom == "dress" else 0.1
		mb.col(sc, 1.0, 0.15)
		mb.lathe(MB.spline(PackedVector2Array([Vector2(0, low), Vector2(0.15, low), Vector2(0.155, low + 0.01), Vector2(0.125, 0.17), Vector2(0.108, 0.215), Vector2(0, 0.215)]), 4), 28,
			func(u: float, _v: float) -> float: return 1.0 + 0.04 * sin(u * TAU * 8.0))
		mb.col(Color.WHITE, 0.0, 0.2)
		var hem := PackedVector3Array()
		for i in 41:
			var a := TAU * i / 40.0
			hem.append(Vector3(sin(a) * 0.154, low + 0.012, cos(a) * 0.154))
		mb.tube(hem, 0.004, 4)
	if acc == "critic":
		mb.col(Color("E8404A"), 1.0, 0.4); mb.at(Vector3(0, 0.37, 0.085)); mb.ellipsoid(0.022, 0.016, 0.01, 10, 6); mb.pop()
	else:
		mb.col(Color.WHITE, 1.0); mb.at(Vector3(0, 0.405, 0.035), Vector3(-0.6, 0, 0)); mb.ellipsoid(0.05, 0.012, 0.035, 12, 6); mb.pop()
		mb.col(Color("FF7EA6"), 0.8, 0.4); mb.at(Vector3(0, 0.36, 0.095)); mb.sphere(0.012, 8, 6); mb.pop()
	body.add_child(FoodArt.mesh_node(FoodArt.finish(mb)))
	# apron (shown at work)
	var ab := MB.new()
	ab.col(Color("FFFDF6"), 1.0, 0.1)
	ab.lathe(MB.spline(PackedVector2Array([Vector2(0, 0.165), Vector2(0.118, 0.17), Vector2(0.13, 0.205), Vector2(0.112, 0.33), Vector2(0, 0.335)]), 3), 24,
		func(u: float, _v: float) -> float: return 1.0 if absf(fposmod(u + 0.25, 1.0) - 0.5) < 0.3 else 0.96)
	ab.col(Color("FF9EBB"), 0.6); ab.at(Vector3(0, 0.25, 0.122)); ab.rbox(Vector3(0.06, 0.04, 0.006), 0.01, 1); ab.pop()
	_apron = FoodArt.mesh_node(FoodArt.finish(ab))
	_apron.visible = false
	body.add_child(_apron)
	arm_l = _arm(shirt, skin, -1.0)
	arm_r = _arm(shirt, skin, 1.0)
	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.55, 0)
	body.add_child(head)
	var hb := MB.new()
	hb.col(skin, 1.0, 0.1); hb.ellipsoid(0.15, 0.14, 0.14, 28, 16)
	for s in [-1.0, 1.0]:
		hb.col(skin); hb.at(Vector3(s * 0.148, -0.01, 0)); hb.ellipsoid(0.022, 0.03, 0.02, 10, 6); hb.pop()
	_hair(hb, style, hair)
	if acc == "critic" or acc == "beret":
		hb.col(Color("3B2340") if acc == "critic" else Color("E8504A"), 1.0, 0.3); hb.at(Vector3(0.01, 0.135, -0.01), Vector3(0.0, 0, 0.18)); hb.ellipsoid(0.15, 0.035, 0.14, 24, 8); hb.pop()
		hb.at(Vector3(0.03, 0.17, -0.01)); hb.sphere(0.016, 8, 6); hb.pop()
	if acc == "fox":
		# a festival fox mask worn on the side of the head
		hb.col(Color.WHITE, 1.0, 0.4); hb.at(Vector3(0.12, 0.09, 0.05), Vector3(0, 0.9, 0.3)); hb.ellipsoid(0.065, 0.06, 0.03, 14, 8); hb.pop()
		for s in [-1.0, 1.0]:
			hb.at(Vector3(0.12 + s * 0.0, 0.13, 0.05 + s * 0.035), Vector3(0, 0.9, 0.3)); hb.cone(0.02, 0.04, 6); hb.pop()
		hb.col(Color("E8404A"), 0.0); hb.at(Vector3(0.17, 0.09, 0.05)); hb.sphere(0.009, 6, 4); hb.pop()
	if acc == "bow":
		hb.col(Color("FF7EA6"), 1.0, 0.4)
		for s in [-1.0, 1.0]:
			hb.at(Vector3(0.07 + s * 0.03, 0.13, 0.02), Vector3(0, 0, s * 0.6)); hb.ellipsoid(0.03, 0.02, 0.012, 10, 6); hb.pop()
		hb.at(Vector3(0.07, 0.13, 0.02)); hb.sphere(0.012, 8, 6); hb.pop()
	if acc == "flower":
		hb.col(Color("FFD24A"), 0.6); hb.at(Vector3(-0.1, 0.1, 0.07)); hb.sphere(0.012, 8, 6); hb.pop()
		hb.col(Color("FFFFFF"), 0.8)
		for i in 5:
			var a := i * TAU / 5.0
			hb.at(Vector3(-0.1 + cos(a) * 0.02, 0.1 + sin(a) * 0.02, 0.068)); hb.sphere(0.012, 8, 6); hb.pop()
	if fem:
		# little eyelashes at the outer corners of the eyes
		hb.col(Color("3B2340"), 0.0)
		for s in [-1.0, 1.0]:
			for k in 2:
				var base := Vector3(s * (0.04 - k * 0.006), -0.009 + k * 0.004, 0.141)
				hb.tube(PackedVector3Array([base, base + Vector3(s * 0.006, 0.004, 0.003), base + Vector3(s * 0.014, 0.006 - k * 0.002, 0.004)]), 0.0024, 4)
	head.add_child(FoodArt.mesh_node(FoodArt.finish(hb)))
	if acc == "critic" or acc == "glasses":
		var gb := MB.new()
		gb.col(Color("3B2340"), 0.0, 0.8)
		for s in [-1.0, 1.0]:
			gb.at(Vector3(s * 0.032, -0.02, 0.15), Vector3(PI * 0.5, 0, 0)); gb.torus(0.024, 0.004, 20, 6); gb.pop()
		gb.tube(PackedVector3Array([Vector3(-0.009, -0.016, 0.152), Vector3(0.009, -0.016, 0.152)]), 0.003, 5)
		head.add_child(FoodArt.mesh_node(FoodArt.finish(gb)))
	# chef hat (shown at work)
	var cb := MB.new()
	cb.col(Color.WHITE, 1.0, 0.1)
	cb.at(Vector3(0, 0.13, -0.01)); cb.puck(0.1, 0.06, 0.02, 24); cb.pop()
	for p in [Vector3(0, 0.22, -0.01), Vector3(-0.055, 0.2, -0.01), Vector3(0.055, 0.2, -0.01), Vector3(0, 0.2, -0.06), Vector3(0, 0.2, 0.04)]:
		cb.at(p); cb.sphere(0.065, 14, 10); cb.pop()
	_hat = FoodArt.mesh_node(FoodArt.finish(cb))
	_hat.visible = false
	head.add_child(_hat)
	face = Face.new(3.6)
	face.position = Vector3(0, -0.02, 0.138)
	head.add_child(face)
	hold.position = Vector3(0, 0.36, 0.2)

func _leg(c: Color, skin: Color, s: float, bottom := "pants") -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(s * 0.05, 0.2, 0)
	var mb := MB.new()
	match bottom:
		"shorts":
			mb.col(c); mb.tube(PackedVector3Array([Vector3(0, 0.0, 0), Vector3(0, -0.07, 0)]), 0.037, 10)
			mb.col(skin); mb.tube(PackedVector3Array([Vector3(0, -0.06, 0), Vector3(0, -0.15, 0)]), 0.028, 10)
		"skirt", "dress":
			mb.col(skin); mb.tube(PackedVector3Array([Vector3(0, 0.0, 0), Vector3(0, -0.12, 0)]), 0.028, 10)
			mb.col(Color.WHITE, 1.0); mb.tube(PackedVector3Array([Vector3(0, -0.1, 0), Vector3(0, -0.15, 0)]), 0.03, 10)
		_:
			mb.col(c); mb.tube(PackedVector3Array([Vector3(0, 0.0, 0), Vector3(0, -0.15, 0)]), 0.033, 10)
	mb.col(Color("FFFFFF") if look.get("acc", "") != "critic" else Color("6A3E20"), 1.0, 0.3); mb.at(Vector3(0, -0.165, 0.02)); mb.ellipsoid(0.038, 0.03, 0.05, 12, 8); mb.pop()
	pivot.add_child(FoodArt.mesh_node(FoodArt.finish(mb)))
	body.add_child(pivot)
	return pivot

func _arm(shirt: Color, skin: Color, s: float) -> Node3D:
	var a := Node3D.new()
	a.position = Vector3(s * 0.1, 0.39, 0)
	var mb := MB.new()
	mb.col(shirt); mb.tube(PackedVector3Array([Vector3(0, 0, 0), Vector3(s * 0.04, -0.1, 0.02)]), 0.03, 10)
	mb.col(skin); mb.at(Vector3(s * 0.045, -0.13, 0.025)); mb.sphere(0.03, 10, 8); mb.pop()
	a.add_child(FoodArt.mesh_node(FoodArt.finish(mb)))
	body.add_child(a)
	return a

static func _sideburns(mb: MB) -> void:
	for s in [-1.0, 1.0]:
		mb.at(Vector3(s * 0.142, -0.015, 0.045), Vector3(0, 0, s * 0.15)); mb.ellipsoid(0.022, 0.05, 0.03, 10, 6); mb.pop()

static func _hair(mb: MB, style: String, c: Color) -> void:
	mb.col(c, 1.0, 0.35)
	# swept-back and textured styles that skip the usual fringe
	match style:
		"quiff":
			mb.at(Vector3(0, 0.035, -0.03)); mb.ellipsoid(0.155, 0.142, 0.138, 28, 16); mb.pop()
			mb.at(Vector3(0, 0.17, 0.05), Vector3(-0.6, 0, 0)); mb.ellipsoid(0.125, 0.075, 0.11, 20, 10); mb.pop()
			mb.at(Vector3(0.02, 0.21, 0.12), Vector3(-1.1, 0, 0.2)); mb.ellipsoid(0.08, 0.04, 0.07, 14, 8); mb.pop()
			_sideburns(mb)
			return
		"slick":
			mb.at(Vector3(0, 0.04, -0.035)); mb.ellipsoid(0.156, 0.142, 0.14, 28, 16); mb.pop()
			mb.at(Vector3(0, 0.115, 0.085), Vector3(-0.4, 0, 0)); mb.ellipsoid(0.115, 0.045, 0.055, 18, 8); mb.pop()
			_sideburns(mb)
			mb.col(c.lightened(0.35), 0.0, 0.9)
			for k in 4:
				var x := -0.06 + k * 0.04
				mb.tube(MB.spline3(PackedVector3Array([Vector3(x, 0.13, 0.07), Vector3(x * 1.1, 0.17, -0.02), Vector3(x * 1.2, 0.12, -0.13)]), 4), 0.004, 4)
			return
		"undercut":
			mb.col(c.darkened(0.25), 1.0, 0.2)
			mb.at(Vector3(0, 0.03, -0.02)); mb.ellipsoid(0.153, 0.138, 0.14, 28, 16); mb.pop()
			mb.col(c, 1.0, 0.35)
			mb.at(Vector3(0.02, 0.14, 0.0), Vector3(0, 0, -0.25)); mb.ellipsoid(0.13, 0.06, 0.13, 22, 10); mb.pop()
			mb.at(Vector3(0.07, 0.11, 0.09), Vector3(-0.3, 0, -0.6)); mb.ellipsoid(0.08, 0.03, 0.06, 14, 8); mb.pop()
			return
		"manbun":
			mb.at(Vector3(0, 0.035, -0.035)); mb.ellipsoid(0.157, 0.145, 0.14, 28, 16); mb.pop()
			mb.at(Vector3(0, 0.16, -0.12)); mb.sphere(0.06, 14, 10); mb.pop()
			mb.at(Vector3(0, 0.11, 0.085), Vector3(-0.4, 0, 0)); mb.ellipsoid(0.11, 0.04, 0.05, 18, 8); mb.pop()
			_sideburns(mb)
			mb.col(Color("3B2340")); mb.at(Vector3(0, 0.11, -0.12), Vector3(0.6, 0, 0)); mb.torus(0.035, 0.007, 14, 6); mb.pop(); mb.col(c)
			for s in [-1.0, 1.0]:
				mb.tube(MB.spline3(PackedVector3Array([Vector3(s * 0.07, 0.1, 0.11), Vector3(s * 0.12, 0.02, 0.1), Vector3(s * 0.13, -0.06, 0.07)]), 4), 0.008, 5)
			return
		"dreads":
			mb.at(Vector3(0, 0.035, -0.03)); mb.ellipsoid(0.158, 0.146, 0.14, 28, 16); mb.pop()
			for i in 16:
				var a := -2.3 + i * 0.31
				var top := Vector3(sin(a) * 0.14, 0.08 + cos(a * 0.5) * 0.04, cos(a) * 0.12 - 0.03)
				if top.z > 0.06 and absf(top.x) < 0.09: continue
				mb.tube(PackedVector3Array([top, top + Vector3(sin(a) * 0.04, -0.18 - (i % 3) * 0.03, 0)]), 0.014, 6)
			for i in 5:
				mb.at(Vector3(-0.08 + i * 0.04, 0.1, 0.11)); mb.sphere(0.022, 8, 6); mb.pop()
			return
	# close-cropped styles: a snug cap with no fringe
	if style == "buzz" or style == "mohawk":
		mb.col(c.darkened(0.08) if style == "mohawk" else c, 1.0, 0.25)
		mb.at(Vector3(0, 0.035, -0.02)); mb.ellipsoid(0.153, 0.14, 0.14, 28, 16); mb.pop()
		if style == "mohawk":
			mb.col(c, 1.0, 0.35)
			for i in 8:
				var a := -0.35 + i * 0.32
				mb.at(Vector3(0, 0.035 + cos(a) * 0.15, -0.02 + sin(a) * 0.15), Vector3(a, 0, 0)); mb.cone(0.028, 0.085, 8); mb.pop()
		return
	mb.at(Vector3(0, 0.03, -0.035)); mb.ellipsoid(0.16, 0.15, 0.135, 28, 16); mb.pop()
	if style == "afro":
		for i in 26:
			var a := i * 2.399
			var y := 0.21 - (i / 25.0) * 0.27
			var rr := sqrt(maxf(0.0, 1.0 - pow((y - 0.06) / 0.2, 2.0))) * 0.19 + 0.02
			var p := Vector3(cos(a) * rr, y, sin(a) * rr - 0.03)
			if p.z > 0.07 and p.y < 0.1: continue
			mb.at(p); mb.sphere(0.06, 10, 8); mb.pop()
		for i in 5:
			mb.at(Vector3(-0.08 + i * 0.04, 0.1, 0.1)); mb.sphere(0.035, 8, 6); mb.pop()
		return
	if style == "pixie" or style == "sidepart":
		# swept fringe instead of straight bangs
		for i in 6:
			var x := -0.1 + i * 0.04
			mb.at(Vector3(x, 0.085 - i * 0.004, 0.105 - absf(x) * 0.25), Vector3(-0.5, 0.0, -0.9)); mb.ellipsoid(0.026, 0.05, 0.02, 12, 8); mb.pop()
		if style == "sidepart":
			mb.at(Vector3(-0.07, 0.13, 0.04), Vector3(0.2, 0, 0.5)); mb.ellipsoid(0.11, 0.05, 0.1, 18, 10); mb.pop()
		else:
			for s in [-1.0, 1.0]:
				mb.at(Vector3(s * 0.135, -0.02, 0.03), Vector3(0, 0, s * 0.2)); mb.ellipsoid(0.03, 0.06, 0.04, 10, 8); mb.pop()
			mb.at(Vector3(0.03, 0.17, -0.02), Vector3(0, 0, -0.6)); mb.cone(0.03, 0.07, 8); mb.pop()
		return
	if style == "bowl":
		mb.at(Vector3(0, 0.07, 0.04)); mb.ellipsoid(0.165, 0.07, 0.11, 28, 10); mb.pop()
		for s in [-1.0, 1.0]:
			mb.at(Vector3(s * 0.14, 0.0, 0.0)); mb.ellipsoid(0.035, 0.08, 0.08, 12, 8); mb.pop()
		return
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
		"spiky":
			for i in 9:
				var a := -1.2 + i * 0.3
				mb.at(Vector3(sin(a) * 0.13, 0.1 + cos(a) * 0.04, -0.03 - (i % 2) * 0.03), Vector3(-0.3, 0, -a * 0.9)); mb.cone(0.04, 0.1, 8); mb.pop()
		"braid":
			var pts: Array = []
			for i in 7:
				pts.append(Vector3(0.14 + i * 0.006, 0.0 - i * 0.035, 0.03 + sin(i * 1.3) * 0.006))
			for i in pts.size():
				mb.at(pts[i]); mb.sphere(0.03 - i * 0.0015, 10, 8); mb.pop()
			mb.col(Color("FF7EA6")); mb.at(pts.back() + Vector3(0, -0.02, 0)); mb.torus(0.018, 0.008, 12, 6); mb.pop(); mb.col(c)
			mb.at(Vector3(0, -0.04, -0.07)); mb.ellipsoid(0.15, 0.12, 0.1, 20, 10); mb.pop()
		"topknot":
			mb.at(Vector3(0, 0.185, -0.03)); mb.sphere(0.062, 16, 10); mb.pop()
			mb.col(Color("FFD24A")); mb.at(Vector3(0, 0.14, -0.03)); mb.torus(0.04, 0.009, 16, 6); mb.pop(); mb.col(c)
		"wavy":
			mb.at(Vector3(0, -0.06, -0.06)); mb.ellipsoid(0.165, 0.15, 0.11, 22, 12); mb.pop()
			for i in 9:
				var a := -1.4 + i * 0.35
				var base := Vector3(sin(a) * 0.15, -0.02, cos(a) * 0.1 - 0.06)
				var wp := PackedVector3Array()
				for k in 6:
					wp.append(base + Vector3(sin(k * 1.4 + i) * 0.015, -k * 0.035, 0))
				mb.tube(MB.spline3(wp, 3), func(t: float) -> float: return 0.03 * (1.0 - t * 0.5), 10)
		"drills":
			for s in [-1.0, 1.0]:
				var hp := PackedVector3Array()
				for k in 30:
					var a := k * 0.6
					hp.append(Vector3(s * 0.16 + cos(a) * 0.03, 0.02 - k * 0.008, -0.02 + sin(a) * 0.03))
				mb.tube(hp, func(t: float) -> float: return 0.028 * (1.0 - t * 0.55), 8)
				mb.col(Color("FF7EA6")); mb.at(Vector3(s * 0.15, 0.06, -0.03)); mb.sphere(0.024, 8, 6); mb.pop(); mb.col(c)
		"messy":
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			for i in 12:
				var a := rng.randf() * TAU
				var el := rng.randf_range(0.2, 1.2)
				var dir := Vector3(cos(a) * sin(el), cos(el), sin(a) * sin(el))
				mb.at(Vector3(0, 0.03, -0.03) + dir * 0.15, Vector3(-dir.z * 1.2, 0, dir.x * 1.2)); mb.cone(0.03, 0.08, 8); mb.pop()
		"curtains":
			for s in [-1.0, 1.0]:
				mb.at(Vector3(s * 0.06, 0.06, 0.1), Vector3(-0.3, 0, s * 0.7)); mb.ellipsoid(0.07, 0.05, 0.03, 14, 8); mb.pop()
			mb.at(Vector3(0, 0.0, -0.08)); mb.ellipsoid(0.15, 0.12, 0.09, 20, 10); mb.pop()
		"wolf":
			for i in 7:
				var a := -1.2 + i * 0.4
				mb.at(Vector3(sin(a) * 0.13, -0.06, cos(a) * 0.06 - 0.11), Vector3(0.3, 0, -a * 0.4)); mb.cone(0.035, 0.1, 8); mb.pop()
			for s in [-1.0, 1.0]:
				mb.at(Vector3(s * 0.14, -0.02, 0.02), Vector3(0, 0, s * 0.25)); mb.ellipsoid(0.035, 0.08, 0.05, 10, 8); mb.pop()
		"curly":
			for i in 14:
				var a := i * TAU / 14.0
				mb.at(Vector3(cos(a) * 0.14, 0.05 + sin(a * 2.0) * 0.03, sin(a) * 0.11 - 0.03)); mb.sphere(0.045, 10, 8); mb.pop()
			mb.at(Vector3(0, 0.15, -0.02)); mb.sphere(0.07, 12, 8); mb.pop()
		_:
			for s in [-1.0, 1.0]:
				mb.at(Vector3(s * 0.135, -0.03, 0.01)); mb.ellipsoid(0.04, 0.09, 0.06, 12, 8); mb.pop()

func _build_cat() -> void:
	var c := _c(look.get("hair"), Color("FFB86A"))
	var mb := MB.new()
	mb.col(c, 1.0, 0.1); mb.at(Vector3(0, 0.12, 0)); mb.ellipsoid(0.11, 0.12, 0.13, 22, 12); mb.pop()
	mb.col(Color("FFF2E0")); mb.at(Vector3(0, 0.1, 0.07)); mb.ellipsoid(0.07, 0.08, 0.06, 16, 10); mb.pop()
	for s in [-1.0, 1.0]:
		mb.col(c); mb.at(Vector3(s * 0.06, 0.02, 0.07)); mb.ellipsoid(0.03, 0.025, 0.04, 10, 6); mb.pop()
	mb.col(c); mb.tube(MB.spline3(PackedVector3Array([Vector3(0, 0.06, -0.12), Vector3(0.08, 0.1, -0.2), Vector3(0.1, 0.25, -0.18)]), 4), func(t: float) -> float: return 0.025 * (1.0 - t * 0.4), 10)
	body.add_child(FoodArt.mesh_node(FoodArt.finish(mb)))
	head = Node3D.new()
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
	head.add_child(FoodArt.mesh_node(FoodArt.finish(hb)))
	face = Face.new(2.6)
	face.position = Vector3(0, -0.005, 0.098)
	head.add_child(face)
	arm_l = Node3D.new(); arm_r = Node3D.new(); leg_l = Node3D.new(); leg_r = Node3D.new()
	for n in [arm_l, arm_r, leg_l, leg_r]: body.add_child(n)
	hold.position = Vector3(0, 0.25, 0.16)

# ---------------------------------------------------------------- outfit toggles
const HAT_FIT := {"afro": [0.075, 1.3], "topknot": [0.06, 1.05], "manbun": [0.03, 1.08], "mohawk": [0.05, 1.05], "buns": [0.02, 1.15], "curly": [0.04, 1.12],
	"quiff": [0.05, 1.1], "dreads": [0.02, 1.08], "messy": [0.03, 1.08], "spiky": [0.03, 1.08], "short": [0.02, 1.04], "undercut": [0.04, 1.05], "drills": [0.0, 1.06]}

func set_work_clothes(on: bool) -> void:
	if _apron: _apron.visible = on
	if _hat:
		_hat.visible = on
		var fit: Array = HAT_FIT.get(String(look.get("style", "")), [0.0, 1.0])
		_hat.position = Vector3(0, float(fit[0]), 0)
		_hat.scale = Vector3.ONE * float(fit[1])

func feel(m: String, hold_t := 2.5) -> void:
	if face: face.set_mood(m, hold_t)

func wave() -> void:
	_wave_t = 1.2

func set_eating(on: bool) -> void:
	_eat = on

func carry(n: Node3D) -> void:
	drop()
	carried = n
	if n:
		if n.get_parent(): n.get_parent().remove_child(n)
		hold.add_child(n)
		n.position = Vector3.ZERO
		n.rotation = Vector3.ZERO
		n.scale = Vector3.ONE * 0.8

func drop() -> Node3D:
	var n := carried
	carried = null
	if n and n.get_parent() == hold: hold.remove_child(n)
	return n

# ---------------------------------------------------------------- movement
func walk_path(p: PackedVector3Array) -> void:
	path = p
	walking = path.size() > 0
	if walking: sitting = false

func walk_to(target: Vector3, nav: NavGrid = null) -> void:
	walk_path(nav.path(global_position, target) if nav else PackedVector3Array([target]))

func stop() -> void:
	path = PackedVector3Array()
	walking = false

func sit_at(pos: Vector3, yaw: float, height: float) -> void:
	stop()
	global_position = Vector3(pos.x, height, pos.z)
	rotation.y = yaw
	sitting = true
	sit_height = height

func stand_up() -> void:
	sitting = false
	position.y = floor_y

func tick(dt: float, clock: float) -> void:
	if walking and path.size():
		var target: Vector3 = path[0]
		var d := target - global_position
		d.y = 0
		if d.length() < 0.04:
			global_position = Vector3(target.x, global_position.y, target.z)
			path.remove_at(0)
			if path.is_empty():
				walking = false
				arrived.emit()
		else:
			global_position += d.normalized() * minf(d.length(), speed * dt)
			rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), minf(1.0, dt * 12.0))
	if not sitting:
		global_position.y = lerpf(global_position.y, floor_y, minf(1.0, dt * 12.0))
	_animate(dt, clock)

func _animate(dt: float, clock: float) -> void:
	var k := minf(1.0, dt * 10.0)
	if walking:
		_walk_t += dt * speed * 7.5
		var w := sin(_walk_t)
		body.position.y = absf(w) * 0.025
		body.rotation.z = w * 0.05
		if leg_l: leg_l.rotation.x = w * 0.7
		if leg_r: leg_r.rotation.x = -w * 0.7
		if carried == null:
			if arm_l: arm_l.rotation.x = -w * 0.6
			if arm_r: arm_r.rotation.x = w * 0.6
	else:
		body.position.y = sin(clock * 1.6 + bob) * 0.004
		body.rotation.z = lerpf(body.rotation.z, 0.0, k)
		var leg_target := -1.35 if sitting else 0.0
		if leg_l: leg_l.rotation.x = lerpf(leg_l.rotation.x, leg_target, k)
		if leg_r: leg_r.rotation.x = lerpf(leg_r.rotation.x, leg_target, k)
		if carried == null and arm_l and arm_r:
			var al := 0.0
			var ar := 0.0
			var arz := 0.0
			if _eat:
				ar = -1.2 if fmod(clock, 0.6) < 0.3 else -0.6
			elif _wave_t > 0.0:
				_wave_t -= dt
				ar = -2.7
				arz = 0.35 + sin(clock * 14.0) * 0.3
			arm_l.rotation.x = lerpf(arm_l.rotation.x, al, k)
			arm_r.rotation.x = lerpf(arm_r.rotation.x, ar, k)
			arm_r.rotation.z = lerpf(arm_r.rotation.z, arz, k)
	if carried and arm_l and arm_r:
		arm_l.rotation.x = lerpf(arm_l.rotation.x, -1.3, k)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -1.3, k)
