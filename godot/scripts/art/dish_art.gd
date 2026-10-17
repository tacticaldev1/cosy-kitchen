## 3D dishes. build(mb, spec) draws any food spec (from G.recipe_spec / G.generic_spec)
## centred on the origin, sitting on y=0, at most ~25 cm across. Mirrors the 2D ART table.
class_name DishArt
extends RefCounted

const WHITE := Color("FFFFFF")
const PLATE_LO := Color("E2E6F7")
const RIM := Color("8C9BE0")
const SYRUP := Color("B4642A")
const CHOC := Color("5A2E1E")
const CREAM := Color("FFFDF6")
const PLUM := Color("3B2340")
const GOLD := Color("EBB25A")
## When true, tableware (plates, boards, bowl shells, glasses) is skipped: used for food
## previews sitting inside pans, pots and ovens.
static var bare := false
## Plates are drawn a little smaller than their nominal size so food fills them nicely.
const PLATE_K := 0.84

const NOT_GARNISH := ["sugar", "flour", "milk", "ice", "soy", "curry", "rice", "nori", "noodles", "pasta", "oats", "kernels", "bread", "tortilla", "coffee", "cream", "yogurt", "caramel"]

static func _has(sp: Dictionary, k: String) -> bool:
	return sp.get("ings", {}).has(k)

static func _extras(sp: Dictionary, skip: Array = []) -> Array:
	var out: Array = []
	for k in sp.get("ings", {}).keys():
		if not NOT_GARNISH.has(k) and not skip.has(k) and G.ING.has(k):
			out.append(k)
	return out

static func _rng(seed_: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_
	return r

# ======================================================================= tableware
## White plate with the dashed periwinkle rim. Returns the height of the plate's well.
static func plate(mb: MB, r := 0.105, rim := RIM) -> float:
	if bare: return 0.0
	r *= PLATE_K
	var pr := MB.spline(PackedVector2Array([Vector2(0, 0.0035), Vector2(r * 0.42, 0.002), Vector2(r * 0.47, 0.0), Vector2(r * 0.52, 0.003),
		Vector2(r * 0.8, 0.009), Vector2(r * 0.97, 0.015), Vector2(r * 1.0, 0.0185), Vector2(r * 0.96, 0.0205), Vector2(r * 0.8, 0.0145),
		Vector2(r * 0.7, 0.0095), Vector2(r * 0.35, 0.0085), Vector2(0, 0.0085)]), 3)
	mb.col(WHITE, 1.0, 0.35)
	mb.lathe(pr, 44, Callable(), func(u: float, _v: float, p: Vector3) -> Color:
		var rr := Vector2(p.x, p.z).length()
		if p.y > 0.0135 and rr > r * 0.82 and rr < r * 0.93 and fposmod(u * 34.0, 1.0) < 0.55:
			return rim
		return WHITE.lerp(PLATE_LO, clampf(rr / r, 0.0, 1.0) * 0.45), 34)
	return 0.0085

## Wooden serving board (geta). Returns its top height.
static func board(mb: MB, w := 0.2, d := 0.09) -> float:
	if bare: return 0.0
	mb.col(Color("9A6436"))
	for sx in [-w * 0.33, w * 0.33]:
		mb.at(Vector3(sx, 0.006, 0)); mb.rbox(Vector3(0.016, 0.012, d * 0.9), 0.003, 1); mb.pop()
	mb.col(Color("E8B87A"), 1.0, 0.1)
	mb.at(Vector3(0, 0.017, 0)); mb.rbox(Vector3(w, 0.012, d), 0.004, 2); mb.pop()
	mb.col(Color("C88A50"), 0.0)
	for i in 4:
		var z := -d * 0.35 + i * d * 0.23
		mb.tube(PackedVector3Array([Vector3(-w * 0.45, 0.0232, z), Vector3(-w * 0.1, 0.0232, z + 0.003), Vector3(w * 0.45, 0.0232, z - 0.002)]), 0.0007, 4)
	mb.outline = 1.0
	return 0.023

## A bowl. Returns [fill_y, fill_r] for the contents surface.
static func bowl(mb: MB, r := 0.078, h := 0.06, c1 := WHITE, c2 := Color("D6DCF2"), band := Color("7C8AD6"), pattern := "wave", fill := 0.8) -> Array:
	var t := 0.0055
	if bare:
		return [0.012, r * 0.8]
	var outer := MB.spline(PackedVector2Array([Vector2(0, 0.0015), Vector2(r * 0.3, 0.0), Vector2(r * 0.34, 0.007), Vector2(r * 0.46, 0.011), Vector2(r * 0.8, h * 0.42), Vector2(r * 0.97, h * 0.82), Vector2(r, h)]), 4)
	var inner := MB.spline(PackedVector2Array([Vector2(r - t, h), Vector2(r * 0.96 - t, h * 0.8), Vector2(r * 0.78 - t, h * 0.42), Vector2(r * 0.42, 0.016), Vector2(0, 0.014)]), 4)
	var prof := PackedVector2Array(outer)
	prof.append(Vector2(r - t * 0.2, h + t * 0.4))
	prof.append(Vector2(r - t * 0.8, h + t * 0.4))
	for i in range(0, inner.size()):
		prof.append(inner[i])
	var outer_len := 0.0
	for i in range(1, outer.size()): outer_len += outer[i].distance_to(outer[i - 1])
	var tot := 0.0
	for i in range(1, prof.size()): tot += prof[i].distance_to(prof[i - 1])
	var vs := outer_len / tot
	var inner_c := c1.lightened(0.25) if c1.get_luminance() < 0.5 else Color("F6F7FF")
	mb.col(c1, 1.0, 0.4)
	mb.lathe(prof, 40, Callable(), func(u: float, v: float, p: Vector3) -> Color:
		if v > vs + 0.03:
			return inner_c
		var y := p.y
		var base := c1.lerp(c2, clampf(1.0 - y / h, 0.0, 1.0) * 0.8)
		match pattern:
			"stripe":
				if absf(y - h * 0.62) < 0.0032 or absf(y - h * 0.5) < 0.0013: return band
			"wave":
				if absf(y - (h * 0.58 + 0.0035 * sin(u * TAU * 16.0))) < 0.0022: return band
			"dots":
				var rr := Vector2(p.x, p.z).length()
				var arc := (fposmod(u * 22.0, 1.0) - 0.5) * TAU * rr / 22.0
				if Vector2(arc, y - h * 0.6).length() < 0.0036: return band
		return base, 34)
	var fy := 0.014 + (h - 0.014) * fill
	var fr := r * 0.42
	for i in range(1, inner.size()):
		if inner[i].y <= fy:
			var a := inner[i - 1]; var b := inner[i]
			fr = lerpf(a.x, b.x, clampf((a.y - fy) / maxf(a.y - b.y, 1e-6), 0.0, 1.0))
			break
	return [fy, fr - 0.0008]

## Flat, slightly domed contents surface (soup, rice, batter).
static func disc(mb: MB, y: float, r: float, c: Color, color_fn: Callable = Callable(), dome := 0.002, ol := 0.5) -> void:
	mb.col(c, ol, 0.25)
	mb.lathe(PackedVector2Array([Vector2(0, y - 0.004), Vector2(r * 0.9, y - 0.004), Vector2(r, y - 0.0015), Vector2(r * 0.97, y), Vector2(r * 0.6, y + dome * 0.6), Vector2(0, y + dome)]), 36, Callable(), color_fn, 10)
	mb.outline = 1.0

static func glass_cup(mb: MB, rb: float, rt: float, h: float, base := 0.008) -> void:
	mb.layer(1)
	mb.lathe(PackedVector2Array([Vector2(0, 0.0), Vector2(rb, 0.0), Vector2(rb + 0.001, 0.002), Vector2(rt, h), Vector2(rt - 0.0025, h), Vector2(rb - 0.0025, base), Vector2(0, base)]), 36, Callable(), Callable(), 12)
	mb.layer(0)
	# opaque lip ring so the rim reads crisply
	mb.col(Color("EAF4FF"), 0.7, 0.6); mb.at(Vector3(0, h - 0.001, 0)); mb.torus(rt - 0.0012, 0.0016, 40, 6); mb.pop()
	mb.outline = 1.0

static func straw(mb: MB, base: Vector3, tip: Vector3, c := Color("FF7EA6")) -> void:
	mb.col(WHITE, 1.0, 0.3)
	var axis := (tip - base)
	mb.tube(PackedVector3Array([base, base + axis * 0.5, tip]), 0.0042, 10, func(_u: float, v: float, _p: Vector3) -> Color:
		return c if fposmod(v * 9.0, 1.0) < 0.5 else WHITE)

## Squiggly line of sauce lying on a surface.
static func zigzag(mb: MB, c: Color, center: Vector3, w: float, d: float, n := 5, r := 0.0022, gloss := 0.8) -> void:
	var pts := PackedVector3Array()
	for i in n * 2 + 1:
		var t := float(i) / (n * 2)
		pts.append(center + Vector3(-w * 0.5 + w * t, 0.0, (d * 0.5) * (1.0 if i % 2 else -1.0)))
	mb.col(c, 0.5, gloss)
	mb.tube(MB.spline3(pts, 4), r, 7, Callable(), 0.55, Vector3.UP)
	mb.outline = 1.0

## Glossy puddle with drips over an edge (syrup, honey, caramel, chocolate).
static func drip_pool(mb: MB, c: Color, center: Vector3, r: float, edge_r: float, drips := 4, seed_ := 1, drip_len := 0.02) -> void:
	mb.col(c, 0.6, 1.0)
	mb.at(center); mb.lathe(PackedVector2Array([Vector2(0, -0.0012), Vector2(r, -0.0012), Vector2(r * 1.02, 0.0004), Vector2(r * 0.8, 0.0022), Vector2(0, 0.0028)]), 30,
		func(u: float, _v: float) -> float: return 1.0 + 0.12 * sin(u * TAU * 5.0 + seed_), Callable(), 6); mb.pop()
	var rng := _rng(seed_)
	for i in drips:
		var a := rng.randf() * TAU
		var top := center + Vector3(cos(a) * edge_r, 0.0, sin(a) * edge_r)
		var len := drip_len * rng.randf_range(0.5, 1.2)
		mb.tube(PackedVector3Array([top + Vector3(cos(a), 0, sin(a)) * -0.004, top + Vector3(cos(a), 0, sin(a)) * 0.0015 + Vector3(0, -len * 0.4, 0), top + Vector3(cos(a), 0, sin(a)) * 0.002 + Vector3(0, -len, 0)]),
			func(t: float) -> float: return 0.0028 * (1.0 - t * 0.35), 7)
		mb.at(top + Vector3(cos(a), 0, sin(a)) * 0.002 + Vector3(0, -len, 0)); mb.sphere(0.0034, 8, 6); mb.pop()
	mb.outline = 1.0

static func cream_swirl(mb: MB, pos: Vector3, r := 0.02, h := 0.03, c := CREAM, turns := 2.6) -> void:
	var pts := PackedVector3Array()
	var n := 40
	for i in n + 1:
		var t := float(i) / n
		var a := t * TAU * turns
		var rr := r * (1.0 - t * 0.9)
		pts.append(pos + Vector3(cos(a) * rr * 0.7, t * h * 0.82, sin(a) * rr * 0.7))
	mb.col(c, 1.0, 0.3)
	mb.tube(pts, func(t: float) -> float: return r * 0.42 * (1.0 - t * 0.55) * (0.5 + 0.5 * sqrt(clampf(t * 12.0, 0.0, 1.0))) + 0.001, 10)
	mb.at(pos + Vector3(0, h * 0.84, 0)); mb.cone(r * 0.2, h * 0.16, 10); mb.pop()

## Kawaii face made of geometry, facing +z. s≈1 is about 3 cm wide.
static func face(mb: MB, pos: Vector3, s := 1.0, mood := "happy", yaw := 0.0) -> void:
	mb.push(Transform3D(Basis.from_euler(Vector3(0, yaw, 0)).scaled(Vector3(s, s, s)), pos))
	for k in [-1.0, 1.0]:
		var ex: float = k * 0.0085
		if mood == "happy":
			mb.col(PLUM, 0.0)
			var arc := PackedVector3Array()
			for i in 7:
				var a := PI * (1.15 + 0.7 * i / 6.0)
				arc.append(Vector3(ex + cos(a) * 0.0032, 0.0018 + sin(a) * -0.0032, 0.0))
			mb.tube(arc, 0.0008, 5)
		else:
			mb.col(PLUM, 0.0); mb.at(Vector3(ex, 0, 0)); mb.ellipsoid(0.0026, 0.0034, 0.0012, 10, 6); mb.pop()
			mb.col(WHITE, 0.0); mb.at(Vector3(ex - 0.001, 0.0012, 0.0011)); mb.sphere(0.0009, 6, 4); mb.pop()
		mb.col(Color("FF8FB0"), 0.0); mb.at(Vector3(k * 0.0145, -0.004, -0.0002)); mb.ellipsoid(0.004, 0.0024, 0.0008, 10, 4); mb.pop()
	mb.col(Color("C2415E"), 0.0)
	var m := PackedVector3Array()
	for i in 7:
		var a := PI * (0.12 + 0.76 * i / 6.0)
		m.append(Vector3(cos(a) * 0.003, -0.0035 - sin(a) * 0.0026, 0.0003))
	mb.tube(m, 0.0008, 5)
	mb.pop()
	mb.outline = 1.0

# ======================================================================= garnishes
static func garnish(mb: MB, k: String, pos: Vector3, s := 1.0, yaw := 0.0) -> void:
	mb.push(Transform3D(Basis.from_euler(Vector3(0, yaw, 0)).scaled(Vector3(s, s, s)), pos))
	match k:
		"strawberry":
			var pr := MB.spline(PackedVector2Array([Vector2(0, 0), Vector2(0.005, 0.003), Vector2(0.0105, 0.011), Vector2(0.0115, 0.017), Vector2(0.008, 0.021), Vector2(0, 0.02)]), 4)
			mb.col(Color("F0475E"), 1.0, 0.7); mb.at(Vector3.ZERO, Vector3(0.5, 0, 0)); mb.lathe(pr, 16, Callable(), func(_u: float, v: float, _p: Vector3) -> Color: return Color("D92A44").lerp(Color("FF7A8A"), v))
			mb.col(Color("5DB04B"), 0.6, 0.0)
			for i in 4:
				mb.at(Vector3(0, 0.02, 0), Vector3(0.4, i * TAU / 4.0, 0)); mb.at(Vector3(0, 0, 0.004)); mb.ellipsoid(0.0022, 0.0008, 0.0045, 6, 3); mb.pop(); mb.pop()
			mb.pop()
		"blueberry":
			mb.col(Color("4A58C0"), 1.0, 0.5); mb.at(Vector3(0, 0.0062, 0)); mb.sphere(0.0065, 12, 8, func(_u: float, v: float, _p: Vector3) -> Color: return Color("34429A").lerp(Color("8C9BFF"), v * 0.8)); mb.pop()
			mb.col(Color("26307A"), 0.0); mb.at(Vector3(0, 0.0125, 0)); mb.ellipsoid(0.0022, 0.0006, 0.0022, 6, 3); mb.pop()
		"banana":
			mb.col(Color("FFF6D6"), 1.0, 0.1); mb.puck(0.0095, 0.0045, 0.0016, 16)
			mb.col(Color("C8A060"), 0.0)
			for i in 5:
				var a := i * TAU / 5.0
				mb.at(Vector3(cos(a) * 0.003, 0.0046, sin(a) * 0.003)); mb.sphere(0.0007, 4, 3); mb.pop()
		"cherry":
			mb.col(Color("D81E3A"), 1.0, 1.0); mb.at(Vector3(0, 0.0075, 0)); mb.sphere(0.0078, 14, 10, func(_u: float, v: float, _p: Vector3) -> Color: return Color("B8102E").lerp(Color("FF5A72"), v)); mb.pop()
			mb.col(Color("5A8A3A"), 0.7, 0.0); mb.tube(MB.spline3(PackedVector3Array([Vector3(0, 0.014, 0), Vector3(0.002, 0.022, 0), Vector3(0.007, 0.028, 0)]), 3), 0.0011, 5)
		"chocolate":
			mb.col(Color("6B3A26"), 0.8, 0.4)
			for p in [Vector3(-0.006, 0, 0.002), Vector3(0.005, 0, -0.003), Vector3(0.001, 0, 0.006)]:
				mb.at(p); mb.cone(0.0035, 0.0055, 8); mb.pop()
		"cream":
			cream_swirl(mb, Vector3.ZERO, 0.011, 0.016)
		"butter":
			mb.col(Color("FFE58A"), 0.4, 0.8); mb.at(Vector3(0, 0.0008, 0)); mb.ellipsoid(0.011, 0.0012, 0.009, 14, 4); mb.pop()
			mb.col(Color("FFF0A0"), 1.0, 0.6); mb.at(Vector3(0, 0.0055, 0), Vector3(0, 0.3, 0)); mb.rbox(Vector3(0.012, 0.009, 0.011), 0.0025, 2); mb.pop()
		"mushroom":
			mb.col(Color("F6E6D2")); mb.at(Vector3(0, 0.002, 0)); mb.rbox(Vector3(0.004, 0.004, 0.009), 0.0015, 1); mb.pop()
			mb.col(Color("A8714A")); mb.at(Vector3(0, 0.002, 0)); mb.lathe(PackedVector2Array([Vector2(0, 0.0), Vector2(0.009, 0.0), Vector2(0.0095, 0.002), Vector2(0.006, 0.006), Vector2(0, 0.007)]), 14); mb.pop()
		"tomato":
			mb.col(Color("E8402E"), 1.0, 0.5); mb.puck(0.0095, 0.0045, 0.0015, 16)
			mb.col(Color("FF9A80"), 0.0); mb.at(Vector3(0, 0.0002, 0)); mb.puck(0.0072, 0.0047, 0.001, 14); mb.pop()
			mb.col(Color("FFE6B0"), 0.0)
			for i in 3:
				var a := i * TAU / 3.0
				mb.at(Vector3(cos(a) * 0.0034, 0.0049, sin(a) * 0.0034)); mb.ellipsoid(0.0016, 0.0005, 0.001, 6, 3); mb.pop()
		"cucumber":
			mb.col(Color("3E8E48")); mb.puck(0.0095, 0.004, 0.0014, 16)
			mb.col(Color("D8F2C2"), 0.0); mb.at(Vector3(0, 0.0002, 0)); mb.puck(0.0078, 0.0042, 0.001, 14); mb.pop()
		"carrot":
			mb.col(Color("FF8A2B"), 1.0, 0.2); mb.puck(0.0085, 0.004, 0.0014, 14)
			mb.col(Color("FFC48A"), 0.0); mb.at(Vector3(0, 0.0002, 0)); mb.puck(0.004, 0.0042, 0.001, 10); mb.pop()
		"corn":
			mb.col(Color("FFD24A"), 0.6, 0.4)
			for p in [Vector3(-0.004, 0.0028, 0), Vector3(0.004, 0.0028, 0.001), Vector3(0, 0.0028, -0.004), Vector3(0.001, 0.0028, 0.004)]:
				mb.at(p); mb.ellipsoid(0.0032, 0.0028, 0.003, 8, 5); mb.pop()
		"spinach", "lettuce", "cabbage":
			mb.col(Color("3F8A4A") if k == "spinach" else Color("8ED16B") if k == "lettuce" else Color("BFE6A0"))
			mb.at(Vector3(0, 0.003, 0)); mb.leaf(0.012, 0.008, 0.0016, 0.5, 0.3 if k == "lettuce" else 0.0); mb.pop()
		"egg":
			mb.col(WHITE); mb.at(Vector3(0, 0.0005, 0)); mb.ellipsoid(0.012, 0.007, 0.009, 16, 8); mb.pop()
			mb.col(Color("FFA12E"), 0.6, 0.7); mb.at(Vector3(0, 0.0062, 0)); mb.ellipsoid(0.0062, 0.0018, 0.0056, 12, 5); mb.pop()
		"bacon":
			var pts := PackedVector3Array()
			for i in 6: pts.append(Vector3(-0.012 + i * 0.0048, 0.003 + (0.0015 if i % 2 else -0.0005), 0))
			mb.tube(pts, 0.0045, 8, func(u: float, _v: float, _p: Vector3) -> Color: return Color("F2C8C0") if absf(sin(u * TAU)) < 0.3 else Color("B8434E"), 0.32, Vector3.UP)
		"cheese":
			mb.col(Color("FFD54A"), 0.6, 0.2)
			for p in [[Vector3(-0.004, 0.001, 0), 0.5], [Vector3(0.004, 0.0018, -0.002), -0.3], [Vector3(0.0, 0.0024, 0.004), 0.9]]:
				mb.at(p[0], Vector3(0, p[1], 0)); mb.rbox(Vector3(0.011, 0.0026, 0.0028), 0.0011, 1); mb.pop()
		"onion":
			mb.col(Color("6BBF59"), 0.5)
			for p in [Vector3(-0.004, 0.0012, -0.001), Vector3(0.003, 0.0012, -0.003), Vector3(0.002, 0.0012, 0.003)]:
				mb.at(p); mb.torus(0.0026, 0.0011, 10, 5); mb.pop()
		"pepper":
			var arc := PackedVector3Array()
			for i in 7:
				var a := PI * (1.1 + 0.8 * i / 6.0)
				arc.append(Vector3(cos(a) * 0.009, 0.0025, sin(a) * 0.009 + 0.006))
			mb.col(Color("E8402E"), 1.0, 0.6); mb.tube(arc, 0.0024, 7, Callable(), 0.6, Vector3.UP)
		"avocado":
			for i in 3:
				mb.at(Vector3(-0.004 + i * 0.004, 0.003, 0), Vector3(0, -0.3 + i * 0.3, 0))
				mb.col(Color("B8DC7A")); mb.ellipsoid(0.0035, 0.0028, 0.011, 10, 6, func(_u: float, _v: float, p: Vector3) -> Color: return Color("8CC152") if p.x > 0.0025 else Color("D8EE9A"))
				mb.pop()
		"sausage":
			mb.col(Color("C8503A"), 1.0, 0.4); mb.puck(0.0085, 0.004, 0.0014, 14)
			mb.col(Color("F2A08A"), 0.0); mb.at(Vector3(0, 0.0002, 0)); mb.puck(0.0062, 0.0042, 0.001, 12); mb.pop()
		"chicken":
			mb.col(Color("F2C08A"), 1.0, 0.2); mb.at(Vector3(0, 0.005, 0)); mb.blob(0.011, 0.006, 0.008, 0.18, 0.7, 3, 12, 8, func(_u: float, v: float, _p: Vector3) -> Color: return Color("D9954A").lerp(Color("FFE0B0"), v)); mb.pop()
		"beef":
			mb.col(Color("8A3A2A"), 1.0, 0.3); mb.at(Vector3(0, 0.0045, 0)); mb.blob(0.01, 0.0055, 0.008, 0.2, 0.7, 7, 12, 8); mb.pop()
		"salmon", "tuna":
			mb.col(Color("F4895A") if k == "salmon" else Color("D63B4E"), 1.0, 0.5); mb.at(Vector3(0, 0.004, 0)); mb.rbox(Vector3(0.016, 0.008, 0.011), 0.002, 1); mb.pop()
			mb.col(Color("FFE3D2") if k == "salmon" else Color("F57C8C"), 0.0)
			for i in 3:
				mb.tube(PackedVector3Array([Vector3(-0.005 + i * 0.005, 0.0082, 0.005), Vector3(-0.003 + i * 0.005, 0.0082, -0.005)]), 0.0006, 4)
		"shrimp":
			var pts := PackedVector3Array()
			for i in 8:
				var a := lerpf(PI * 0.2, PI * 1.5, i / 7.0)
				pts.append(Vector3(cos(a) * 0.007, 0.004, sin(a) * 0.007))
			mb.col(Color("FF8C6A"), 1.0, 0.4); mb.tube(pts, func(t: float) -> float: return 0.0042 * (1.0 - t * 0.6), 8, func(_u: float, v: float, _p: Vector3) -> Color: return Color("FFE3D8") if fposmod(v * 5.0, 1.0) < 0.15 else Color("FF8C6A"))
		"honey", "syrup", "caramel":
			mb.col(Color("F6B73C") if k == "honey" else SYRUP if k == "syrup" else Color("C8742E"), 0.5, 1.0)
			mb.at(Vector3(0, 0.0015, 0)); mb.ellipsoid(0.011, 0.0022, 0.009, 16, 5); mb.pop()
		"sprinkles":
			var cols := [Color("FF7EA6"), Color("7FD3F7"), Color("FFD24A"), Color("9BE38F"), Color("C3A6FF")]
			for i in 7:
				var a := i * 2.2
				mb.col(cols[i % 5], 0.0); mb.at(Vector3(cos(a) * 0.006, 0.0012, sin(a) * 0.005), Vector3(0, a, 0)); mb.rbox(Vector3(0.005, 0.0016, 0.0016), 0.0007, 1); mb.pop()
		"redbean":
			mb.col(Color("6A2230"), 1.0, 0.4); mb.at(Vector3(0, 0.003, 0)); mb.blob(0.011, 0.004, 0.009, 0.15, 0.9, 4, 14, 7); mb.pop()
			mb.col(Color("8E3A48"), 0.0)
			for i in 5:
				var a := i * 1.3
				mb.at(Vector3(cos(a) * 0.005, 0.006, sin(a) * 0.004)); mb.ellipsoid(0.0018, 0.0012, 0.0024, 6, 4); mb.pop()
		"matcha":
			mb.col(Color("7DB54A"), 0.0)
			var rng := _rng(4)
			for i in 12:
				mb.at(Vector3(rng.randf_range(-0.009, 0.009), 0.0006, rng.randf_range(-0.007, 0.007))); mb.sphere(0.001, 4, 3); mb.pop()
		"orange", "lemon":
			var c := Color("FF9F2E") if k == "orange" else Color("FFD83A")
			mb.at(Vector3(0, 0.0, 0)); mb.col(c, 1.0, 0.4); mb.puck(0.0105, 0.004, 0.0015, 18)
			mb.col(c.lightened(0.55), 0.0); mb.at(Vector3(0, 0.0002, 0)); mb.puck(0.0085, 0.0042, 0.001, 16); mb.pop()
			mb.col(c.lightened(0.15), 0.0)
			for i in 6:
				mb.at(Vector3(0, 0.0045, 0), Vector3(0, i * TAU / 6.0, 0)); mb.at(Vector3(0.0045, 0, 0)); mb.rbox(Vector3(0.008, 0.0004, 0.0008), 0.0002, 1); mb.pop(); mb.pop()
			mb.pop()
		"apple":
			var o := PackedVector2Array()
			for i in 13:
				var a := PI * i / 12.0
				o.append(Vector2(cos(a) * 0.011, sin(a) * 0.008 - 0.003))
			mb.col(Color("E8404A")); mb.extrude(o, 0.006, 0.0015)
			mb.col(Color("FFF2D6"), 0.0); mb.at(Vector3(0, 0.0004, 0)); mb.extrude(_scaled(o, 0.84), 0.0062, 0.001); mb.pop()
		_:
			if G.ING.has(k):
				IngArt.piece(mb, k, 0.6)
	mb.pop()
	mb.col(WHITE, 1.0, 0.0)

static func _scaled(o: PackedVector2Array, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in o: out.append(p * s)
	return out

## Places n garnishes from keys over an ellipse at height y.
static func scatter(mb: MB, keys: Array, n: int, center: Vector3, rx: float, rz: float, s: float, seed_: int, y_fn: Callable = Callable()) -> void:
	if keys.is_empty():
		return
	var rng := _rng(seed_)
	var pts: Array = []
	for i in n:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * 0.9
		var p := center + Vector3(cos(a) * rx * d, 0, sin(a) * rz * d)
		if y_fn.is_valid():
			p.y = y_fn.call(p)
		pts.append([p, keys[i % keys.size()], rng.randf() * TAU])
	for e in pts:
		garnish(mb, e[1], e[0], s, e[2])

# ======================================================================= dispatcher
static func build(mb: MB, sp: Dictionary) -> void:
	var art: String = sp.get("art", "chunks")
	match art:
		"chunks": _chunks(mb, sp)
		"log": _log(mb, sp)
		"glass": _glass(mb, sp)
		"mug": _mug(mb, sp)
		"bowl": _bowl(mb, sp)
		"salad": _salad(mb, sp)
		"stack": _stack(mb, sp)
		"egg": _egg(mb, sp)
		"toast": _toast(mb, sp)
		"sandwich": _toast(mb, sp)
		"burger": _burger(mb, sp)
		"hotdog": _hotdog(mb, sp)
		"taco": _taco(mb, sp)
		"pizza": _pizza(mb, sp)
		"maki": _maki(mb, sp)
		"onigiri": _onigiri(mb, sp)
		"pile": _pile(mb, sp)
		"cookie": _cookie(mb, sp)
		"cupcake": _cupcake(mb, sp)
		"cake": _cake(mb, sp)
		"scoop": _scoop(mb, sp)
		"plate": _plate_dish(mb, sp)
		"raw":
			if sp.has("ing"): IngArt.build(mb, sp.ing)
		_: _chunks(mb, sp)
	mb.col(WHITE, 1.0, 0.0)

# ======================================================================= dishes
static func _chunks(mb: MB, sp: Dictionary) -> void:
	var y := plate(mb, 0.095)
	var rng := _rng(7)
	var pieces: Array = sp.get("pieces", sp.get("ings", {}).keys())
	var pts: Array = []
	for k in pieces:
		if not G.ING.has(k): continue
		for j in 4:
			var a := rng.randf() * TAU
			var d := sqrt(rng.randf()) * 0.045
			pts.append([Vector3(cos(a) * d, y + j * 0.004 * rng.randf(), sin(a) * d * 0.8), k, rng.randf() * TAU])
	for p in pts:
		mb.at(p[0], Vector3(0, p[2], 0)); IngArt.piece(mb, p[1], 0.85); mb.pop()

static func _log(mb: MB, sp: Dictionary) -> void:
	var y := board(mb, 0.19, 0.08)
	mb.col(Color("22362A"), 1.0, 0.3)
	mb.tube(PackedVector3Array([Vector3(-0.07, y + 0.022, 0), Vector3(0.07, y + 0.022, 0)]), 0.022, 18)
	mb.col(Color("FDFAF3"), 0.6); mb.at(Vector3(0.0705, y + 0.022, 0), Vector3(0, 0, PI * 0.5)); mb.puck(0.0185, 0.003, 0.001, 18); mb.pop()
	var tops: Array = sp.get("tops", [])
	for i in mini(tops.size(), 3):
		mb.col(tops[i], 0.0); mb.at(Vector3(0.0738, y + 0.022 + (i - 1) * 0.008, (i % 2) * 0.004), Vector3(0, 0, PI * 0.5)); mb.puck(0.005, 0.0012, 0.0005, 10); mb.pop()

static func _glass(mb: MB, sp: Dictionary) -> void:
	var st: String = sp.get("style", "")
	var c: Color = sp.get("main", Color("FF9DB8"))
	var rb := 0.033
	var rt := 0.041
	var h := 0.118
	# saucer
	mb.col(Color("FFC8D8"), 1.0, 0.2); mb.puck(0.058, 0.007, 0.003, 32)
	mb.at(Vector3(0, 0.007, 0))
	glass_cup(mb, rb, rt, h)
	var top := h * (0.9 if st == "shake" else 0.82)
	var lf := func(y: float) -> float: return lerpf(rb, rt, y / h) - 0.0028
	var prof := PackedVector2Array([Vector2(0, 0.009), Vector2(lf.call(0.009), 0.009), Vector2(lf.call(top), top), Vector2(0, top)])
	if st == "parfait":
		var fr := Color("5B6CD6") if _has(sp, "blueberry") else Color("E0405A")
		mb.col(CREAM, 0.0, 0.2)
		mb.lathe(prof, 28, Callable(), func(_u: float, _v: float, p: Vector3) -> Color:
			var band := int((p.y - 0.009) / 0.0165 + sin(atan2(p.z, p.x) * 3.0) * 0.12)
			return [Color("FFF8FA"), fr, Color("E8D2A6")][band % 3], 16)
		scatter(mb, ["strawberry"] if not _has(sp, "blueberry") else ["blueberry", "strawberry"], 3, Vector3(0, top, 0), 0.018, 0.018, 0.85, 5)
	elif _has(sp, "matcha") and _has(sp, "ice"):
		mb.col(Color("FFFDF6"), 0.0, 0.2)
		mb.lathe(prof, 28, Callable(), func(_u: float, _v: float, p: Vector3) -> Color:
			return Color("FFFDF6") if p.y < top * 0.55 + 0.004 * sin(atan2(p.z, p.x) * 4.0) else Color("8CC152").lerp(Color("B8DC7A"), (p.y - top * 0.55) / (top * 0.45)), 16)
	else:
		mb.col(c, 0.0, 0.25)
		mb.lathe(prof, 28, Callable(), func(_u: float, _v: float, p: Vector3) -> Color: return G.darken(c, 0.12).lerp(G.lighten(c, 0.22), p.y / top), 12)
	# surface ring
	mb.col(G.lighten(c if st != "parfait" else Color("FFF8FA"), 0.42), 0.0, 0.3)
	mb.at(Vector3(0, top + 0.0004, 0)); mb.puck(lf.call(top) - 0.0004, 0.001, 0.0005, 28); mb.pop()
	if st == "ice" or (_has(sp, "ice") and st != "shake"):
		var rng := _rng(9)
		for i in 3:
			mb.at(Vector3(rng.randf_range(-0.012, 0.012), top - 0.002, rng.randf_range(-0.012, 0.012)), Vector3(rng.randf(), rng.randf() * TAU, rng.randf() * 0.5))
			mb.col(Color("E2F4FF"), 0.7, 1.0); mb.rbox(Vector3(0.016, 0.014, 0.016), 0.003, 1); mb.pop()
	if st == "shake":
		cream_swirl(mb, Vector3(0, top, 0), 0.03, 0.04)
		if _has(sp, "chocolate"):
			drip_pool(mb, Color("6B3A26"), Vector3(0, top + 0.012, 0), 0.02, 0.022, 3, 2, 0.012)
		garnish(mb, "cherry", Vector3(0.002, top + 0.038, 0.0), 1.15)
	else:
		var rim := ""
		for k in ["strawberry", "lemon", "orange", "watermelon", "mango", "pineapple", "banana"]:
			if _has(sp, k):
				rim = k
				break
		if rim in ["lemon", "orange"]:
			mb.at(Vector3(-rt + 0.002, h - 0.004, 0.006), Vector3(0, 0, PI * 0.5 - 0.25)); garnish(mb, rim, Vector3.ZERO, 1.4); mb.pop()
		elif rim != "":
			garnish(mb, rim if rim != "watermelon" else "strawberry", Vector3(-rt + 0.006, h - 0.004, 0.008), 1.25, 0.6)
		if _has(sp, "cream"):
			cream_swirl(mb, Vector3(0.004, top, 0), 0.018, 0.022)
	straw(mb, Vector3(0.006, 0.02, -0.004), Vector3(0.026, h + 0.05, -0.012))
	mb.pop()

static func _mug(mb: MB, sp: Dictionary) -> void:
	var c: Color = sp.get("main", Color("8A5A40"))
	mb.col(WHITE, 1.0, 0.3); mb.puck(0.065, 0.007, 0.003, 32, 0.062)
	mb.col(Color("D6DCF2"), 0.0); mb.at(Vector3(0, 0.0072, 0)); mb.puck(0.035, 0.0006, 0.0003, 24); mb.pop()
	var h := 0.072
	var r := 0.042
	var y0 := 0.007
	var prof := MB.spline(PackedVector2Array([Vector2(0, y0), Vector2(r * 0.85, y0), Vector2(r * 0.97, y0 + 0.006), Vector2(r, y0 + h * 0.5), Vector2(r * 1.02, y0 + h), Vector2(r * 0.94, y0 + h + 0.002), Vector2(r * 0.9, y0 + h - 0.008), Vector2(0, y0 + h - 0.008)]), 3)
	mb.col(Color("FFC2D6"), 1.0, 0.4)
	mb.lathe(prof, 40, Callable(), func(u: float, _v: float, p: Vector3) -> Color:
		if p.y > y0 + h - 0.009 and Vector2(p.x, p.z).length() < r * 0.93: return Color("FFF4F8")
		var star := fposmod(u * 10.0, 1.0)
		var yy := fposmod((p.y - y0) / 0.018, 1.0)
		if absf(star - 0.5) < 0.06 and absf(yy - 0.5) < 0.12 and p.y < y0 + h - 0.012 and p.y > y0 + 0.012: return Color("FFF0F6")
		return Color("FFE0EA").lerp(Color("E58AAE"), clampf(0.5 - p.x / r * 0.5, 0.0, 1.0)), 30)
	# handle
	var hp := PackedVector3Array()
	for i in 13:
		var a := -PI * 0.5 + PI * i / 12.0
		hp.append(Vector3(r + 0.002 + cos(a) * 0.018, y0 + h * 0.52 + sin(a) * -0.02, 0))
	mb.col(Color("FFB3CC"), 1.0, 0.4); mb.tube(hp, 0.0055, 10)
	# drink
	var dy := y0 + h - 0.012
	disc(mb, dy, r * 0.88, c, func(_u: float, _v: float, p: Vector3) -> Color: return G.lighten(c, 0.2).lerp(G.darken(c, 0.12), Vector2(p.x, p.z).length() / (r * 0.88)), 0.0015, 0.3)
	if _has(sp, "milk") or _has(sp, "cream"):
		if _has(sp, "chocolate"):
			var rng := _rng(3)
			for i in 4:
				mb.at(Vector3(rng.randf_range(-0.016, 0.016), dy + 0.003, rng.randf_range(-0.014, 0.014)), Vector3(rng.randf(), rng.randf() * TAU, 0))
				mb.col(WHITE if i % 2 else Color("FFD6E4"), 0.8, 0.2); mb.rbox(Vector3(0.011, 0.009, 0.011), 0.003, 1); mb.pop()
		else:
			var heart := PackedVector2Array()
			for i in 32:
				var t := float(i) / 32.0 * TAU
				heart.append(Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * 0.0011)
			mb.col(Color("FFFAF0"), 0.0, 0.2); mb.at(Vector3(0, dy + 0.0005, 0.002)); mb.extrude(heart, 0.0012, 0.0005); mb.pop()
	if _has(sp, "lemon"):
		garnish(mb, "lemon", Vector3(0.008, dy + 0.001, -0.004), 1.0)
	face(mb, Vector3(0, y0 + h * 0.42, r + 0.0015), 1.15, "happy")

static func _bowl(mb: MB, sp: Dictionary) -> void:
	var st: String = sp.get("style", "")
	var main: Color = sp.get("main", Color("E9B970"))
	match st:
		"curry":
			var py := plate(mb, 0.112, Color("E8A85A"))
			var pool := MB.spline(PackedVector2Array([Vector2(0.0, -0.06), Vector2(0.05, -0.05), Vector2(0.07, 0.0), Vector2(0.05, 0.05), Vector2(0.0, 0.06), Vector2(-0.01, 0.0), Vector2(0.0, -0.06)]), 5)
			pool.remove_at(pool.size() - 1)
			mb.col(Color("B8732A"), 0.5, 0.7); mb.at(Vector3(0.012, py - 0.001, 0)); mb.extrude(pool, 0.007, 0.003, 2, Color("C8822E")); mb.pop()
			var meat := "beef" if _has(sp, "beef") else ("chicken" if _has(sp, "chicken") and not _has(sp, "flour") else "onion")
			scatter(mb, ["carrot", "potato", meat], 7, Vector3(0.04, py + 0.006, 0), 0.025, 0.04, 1.1, 5)
			_rice_mound(mb, Vector3(-0.04, py, 0.0), 0.045, 0.035, 3)
			if _has(sp, "flour") and _has(sp, "egg"):
				for i in 4:
					mb.at(Vector3(0.0 + i * 0.016, py + 0.016 + i * 0.002, -0.01 + i * 0.008), Vector3(0.3, 0.5, -0.35))
					mb.col(Color("E8A84A"), 1.0, 0.2); mb.blob(0.01, 0.007, 0.024, 0.06, 1.5, i, 14, 8, func(_u: float, v: float, _p: Vector3) -> Color: return Color("C8822E").lerp(Color("F6C46A"), v))
					mb.col(Color("FFF2E2"), 0.0); mb.at(Vector3(-0.0095, 0, 0), Vector3(0, 0, PI * 0.5)); mb.ellipsoid(0.005, 0.0012, 0.02, 10, 4); mb.pop()
					mb.pop()
			mb.col(Color("E8404A"), 0.8, 0.5); mb.at(Vector3(-0.08, py + 0.004, 0.03)); mb.ellipsoid(0.008, 0.004, 0.006, 10, 6); mb.pop()
			return
		"pasta":
			var py := plate(mb, 0.108, Color("E8A85A"))
			var rng := _rng(4)
			for i in 16:
				var pts := PackedVector3Array()
				var a0 := rng.randf() * TAU
				var rr := rng.randf_range(0.012, 0.05)
				var hh := py + 0.004 + (1.0 - rr / 0.05) * 0.022
				for k in 9:
					var a := a0 + k * 0.32
					pts.append(Vector3(cos(a) * rr, hh + sin(k * 0.9 + i) * 0.003, sin(a) * rr * 0.85))
				mb.col(Color("F2C86A") if i % 3 else Color("FFE29A"), 0.4, 0.2); mb.tube(MB.spline3(pts, 2), 0.0028, 6)
			if _has(sp, "tomato"):
				mb.col(Color("D8301E"), 0.8, 0.8); mb.at(Vector3(0, py + 0.026, 0)); mb.blob(0.03, 0.009, 0.026, 0.12, 0.8, 2, 20, 10, func(_u: float, v: float, _p: Vector3) -> Color: return Color("C8281E").lerp(Color("FF6A4A"), v)); mb.pop()
				garnish(mb, "spinach", Vector3(0.006, py + 0.035, -0.004), 1.2, 0.6)
				garnish(mb, "spinach", Vector3(-0.008, py + 0.034, 0.004), 1.0, -0.8)
			elif _has(sp, "egg"):
				mb.col(Color("FFF2C0"), 0.4, 0.5); mb.at(Vector3(0, py + 0.024, 0)); mb.blob(0.034, 0.006, 0.03, 0.15, 0.9, 6, 18, 8); mb.pop()
				scatter(mb, ["bacon"], 6, Vector3(0, py + 0.028, 0), 0.03, 0.025, 1.0, 5)
				mb.col(Color("3A2A2A"), 0.0)
				var rr2 := _rng(6)
				for i in 16:
					mb.at(Vector3(rr2.randf_range(-0.03, 0.03), py + 0.031, rr2.randf_range(-0.025, 0.025))); mb.sphere(0.0008, 4, 3); mb.pop()
			if _has(sp, "cheese"):
				mb.col(Color("FFF6D8"), 0.0)
				var rr3 := _rng(7)
				for i in 14:
					mb.at(Vector3(rr3.randf_range(-0.022, 0.022), py + 0.034, rr3.randf_range(-0.02, 0.02)), Vector3(0, rr3.randf() * TAU, 0)); mb.rbox(Vector3(0.004, 0.0012, 0.0012), 0.0005, 1); mb.pop()
			return
		"guac":
			var f := bowl(mb, 0.07, 0.048, Color("77738A"), Color("4E4A60"), Color("3A3648"), "stripe", 0.92)
			mb.col(Color("A8D46A"), 0.5, 0.3); mb.at(Vector3(0, f[0] - 0.004, 0)); mb.blob(f[1], 0.012, f[1], 0.12, 1.1, 2, 26, 10, func(_u: float, v: float, _p: Vector3) -> Color: return Color("7DB54A").lerp(Color("C8E68A"), v)); mb.pop()
			scatter(mb, ["tomato", "onion"], 7, Vector3(0, f[0] + 0.006, 0), f[1] * 0.7, f[1] * 0.7, 0.7, 3)
			for e in [[Vector3(-0.045, f[0] + 0.012, -0.01), -0.4], [Vector3(0.035, f[0] + 0.012, -0.02), 0.5], [Vector3(0.05, f[0] + 0.008, 0.02), 1.0]]:
				mb.at(e[0], Vector3(-0.3, e[1], 0.25)); _chip(mb, 1.25); mb.pop()
			garnish(mb, "lemon", Vector3(0.06, 0.045, 0.03), 1.2, 0.3)
			return
	# bowls with contents
	var pal := {"c1": WHITE, "c2": Color("D6DCF2"), "band": Color("7C8AD6"), "pattern": "wave"}
	if st == "ramen" or st == "rice": pal = {"c1": Color("3A3550"), "c2": Color("221E33"), "band": Color("E8404A"), "pattern": "stripe"}
	elif st == "don": pal = {"c1": Color("3A3550"), "c2": Color("221E33"), "band": Color("D9A040"), "pattern": "wave"}
	elif st == "mac": pal = {"c1": Color("FFE3EC"), "c2": Color("F2B3C8"), "band": WHITE, "pattern": "dots"}
	elif st == "batter": pal = {"c1": Color("A9C8FF"), "c2": Color("7E9AE0"), "band": WHITE, "pattern": "dots"}
	var big := st == "ramen"
	var f := bowl(mb, 0.085 if big else 0.075, 0.062 if big else 0.056, pal.c1, pal.c2, pal.band, pal.pattern, 0.86)
	var fy: float = f[0]
	var fr: float = f[1]
	match st:
		"ramen":
			disc(mb, fy, fr, main, func(_u: float, _v: float, p: Vector3) -> Color: return G.lighten(main, 0.25).lerp(G.darken(main, 0.08), Vector2(p.x, p.z).length() / fr))
			for i in 7:
				var pts := PackedVector3Array()
				var zz := -fr * 0.1 + i * fr * 0.11
				for k in 12:
					var x := -fr * 0.85 + k * fr * 0.155
					pts.append(Vector3(x, fy + 0.0018 + sin(k * 1.4 + i) * 0.0012, zz + sin(x / 0.012 + i * 1.3) * 0.004))
				mb.col(Color("F3D27E"), 0.0, 0.3); mb.tube(MB.spline3(pts, 2), 0.0024, 6)
			mb.col(Color("1F2C25"), 0.8); mb.at(Vector3(-fr * 0.55, fy + 0.016, -fr * 0.45), Vector3(-0.35, 0.3, 0)); mb.rbox(Vector3(0.026, 0.036, 0.002), 0.001, 1); mb.pop()
			if _has(sp, "chicken"):
				for e in [[Vector3(-fr * 0.3, fy + 0.004, -fr * 0.15), -0.2], [Vector3(-fr * 0.05, fy + 0.004, -fr * 0.35), 0.3]]:
					garnish(mb, "chicken", e[0], 1.5, e[1])
			else:
				mb.at(Vector3(-fr * 0.25, fy + 0.0025, -fr * 0.18), Vector3(0.15, 0, 0.1))
				mb.col(Color("D9906A"), 1.0, 0.4); mb.puck(0.017, 0.006, 0.002, 20)
				mb.col(Color("FFE2D2"), 0.0); mb.at(Vector3(0, 0.0003, 0)); mb.puck(0.012, 0.0062, 0.001, 18); mb.pop()
				mb.col(Color("C97E5A"), 0.0); mb.at(Vector3(0, 0.0004, 0)); mb.puck(0.006, 0.0063, 0.001, 14); mb.pop()
				mb.pop()
			if _has(sp, "egg"):
				for s in [0.0, 1.0]:
					mb.at(Vector3(fr * 0.36 + s * 0.02, fy + 0.002, -fr * 0.18 + s * 0.008), Vector3(0, 0.4 * s, 0))
					mb.col(WHITE); mb.ellipsoid(0.0135, 0.007, 0.011, 16, 8)
					mb.col(Color("FF9A2E"), 0.6, 0.9); mb.at(Vector3(0, 0.0058, 0)); mb.ellipsoid(0.007, 0.002, 0.0062, 12, 5); mb.pop()
					mb.pop()
			else:
				mb.at(Vector3(fr * 0.4, fy + 0.002, -fr * 0.2))
				mb.col(WHITE); mb.puck(0.012, 0.004, 0.0015, 18)
				var sw := PackedVector3Array()
				for k in 24:
					var a := k / 24.0 * TAU * 2.0
					var d := 0.001 + k * 0.00038
					sw.append(Vector3(cos(a) * d, 0.0042, sin(a) * d))
				mb.col(Color("FF7EA6"), 0.0); mb.tube(sw, 0.0009, 5, Callable(), 0.4, Vector3.UP)
				mb.pop()
			scatter(mb, _extras(sp, ["egg", "chicken", "beef", "onion"]), 5, Vector3(fr * 0.12, fy + 0.002, fr * 0.4), fr * 0.4, fr * 0.2, 1.0, 4)
			mb.col(Color("6BBF59"), 0.4)
			for i in 9:
				mb.at(Vector3(-fr * 0.55 + i * fr * 0.13, fy + 0.0018, fr * (0.1 + (i % 3) * 0.12))); mb.torus(0.0026, 0.0011, 10, 5); mb.pop()
		"don":
			disc(mb, fy, fr, Color("FFFDF6"))
			_grains(mb, Vector3(0, fy, 0), fr * 0.95, 40, 4)
			var rng := _rng(6)
			for i in 9:
				var a := rng.randf() * TAU
				var d := sqrt(rng.randf()) * fr * 0.75
				mb.col(Color("FFD84A"), 0.6, 0.4); mb.at(Vector3(cos(a) * d, fy + 0.002, sin(a) * d), Vector3(0, rng.randf() * TAU, 0)); mb.blob(0.012, 0.004, 0.008, 0.2, 0.8, i, 12, 6, func(_u: float, v: float, _p: Vector3) -> Color: return Color("F6B83A").lerp(Color("FFE680"), v)); mb.pop()
			scatter(mb, ["chicken", "onion"], 7, Vector3(0, fy + 0.003, 0), fr * 0.7, fr * 0.7, 1.0, 7)
			garnish(mb, "spinach", Vector3(0.008, fy + 0.008, -0.004), 1.2, -0.4)
		"mac":
			disc(mb, fy, fr, Color("F7C24A"))
			var rng := _rng(8)
			for i in 26:
				var a := rng.randf() * TAU
				var d := sqrt(rng.randf()) * fr * 0.85
				var pts := PackedVector3Array()
				for k in 6:
					var b := k / 5.0 * PI * 0.9
					pts.append(Vector3(cos(b) * 0.005, 0, sin(b) * 0.005))
				mb.at(Vector3(cos(a) * d, fy + 0.0025 + rng.randf() * 0.003, sin(a) * d), Vector3(rng.randf() * 0.6, rng.randf() * TAU, 0))
				mb.col(Color("FFD45A"), 0.5, 0.5); mb.tube(pts, 0.0022, 6); mb.pop()
			if _has(sp, "butter"): garnish(mb, "butter", Vector3(0.004, fy + 0.004, 0.0), 1.0)
		"porridge":
			disc(mb, fy, fr, main)
			mb.col(Color("D8C298"), 0.0)
			var rng := _rng(2)
			for i in 22:
				var a := rng.randf() * TAU
				var d := sqrt(rng.randf()) * fr * 0.9
				mb.at(Vector3(cos(a) * d, fy + 0.0012, sin(a) * d), Vector3(0, rng.randf() * TAU, 0)); mb.ellipsoid(0.003, 0.0008, 0.002, 6, 3); mb.pop()
			scatter(mb, _extras(sp, ["honey"]), 6, Vector3(0, fy + 0.0015, 0), fr * 0.6, fr * 0.6, 1.0, 3)
			if _has(sp, "honey"): zigzag(mb, Color("F6B73C"), Vector3(0, fy + 0.006, 0), fr * 1.1, fr * 0.6, 3, 0.0018)
		"smooth":
			disc(mb, fy, fr, main, func(_u: float, _v: float, p: Vector3) -> Color: return G.lighten(main, 0.18).lerp(G.darken(main, 0.06), Vector2(p.x, p.z).length() / fr))
			var sw := PackedVector3Array()
			for k in 40:
				var a := k / 40.0 * TAU * 2.2
				var d := 0.002 + k * fr * 0.016
				sw.append(Vector3(cos(a) * d, fy + 0.0018, sin(a) * d))
			mb.col(Color("FFF8F0"), 0.0, 0.5); mb.tube(sw, 0.0016, 5, Callable(), 0.35, Vector3.UP)
			garnish(mb, "spinach", Vector3(fr * 0.4, fy + 0.002, -fr * 0.2), 0.8, 0.4)
			if _has(sp, "bread"):
				mb.col(Color("E8B26A"), 0.6, 0.0)
				for p in [Vector3(-fr * 0.4, fy + 0.004, fr * 0.2), Vector3(-fr * 0.2, fy + 0.004, fr * 0.45), Vector3(fr * 0.1, fy + 0.004, fr * 0.35)]:
					mb.at(p, Vector3(0.2, p.x * 40.0, 0)); mb.rbox(Vector3(0.008, 0.007, 0.008), 0.002, 1); mb.pop()
		"rice":
			_rice_mound(mb, Vector3(0, fy - 0.006, 0), fr, 0.024, 5)
		"batter":
			disc(mb, fy, fr, sp.get("main", Color("F6D58A")), func(_u: float, _v: float, p: Vector3) -> Color:
				var m: Color = sp.get("main", Color("F6D58A"))
				return G.lighten(m, 0.12).lerp(G.darken(m, 0.05), Vector2(p.x, p.z).length() / fr))
			var sw := PackedVector3Array()
			for k in 30:
				var a := k / 30.0 * TAU * 1.6
				var d := 0.004 + k * fr * 0.022
				sw.append(Vector3(cos(a) * d, fy + 0.0014, sin(a) * d))
			mb.col(G.lighten(sp.get("main", Color("F6D58A")), 0.3), 0.0, 0.5); mb.tube(sw, 0.0016, 5, Callable(), 0.35, Vector3.UP)
		"mash":
			mb.col(Color("FFF0C8"), 0.6, 0.2); mb.at(Vector3(0, fy - 0.004, 0)); mb.blob(fr, 0.02, fr, 0.12, 1.0, 3, 24, 10); mb.pop()
			garnish(mb, "butter", Vector3(0, fy + 0.013, 0), 1.0)
		_:
			# chunky stew / generic hot bowl
			disc(mb, fy, fr, main)
			var keys := _extras(sp)
			if keys.is_empty():
				keys = sp.get("ings", {}).keys().filter(func(k): return G.ING.has(k))
			scatter(mb, keys, 9, Vector3(0, fy + 0.001, 0), fr * 0.75, fr * 0.75, 1.15, 6)

static func _rice_mound(mb: MB, pos: Vector3, r: float, h: float, seed_: int) -> void:
	mb.col(Color("FFFDF6"), 1.0, 0.1)
	mb.at(pos); mb.lathe(MB.spline(PackedVector2Array([Vector2(0, 0), Vector2(r, 0.0), Vector2(r * 0.95, h * 0.35), Vector2(r * 0.6, h * 0.85), Vector2(0, h)]), 4), 30, func(u: float, v: float) -> float: return 1.0 + 0.04 * sin(u * TAU * 7.0 + seed_) * v, Callable(), 12); mb.pop()
	_grains(mb, pos + Vector3(0, h * 0.5, 0), r * 0.8, int(r * 900.0), seed_, h * 0.5)

static func _grains(mb: MB, center: Vector3, r: float, n: int, seed_: int, dome := 0.0) -> void:
	var rng := _rng(seed_)
	mb.col(WHITE, 0.0, 0.3)
	for i in n:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf())
		var p := center + Vector3(cos(a) * r * d, 0.0012 + dome * (1.0 - d * d), sin(a) * r * d)
		mb.at(p, Vector3(rng.randf() * 0.4, rng.randf() * TAU, 0)); mb.ellipsoid(0.0032, 0.0014, 0.0017, 6, 4); mb.pop()
	mb.outline = 1.0

static func _chip(mb: MB, s := 1.0) -> void:
	var tri := PackedVector2Array()
	for i in 3:
		var a := -PI * 0.5 + i * TAU / 3.0
		var b := -PI * 0.5 + (i + 1) * TAU / 3.0
		for k in 5:
			var t := 0.12 + 0.76 * k / 4.0
			tri.append(Vector2(cos(a), sin(a)).lerp(Vector2(cos(b), sin(b)), t) * 0.016 * s)
	mb.col(Color("F2C84A"), 1.0, 0.1); mb.extrude(tri, 0.0035 * s, 0.0012, 2, Color("FFE08A"))
	mb.col(Color("E8A030"), 0.0)
	for p in [Vector2(-0.003, 0.002), Vector2(0.004, -0.002)]:
		mb.at(Vector3(p.x * s, 0.0037 * s, p.y * s)); mb.ellipsoid(0.0015 * s, 0.0004, 0.0012 * s, 6, 3); mb.pop()

static func _salad(mb: MB, sp: Dictionary) -> void:
	var fruit: bool = sp.get("style", "") == "fruit"
	var f := bowl(mb, 0.08, 0.05, Color("FFE3EC") if fruit else Color("F6E2C8"), Color("F2B3C8") if fruit else Color("D9B48A"), WHITE if fruit else Color("8EC274"), "dots" if fruit else "wave", 0.9)
	var fy: float = f[0]
	var fr: float = f[1]
	if not fruit:
		var rng := _rng(3)
		for i in 9:
			var a := i * TAU / 9.0 + rng.randf() * 0.3
			var d := fr * rng.randf_range(0.3, 0.75)
			mb.push(Transform3D(Basis.from_euler(Vector3(-0.35 + rng.randf() * 0.3, a + PI * 0.5, 0)), Vector3(cos(a) * d, fy + 0.006, sin(a) * d)))
			mb.col(Color("8ED16B") if i % 2 else Color("6BBF59"), 1.0, 0.1); mb.leaf(0.022, 0.016, 0.0022, 0.6, 0.35); mb.pop()
	var keys := _extras(sp, ["lettuce", "spinach", "cabbage", "honey"])
	scatter(mb, keys, 11 if fruit else 8, Vector3(0, fy + (0.004 if fruit else 0.012), 0), fr * 0.7, fr * 0.7, 1.2, 9)
	if fruit and _has(sp, "honey"):
		zigzag(mb, Color("F6B73C"), Vector3(0, fy + 0.014, 0), fr * 0.9, fr * 0.5, 3, 0.0016)

static func _pancake(mb: MB, pos: Vector3, r: float, h: float, c: Color, side := Color("FFE6B0")) -> void:
	mb.at(pos)
	mb.col(c, 1.0, 0.15)
	mb.puck(r, h, h * 0.45, 32, -1.0, func(_u: float, _v: float, p: Vector3) -> Color:
		var edge := Vector2(p.x, p.z).length() > r * 0.94 and p.y > h * 0.2 and p.y < h * 0.8
		return side if edge else c.lerp(G.lighten(c, 0.2), clampf(1.0 - Vector2(p.x, p.z).length() / r, 0.0, 1.0) * 0.6))
	mb.pop()

static func _stack(mb: MB, sp: Dictionary) -> void:
	var st: String = sp.get("style", "")
	var main: Color = sp.get("main", GOLD)
	var py := plate(mb, 0.1)
	match st:
		"crepe":
			for i in 3:
				var tri := PackedVector2Array()
				for k in 9:
					var a := -0.5 + k / 8.0 * 1.0
					tri.append(Vector2(cos(a), sin(a)) * 0.065)
				tri.append(Vector2.ZERO)
				mb.at(Vector3(-0.03 + i * 0.012, py + i * 0.007, 0.01 - i * 0.006), Vector3(0.0, -0.9 + i * 0.25, 0))
				mb.col(Color("F6D58A"), 1.0, 0.1); mb.extrude(tri, 0.006, 0.0025, 2, Color("F9DE9A"))
				mb.col(Color("E8B860"), 0.0)
				for j in 4:
					mb.at(Vector3(0.02 + j * 0.008, 0.0062, (j % 2) * 0.006 - 0.003)); mb.ellipsoid(0.003, 0.0004, 0.002, 6, 3); mb.pop()
				mb.pop()
			var tops := _extras(sp, ["butter", "egg"])
			scatter(mb, tops, 5, Vector3(0.0, py + 0.024, 0.0), 0.03, 0.02, 1.0, 3)
			if _has(sp, "chocolate"): zigzag(mb, Color("5A2E1E"), Vector3(-0.005, py + 0.024, 0), 0.06, 0.03, 4, 0.0018)
			if _has(sp, "cream"): cream_swirl(mb, Vector3(0.03, py + 0.004, 0.035), 0.016, 0.02)
		"dorayaki":
			_pancake(mb, Vector3(0, py, 0), 0.05, 0.014, main)
			mb.col(Color("6A2230"), 0.6, 0.4); mb.at(Vector3(0, py + 0.013, 0)); mb.puck(0.044, 0.009, 0.004, 28); mb.pop()
			mb.at(Vector3(0, py + 0.022, 0.0), Vector3(0.06, 0, 0)); _pancake(mb, Vector3.ZERO, 0.05, 0.014, main); mb.pop()
			mb.col(Color("8A4A1E"), 0.0)
			for i in 3:
				mb.at(Vector3(-0.012 + i * 0.012, py + 0.037, 0.008), Vector3(0, 0.2 * i, 0)); mb.ellipsoid(0.006, 0.0005, 0.004, 8, 3); mb.pop()
		"okonomi":
			_pancake(mb, Vector3(0, py, 0), 0.07, 0.022, Color("E8B26A"), Color("F6E0A8"))
			mb.col(Color("6A3A1E"), 0.5, 0.9); mb.at(Vector3(0, py + 0.021, 0)); mb.puck(0.058, 0.003, 0.0012, 30); mb.pop()
			zigzag(mb, Color("FFF8E8"), Vector3(0, py + 0.0255, 0), 0.09, 0.05, 5, 0.0018)
			mb.col(Color("6BBF59"), 0.0)
			var rng := _rng(3)
			for i in 26:
				mb.at(Vector3(rng.randf_range(-0.045, 0.045), py + 0.0262, rng.randf_range(-0.04, 0.04))); mb.sphere(0.001, 4, 3); mb.pop()
			mb.col(Color("F6C8A8"), 0.4, 0.0)
			for i in 6:
				mb.at(Vector3(rng.randf_range(-0.03, 0.03), py + 0.027, rng.randf_range(-0.03, 0.03)), Vector3(rng.randf(), rng.randf() * TAU, 0)); mb.leaf(0.005, 0.004, 0.0008, 0.8); mb.pop()
			if _has(sp, "bacon"): scatter(mb, ["bacon"], 3, Vector3(0, py + 0.024, 0), 0.04, 0.035, 1.2, 4)
		_:
			for i in 3:
				_pancake(mb, Vector3(sin(i * 1.7) * 0.003, py + i * 0.0165, cos(i * 2.3) * 0.003), 0.062 - i * 0.002, 0.017, main, Color("FFF0C8") if st != "choc" else Color("A0674A"))
			var ty := py + 3 * 0.0165
			if st == "choc":
				drip_pool(mb, Color("4A2416"), Vector3(0, ty, 0), 0.042, 0.055, 5, 3, 0.022)
				if _has(sp, "cream"): cream_swirl(mb, Vector3(0, ty + 0.003, 0), 0.016, 0.022)
			else:
				drip_pool(mb, SYRUP if not _has(sp, "honey") or _has(sp, "syrup") else Color("F6B73C"), Vector3(0, ty, 0), 0.04, 0.055, 5, 3, 0.024)
				garnish(mb, "butter", Vector3(0.0, ty + 0.002, 0.0), 1.15, 0.4)
			var fruits: Array = _extras(sp, ["butter", "egg", "honey", "syrup", "chocolate"])
			for i in mini(fruits.size(), 2):
				var k: String = fruits[i]
				var rng := _rng(i + 3)
				for j in (3 if k != "blueberry" else 5):
					var a := rng.randf() * TAU
					garnish(mb, k, Vector3(cos(a) * 0.026, ty + 0.002, sin(a) * 0.022), 1.0, rng.randf() * TAU)

static func _fried_egg(mb: MB, pos: Vector3, s := 1.0) -> void:
	mb.push(Transform3D(Basis.IDENTITY.scaled(Vector3(s, s, s)), pos))
	mb.col(WHITE, 1.0, 0.2)
	mb.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.036, 0.0), Vector2(0.038, 0.0025), Vector2(0.03, 0.005), Vector2(0, 0.0055)]), 36, func(u: float, _v: float) -> float: return 1.0 + 0.09 * sin(u * TAU * 5.0) + 0.05 * sin(u * TAU * 3.0 + 1.0), Callable(), 6)
	mb.col(Color("FFB52E"), 1.0, 1.0); mb.at(Vector3(-0.004, 0.004, -0.002)); mb.ellipsoid(0.014, 0.008, 0.013, 18, 10, func(_u: float, v: float, _p: Vector3) -> Color: return Color("F28A1E").lerp(Color("FFC94A"), v)); mb.pop()
	mb.pop()

static func _egg(mb: MB, sp: Dictionary) -> void:
	var st: String = sp.get("style", "")
	if st == "tamago":
		var y := board(mb, 0.17, 0.075)
		for i in 4:
			mb.at(Vector3(-0.048 + i * 0.032, y + 0.012, 0.0), Vector3(0, 0.08 * (i - 1.5), 0))
			mb.col(Color("FFD84A"), 1.0, 0.15); mb.rbox(Vector3(0.026, 0.024, 0.05), 0.005, 2)
			var sw := PackedVector3Array()
			for k in 30:
				var a := k / 30.0 * TAU * 2.2
				var d := 0.001 + k * 0.00034
				sw.append(Vector3(cos(a) * d * 1.1, sin(a) * d, 0.0252))
			mb.col(Color("E8A82A"), 0.0); mb.tube(sw, 0.0009, 5)
			mb.pop()
		return
	var py := plate(mb, 0.1)
	match st:
		"scramble":
			var rng := _rng(4)
			for i in 9:
				var a := rng.randf() * TAU
				var d := sqrt(rng.randf()) * 0.034
				mb.col(Color("FFD84A"), 1.0, 0.2); mb.at(Vector3(cos(a) * d, py + 0.006 + (1.0 - d / 0.034) * 0.006, sin(a) * d * 0.85)); mb.blob(0.018, 0.009, 0.015, 0.25, 0.9, i, 14, 8, func(_u: float, v: float, _p: Vector3) -> Color: return Color("F6C23A").lerp(Color("FFEC8A"), v)); mb.pop()
			if _has(sp, "cheese"): garnish(mb, "cheese", Vector3(0, py + 0.022, 0), 1.2)
			mb.col(Color("6BBF59"), 0.0)
			for i in 10:
				mb.at(Vector3(rng.randf_range(-0.03, 0.03), py + 0.02, rng.randf_range(-0.025, 0.025)), Vector3(0, rng.randf() * TAU, 0)); mb.rbox(Vector3(0.004, 0.0012, 0.0012), 0.0005, 1); mb.pop()
		"omelette":
			var half := PackedVector2Array()
			for i in 25:
				var a := PI * i / 24.0
				half.append(Vector2(cos(a) * 0.058, sin(a) * 0.042 - 0.015))
			mb.at(Vector3(0, py, 0), Vector3(0, 0.25, 0))
			mb.col(Color("FFD84A"), 1.0, 0.15); mb.extrude(half, 0.02, 0.0095, 4, Color("FFE070"))
			mb.col(Color("F2B830"), 0.0)
			var rng := _rng(2)
			for i in 6:
				mb.at(Vector3(rng.randf_range(-0.03, 0.03), 0.0202, rng.randf_range(-0.005, 0.02))); mb.ellipsoid(0.005, 0.0004, 0.0035, 8, 3); mb.pop()
			var vegs := _extras(sp, ["egg", "cheese", "milk"])
			for i in mini(vegs.size(), 4):
				garnish(mb, vegs[i], Vector3(-0.035 + i * 0.022, 0.004, -0.017), 0.9, i)
			if _has(sp, "cheese"):
				mb.col(Color("FFE88A"), 0.6, 0.5)
				for x in [-0.02, 0.0, 0.025]:
					mb.at(Vector3(x, 0.006, -0.016)); mb.ellipsoid(0.006, 0.004, 0.003, 10, 6); mb.pop()
			zigzag(mb, Color("E8402E"), Vector3(0, 0.021, 0.005), 0.07, 0.016, 4, 0.0018)
			mb.pop()
		"bacon":
			_fried_egg(mb, Vector3(0.012, py, 0.008), 1.0)
			for i in 2:
				var pts := PackedVector3Array()
				for k in 8:
					pts.append(Vector3(-0.055 + k * 0.012, py + 0.004 + (0.0025 if k % 2 else 0.0), -0.03 + i * 0.016 + k * 0.002))
				mb.tube(MB.spline3(pts, 2), 0.009, 10, func(u: float, _v: float, _p: Vector3) -> Color: return Color("F2C8C0") if absf(sin(u * TAU)) < 0.3 else Color("B8434E"), 0.3, Vector3.UP)
		_:
			if _has(sp, "bread"):
				_toast_slice(mb, Vector3(0, py, 0), 0.9, Color("E2A55A"))
				_fried_egg(mb, Vector3(0, py + 0.012, 0), 1.0)
			else:
				_fried_egg(mb, Vector3(0, py, 0), 1.3)

static func _bread_outline(s := 1.0) -> PackedVector2Array:
	var prof := PackedVector2Array()
	for i in 5:
		var a := PI + i / 4.0 * PI * 0.5
		prof.append(Vector2(-0.032 + cos(a) * 0.005, 0.03 - (0.005 + sin(a) * 0.005)) * s)
	for i in 5:
		var a := PI * 1.5 + i / 4.0 * PI * 0.5
		prof.append(Vector2(0.032 + cos(a) * 0.005, 0.03 - (0.005 + sin(a) * 0.005)) * s)
	for i in 12:
		var a := i / 11.0 * (PI - 0.42)
		prof.append(Vector2(0.0175 + cos(a) * 0.0185, 0.03 - (0.034 + sin(a) * 0.0185)) * s)
	for i in 12:
		var a := 0.42 + i / 11.0 * (PI - 0.42)
		prof.append(Vector2(-0.0175 + cos(a) * 0.0185, 0.03 - (0.034 + sin(a) * 0.0185)) * s)
	return prof

## A slice of toast lying flat.
static func _toast_slice(mb: MB, pos: Vector3, s: float, top: Color, yaw := 0.0) -> void:
	var o := _bread_outline(1.15 * s)
	mb.at(pos, Vector3(0, yaw, 0))
	mb.col(Color("C8823A"), 1.0, 0.1); mb.extrude(o, 0.012 * s, 0.003, 2, Color("C8823A"))
	mb.col(top, 0.4, 0.1); mb.at(Vector3(0, 0.0005, 0)); mb.extrude(_scaled(o, 0.86), 0.0122 * s, 0.002, 2, top); mb.pop()
	mb.pop()

static func _toast(mb: MB, sp: Dictionary) -> void:
	var st: String = sp.get("style", "")
	var main: Color = sp.get("main", Color("E2A55A"))
	var py := plate(mb, 0.1)
	match st:
		"honey":
			mb.col(Color("D9954A"), 1.0, 0.1); mb.at(Vector3(0, py + 0.03, 0), Vector3(0, 0.3, 0)); mb.rbox(Vector3(0.07, 0.06, 0.07), 0.008, 2); mb.pop()
			mb.col(Color("FFF0D2"), 0.5); mb.at(Vector3(0, py + 0.0605, 0), Vector3(0, 0.3, 0)); mb.rbox(Vector3(0.06, 0.003, 0.06), 0.002, 1); mb.pop()
			drip_pool(mb, Color("F6B73C"), Vector3(0, py + 0.062, 0), 0.03, 0.04, 6, 5, 0.035)
			if _has(sp, "cream"): cream_swirl(mb, Vector3(0.004, py + 0.064, 0), 0.02, 0.028)
			else: garnish(mb, "butter", Vector3(0, py + 0.064, 0), 1.2)
		"french":
			_toast_slice(mb, Vector3(-0.012, py, 0.005), 0.95, Color("D9954A"), 0.25)
			_toast_slice(mb, Vector3(0.015, py + 0.012, -0.006), 0.95, Color("E0A050"), -0.3)
			mb.col(WHITE, 0.0)
			var rng := _rng(4)
			for i in 30:
				mb.at(Vector3(rng.randf_range(-0.03, 0.04), py + 0.0255, rng.randf_range(-0.03, 0.02))); mb.sphere(0.001, 4, 3); mb.pop()
			drip_pool(mb, SYRUP, Vector3(0.012, py + 0.024, -0.004), 0.018, 0.03, 3, 2, 0.012)
			if _has(sp, "strawberry"):
				for i in 3: garnish(mb, "strawberry", Vector3(0.04 + i * 0.012, py, 0.035 - i * 0.008), 1.0, i)
		"avo":
			_toast_slice(mb, Vector3(0, py, 0), 1.0, main)
			mb.col(Color("A8D46A"), 0.6, 0.2); mb.at(Vector3(0, py + 0.012, 0.002)); mb.blob(0.034, 0.006, 0.026, 0.25, 0.9, 4, 18, 8, func(_u: float, v: float, _p: Vector3) -> Color: return Color("7DB54A").lerp(Color("D0EC8A"), v)); mb.pop()
			mb.col(Color("D8402E"), 0.0)
			var rng := _rng(3)
			for i in 10:
				mb.at(Vector3(rng.randf_range(-0.025, 0.025), py + 0.019, rng.randf_range(-0.018, 0.02))); mb.sphere(0.0011, 4, 3); mb.pop()
			if _has(sp, "egg"): _fried_egg(mb, Vector3(0.0, py + 0.018, 0.0), 0.65)
			elif _has(sp, "tomato"):
				for i in 2: garnish(mb, "tomato", Vector3(-0.012 + i * 0.024, py + 0.019, 0.004), 1.1)
		"grilled":
			for half in 2:
				mb.at(Vector3(-0.02 + half * 0.034, py + half * 0.016, half * -0.01), Vector3(half * 0.5, 0.4 - half * 0.9, half * 0.25))
				var tri := PackedVector2Array([Vector2(-0.042, 0.03), Vector2(0.042, 0.03), Vector2(-0.042, -0.035)])
				var rt := PackedVector2Array()
				for i in 3:
					var a := tri[i]; var b := tri[(i + 1) % 3]
					for k in 6: rt.append(a.lerp(b, 0.06 + 0.88 * k / 5.0))
				mb.col(Color("D9954A"), 1.0, 0.1); mb.extrude(rt, 0.01, 0.003, 2, Color("E8A850"))
				mb.col(Color("FFD84A"), 0.6, 0.5); mb.at(Vector3(0, 0.0095, 0)); mb.extrude(_scaled(rt, 1.04), 0.004, 0.0015); mb.pop()
				mb.col(Color("D9954A"), 1.0, 0.1); mb.at(Vector3(0, 0.0135, 0)); mb.extrude(rt, 0.01, 0.003, 2, Color("E8A850")); mb.pop()
				mb.col(Color("FFD84A"), 0.6, 0.6)
				for d in 3:
					var x := -0.03 + d * 0.025
					mb.tube(PackedVector3Array([Vector3(x, 0.012, 0.03), Vector3(x + 0.002, 0.008, 0.034), Vector3(x + 0.001, 0.003, 0.035)]), 0.0025, 6)
				mb.pop()
		_:
			_toast_slice(mb, Vector3(0, py, 0), 1.0, main)
			if st == "egg":
				_fried_egg(mb, Vector3(0.0, py + 0.024, 0.0), 0.75)
			elif st == "cheese":
				mb.col(Color("FFD84A"), 0.6, 0.6); mb.at(Vector3(0, py + 0.024, 0)); mb.blob(0.03, 0.003, 0.026, 0.2, 1.0, 2, 16, 6); mb.pop()
			else:
				garnish(mb, "butter", Vector3(0.0, py + 0.024, 0.0), 1.3, 0.5)
				if _has(sp, "honey"): zigzag(mb, Color("F6B73C"), Vector3(0, py + 0.026, 0.006), 0.05, 0.02, 3, 0.002)
				var fr := _extras(sp, ["butter", "honey"])
				for i in mini(fr.size(), 3): garnish(mb, fr[i], Vector3(-0.02 + i * 0.02, py + 0.025, -0.012), 1.0, i)

static func _bun_half(mb: MB, pos: Vector3, r: float, h: float, top: bool) -> void:
	mb.at(pos)
	if top:
		mb.col(Color("E8A050"), 1.0, 0.3)
		mb.lathe(MB.spline(PackedVector2Array([Vector2(0, 0), Vector2(r * 0.95, 0.0), Vector2(r, h * 0.25), Vector2(r * 0.8, h * 0.8), Vector2(0, h)]), 4), 32, Callable(), func(_u: float, v: float, p: Vector3) -> Color: return Color("FFE9C0") if p.y < h * 0.12 else Color("C8742E").lerp(Color("F2B060"), v), 12)
		var rng := _rng(5)
		mb.col(Color("FFF6DC"), 0.0)
		for i in 14:
			var a := rng.randf() * TAU
			var d := sqrt(rng.randf()) * 0.75
			var y := h * (1.0 - d * d * 0.8) - 0.0006
			mb.at(Vector3(cos(a) * r * d, y, sin(a) * r * d), Vector3(0, rng.randf() * TAU, 0)); mb.ellipsoid(0.0022, 0.0009, 0.0013, 6, 3); mb.pop()
	else:
		mb.col(Color("E8A050"), 1.0, 0.1)
		mb.puck(r, h, h * 0.4, 32, -1.0, func(_u: float, _v: float, p: Vector3) -> Color: return Color("FFE9C0") if p.y > h * 0.85 else Color("D9954A"))
	mb.pop()

static func _burger(mb: MB, sp: Dictionary) -> void:
	var y := board(mb, 0.15, 0.13)
	var r := 0.052
	_bun_half(mb, Vector3(0, y, 0), r, 0.014, false)
	y += 0.014
	mb.col(Color("6A3A22"), 1.0, 0.3); mb.at(Vector3(0, y, 0)); mb.blob(r * 1.02, 0.0085, r * 1.02, 0.05, 1.0, 3, 28, 8); mb.pop()
	y += 0.009
	if _has(sp, "cheese"):
		mb.at(Vector3(0, y, 0), Vector3(0, 0.6, 0)); mb.col(Color("FFC830"), 1.0, 0.4); mb.rbox(Vector3(0.082, 0.003, 0.082), 0.0012, 1)
		for c in [Vector3(0.041, -0.004, 0.0), Vector3(0.0, -0.005, 0.041), Vector3(-0.03, -0.004, -0.03)]:
			mb.at(c); mb.ellipsoid(0.008, 0.006, 0.006, 10, 6); mb.pop()
		mb.pop()
		y += 0.003
	if _has(sp, "tomato"):
		for i in 2:
			mb.at(Vector3(-0.016 + i * 0.03, y, (i - 0.5) * 0.02)); mb.col(Color("E8402E"), 1.0, 0.5); mb.puck(0.022, 0.0045, 0.0015, 20)
			mb.col(Color("FF9A80"), 0.0); mb.at(Vector3(0, 0.0003, 0)); mb.puck(0.017, 0.0046, 0.001, 18); mb.pop(); mb.pop()
		y += 0.0045
	if _has(sp, "lettuce"):
		mb.col(Color("8ED16B"), 1.0, 0.1)
		mb.at(Vector3(0, y + 0.002, 0)); mb.lathe(PackedVector2Array([Vector2(0, -0.001), Vector2(r * 1.12, -0.001), Vector2(r * 1.14, 0.001), Vector2(r * 1.0, 0.0025), Vector2(0, 0.0025)]), 40, func(u: float, _v: float) -> float: return 1.0 + 0.08 * sin(u * TAU * 11.0), Callable(), 6); mb.pop()
		y += 0.004
	if _has(sp, "onion"):
		mb.col(Color("F3E2F7"), 0.6)
		for i in 2:
			mb.at(Vector3(-0.012 + i * 0.024, y + 0.001, 0.004)); mb.torus(0.012, 0.0018, 20, 6); mb.pop()
		y += 0.002
	_bun_half(mb, Vector3(0, y, 0), r * 1.02, 0.032, true)
	if not _has(sp, "cheese"):
		mb.col(Color("E8402E"), 0.0, 0.6); mb.at(Vector3(0.02, y - 0.001, 0.04)); mb.ellipsoid(0.008, 0.004, 0.005, 10, 6); mb.pop()

static func _hotdog(mb: MB, sp: Dictionary) -> void:
	var y := board(mb, 0.17, 0.08)
	mb.at(Vector3(0, y, 0), Vector3(0, 0.2, 0))
	for s in [-1.0, 1.0]:
		mb.col(Color("E8A050"), 1.0, 0.2); mb.at(Vector3(0, 0.014, s * 0.011), Vector3(s * 0.45, 0, 0)); mb.rbox(Vector3(0.12, 0.026, 0.018), 0.009, 3); mb.pop()
	mb.col(Color("C8503A"), 1.0, 0.6)
	mb.tube(PackedVector3Array([Vector3(-0.07, 0.024, 0), Vector3(0, 0.022, 0), Vector3(0.07, 0.024, 0)]), func(t: float) -> float: return 0.0105 * pow(sin(clampf(t, 0.02, 0.98) * PI), 0.2), 12, func(u: float, _v: float, _p: Vector3) -> Color: return Color("E8846A") if sin(u * TAU) > 0.6 else Color("C8503A"))
	var pts := PackedVector3Array()
	for i in 13:
		pts.append(Vector3(-0.055 + i * 0.0092, 0.0345, 0.004 * (1.0 if i % 2 else -1.0)))
	mb.col(Color("FFD030"), 0.4, 0.8); mb.tube(MB.spline3(pts, 3), 0.0022, 6)
	if _has(sp, "onion"):
		mb.col(Color("F3E2F7"), 0.4)
		var rng := _rng(5)
		for i in 8:
			mb.at(Vector3(rng.randf_range(-0.04, 0.04), 0.034, rng.randf_range(-0.006, 0.006))); mb.rbox(Vector3(0.004, 0.003, 0.004), 0.001, 1); mb.pop()
	mb.pop()

static func _taco(mb: MB, sp: Dictionary) -> void:
	var py := plate(mb, 0.1)
	var quesa: bool = sp.get("style", "") == "quesadilla"
	if quesa:
		for i in 3:
			var tri := PackedVector2Array()
			for k in 10: tri.append(Vector2(cos(-0.45 + k / 9.0 * 0.9), sin(-0.45 + k / 9.0 * 0.9)) * 0.06)
			tri.append(Vector2.ZERO)
			mb.at(Vector3(-0.025, py + i * 0.004, 0), Vector3(0, -0.6 + i * 0.6, 0))
			mb.col(Color("F2C87A"), 1.0, 0.1); mb.extrude(tri, 0.011, 0.004, 2, Color("E8B060"))
			mb.col(Color("FFD84A"), 0.4, 0.6); mb.at(Vector3(0.05, 0.004, 0)); mb.ellipsoid(0.004, 0.004, 0.012, 8, 5); mb.pop()
			mb.pop()
		return
	for i in 2:
		mb.at(Vector3(-0.026 + i * 0.05, py, -0.006 + i * 0.012), Vector3(0, 0.15 - i * 0.3, 0))
		# shell: a folded tortilla, inner and outer skins
		for side in [0, 1]:
			mb.col(Color("F2C870") if side == 0 else Color("E8B860"), 1.0, 0.1)
			mb.grid(func(u: float, v: float) -> Vector3:
				var a := PI * (0.06 + u * 0.88)
				var x := -0.052 * cos(a)
				var rr: float = 0.034 * pow(sin(a), 0.6) + side * 0.0025
				var b := lerpf(-PI * 0.5, PI * 0.5, v if side == 0 else 1.0 - v)
				return Vector3(x, 0.003 + rr * (1.0 - cos(b)), rr * sin(b) * 0.8), 18, 10, false)
		mb.col(Color("8A4A2A"), 0.6, 0.2); mb.at(Vector3(0, 0.024, 0)); mb.blob(0.034, 0.008, 0.012, 0.3, 1.5, 4 + i, 16, 6); mb.pop()
		mb.col(Color("8ED16B"), 0.4, 0.0)
		var rng := _rng(i + 3)
		for k in 8:
			mb.at(Vector3(rng.randf_range(-0.032, 0.032), 0.031 + rng.randf() * 0.004, rng.randf_range(-0.008, 0.008)), Vector3(rng.randf(), rng.randf() * TAU, 0)); mb.leaf(0.0055, 0.0035, 0.001, 0.5); mb.pop()
		mb.col(Color("E8402E"), 0.4, 0.4)
		for k in 4:
			mb.at(Vector3(rng.randf_range(-0.03, 0.03), 0.034, rng.randf_range(-0.006, 0.006))); mb.rbox(Vector3(0.0055, 0.004, 0.0055), 0.0012, 1); mb.pop()
		mb.col(Color("FFD84A"), 0.0, 0.2)
		for k in 10:
			mb.at(Vector3(rng.randf_range(-0.03, 0.03), 0.037, rng.randf_range(-0.007, 0.007)), Vector3(0, rng.randf() * TAU, 0)); mb.rbox(Vector3(0.006, 0.0013, 0.0013), 0.0005, 1); mb.pop()
		mb.pop()

static func _pizza(mb: MB, sp: Dictionary) -> void:
	var y := board(mb, 0.2, 0.18)
	var r := 0.078
	mb.col(Color("E8A050"), 1.0, 0.2)
	mb.at(Vector3(0, y, 0)); mb.lathe(MB.spline(PackedVector2Array([Vector2(0, 0), Vector2(r * 0.98, 0.0), Vector2(r * 1.02, 0.007), Vector2(r * 0.96, 0.013), Vector2(r * 0.88, 0.009), Vector2(0, 0.007)]), 3), 44, func(u: float, _v: float) -> float: return 1.0 + 0.015 * sin(u * TAU * 9.0), func(_u: float, _v: float, p: Vector3) -> Color: return Color("F2B860") if p.y > 0.008 else Color("D9954A"), 14); mb.pop()
	mb.col(Color("D8301E"), 0.0, 0.6); mb.at(Vector3(0, y + 0.0055, 0)); mb.puck(r * 0.86, 0.003, 0.001, 36); mb.pop()
	mb.col(Color("FFE7A0"), 0.4, 0.5)
	var rng := _rng(3)
	for i in 11:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * r * 0.66
		mb.at(Vector3(cos(a) * d, y + 0.008, sin(a) * d), Vector3(0, rng.randf() * TAU, 0)); mb.blob(0.017, 0.0026, 0.014, 0.3, 1.2, i, 14, 5, func(_u: float, v: float, _p: Vector3) -> Color: return Color("FFF0B0").lerp(Color("FFD86A"), 1.0 - v)); mb.pop()
	mb.col(Color("D8A030"), 0.0)
	for i in 12:
		mb.at(Vector3(rng.randf_range(-0.055, 0.055), y + 0.0105, rng.randf_range(-0.055, 0.055))); mb.ellipsoid(0.003, 0.0004, 0.002, 6, 3); mb.pop()
	if _has(sp, "sausage"):
		for i in 7:
			var a := i * TAU / 7.0 + 0.3
			var d := r * (0.32 if i % 2 else 0.6)
			mb.at(Vector3(cos(a) * d, y + 0.0095, sin(a) * d)); mb.col(Color("C8303A"), 1.0, 0.6); mb.puck(0.0105, 0.003, 0.0012, 16)
			mb.col(Color("E8606A"), 0.0)
			for k in 3:
				mb.at(Vector3(cos(k * 2.1) * 0.005, 0.0031, sin(k * 2.1) * 0.005)); mb.sphere(0.0011, 4, 3); mb.pop()
			mb.pop()
	else:
		for i in 5:
			var a := i * TAU / 5.0
			garnish(mb, "spinach", Vector3(cos(a) * r * 0.45, y + 0.011, sin(a) * r * 0.45), 1.15, a)
	var extra := _extras(sp, ["tomato", "cheese", "sausage", "flour"])
	scatter(mb, extra, 6, Vector3(0, y + 0.01, 0), r * 0.6, r * 0.6, 1.0, 8)

static func _maki_piece(mb: MB, pos: Vector3, tops: Array, s := 1.0) -> void:
	mb.at(pos, Vector3(0, 0, 0), Vector3(s, s, s))
	mb.col(Color("1F2C25"), 1.0, 0.3); mb.puck(0.019, 0.022, 0.003, 24)
	mb.col(Color("FDFAF3"), 0.0, 0.1); mb.at(Vector3(0, 0.0003, 0)); mb.puck(0.016, 0.0222, 0.002, 22); mb.pop()
	_grains(mb, Vector3(0, 0.0215, 0), 0.0145, 12, int(pos.x * 1000.0) + 3)
	var n := maxi(tops.size(), 1)
	for i in mini(tops.size(), 3):
		var a := i * TAU / n + 0.4
		var d := 0.0 if n == 1 else 0.0045
		mb.col(tops[i], 0.4, 0.6); mb.at(Vector3(cos(a) * d, 0.019, sin(a) * d)); mb.rbox(Vector3(0.0085 if n == 1 else 0.0062, 0.0058, 0.0085 if n == 1 else 0.0062), 0.0018, 1); mb.pop()
	mb.pop()

static func _maki(mb: MB, sp: Dictionary) -> void:
	var y := board(mb, 0.19, 0.11)
	var tops: Array = sp.get("tops", [])
	if tops.is_empty(): tops = [Color("F4895A")]
	var fut := tops.size() >= 3
	for i in 6:
		var row := i / 3
		var col := i % 3
		_maki_piece(mb, Vector3(-0.048 + col * 0.04, y, -0.02 + row * 0.04), tops, 1.18 if fut else 1.0)
	mb.col(Color("FFB8C8"), 0.6, 0.2)
	for i in 4:
		mb.at(Vector3(0.078, y + 0.002 + i * 0.0012, 0.025 + (i % 2) * 0.004), Vector3(0.2, i * 0.8, 0)); mb.leaf(0.008, 0.006, 0.0008, 0.6); mb.pop()
	mb.col(Color("9BCB5E"), 1.0, 0.3); mb.at(Vector3(0.078, y + 0.003, -0.025)); mb.blob(0.009, 0.006, 0.008, 0.25, 1.5, 2, 12, 8); mb.pop()

static func _onigiri_shape(mb: MB, pos: Vector3, s: float, yaw := 0.0) -> void:
	mb.at(pos, Vector3(0, yaw, 0), Vector3(s, s, s))
	mb.col(Color("FFFDF6"), 1.0, 0.15)
	mb.grid(func(u: float, v: float) -> Vector3:
		var a := u * TAU
		var ph := v * PI
		var tri := 1.0 + 0.16 * cos(3.0 * (a + PI * 0.5))
		var rr := sin(ph) * 0.036 * tri
		var y := (1.0 - cos(ph)) * 0.5
		return Vector3(cos(a) * rr * 1.05 * (1.0 - y * 0.25), y * 0.072 - 0.0, sin(a) * rr * 0.62), 30, 16, true)
	_grains_on_onigiri(mb)
	mb.col(Color("1F2C25"), 1.0, 0.25); mb.at(Vector3(0, 0.014, 0.0)); mb.rbox(Vector3(0.034, 0.028, 0.048), 0.004, 2); mb.pop()
	mb.col(Color("3F5E4C"), 0.0)
	for i in 3:
		mb.at(Vector3(0, 0.006 + i * 0.008, 0.0242)); mb.rbox(Vector3(0.03, 0.0008, 0.0008), 0.0003, 1); mb.pop()
	mb.pop()

static func _grains_on_onigiri(mb: MB) -> void:
	var rng := _rng(11)
	mb.col(Color("F2EADB"), 0.0)
	for i in 30:
		var a := rng.randf() * TAU
		var y := rng.randf_range(0.03, 0.065)
		var t := y / 0.072
		var r := 0.036 * sin(acos(1.0 - 2.0 * t)) * (1.0 + 0.16 * cos(3.0 * (a + PI * 0.5)))
		mb.at(Vector3(cos(a) * r * 1.05 * (1.0 - t * 0.25), y, sin(a) * r * 0.62), Vector3(0, rng.randf() * TAU, 0)); mb.ellipsoid(0.0026, 0.001, 0.0014, 6, 3); mb.pop()

static func _onigiri(mb: MB, sp: Dictionary) -> void:
	var main: Color = sp.get("main", Color("F4895A"))
	if sp.get("style", "") == "nigiri":
		var y := board(mb, 0.17, 0.08)
		for i in 2:
			mb.at(Vector3(-0.034 + i * 0.066, y, 0.0), Vector3(0, 0.15 - i * 0.3, 0))
			mb.col(Color("FFFDF6"), 1.0, 0.1); mb.at(Vector3(0, 0.011, 0)); mb.blob(0.026, 0.012, 0.016, 0.06, 1.5, i, 18, 10); mb.pop()
			_grains(mb, Vector3(0, 0.017, 0.0), 0.018, 10, i + 4)
			mb.col(main, 1.0, 0.7)
			mb.grid(func(u: float, v: float) -> Vector3:
				var x := lerpf(-0.034, 0.034, u)
				var z := lerpf(-0.018, 0.018, v)
				var bow := 1.0 - pow(x / 0.034, 2.0)
				return Vector3(x, 0.022 + bow * 0.006 - pow(z / 0.018, 2.0) * 0.004, z), 12, 6, false,
				func(u: float, _v: float, _p: Vector3) -> Color: return main.lightened(0.45) if fposmod(u * 6.0 + 0.2, 1.0) < 0.14 else main)
			mb.col(main.darkened(0.08), 1.0, 0.7)
			mb.grid(func(u: float, v: float) -> Vector3:
				var x := lerpf(-0.034, 0.034, u)
				var z := lerpf(0.018, -0.018, v)
				var bow := 1.0 - pow(x / 0.034, 2.0)
				return Vector3(x, 0.0195 + bow * 0.006 - pow(z / 0.018, 2.0) * 0.004, z), 12, 6, false)
			mb.pop()
		mb.col(Color("9BCB5E"), 1.0, 0.3); mb.at(Vector3(0.07, y + 0.003, 0.02)); mb.blob(0.008, 0.005, 0.007, 0.25, 1.5, 2, 12, 8); mb.pop()
		return
	var py := plate(mb, 0.09)
	var has_p := (sp.get("tops", []) as Array).size() > 0
	_onigiri_shape(mb, Vector3(0, py, 0), 1.0)
	if has_p:
		mb.col(main, 0.6, 0.4)
		var rng := _rng(4)
		for i in 5:
			mb.at(Vector3(rng.randf_range(-0.008, 0.008), py + 0.068 + rng.randf() * 0.003, rng.randf_range(-0.004, 0.004)), Vector3(rng.randf(), rng.randf() * TAU, 0)); mb.blob(0.0045, 0.0028, 0.0035, 0.2, 1.5, i, 8, 6); mb.pop()
	face(mb, Vector3(0, py + 0.04, 0.0222), 1.0, "happy")

static func _pile(mb: MB, sp: Dictionary) -> void:
	var st: String = sp.get("style", "")
	var main: Color = sp.get("main", Color("D9954A"))
	match st:
		"fries":
			var py := plate(mb, 0.095)
			var prof := PackedVector2Array([Vector2(0, 0), Vector2(0.026, 0.0), Vector2(0.028, 0.002), Vector2(0.037, 0.06), Vector2(0.034, 0.06), Vector2(0.025, 0.004), Vector2(0, 0.004)])
			mb.at(Vector3(-0.01, py, -0.008)); mb.col(Color("E8402E"), 1.0, 0.2)
			mb.lathe(prof, 30, Callable(), func(u: float, _v: float, p: Vector3) -> Color: return WHITE if fposmod(u * 10.0, 1.0) < 0.35 and p.y > 0.015 and p.y < 0.05 else Color("E8402E"), 10)
			var rng := _rng(5)
			for i in 14:
				var a := rng.randf() * TAU
				var d := sqrt(rng.randf()) * 0.022
				mb.col(Color("FFD24A") if i % 3 else Color("F2B830"), 1.0, 0.2)
				mb.at(Vector3(cos(a) * d, 0.055 + rng.randf() * 0.012, sin(a) * d), Vector3(rng.randf_range(-0.35, 0.35), rng.randf() * TAU, rng.randf_range(-0.35, 0.35))); mb.rbox(Vector3(0.008, 0.06, 0.008), 0.002, 1); mb.pop()
			mb.pop()
			mb.col(WHITE, 1.0, 0.2); mb.at(Vector3(0.05, py, 0.03)); mb.puck(0.018, 0.009, 0.003, 18)
			mb.col(Color("E8402E"), 0.0, 0.8); mb.at(Vector3(0, 0.006, 0)); mb.puck(0.0145, 0.003, 0.001, 16); mb.pop(); mb.pop()
		"popcorn":
			var py := 0.0
			var prof := PackedVector2Array([Vector2(0, 0), Vector2(0.034, 0.0), Vector2(0.036, 0.002), Vector2(0.048, 0.07), Vector2(0.045, 0.07), Vector2(0.034, 0.004), Vector2(0, 0.004)])
			mb.col(Color("FF5A7A"), 1.0, 0.2)
			mb.lathe(prof, 36, Callable(), func(u: float, _v: float, _p: Vector3) -> Color: return Color("FF5A7A") if fposmod(u * 8.0, 1.0) < 0.5 else WHITE, 10)
			var car := _has(sp, "caramel")
			var but := _has(sp, "butter")
			var rng := _rng(6)
			for i in 22:
				var a := rng.randf() * TAU
				var d := sqrt(rng.randf()) * 0.04
				var yy := 0.066 + (1.0 - d / 0.04) * 0.02 + rng.randf() * 0.006
				mb.at(Vector3(cos(a) * d, yy, sin(a) * d)).col(Color("FFFBEA"), 0.7, 0.3 if car else 0.0)
				mb.blob(0.0105, 0.009, 0.0105, 0.3, 0.6, i, 12, 8, func(_u: float, v: float, _p: Vector3) -> Color:
					if car: return Color("C8742E").lerp(Color("F2B060"), v)
					return Color("FFE070") if v < 0.28 else (Color("FFF4C0") if but else Color("FFFBEA")))
				mb.pop()
		"noodle":
			var py := plate(mb, 0.1)
			var rng := _rng(4)
			for i in 14:
				var pts := PackedVector3Array()
				var a0 := rng.randf() * TAU
				var rr := rng.randf_range(0.005, 0.045)
				for k in 8:
					var a := a0 + k * 0.4
					pts.append(Vector3(cos(a) * rr, py + 0.006 + (1.0 - rr / 0.045) * 0.02 + sin(k + i) * 0.003, sin(a) * rr * 0.85))
				mb.col(main if i % 2 else main.lightened(0.12), 0.4, 0.3); mb.tube(MB.spline3(pts, 2), 0.003, 6)
			scatter(mb, _extras(sp, ["soy"]), 8, Vector3(0, py + 0.024, 0), 0.03, 0.026, 1.0, 5)
			mb.col(Color("4E9E57"), 0.0)
			for i in 20:
				mb.at(Vector3(rng.randf_range(-0.03, 0.03), py + 0.03, rng.randf_range(-0.025, 0.025))); mb.sphere(0.001, 4, 3); mb.pop()
		"rice":
			# a golden dome of egg-fried rice, packed with colourful bits
			var py := plate(mb, 0.1)
			var R := 0.064
			var H := 0.05
			var dome := func(d: float) -> float: return H * (1.0 - pow(d, 3.0)) + 0.0025
			mb.col(Color("F2D27A"), 1.0, 0.1)
			mb.at(Vector3(0, py, 0)); mb.lathe(MB.spline(PackedVector2Array([Vector2(0, 0), Vector2(R, 0.0), Vector2(R * 0.93, H * 0.3), Vector2(R * 0.6, H * 0.82), Vector2(0, H)]), 4), 34,
				func(u: float, v: float) -> float: return 1.0 + 0.035 * sin(u * TAU * 7.0) * v, func(_u: float, v: float, _p: Vector3) -> Color: return Color("E8B858").lerp(Color("FFE7A0"), v), 12); mb.pop()
			_grains(mb, Vector3(0, py, 0), R * 0.9, 70, 4, H * 0.95)
			var rng := _rng(3)
			var bits := [[Color("FF8A2B"), 0.0065], [Color("FFD84A"), 0.009], [Color("6BBF59"), 0.0055], [Color("FFE36A"), 0.008], [Color("E8402E"), 0.006]]
			for i in 42:
				var a := rng.randf() * TAU
				var d := sqrt(rng.randf()) * 0.95
				var p := Vector3(cos(a) * d * R, py + dome.call(d) + 0.0015, sin(a) * d * R)
				var bc: Array = bits[i % bits.size()]
				mb.col(bc[0], 0.5 if bc[1] > 0.007 else 0.0, 0.3)
				mb.at(p, Vector3(rng.randf(), rng.randf() * TAU, rng.randf()))
				if i % 5 == 2: mb.sphere(bc[1] * 0.55, 8, 6)
				else: mb.rbox(Vector3(bc[1], bc[1] * 0.6, bc[1] * 0.8), bc[1] * 0.25, 1)
				mb.pop()
			mb.col(Color("4E9E57"), 0.4)
			for i in 7:
				var a := i * 0.9
				mb.at(Vector3(cos(a) * 0.012, py + H + 0.002, sin(a) * 0.012)); mb.torus(0.0035, 0.0013, 10, 5); mb.pop()
		"dumpling":
			var py := plate(mb, 0.1)
			for i in 5:
				var row := i / 3
				mb.at(Vector3(-0.042 + (i % 3) * 0.042 + row * 0.02, py, -0.018 + row * 0.04), Vector3(0, 0.15 * (i - 2), 0))
				mb.col(Color("FFF2DC"), 1.0, 0.25)
				mb.grid(func(u: float, v: float) -> Vector3:
					var a := PI * u
					var r := 0.022 * pow(sin(a), 0.7)
					var b := lerpf(PI, 0.0, v)
					return Vector3(-0.03 * cos(a), r * sin(b) * 1.25, r * cos(b) * 0.95), 18, 12, false,
					func(_u: float, _v: float, p: Vector3) -> Color: return Color("C8822E") if p.y < 0.006 else Color("E8B060") if p.y < 0.009 else Color("FFF4E0"))
				mb.col(Color("F6E2BE"), 0.6, 0.2)
				for k in 5:
					mb.at(Vector3(-0.016 + k * 0.008, 0.0262, 0.0), Vector3(0, 0, 0.5)); mb.ellipsoid(0.0042, 0.003, 0.0022, 8, 5); mb.pop()
				mb.pop()
			mb.col(WHITE, 1.0, 0.2); mb.at(Vector3(0.062, py, 0.045)); mb.puck(0.019, 0.01, 0.003, 18)
			mb.col(Color("4A2618"), 0.0, 0.8); mb.at(Vector3(0, 0.0065, 0)); mb.puck(0.015, 0.003, 0.001, 16); mb.pop(); mb.pop()
		"tempura":
			# plump, craggy battered shrimp leaning on folded paper, with dipping sauce
			var py := plate(mb, 0.1)
			mb.col(Color("FFFDF6"), 0.6, 0.0); mb.at(Vector3(-0.005, py + 0.001, 0), Vector3(0, 0.5, 0)); mb.rbox(Vector3(0.1, 0.0015, 0.075), 0.0006, 1); mb.pop()
			mb.col(Color("E8E2D2"), 0.0); mb.tube(PackedVector3Array([Vector3(-0.045, py + 0.0028, 0.03), Vector3(0.03, py + 0.0028, -0.04)]), 0.0006, 4)
			for i in 3:
				var pts := PackedVector3Array()
				for k in 7:
					var t := k / 6.0
					pts.append(Vector3(-0.05 + t * 0.09, py + 0.016 + sin(t * PI) * 0.016 + i * 0.006, -0.026 + i * 0.024 + sin(t * 2.5) * 0.006))
				mb.col(Color("E9A94A"), 1.0, 0.25)
				mb.tube(MB.spline3(pts, 3), func(t: float) -> float: return 0.0155 * (0.45 + 0.55 * sin(clampf(t / 0.88, 0.04, 1.0) * PI)), 14,
					func(u: float, v: float, _p: Vector3) -> Color:
						var n := sin(u * 37.0 + v * 23.0) * sin(u * 17.0 - v * 41.0)
						return Color("FFD98A") if n > 0.35 else Color("C8822E") if n < -0.55 else Color("E9A94A"))
				var bumps := _rng(10 + i)
				mb.col(Color("F6C870"), 0.6, 0.2)
				for k in 9:
					var t := bumps.randf_range(0.1, 0.8)
					var c := MB.spline3(pts, 3)
					var idx := int(t * (c.size() - 1))
					var a := bumps.randf() * TAU
					mb.at(c[idx] + Vector3(0, cos(a), sin(a)) * 0.012); mb.blob(0.0045, 0.0035, 0.0045, 0.3, 1.5, k + i * 9, 8, 6); mb.pop()
				var tail := pts[pts.size() - 1]
				for sgn in [-1.0, 1.0]:
					mb.col(Color("FF5A3A"), 1.0, 0.4)
					mb.at(tail + Vector3(0.008, 0.004, sgn * 0.004), Vector3(0, sgn * 0.5, -0.6)); mb.leaf(0.008, 0.0065, 0.0015, 0.0); mb.pop()
			mb.col(WHITE, 1.0, 0.2); mb.at(Vector3(0.062, py, 0.048)); mb.puck(0.019, 0.01, 0.003, 18)
			mb.col(Color("6A3A22"), 0.0, 0.8); mb.at(Vector3(0, 0.0065, 0)); mb.puck(0.015, 0.003, 0.001, 16); mb.pop(); mb.pop()
			mb.col(Color("FFFDF6"), 0.5); mb.at(Vector3(0.062, py + 0.0102, 0.048)); mb.blob(0.006, 0.003, 0.006, 0.3, 1.5, 3, 8, 6); mb.pop()
		"nachos":
			var py := plate(mb, 0.1)
			var rng := _rng(4)
			for i in 12:
				var a := rng.randf() * TAU
				var d := sqrt(rng.randf()) * 0.045
				mb.at(Vector3(cos(a) * d, py + 0.004 + (1.0 - d / 0.045) * 0.018, sin(a) * d), Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.5, 0.5))); _chip(mb, 1.3); mb.pop()
			mb.col(Color("FFC830"), 0.5, 0.8)
			for i in 5:
				var pts := PackedVector3Array()
				var a0 := rng.randf() * TAU
				for k in 5:
					var a := a0 + k * 0.5
					pts.append(Vector3(cos(a) * 0.025 * (1.0 - k * 0.1), py + 0.026 - k * 0.002, sin(a) * 0.02))
				mb.tube(MB.spline3(pts, 2), 0.0035, 7)
			scatter(mb, _extras(sp, ["cheese", "tortilla"]), 6, Vector3(0, py + 0.026, 0), 0.03, 0.025, 1.0, 6)
		_:
			var py := plate(mb, 0.1)
			var keys := _extras(sp)
			if keys.is_empty(): keys = sp.get("ings", {}).keys().filter(func(k): return G.ING.has(k))
			var rng := _rng(5)
			for i in 18:
				var a := rng.randf() * TAU
				var d := sqrt(rng.randf()) * 0.045
				var k: String = keys[i % keys.size()]
				mb.at(Vector3(cos(a) * d, py + (1.0 - d / 0.045) * 0.016, sin(a) * d), Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, 0))
				garnish(mb, k, Vector3.ZERO, 1.25)
				mb.pop()
			if _has(sp, "soy"): zigzag(mb, Color("6A3A22"), Vector3(0, py + 0.022, 0), 0.06, 0.03, 3, 0.0016)

static func _cookie_one(mb: MB, pos: Vector3, rot: Vector3, choc: bool, sprinkles: bool, seed_: int) -> void:
	mb.at(pos, rot)
	mb.col(Color("E8B26A"), 1.0, 0.1)
	mb.lathe(MB.spline(PackedVector2Array([Vector2(0, 0), Vector2(0.03, 0.0), Vector2(0.032, 0.004), Vector2(0.026, 0.008), Vector2(0, 0.009)]), 3), 32,
		func(u: float, _v: float) -> float: return 1.0 + 0.04 * sin(u * TAU * 5.0 + seed_), func(_u: float, _v: float, p: Vector3) -> Color: return Color("D9954A") if Vector2(p.x, p.z).length() > 0.027 else Color("EAB86A"), 8)
	var rng := _rng(seed_)
	if choc:
		mb.col(Color("4A2416"), 0.6, 0.4)
		for i in 7:
			var a := rng.randf() * TAU
			var d := sqrt(rng.randf()) * 0.022
			mb.at(Vector3(cos(a) * d, 0.0085 - d * 0.04, sin(a) * d)); mb.blob(0.0042, 0.003, 0.0042, 0.2, 1.5, i, 8, 6); mb.pop()
	else:
		mb.col(Color("D9954A"), 0.0)
		for i in 4:
			var a := rng.randf() * TAU
			mb.tube(PackedVector3Array([Vector3(cos(a) * 0.005, 0.0092, sin(a) * 0.005), Vector3(cos(a + 0.3) * 0.016, 0.0088, sin(a + 0.3) * 0.016)]), 0.0007, 4)
		if sprinkles:
			mb.col(Color("FFE3EC"), 0.5, 0.4); mb.at(Vector3(0, 0.0085, 0)); mb.puck(0.022, 0.0018, 0.0008, 24); mb.pop()
			garnish(mb, "sprinkles", Vector3(0, 0.0105, 0), 1.6)
			garnish(mb, "sprinkles", Vector3(0.008, 0.0105, 0.006), 1.3, 1.0)
	mb.pop()

static func _cookie(mb: MB, sp: Dictionary) -> void:
	var py := plate(mb, 0.095)
	var choc: bool = sp.get("style", "") == "choc"
	var spr := _has(sp, "sprinkles")
	_cookie_one(mb, Vector3(-0.03, py, 0.012), Vector3(0, 0, 0), choc, spr, 1)
	_cookie_one(mb, Vector3(0.03, py, 0.015), Vector3(0, 1.0, 0), choc, spr, 2)
	_cookie_one(mb, Vector3(0.0, py + 0.016, -0.018), Vector3(0.5, 0.4, 0.0), choc, spr, 3)

static func _cupcake(mb: MB, sp: Dictionary) -> void:
	var main: Color = sp.get("main", Color("E9B45A"))
	var frost: Color = sp.get("frost", Color("FFB3CF"))
	var muffin: bool = sp.get("style", "") == "muffin"
	mb.col(Color("FF9EBB"), 1.0, 0.2)
	mb.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.028, 0.0), Vector2(0.03, 0.002), Vector2(0.037, 0.04), Vector2(0.034, 0.04), Vector2(0, 0.04)]), 40,
		func(u: float, _v: float) -> float: return 1.0 + 0.035 * absf(sin(u * TAU * 10.0)), func(u: float, _v: float, _p: Vector3) -> Color: return Color("FFB3CF") if fposmod(u * 10.0, 1.0) < 0.5 else Color("FFE3EC"), 10)
	mb.col(main, 1.0, 0.1)
	mb.at(Vector3(0, 0.036, 0)); mb.blob(0.041, 0.018 if muffin else 0.012, 0.041, 0.07, 1.0, 3, 26, 10, func(_u: float, v: float, _p: Vector3) -> Color: return G.darken(main, 0.1).lerp(G.lighten(main, 0.15), v)); mb.pop()
	if muffin:
		mb.col(Color("5B6CD6"), 0.6, 0.4)
		var rng := _rng(2)
		for i in 6:
			var a := rng.randf() * TAU
			mb.at(Vector3(cos(a) * 0.024, 0.05, sin(a) * 0.024)); mb.sphere(0.004, 8, 6); mb.pop()
		return
	cream_swirl(mb, Vector3(0, 0.042, 0), 0.034, 0.042, frost, 3.0)
	var tops := _extras(sp, ["flour", "egg", "sugar", "butter", "milk", "chocolate", "cream"])
	var top_k := ""
	for k in ["cherry", "strawberry", "blueberry"]:
		if tops.has(k):
			top_k = k
			break
	if top_k != "":
		garnish(mb, top_k, Vector3(0.0, 0.082, 0.0), 1.3)
	if _has(sp, "sprinkles") or top_k == "":
		var cols := [Color("FF7EA6"), Color("7FD3F7"), Color("FFD24A"), Color("9BE38F"), Color("C3A6FF")]
		var rng := _rng(4)
		for i in 16:
			var t := rng.randf_range(0.1, 0.75)
			var a := rng.randf() * TAU
			var r := 0.034 * (1.0 - t * 0.85) * 0.75 + 0.004
			mb.col(cols[i % 5], 0.0, 0.3); mb.at(Vector3(cos(a) * r, 0.042 + t * 0.036 + 0.005, sin(a) * r), Vector3(rng.randf(), a, 0)); mb.rbox(Vector3(0.005, 0.0016, 0.0016), 0.0007, 1); mb.pop()

static func _cake(mb: MB, sp: Dictionary) -> void:
	var st: String = sp.get("style", "")
	var main: Color = sp.get("main", Color("F6E0A8"))
	var py := plate(mb, 0.1)
	match st:
		"pie":
			mb.at(Vector3(0, py, 0))
			mb.col(Color("E8A050"), 1.0, 0.1)
			mb.lathe(MB.spline(PackedVector2Array([Vector2(0, 0), Vector2(0.062, 0.0), Vector2(0.07, 0.016), Vector2(0.072, 0.024), Vector2(0.064, 0.026), Vector2(0.058, 0.02), Vector2(0, 0.019)]), 3), 44,
				func(u: float, _v: float) -> float: return 1.0 + 0.025 * absf(sin(u * TAU * 12.0)), func(_u: float, _v: float, p: Vector3) -> Color: return Color("F2B860") if p.y > 0.018 else Color("D9954A"), 12)
			mb.col(Color("FFE8B0"), 0.0, 0.3); mb.at(Vector3(0, 0.0185, 0)); mb.puck(0.058, 0.002, 0.001, 36); mb.pop()
			mb.col(Color("F2B860"), 1.0, 0.2)
			for i in 5:
				var x := -0.044 + i * 0.022
				var l := sqrt(maxf(0.0, 0.058 * 0.058 - x * x))
				mb.at(Vector3(x, 0.022, 0)); mb.rbox(Vector3(0.008, 0.004, l * 2.0), 0.002, 1); mb.pop()
				mb.at(Vector3(0, 0.0245, x)); mb.rbox(Vector3(l * 2.0, 0.004, 0.008), 0.002, 1); mb.pop()
			mb.pop()
			if _has(sp, "cream"): cream_swirl(mb, Vector3(0.0, py + 0.026, 0.0), 0.016, 0.02)
		"loaf":
			mb.at(Vector3(-0.01, py, 0), Vector3(0, 0.35, 0))
			mb.col(main, 1.0, 0.1); mb.at(Vector3(0, 0.022, 0)); mb.rbox(Vector3(0.1, 0.044, 0.05), 0.01, 3); mb.pop()
			mb.col(G.darken(main, 0.15), 0.4); mb.tube(PackedVector3Array([Vector3(-0.038, 0.045, 0.0), Vector3(0.0, 0.048, 0.002), Vector3(0.038, 0.045, 0.0)]), 0.004, 8)
			mb.pop()
			mb.at(Vector3(0.052, py, 0.03), Vector3(0, 0.35, 0.0))
			mb.col(main, 1.0, 0.1); mb.at(Vector3(0, 0.022, 0)); mb.rbox(Vector3(0.014, 0.044, 0.05), 0.005, 2); mb.pop()
			mb.col(Color("F2D29A"), 0.4); mb.at(Vector3(0.0072, 0.021, 0)); mb.rbox(Vector3(0.0012, 0.036, 0.042), 0.0006, 1); mb.pop()
			mb.pop()
			if _has(sp, "chocolate"):
				mb.col(Color("4A2416"), 0.0)
				var rng := _rng(3)
				for i in 8:
					mb.at(Vector3(0.0595, py + rng.randf_range(0.008, 0.038), 0.03 + rng.randf_range(-0.015, 0.015)), Vector3(0, 0.35, 0)); mb.sphere(0.0022, 6, 4); mb.pop()
		"brownie":
			for e in [[Vector3(-0.02, py, 0.01), 0.3], [Vector3(0.025, py, -0.004), -0.25], [Vector3(0.0, py + 0.026, 0.004), 0.1]]:
				mb.at(e[0], Vector3(0, e[1], 0))
				mb.col(main, 1.0, 0.2); mb.at(Vector3(0, 0.013, 0)); mb.rbox(Vector3(0.042, 0.026, 0.042), 0.004, 2); mb.pop()
				mb.col(Color("7A4A33"), 0.0, 0.5)
				for k in 3:
					mb.tube(PackedVector3Array([Vector3(-0.015, 0.0262, -0.01 + k * 0.01), Vector3(0.0, 0.0263, -0.006 + k * 0.01), Vector3(0.016, 0.0262, -0.012 + k * 0.01)]), 0.0007, 4)
				mb.pop()
		_:
			# a tall wedge slice
			var ang := 0.55
			var r := 0.075
			var w := PackedVector2Array([Vector2.ZERO])
			for i in 9:
				var a := -ang * 0.5 + ang * i / 8.0
				w.append(Vector2(cos(a), sin(a)) * r)
			var layers := 3
			var lh := 0.016
			mb.at(Vector3(-0.035, py, 0.0), Vector3(0, -0.5, 0))
			for L in layers:
				mb.col(main, 1.0, 0.1); mb.at(Vector3(0, L * (lh + 0.006), 0)); mb.extrude(w, lh, 0.002, 2, main); mb.pop()
				if L < layers - 1:
					var fill := Color("FFFDF6") if st != "choc" else Color("4A2416")
					mb.col(fill, 0.4, 0.2); mb.at(Vector3(0, L * (lh + 0.006) + lh, 0)); mb.extrude(_scaled(w, 1.0), 0.006, 0.002); mb.pop()
					if st == "short":
						mb.col(Color("F0475E"), 0.0, 0.5)
						for k in 3:
							mb.at(Vector3(r * (0.35 + k * 0.25), L * (lh + 0.006) + lh + 0.003, 0.0), Vector3(0, 0, PI * 0.5)); mb.puck(0.0045, 0.0012, 0.0004, 10); mb.pop()
			var topy := layers * (lh + 0.006) - 0.006
			var icing := Color("FFFDF6") if st != "choc" else Color("3A1A10")
			mb.col(icing, 0.6, 0.9 if st == "choc" else 0.2); mb.at(Vector3(0, topy, 0)); mb.extrude(_scaled(w, 1.0), 0.005, 0.002); mb.pop()
			if st == "short":
				cream_swirl(mb, Vector3(r * 0.55, topy + 0.005, 0.0), 0.014, 0.018)
				garnish(mb, "strawberry", Vector3(r * 0.55, topy + 0.022, 0.0), 1.2)
			elif st == "carrot":
				mb.col(Color("FF8A2B"), 0.6, 0.2); mb.at(Vector3(r * 0.6, topy + 0.007, 0), Vector3(0, 0, PI * 0.5 - 0.3)); mb.cone(0.004, 0.016, 8); mb.pop()
				mb.col(Color("6BBF59"), 0.4); mb.at(Vector3(r * 0.6 - 0.008, topy + 0.008, 0)); mb.sphere(0.003, 6, 4); mb.pop()
				mb.col(Color("F2C88A"), 0.0)
				for k in 8:
					mb.at(Vector3(r * (0.3 + 0.08 * k), topy + 0.0054, sin(k * 2.0) * 0.006)); mb.sphere(0.0012, 4, 3); mb.pop()
			elif st == "choc":
				mb.col(Color("FFFDF6"), 0.0)
				for k in 5:
					mb.at(Vector3(r * (0.3 + 0.12 * k), topy + 0.0055, sin(k * 1.7) * 0.008)); mb.rbox(Vector3(0.004, 0.0012, 0.0012), 0.0005, 1); mb.pop()
				if _has(sp, "cream"): cream_swirl(mb, Vector3(r * 0.5, topy + 0.005, 0.0), 0.013, 0.016)
			mb.pop()

static func _scoop(mb: MB, sp: Dictionary) -> void:
	var st: String = sp.get("style", "")
	var main: Color = sp.get("main", Color("FFC2D2"))
	match st:
		"mochi":
			var py := plate(mb, 0.09)
			mb.col(Color("C8A060"), 0.8); mb.tube(PackedVector3Array([Vector3(-0.07, py + 0.02, 0.0), Vector3(0.07, py + 0.02, 0.0)]), 0.0022, 6)
			var cols := [Color("FFC2D2"), WHITE, Color("CDE8A8")] if _has(sp, "matcha") or _has(sp, "strawberry") else [main, main.lightened(0.1), main]
			for i in 3:
				mb.col(cols[i], 1.0, 0.25); mb.at(Vector3(-0.032 + i * 0.032, py + 0.02, 0.0)); mb.ellipsoid(0.016, 0.0145, 0.016, 20, 12); mb.pop()
		"purin":
			var py := plate(mb, 0.09)
			mb.at(Vector3(0, py, 0))
			mb.col(Color("FFE08A"), 1.0, 0.4)
			mb.lathe(MB.spline(PackedVector2Array([Vector2(0, 0), Vector2(0.038, 0.0), Vector2(0.036, 0.008), Vector2(0.028, 0.04), Vector2(0.025, 0.046), Vector2(0, 0.046)]), 3), 32,
				func(u: float, v: float) -> float: return 1.0 + 0.012 * sin(u * TAU * 3.0) * v, func(_u: float, _v: float, p: Vector3) -> Color: return Color("8A4A1E") if p.y > 0.04 else Color("FFE08A").lerp(Color("FFF0B8"), p.y / 0.04), 14)
			for i in 5:
				var a := i * TAU / 5.0 + 0.4
				mb.col(Color("8A4A1E"), 0.5, 1.0); mb.tube(PackedVector3Array([Vector3(cos(a) * 0.024, 0.042, sin(a) * 0.024), Vector3(cos(a) * 0.027, 0.034, sin(a) * 0.027), Vector3(cos(a) * 0.029, 0.026 + (i % 2) * 0.006, sin(a) * 0.029)]), 0.0026, 6)
			if _has(sp, "cream"): cream_swirl(mb, Vector3(0, 0.046, 0), 0.012, 0.015)
			if _has(sp, "cherry"): garnish(mb, "cherry", Vector3(0, 0.046 + (0.013 if _has(sp, "cream") else 0.0), 0), 1.1)
			mb.pop()
		"pop":
			var tops: Array = sp.get("tops", [])
			if tops.is_empty(): tops = [main]
			mb.col(Color("E8C890"), 1.0, 0.1); mb.at(Vector3(0, 0.003, 0.04), Vector3(PI * 0.5, 0, 0)); mb.rbox(Vector3(0.012, 0.05, 0.004), 0.003, 1); mb.pop()
			mb.at(Vector3(0, 0.012, -0.02), Vector3(-PI * 0.5 + 0.12, 0, 0))
			for i in tops.size():
				var h := 0.075 / tops.size()
				mb.col(tops[i], 1.0, 0.5); mb.at(Vector3(0, -0.0375 + h * (i + 0.5), 0)); mb.rbox(Vector3(0.042, h + (0.001 if i < tops.size() - 1 else 0.0), 0.02), 0.008 if (i == 0 or i == tops.size() - 1) else 0.003, 2); mb.pop()
			mb.pop()
		_:
			# ice cream cup with scoops
			mb.col(Color("FFB3CF"), 1.0, 0.3)
			mb.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.024, 0.0), Vector2(0.026, 0.002), Vector2(0.04, 0.034), Vector2(0.037, 0.034), Vector2(0, 0.034)]), 36, Callable(),
				func(u: float, _v: float, p: Vector3) -> Color: return WHITE if absf(p.y - 0.02) < 0.004 and fposmod(u * 18.0, 1.0) < 0.5 else Color("FFB3CF"), 10)
			var n := 2
			for i in n:
				var pos := Vector3(-0.012 + i * 0.024, 0.044 + i * 0.006, -0.004 + i * 0.006)
				mb.col(main, 1.0, 0.2); mb.at(pos); mb.blob(0.022, 0.018, 0.022, 0.08, 1.2, i, 20, 12, func(_u: float, v: float, _p: Vector3) -> Color: return G.darken(main, 0.06).lerp(G.lighten(main, 0.15), v)); mb.pop()
				mb.col(main, 1.0, 0.2); mb.at(pos + Vector3(0, -0.012, 0)); mb.torus(0.019, 0.004, 24, 6); mb.pop()
			if _has(sp, "redbean"): garnish(mb, "redbean", Vector3(0.0, 0.066, 0.004), 1.0)
			var fr: Array = _extras(sp, ["milk", "cream", "sugar", "matcha", "redbean", "lemon"])
			if not fr.is_empty(): garnish(mb, fr[0], Vector3(0.006, 0.064, 0.006), 1.1)
			mb.col(Color("E8B860"), 1.0, 0.2); mb.at(Vector3(0.024, 0.06, -0.01), Vector3(0, 0, -0.5)); mb.rbox(Vector3(0.01, 0.04, 0.004), 0.002, 1); mb.pop()

static func _plate_dish(mb: MB, sp: Dictionary) -> void:
	var st: String = sp.get("style", "")
	var py := plate(mb, 0.108)
	match st:
		"breakfast":
			_fried_egg(mb, Vector3(-0.018, py, -0.018), 0.85)
			for i in 2:
				var pts := PackedVector3Array()
				for k in 7: pts.append(Vector3(0.012 + k * 0.009, py + 0.004 + (0.002 if k % 2 else 0.0), -0.04 + i * 0.014 + k * 0.003))
				mb.tube(MB.spline3(pts, 2), 0.008, 10, func(u: float, _v: float, _p: Vector3) -> Color: return Color("F2C8C0") if absf(sin(u * TAU)) < 0.3 else Color("B8434E"), 0.3, Vector3.UP)
			for i in 2:
				mb.col(Color("A84A2E"), 1.0, 0.5)
				mb.tube(PackedVector3Array([Vector3(-0.05 + i * 0.008, py + 0.008, 0.012 + i * 0.016), Vector3(-0.005 + i * 0.008, py + 0.008, 0.02 + i * 0.016)]), func(t: float) -> float: return 0.0085 * pow(sin(clampf(t, 0.02, 0.98) * PI), 0.25), 10)
			_toast_slice(mb, Vector3(0.04, py, 0.03), 0.7, Color("E2A55A"), 0.5)
			if _has(sp, "tomato"):
				for i in 2: garnish(mb, "tomato", Vector3(0.0 + i * 0.016, py + 0.001, 0.05), 1.1)
			if _has(sp, "mushroom"):
				for i in 2: garnish(mb, "mushroom", Vector3(-0.06 + i * 0.014, py, -0.02), 1.2)
		"roast":
			mb.at(Vector3(0, py, 0), Vector3(0, 0.4, 0))
			mb.col(Color("D9883A"), 1.0, 0.6)
			mb.at(Vector3(0, 0.028, 0)); mb.blob(0.05, 0.03, 0.038, 0.05, 1.0, 3, 26, 14, func(_u: float, v: float, _p: Vector3) -> Color: return Color("B8642A").lerp(Color("F2B060"), v)); mb.pop()
			for s in [-1.0, 1.0]:
				mb.col(Color("C8742E"), 1.0, 0.6)
				mb.tube(PackedVector3Array([Vector3(0.03, 0.03, s * 0.02), Vector3(0.055, 0.04, s * 0.026), Vector3(0.068, 0.05, s * 0.024)]), func(t: float) -> float: return 0.012 * (1.0 - t * 0.6), 10)
				mb.col(WHITE, 1.0, 0.2); mb.at(Vector3(0.07, 0.052, s * 0.024)); mb.sphere(0.0045, 8, 6); mb.pop()
			mb.pop()
			scatter(mb, ["potato", "carrot"] if _has(sp, "potato") or _has(sp, "carrot") else ["spinach"], 6, Vector3(0, py + 0.004, 0), 0.075, 0.07, 1.3, 4,
				func(p: Vector3) -> float: return py + 0.004 if Vector2(p.x, p.z).length() > 0.05 else py + 0.03)
		"fish":
			mb.at(Vector3(-0.02, py, 0), Vector3(0, 0.3, 0))
			mb.col(Color("F2C47A"), 1.0, 0.2); mb.at(Vector3(0, 0.012, 0)); mb.blob(0.052, 0.013, 0.026, 0.12, 1.3, 5, 22, 10, func(u: float, v: float, _p: Vector3) -> Color: return Color("FFE6A8") if fposmod(u * 6.0 + v * 4.0, 1.0) < 0.25 else Color("E8B060")); mb.pop()
			mb.pop()
			var rng := _rng(4)
			for i in 9:
				mb.col(Color("FFD24A"), 1.0, 0.2); mb.at(Vector3(0.035 + rng.randf_range(-0.015, 0.02), py + 0.006 + rng.randf() * 0.01, rng.randf_range(-0.03, 0.03)), Vector3(rng.randf() * 0.3, rng.randf() * TAU, PI * 0.5)); mb.rbox(Vector3(0.008, 0.05, 0.008), 0.002, 1); mb.pop()
			garnish(mb, "lemon", Vector3(-0.02, py + 0.026, 0.03), 1.3, 0.4)
		"corn":
			mb.at(Vector3(0, py + 0.02, 0), Vector3(0, 0.25, PI * 0.5))
			mb.col(Color("FFD24A"), 1.0, 0.4)
			mb.lathe(MB.spline(PackedVector2Array([Vector2(0, -0.055), Vector2(0.015, -0.05), Vector2(0.02, -0.02), Vector2(0.02, 0.02), Vector2(0.015, 0.05), Vector2(0, 0.055)]), 4), 36,
				func(u: float, v: float) -> float: return 1.0 + 0.07 * absf(sin(u * TAU * 9.0)) * sin(v * PI), func(u: float, v: float, _p: Vector3) -> Color: return Color("D99A1E") if fposmod(u * 18.0, 1.0) < 0.2 or fposmod(v * 14.0, 1.0) < 0.2 else Color("FFE878"), 30)
			mb.pop()
			garnish(mb, "butter", Vector3(0.0, py + 0.038, 0.0), 1.3, 0.3)
			mb.col(Color("FFE58A"), 0.4, 1.0)
			for i in 3:
				mb.tube(PackedVector3Array([Vector3(-0.002 + i * 0.006, py + 0.036, 0.004), Vector3(0.0 + i * 0.006, py + 0.03, 0.016), Vector3(0.002 + i * 0.006, py + 0.02, 0.02)]), 0.0022, 6)
		"potato":
			mb.col(Color("C8955A"), 1.0, 0.2); mb.at(Vector3(0, py + 0.022, 0)); mb.blob(0.048, 0.024, 0.034, 0.08, 0.9, 11, 22, 12); mb.pop()
			mb.col(Color("FFF0C8"), 0.6, 0.2); mb.at(Vector3(0, py + 0.043, 0)); mb.blob(0.026, 0.006, 0.016, 0.2, 1.2, 3, 16, 8); mb.pop()
			garnish(mb, "butter", Vector3(0.0, py + 0.047, 0.0), 1.2, 0.3)
		_:
			var keys := _extras(sp)
			scatter(mb, keys if not keys.is_empty() else ["potato"], 8, Vector3(0, py + 0.003, 0), 0.06, 0.06, 1.3, 3)
