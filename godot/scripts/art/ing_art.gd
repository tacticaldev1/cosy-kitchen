## 3D ingredients. build(mb, key) draws a whole ingredient sitting on y=0, roughly 9 cm
## across, centred on x/z. piece(mb, key) draws one chopped piece (about 3 cm).
class_name IngArt
extends RefCounted

const STEM := Color("7A4A28")
const LEAF := Color("6BBF59")
const LEAF_D := Color("4E9E57")
const WHITE := Color("FFFDF8")
const PINK := Color("FF9EBB")

static func _c(key: String) -> Color: return G.ING[key].c
static func _c2(key: String) -> Color: return G.ING[key].c2

static func _grad(a: Color, b: Color) -> Callable:
	return func(_u: float, v: float, _p: Vector3) -> Color: return a.lerp(b, v)

## Small leaf at a position, pointing along dir (in xz), tilted up.
static func _leaf_at(mb: MB, pos: Vector3, yaw: float, tilt: float, length: float, width: float, c := LEAF) -> void:
	mb.push(Transform3D(Basis.from_euler(Vector3(tilt, yaw, 0)), pos)).col(c)
	mb.at(Vector3(0, 0, length)); mb.leaf(length, width, 0.0022, 0.35); mb.pop()
	mb.pop()

static func _stem(mb: MB, a: Vector3, b: Vector3, r: float, c := STEM) -> void:
	mb.col(c, 0.8)
	var mid := (a + b) * 0.5 + Vector3(0.002, 0, 0)
	mb.tube(MB.spline3(PackedVector3Array([a, mid, b]), 3), r, 8)
	mb.outline = 1.0

## Dots placed on a parametric surface (seeds, eyes, spots), no outline.
static func _dots_on(mb: MB, fn: Callable, pts: Array, r: float, c: Color, flat := 0.45, ol := 0.0) -> void:
	for p in pts:
		var t := MB.frame_on(fn, p.x, p.y)
		mb.push(t).col(c, ol)
		mb.ellipsoid(r, r * flat, r, 8, 5)
		mb.pop()

static func _lathe_fn(profile: PackedVector2Array) -> Callable:
	# returns fn(u, v) matching MB.lathe's sampling, for placing things on the surface
	var cum := PackedFloat32Array([0.0])
	for i in range(1, profile.size()):
		cum.append(cum[i - 1] + profile[i].distance_to(profile[i - 1]))
	var total := maxf(cum[cum.size() - 1], 1e-6)
	return func(u: float, v: float) -> Vector3:
		var d := clampf(v, 0.0, 1.0) * total
		var k := 1
		while k < cum.size() - 1 and cum[k] < d:
			k += 1
		var seg := maxf(cum[k] - cum[k - 1], 1e-9)
		var p := profile[k - 1].lerp(profile[k], clampf((d - cum[k - 1]) / seg, 0.0, 1.0))
		var a := u * TAU
		return Vector3(cos(a) * p.x, p.y, sin(a) * p.x)

static func _ring_dots(n: int, v0: float, v1: float, seed_: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var out: Array = []
	for i in n:
		out.append(Vector2(rng.randf(), rng.randf_range(v0, v1)))
	return out

## Layered flat shape: outer colour, then an inner face colour that stands proud on both sides.
static func _layered_extrude(mb: MB, outline: PackedVector2Array, inner: PackedVector2Array, h: float, outer_c: Color, inner_c: Color, bevel := 0.003) -> void:
	mb.col(outer_c); mb.extrude(outline, h, bevel)
	mb.col(inner_c, 0.6)
	mb.at(Vector3(0, -0.0012, 0)); mb.extrude(inner, h + 0.0024, bevel * 0.6); mb.pop()
	mb.outline = 1.0

# ======================================================================= whole
static func build(mb: MB, key: String) -> void:
	var c := _c(key)
	var c2 := _c2(key)
	mb.col(c, 1.0, 0.0)
	match G.ING[key].sh:
		"round": _round(mb, key, c)
		"banana":
			for k in 2:
				mb.at(Vector3(0.0, 0.0, -0.012 + k * 0.022), Vector3(0, 0.12 - k * 0.24, 0))
				var path := MB.spline3(PackedVector3Array([Vector3(-0.052, 0.042, 0), Vector3(-0.03, 0.018, 0), Vector3(0.0, 0.012, 0), Vector3(0.03, 0.02, 0), Vector3(0.05, 0.04, 0)]), 5)
				mb.col(c)
				mb.tube(path, func(t: float) -> float: return 0.0145 * pow(sin(clampf(t, 0.02, 0.98) * PI), 0.45), 10,
					func(_u: float, v: float, _p: Vector3) -> Color:
						if v < 0.07: return Color("6A4A2A")
						if v > 0.95: return Color("8A6A3A")
						return Color("FFE98A").lerp(Color("F6CC3A"), 0.5 + 0.5 * sin(v * 3.0)))
				mb.pop()
		"straw":
			var pr := MB.spline(PackedVector2Array([Vector2(0, 0), Vector2(0.012, 0.006), Vector2(0.03, 0.028), Vector2(0.036, 0.05), Vector2(0.03, 0.066), Vector2(0.012, 0.072), Vector2(0, 0.07)]), 5)
			mb.col(c, 1.0, 0.6)
			mb.lathe(pr, 26, Callable(), _grad(Color("D92A44"), Color("FF6A80")))
			_dots_on(mb, _lathe_fn(pr), _ring_dots(26, 0.12, 0.8, 4), 0.0024, Color("FFE680"))
			for i in 5:
				_leaf_at(mb, Vector3(0, 0.068, 0), i * TAU / 5.0, 0.35, 0.012, 0.0065)
			_stem(mb, Vector3(0, 0.068, 0), Vector3(0.002, 0.085, 0.001), 0.0022, LEAF_D)
		"cluster":
			for p in [Vector3(-0.02, 0, 0.012), Vector3(0.02, 0, 0.012), Vector3(0, 0, -0.018)]:
				mb.at(p + Vector3(0, 0.021, 0)).col(c, 1.0, 0.5)
				mb.sphere(0.021, 20, 12, func(_u: float, v: float, _q: Vector3) -> Color: return Color("3442A0").lerp(Color("8C9BFF"), v))
				mb.col(Color("26307A"), 0.0)
				for i in 5:
					mb.at(Vector3(0, 0.019, 0), Vector3(0, i * TAU / 5.0, 0)); mb.at(Vector3(0, 0, 0.004)); mb.ellipsoid(0.0018, 0.0012, 0.004, 6, 4); mb.pop(); mb.pop()
				mb.pop()
			mb.col(c, 1.0, 0.0)
		"lemon":
			mb.at(Vector3(0, 0.033, 0), Vector3(0, 0, 0.18))
			mb.col(c, 1.0, 0.15); mb.ellipsoid(0.046, 0.032, 0.033, 24, 14, _grad(Color("F2C820"), Color("FFF07A")))
			for s in [-1.0, 1.0]:
				mb.at(Vector3(s * 0.045, 0, 0), Vector3(0, 0, -s * PI * 0.5)); mb.cone(0.009, 0.01, 10); mb.pop()
			mb.pop()
			_leaf_at(mb, Vector3(-0.03, 0.058, 0), 0.6, -0.3, 0.013, 0.007)
		"mango":
			mb.at(Vector3(0, 0.035, 0), Vector3(0, 0.3, 0.25))
			mb.ellipsoid(0.05, 0.034, 0.037, 24, 14, func(_u: float, v: float, p: Vector3) -> Color:
				return Color("FFC94A").lerp(Color("FF7A4A"), clampf(p.x / 0.05 * 0.6 + 0.2 + v * 0.3, 0.0, 0.85)))
			mb.pop()
			_stem(mb, Vector3(-0.042, 0.055, 0), Vector3(-0.048, 0.064, 0), 0.0025)
			_leaf_at(mb, Vector3(-0.046, 0.062, 0), -0.5, -0.4, 0.016, 0.007)
		"pine":
			mb.at(Vector3(0, 0.044, 0))
			mb.ellipsoid(0.034, 0.044, 0.034, 24, 16, func(u: float, v: float, _p: Vector3) -> Color:
				var a := fposmod(u * 9.0 + v * 6.0, 1.0)
				var b := fposmod(u * 9.0 - v * 6.0, 1.0)
				var line := minf(minf(a, 1.0 - a), minf(b, 1.0 - b))
				return Color("C8862A") if line < 0.07 else Color("FFC93C").lerp(Color("FFE27A"), v))
			mb.pop()
			for i in 7:
				var yaw := i * TAU / 7.0
				_leaf_at(mb, Vector3(0, 0.084, 0), yaw, -1.05 + (i % 2) * 0.25, 0.017 + (i % 2) * 0.005, 0.0065, LEAF if i % 2 else LEAF_D)
			_leaf_at(mb, Vector3(0, 0.086, 0), 0.0, -1.5, 0.02, 0.006)
		"melon":
			var r := 0.05
			var outer := PackedVector2Array()
			var mid := PackedVector2Array()
			var inner := PackedVector2Array()
			for i in 25:
				var a := PI * i / 24.0
				outer.append(Vector2(cos(a) * r, sin(a) * r))
				mid.append(Vector2(cos(a) * r * 0.9, sin(a) * r * 0.9 - 0.0005))
				inner.append(Vector2(cos(a) * r * 0.8, sin(a) * r * 0.8 - 0.001))
			# stand it up: rotate +90° about x, rind at the bottom
			mb.push(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), Vector3(0, r, -0.012)))
			mb.col(Color("5DAE4B")); mb.extrude(outer, 0.024, 0.004)
			mb.col(Color("EAF7D8"), 0.5); mb.at(Vector3(0, -0.001, 0)); mb.extrude(mid, 0.026, 0.003); mb.pop()
			mb.col(c, 0.5); mb.at(Vector3(0, -0.002, 0)); mb.extrude(inner, 0.028, 0.003); mb.pop()
			mb.col(Color("3B2340"), 0.0)
			for sp in [Vector2(-0.02, 0.018), Vector2(0.0, 0.026), Vector2(0.02, 0.018), Vector2(-0.01, 0.012), Vector2(0.011, 0.011)]:
				for side in [-1.0, 1.0]:
					mb.at(Vector3(sp.x, 0.012 + side * 0.014, sp.y)); mb.ellipsoid(0.0025, 0.0015, 0.004, 8, 5); mb.pop()
			mb.pop()
		"avo":
			var pear := MB.spline(PackedVector2Array([Vector2(0, -0.048), Vector2(0.026, -0.044), Vector2(0.036, -0.02), Vector2(0.03, 0.012), Vector2(0.02, 0.036), Vector2(0, 0.044)]), 6)
			var outl := PackedVector2Array()
			var inl := PackedVector2Array()
			for p in pear: outl.append(Vector2(p.x, p.y))
			for i in range(pear.size() - 2, 0, -1): outl.append(Vector2(-pear[i].x, pear[i].y))
			for p in outl: inl.append(p * 0.84)
			mb.at(Vector3(0, 0, 0), Vector3(0, 0.5, 0))
			mb.col(Color("3E6B2E")); mb.extrude(outl, 0.026, 0.012)
			mb.col(c2, 0.6); mb.at(Vector3(0, 0.002, 0)); mb.extrude(inl, 0.026, 0.004); mb.pop()
			mb.col(Color("A0603A"), 1.0, 0.6); mb.at(Vector3(0, 0.026, -0.012)); mb.ellipsoid(0.015, 0.012, 0.015, 18, 10); mb.pop()
			mb.pop()
		"cherry":
			for k in [-1.0, 1.0]:
				var base := Vector3(k * 0.018, 0, k * 0.004)
				var pr := MB.spline(PackedVector2Array([Vector2(0, 0.002), Vector2(0.014, 0.0), Vector2(0.022, 0.016), Vector2(0.018, 0.03), Vector2(0.006, 0.036), Vector2(0, 0.032)]), 5)
				mb.at(base).col(c, 1.0, 1.0)
				mb.lathe(pr, 22, Callable(), _grad(Color("B8102E"), Color("FF5A72")))
				mb.pop()
				mb.col(Color("5A8A3A"), 0.8, 0.0)
				mb.tube(MB.spline3(PackedVector3Array([base + Vector3(0, 0.032, 0), base + Vector3(-k * 0.004, 0.06, 0), Vector3(0, 0.085, 0.004)]), 5), 0.0018, 7)
			_leaf_at(mb, Vector3(0, 0.084, 0.004), 0.9, -0.2, 0.016, 0.008)
		"leafy", "cabbage":
			if key == "spinach":
				for i in 3:
					var yaw := -0.5 + i * 0.5
					mb.push(Transform3D(Basis.from_euler(Vector3(-0.18, yaw, 0)), Vector3(0, 0.01 + i * 0.004, 0)))
					mb.col(c if i != 1 else c.lightened(0.12))
					mb.at(Vector3(0, 0, 0.012)); mb.leaf(0.034, 0.022, 0.003, 0.5, 0.15); mb.pop()
					mb.col(Color("9BD27E"), 0.6)
					mb.tube(PackedVector3Array([Vector3(0, 0.002, -0.04), Vector3(0, 0.004, 0.03)]), 0.0022, 6)
					mb.pop()
			else:
				var cab := key == "cabbage"
				mb.col(c2 if not cab else c.lightened(0.15))
				mb.at(Vector3(0, 0.036, 0)); mb.blob(0.034, 0.032, 0.034, 0.05, 0.12, 5, 20, 12); mb.pop()
				var n := 6 if cab else 7
				for i in n:
					var yaw := i * TAU / n + 0.3
					mb.push(Transform3D(Basis.from_euler(Vector3(0, yaw, 0)), Vector3(0, 0, 0)))
					mb.push(Transform3D(Basis.from_euler(Vector3(-1.22 if cab else -1.05, 0, 0)), Vector3(0, 0.004, 0.022)))
					mb.col(c if i % 2 == 0 else c.lerp(c2, 0.25))
					mb.at(Vector3(0, 0, 0.034)); mb.leaf(0.036, 0.03 if cab else 0.027, 0.0028, 0.9 if cab else 0.6, 0.0 if cab else 0.35); mb.pop()
					mb.pop(); mb.pop()
		"long":
			var path := MB.spline3(PackedVector3Array([Vector3(-0.055, 0.017, 0.006), Vector3(-0.02, 0.016, -0.002), Vector3(0.02, 0.016, -0.002), Vector3(0.055, 0.018, 0.006)]), 4)
			mb.at(Vector3.ZERO, Vector3(0, 0.45, 0))
			mb.tube(path, func(t: float) -> float: return 0.0165 * pow(sin(clampf(t, 0.015, 0.985) * PI), 0.28), 14,
				func(u: float, v: float, _p: Vector3) -> Color:
					var s := fposmod(u * 7.0, 1.0)
					return Color("3E8E48") if s < 0.35 else Color("5AAE5E").lerp(Color("4E9E57"), v))
			mb.col(Color("D2EFB6"), 0.0)
			var rng := RandomNumberGenerator.new(); rng.seed = 3
			for i in 12:
				var t := rng.randf_range(0.12, 0.88)
				var a := rng.randf() * TAU
				var p := Vector3(lerpf(-0.055, 0.055, t), 0.017 + sin(a) * 0.016, cos(a) * 0.016)
				mb.at(p); mb.sphere(0.0018, 6, 4); mb.pop()
			mb.pop()
		"carrot":
			var path := MB.spline3(PackedVector3Array([Vector3(-0.045, 0.02, 0), Vector3(-0.01, 0.015, 0.004), Vector3(0.03, 0.009, 0.002), Vector3(0.058, 0.005, -0.004)]), 5)
			mb.at(Vector3.ZERO, Vector3(0, -0.35, 0))
			mb.tube(path, func(t: float) -> float: return 0.019 * pow(1.0 - t, 0.75) * (0.75 + 0.25 * sqrt(clampf(t * 12.0, 0.0, 1.0))), 12,
				func(_u: float, v: float, _p: Vector3) -> Color: return Color("E8701E") if fposmod(v * 11.0, 1.0) < 0.12 else Color("FF8A2B").lerp(Color("FFA04A"), 0.3))
			for i in 3:
				var dir := Vector3(-0.045 - 0.02, 0.04 + i * 0.006, -0.012 + i * 0.012)
				mb.col(LEAF, 0.8)
				mb.tube(MB.spline3(PackedVector3Array([Vector3(-0.048, 0.02, 0), Vector3(-0.055, 0.03, (i - 1) * 0.004), dir]), 4), func(t: float) -> float: return 0.0028 * (1.0 - t * 0.6), 6)
				mb.push(Transform3D(Basis.from_euler(Vector3(-0.6, -PI * 0.5 + (i - 1) * 0.5, 0)), dir)); mb.leaf(0.012, 0.007, 0.002, 0.3, 0.6); mb.pop()
			mb.pop()
		"potato":
			mb.at(Vector3(0, 0.028, 0), Vector3(0, 0.4, 0.1))
			mb.blob(0.048, 0.029, 0.036, 0.09, 0.09, 11, 24, 14, _grad(Color("C8955A"), Color("E8BC80")))
			mb.col(Color("8A5A30"), 0.0)
			for p in [Vector3(-0.025, 0.012, 0.022), Vector3(0.012, 0.022, 0.018), Vector3(0.03, 0.008, -0.02), Vector3(-0.01, 0.026, -0.012)]:
				mb.at(p); mb.ellipsoid(0.003, 0.002, 0.003, 6, 4); mb.pop()
			mb.pop()
		"onion":
			var pr := MB.spline(PackedVector2Array([Vector2(0, 0.0), Vector2(0.01, 0.002), Vector2(0.036, 0.016), Vector2(0.042, 0.036), Vector2(0.03, 0.06), Vector2(0.01, 0.078), Vector2(0.0025, 0.09), Vector2(0, 0.092)]), 5)
			mb.lathe(pr, 26, Callable(), func(u: float, v: float, _p: Vector3) -> Color:
				return Color("E8C8F0") if fposmod(u * 9.0, 1.0) < 0.07 and v > 0.1 and v < 0.92 else Color("A060B8").lerp(Color("CC90DA"), v))
			mb.col(Color("D9C8A0"), 0.0)
			for i in 6:
				var a := i * TAU / 6.0
				mb.tube(PackedVector3Array([Vector3(0, 0.002, 0), Vector3(cos(a) * 0.009, -0.002, sin(a) * 0.009)]), 0.0012, 5)
		"mushroom":
			mb.col(c2); mb.puck(0.0135, 0.042, 0.005, 18, 0.0105)
			var cap := MB.spline(PackedVector2Array([Vector2(0, 0.036), Vector2(0.026, 0.034), Vector2(0.037, 0.041), Vector2(0.035, 0.054), Vector2(0.021, 0.066), Vector2(0, 0.07)]), 5)
			mb.col(c); mb.lathe(cap, 28, Callable(), _grad(Color("A8714A"), Color("D9A27A")))
			_dots_on(mb, _lathe_fn(cap), [Vector2(0.1, 0.55), Vector2(0.35, 0.7), Vector2(0.6, 0.5), Vector2(0.82, 0.68), Vector2(0.5, 0.9)], 0.0065, Color("FFF1E2"), 0.25, 0.4)
		"pepper":
			var pr := MB.spline(PackedVector2Array([Vector2(0, 0.004), Vector2(0.024, 0.0), Vector2(0.038, 0.016), Vector2(0.041, 0.04), Vector2(0.036, 0.062), Vector2(0.02, 0.07), Vector2(0, 0.064)]), 5)
			mb.col(c, 1.0, 0.7)
			mb.lathe(pr, 32, func(u: float, v: float) -> float: return 1.0 + 0.09 * cos(u * TAU * 4.0) * (1.0 - absf(v - 0.5)), _grad(Color("D8301E"), Color("FF6A50")))
			mb.col(Color("4E9E57"), 1.0, 0.2); mb.at(Vector3(0, 0.06, 0)); mb.puck(0.012, 0.006, 0.003, 12); mb.pop()
			_stem(mb, Vector3(0, 0.064, 0), Vector3(0.008, 0.082, 0.002), 0.0035, Color("5DAE4B"))
		"corn":
			mb.at(Vector3(0, 0.022, 0), Vector3(0, 0.3, PI * 0.5))
			var pr := MB.spline(PackedVector2Array([Vector2(0, -0.05), Vector2(0.014, -0.046), Vector2(0.02, -0.02), Vector2(0.02, 0.02), Vector2(0.014, 0.045), Vector2(0, 0.052)]), 5)
			mb.col(c, 1.0, 0.3)
			mb.lathe(pr, 36, func(u: float, v: float) -> float: return 1.0 + 0.07 * absf(sin(u * TAU * 9.0)) * sin(v * PI), func(u: float, v: float, _p: Vector3) -> Color:
				var a := fposmod(u * 18.0, 1.0)
				var b := fposmod(v * 14.0, 1.0)
				return Color("D99A1E") if a < 0.2 or b < 0.2 else Color("FFE878").lerp(Color("FFD24A"), v), 30)
			for s in [-1.0, 1.0]:
				mb.push(Transform3D(Basis.from_euler(Vector3(0, s * 1.1, 0)), Vector3(0, -0.05, s * 0.004)))
				mb.push(Transform3D(Basis.from_euler(Vector3(-PI * 0.5 + 0.35, 0, 0)), Vector3.ZERO))
				mb.col(Color("7CC35A") if s > 0 else Color("9BD27E")); mb.at(Vector3(0, 0, 0.036)); mb.leaf(0.038, 0.017, 0.0028, 0.7); mb.pop()
				mb.pop(); mb.pop()
			mb.pop()
		"broccoli":
			var st := MB.spline3(PackedVector3Array([Vector3(0, 0, 0), Vector3(0.002, 0.02, 0), Vector3(0, 0.04, 0)]), 3)
			mb.col(Color("9BD27E")); mb.tube(st, func(t: float) -> float: return 0.012 - t * 0.004, 12)
			var fl := [Vector3(0, 0.062, 0), Vector3(-0.022, 0.05, 0.008), Vector3(0.022, 0.052, 0.006), Vector3(0.0, 0.05, -0.022), Vector3(0.004, 0.048, 0.022)]
			for i in fl.size():
				mb.at(fl[i]); mb.col(c if i else c.lightened(0.08))
				mb.blob(0.022, 0.018, 0.022, 0.16, 0.5, 20 + i, 18, 10, _grad(Color("3E8A48"), Color("6BBF59")))
				mb.pop()
		"pumpkin":
			var pr := MB.spline(PackedVector2Array([Vector2(0, 0.008), Vector2(0.03, 0.0), Vector2(0.05, 0.02), Vector2(0.05, 0.042), Vector2(0.032, 0.058), Vector2(0.006, 0.054), Vector2(0, 0.05)]), 5)
			mb.lathe(pr, 40, func(u: float, _v: float) -> float: return 0.9 + 0.1 * absf(cos(u * TAU * 4.0)), func(u: float, v: float, _p: Vector3) -> Color:
				return Color("E8781E").lerp(Color("FFB050"), 0.4 + 0.6 * absf(cos(u * TAU * 4.0)) * (0.5 + v * 0.5)))
			_stem(mb, Vector3(0, 0.05, 0), Vector3(0.006, 0.07, 0.003), 0.0055, Color("7A5A2E"))
			_leaf_at(mb, Vector3(0.004, 0.056, 0), 1.2, -0.2, 0.016, 0.01)
		"egg":
			var pr := MB.spline(PackedVector2Array([Vector2(0, 0.0), Vector2(0.018, 0.003), Vector2(0.027, 0.022), Vector2(0.024, 0.046), Vector2(0.013, 0.062), Vector2(0, 0.066)]), 6)
			mb.col(c, 1.0, 0.3); mb.lathe(pr, 24, Callable(), _grad(Color("F2E2C8"), Color("FFFBF2")))
		"drum":
			mb.push(Transform3D(Basis.from_euler(Vector3(0, 0.5, -0.12)), Vector3(0, 0.024, 0)))
			mb.col(WHITE)
			mb.tube(PackedVector3Array([Vector3(0.02, 0, 0), Vector3(0.058, 0, 0)]), 0.0055, 10)
			for s in [-1.0, 1.0]:
				mb.at(Vector3(0.06, 0, s * 0.006)); mb.sphere(0.0075, 12, 8); mb.pop()
			var pr := MB.spline(PackedVector2Array([Vector2(0, -0.05), Vector2(0.016, -0.045), Vector2(0.026, -0.022), Vector2(0.022, 0.005), Vector2(0.008, 0.02), Vector2(0.0, 0.024)]), 5)
			mb.at(Vector3(0.0, 0, 0), Vector3(0, 0, -PI * 0.5))
			mb.col(c); mb.lathe(pr, 22, Callable(), _grad(Color("EFA88E"), Color("FFE2D4")))
			mb.pop(); mb.pop()
		"steak":
			var o := MB.spline(PackedVector2Array([Vector2(-0.05, 0.0), Vector2(-0.04, -0.03), Vector2(0.0, -0.036), Vector2(0.045, -0.026), Vector2(0.052, 0.006), Vector2(0.03, 0.032), Vector2(-0.01, 0.03), Vector2(-0.045, 0.02), Vector2(-0.05, 0.0)]), 5)
			o.remove_at(o.size() - 1)
			mb.col(c, 1.0, 0.3); mb.extrude(o, 0.02, 0.007)
			mb.col(Color("FFE0E3"), 0.0, 0.0)
			for ln in [[Vector3(-0.03, 0.0205, -0.012), Vector3(0.0, 0.0205, -0.004), Vector3(0.03, 0.0205, -0.016)], [Vector3(-0.02, 0.0205, 0.012), Vector3(0.008, 0.0205, 0.016), Vector3(0.028, 0.0205, 0.008)]]:
				mb.tube(MB.spline3(PackedVector3Array(ln), 4), 0.0018, 6)
			mb.col(Color("FFF2EC"), 0.8)
			var fat := PackedVector3Array([Vector3(0.042, 0.01, -0.03), Vector3(0.056, 0.01, 0.0), Vector3(0.036, 0.01, 0.034)])
			mb.tube(MB.spline3(fat, 4), 0.0075, 8, Callable(), 1.0)
		"sausage":
			var path := MB.spline3(PackedVector3Array([Vector3(-0.048, 0.016, -0.01), Vector3(-0.015, 0.014, 0.008), Vector3(0.02, 0.014, 0.008), Vector3(0.05, 0.016, -0.01)]), 5)
			mb.col(c, 1.0, 0.6)
			mb.tube(path, func(t: float) -> float: return 0.0145 * pow(sin(clampf(t, 0.01, 0.99) * PI), 0.25), 12, func(u: float, _v: float, _p: Vector3) -> Color:
				return Color("E8846A") if sin(u * TAU) > 0.55 else Color("C8503A"))
		"bacon":
			for k in 2:
				var pts := PackedVector3Array()
				for i in 9:
					var x := -0.05 + i * 0.0125
					pts.append(Vector3(x, 0.008 + k * 0.012 + sin(i * 1.4 + k) * 0.005, -0.012 + k * 0.024))
				mb.tube(MB.spline3(pts, 3), 0.016, 12, func(u: float, _v: float, _p: Vector3) -> Color:
					var s := sin(u * TAU)
					return Color("F7D8D4") if absf(s) < 0.28 else Color("C8434E") if absf(s) < 0.75 else Color("E8677A"), 0.28, Vector3.UP)
		"fillet":
			var sal := key == "salmon"
			var o := MB.spline(PackedVector2Array([Vector2(-0.052, 0.0), Vector2(-0.04, -0.024), Vector2(0.0, -0.028), Vector2(0.04, -0.022), Vector2(0.056, -0.004), Vector2(0.044, 0.018), Vector2(0.0, 0.028), Vector2(-0.04, 0.022), Vector2(-0.052, 0.0)]), 5)
			o.remove_at(o.size() - 1)
			mb.at(Vector3.ZERO, Vector3(0, 0.25, 0))
			mb.col(Color("F07A44") if sal else Color("C8283E"), 1.0, 0.5); mb.extrude(o, 0.022, 0.008)
			mb.col(Color("FFB08A") if sal else Color("E8566A"), 0.0, 0.5)
			mb.at(Vector3(0, 0.0008, 0)); mb.extrude(MB.spline(PackedVector2Array([Vector2(-0.044, 0.0), Vector2(-0.034, -0.018), Vector2(0.0, -0.021), Vector2(0.034, -0.016), Vector2(0.046, -0.003), Vector2(0.036, 0.013), Vector2(0.0, 0.021), Vector2(-0.034, 0.016), Vector2(-0.044, 0.0)]), 4).slice(0, -1), 0.022, 0.004); mb.pop()
			mb.col(Color("FFF0E6") if sal else Color("FFB8C2"), 0.0)
			for i in range(-3, 4):
				var x := i * 0.012
				mb.tube(MB.spline3(PackedVector3Array([Vector3(x - 0.006, 0.0232, 0.017), Vector3(x + 0.004, 0.0236, 0.0), Vector3(x - 0.002, 0.0232, -0.018)]), 3), 0.0016 if sal else 0.001, 5)
			mb.pop()
		"shrimp":
			var pts := PackedVector3Array()
			for i in 12:
				var a := lerpf(PI * 0.15, PI * 1.45, i / 11.0)
				pts.append(Vector3(cos(a) * 0.03, 0.016, sin(a) * 0.03))
			mb.col(c, 1.0, 0.5)
			mb.tube(pts, func(t: float) -> float: return 0.0145 * pow(1.0 - t * 0.75, 0.8) * (0.7 + 0.3 * sqrt(clampf(t * 10.0, 0, 1))), 12,
				func(_u: float, v: float, _p: Vector3) -> Color: return Color("FFE3D8") if fposmod(v * 7.0, 1.0) < 0.12 else Color("FF8C6A").lerp(Color("FFB49A"), 0.4), 1.0, Vector3.UP)
			var tail := pts[pts.size() - 1]
			for s in [-1.0, 1.0]:
				mb.push(Transform3D(Basis.from_euler(Vector3(0, -PI * 0.15 + s * 0.45, 0)), tail + Vector3(0, 0.0, 0)))
				mb.col(Color("FF6A4A")); mb.at(Vector3(0, 0, 0.012)); mb.leaf(0.012, 0.007, 0.002, 0.1); mb.pop(); mb.pop()
			mb.col(Color("3B2340"), 0.0)
			mb.at(pts[0] + Vector3(0.004, 0.008, 0.006)); mb.sphere(0.0022, 6, 4); mb.pop()
		"strip":
			mb.at(Vector3.ZERO, Vector3(0, 0.4, 0))
			mb.col(Color("FFF6F0")); mb.at(Vector3(0, 0.011, 0)); mb.rbox(Vector3(0.095, 0.022, 0.024), 0.009, 3); mb.pop()
			mb.col(Color("F0503A"), 0.5); mb.at(Vector3(0, 0.0175, 0)); mb.rbox(Vector3(0.097, 0.011, 0.0256), 0.005, 2); mb.pop()
			mb.pop()
		"block":
			mb.col(c); mb.at(Vector3(0, 0.024, 0), Vector3(0, 0.35, 0)); mb.rbox(Vector3(0.062, 0.048, 0.054), 0.008, 3); mb.pop()
		"carton":
			var sc := 1.0 if key == "milk" else 0.82
			mb.push(Transform3D(Basis.IDENTITY.scaled(Vector3(sc, sc, sc)), Vector3.ZERO))
			mb.at(Vector3.ZERO, Vector3(0, 0.4, 0))
			mb.col(WHITE); mb.at(Vector3(0, 0.038, 0)); mb.rbox(Vector3(0.05, 0.076, 0.05), 0.005, 2); mb.pop()
			mb.col(c2, 0.5); mb.at(Vector3(0, 0.03, 0)); mb.rbox(Vector3(0.0512, 0.026, 0.0512), 0.005, 2); mb.pop()
			# gable roof
			mb.push(Transform3D(Basis.from_euler(Vector3(-PI * 0.5, 0, 0)), Vector3(0, 0.076, 0.025)))
			mb.col(WHITE); mb.extrude(PackedVector2Array([Vector2(-0.025, 0.0), Vector2(0.0, 0.024), Vector2(0.025, 0.0)]), 0.05, 0.003)
			mb.pop()
			mb.col(WHITE); mb.at(Vector3(0, 0.103, 0)); mb.rbox(Vector3(0.012, 0.01, 0.05), 0.002, 1); mb.pop()
			mb.col(c2); mb.at(Vector3(0.012, 0.09, 0.012), Vector3(-0.78, 0, 0)); mb.puck(0.006, 0.006, 0.002, 12); mb.pop()
			mb.col(Color("FFFFFF"), 0.6); mb.at(Vector3(0, 0.03, 0.0258), Vector3(PI * 0.5, 0, 0)); mb.puck(0.0085, 0.0015, 0.0006, 16); mb.pop()
			mb.pop(); mb.pop()
		"wedge":
			var tri := PackedVector2Array()
			for p in [Vector2(-0.05, 0.03), Vector2(0.05, 0.03), Vector2(0.0, -0.05)]:
				tri.append(p)
			var rounded := PackedVector2Array()
			for i in 3:
				var a := tri[i]; var b := tri[(i + 1) % 3]
				for s in 8:
					rounded.append(a.lerp(b, 0.08 + 0.84 * s / 7.0))
			mb.at(Vector3.ZERO, Vector3(0, 0.3, 0))
			mb.col(c, 1.0, 0.1); mb.extrude(rounded, 0.036, 0.004, 3, c.lightened(0.15))
			mb.col(Color("E8B830"), 0.5)
			for h in [Vector3(-0.015, 0.0362, 0.012), Vector3(0.012, 0.0362, 0.0), Vector3(0.0, 0.0362, -0.022)]:
				mb.at(h); mb.ellipsoid(0.0065, 0.0012, 0.0065, 12, 4); mb.pop()
			for h in [Vector3(-0.02, 0.016, 0.0302), Vector3(0.02, 0.024, 0.0302)]:
				mb.at(h, Vector3(PI * 0.5, 0, 0)); mb.ellipsoid(0.006, 0.0012, 0.006, 12, 4); mb.pop()
			mb.pop()
		"stick":
			mb.at(Vector3.ZERO, Vector3(0, 0.35, 0))
			mb.col(c); mb.at(Vector3(-0.012, 0.0135, 0)); mb.rbox(Vector3(0.075, 0.027, 0.032), 0.006, 3); mb.pop()
			mb.col(Color("D8E0F2")); mb.at(Vector3(0.016, 0.0135, 0)); mb.rbox(Vector3(0.05, 0.029, 0.034), 0.006, 3); mb.pop()
			mb.col(Color("8EA6E0"), 0.4); mb.at(Vector3(0.016, 0.0135, 0)); mb.rbox(Vector3(0.012, 0.0295, 0.0345), 0.004, 2); mb.pop()
			mb.pop()
		"tub":
			var pr := PackedVector2Array([Vector2(0, 0), Vector2(0.028, 0.0), Vector2(0.03, 0.002), Vector2(0.036, 0.044), Vector2(0, 0.044)])
			mb.col(c); mb.lathe(pr, 26)
			mb.col(c2); mb.at(Vector3(0, 0.042, 0)); mb.puck(0.039, 0.009, 0.003, 26); mb.pop()
			mb.col(c2, 0.5); mb.at(Vector3(0, 0.014, 0)); mb.puck(0.0322, 0.014, 0.001, 26, 0.0345); mb.pop()
			mb.col(Color("FF6A8A"), 0.6); mb.at(Vector3(0, 0.022, 0.032), Vector3(PI * 0.5 - 0.15, 0, 0)); mb.puck(0.0065, 0.002, 0.001, 12); mb.pop()
		"bag":
			mb.at(Vector3.ZERO, Vector3(0, 0.3, 0))
			mb.col(c); mb.at(Vector3(0, 0.034, 0)); mb.rbox(Vector3(0.056, 0.068, 0.04), 0.008, 3); mb.pop()
			mb.col(c2); mb.at(Vector3(0, 0.07, 0)); mb.rbox(Vector3(0.058, 0.012, 0.03), 0.004, 2); mb.pop()
			mb.col(WHITE, 0.6); mb.at(Vector3(0, 0.03, 0.0195)); mb.rbox(Vector3(0.04, 0.034, 0.003), 0.0012, 1); mb.pop()
			if key == "sugar":
				for p in [Vector3(-0.008, 0.024, 0.023), Vector3(0.008, 0.024, 0.023), Vector3(0.0, 0.036, 0.023)]:
					mb.col(Color.WHITE, 0.6); mb.at(p, Vector3(0, 0, 0.2)); mb.rbox(Vector3(0.011, 0.01, 0.006), 0.002, 1); mb.pop()
			else:
				mb.col(Color("C8963A"), 0.0); mb.tube(PackedVector3Array([Vector3(0, 0.017, 0.022), Vector3(0, 0.043, 0.022)]), 0.0012, 5)
				for i in 3:
					for s in [-1.0, 1.0]:
						mb.col(Color("C8A878") if key == "oats" else Color("E8B84A"), 0.4)
						mb.at(Vector3(s * 0.004, 0.026 + i * 0.006, 0.0225), Vector3(0, 0, -s * 0.7)); mb.ellipsoid(0.0045, 0.0022, 0.0015, 8, 4); mb.pop()
			mb.pop()
		"sack":
			mb.at(Vector3.ZERO, Vector3(0, 0.3, 0))
			mb.col(Color.WHITE); mb.at(Vector3(0, 0.032, 0)); mb.rbox(Vector3(0.056, 0.064, 0.04), 0.013, 3); mb.pop()
			var neck := MB.spline(PackedVector2Array([Vector2(0.02, 0.058), Vector2(0.011, 0.07), Vector2(0.012, 0.076), Vector2(0.02, 0.084), Vector2(0.0, 0.086)]), 4)
			mb.col(Color.WHITE); mb.lathe(neck, 18, func(u: float, _v: float) -> float: return 1.0 + 0.12 * sin(u * TAU * 6.0))
			mb.col(c2); mb.at(Vector3(0, 0.072, 0)); mb.torus(0.0125, 0.0032, 18, 8); mb.pop()
			mb.col(c2, 0.6); mb.at(Vector3(0, 0.03, 0.0198)); mb.rbox(Vector3(0.042, 0.036, 0.003), 0.008, 2); mb.pop()
			mb.push(Transform3D(Basis.from_euler(Vector3(-PI * 0.5, 0, 0)), Vector3(0, 0.03, 0.0238)))
			var tri := PackedVector2Array()
			for i in 18:
				var a := -PI * 0.5 + i * TAU / 18.0
				var rr := 0.0105 * (1.0 + 0.16 * cos(3.0 * (a + PI * 0.5)))
				tri.append(Vector2(cos(a) * rr, -sin(a) * rr - 0.001))
			mb.col(Color.WHITE, 0.6); mb.extrude(tri, 0.0025, 0.001)
			mb.col(Color("1F2C25"), 0.0); mb.at(Vector3(0, 0.0012, -0.0062)); mb.rbox(Vector3(0.008, 0.0028, 0.0062), 0.001, 1); mb.pop()
			mb.pop()
			mb.pop()
		"pasta":
			mb.col(c, 0.5)
			var rng := RandomNumberGenerator.new(); rng.seed = 2
			for i in 16:
				var a := rng.randf() * TAU
				var r := sqrt(rng.randf()) * 0.012
				var bot := Vector3(cos(a) * r, 0.0, sin(a) * r)
				var top := bot * 2.0 + Vector3(0, 0.1, 0)
				mb.tube(PackedVector3Array([bot, top]), 0.0022, 6)
			mb.col(PINK); mb.at(Vector3(0, 0.045, 0)); mb.puck(0.0175, 0.01, 0.003, 18); mb.pop()
		"noodle":
			mb.col(c, 0.6)
			for k in 4:
				var pts := PackedVector3Array()
				var rr := 0.038 - k * 0.006
				for i in 41:
					var a := i / 40.0 * TAU
					var w := sin(a * 7.0 + k) * 0.0035
					pts.append(Vector3(cos(a) * (rr + w), 0.006 + k * 0.007 + cos(a * 5.0 + k * 2.0) * 0.002, sin(a) * (rr + w)))
				mb.tube(pts, 0.0042, 7)
			mb.col(c.darkened(0.05), 0.6); mb.at(Vector3(0, 0.004, 0)); mb.puck(0.032, 0.012, 0.004, 22); mb.pop()
		"tortilla":
			mb.col(c, 1.0, 0.0)
			mb.lathe(PackedVector2Array([Vector2(0, 0.0), Vector2(0.046, 0.0), Vector2(0.052, 0.003), Vector2(0.048, 0.007), Vector2(0, 0.009)]), 40, func(u: float, _v: float) -> float: return 1.0 + 0.03 * sin(u * TAU * 7.0))
			mb.col(Color("C8955A"), 0.0)
			for p in [Vector2(-0.02, -0.01), Vector2(0.015, 0.018), Vector2(0.005, -0.025), Vector2(-0.01, 0.022), Vector2(0.028, -0.006), Vector2(-0.032, 0.008)]:
				mb.at(Vector3(p.x, 0.0092, p.y)); mb.ellipsoid(0.005, 0.0006, 0.0035, 8, 3); mb.pop()
		"sheet":
			mb.at(Vector3.ZERO, Vector3(0, 0.3, 0))
			mb.col(c, 1.0, 0.3); mb.at(Vector3(0, 0.003, 0)); mb.rbox(Vector3(0.085, 0.005, 0.085), 0.002, 1); mb.pop()
			mb.col(c2, 0.0)
			for i in range(-2, 3):
				mb.tube(PackedVector3Array([Vector3(-0.038, 0.0056, i * 0.016), Vector3(0.038, 0.0056, i * 0.016 + 0.004)]), 0.0009, 4)
			mb.pop()
		"bread":
			var prof := PackedVector2Array()
			for i in 5:
				var a := PI + i / 4.0 * PI * 0.5
				prof.append(Vector2(-0.032 + cos(a) * 0.004, -(0.004 + sin(a) * 0.004)))
			for i in 5:
				var a := PI * 1.5 + i / 4.0 * PI * 0.5
				prof.append(Vector2(0.032 + cos(a) * 0.004, -(0.004 + sin(a) * 0.004)))
			for i in 14:
				var a := i / 13.0 * (PI - 0.42)
				prof.append(Vector2(0.0175 + cos(a) * 0.0185, -(0.036 + sin(a) * 0.0185)))
			for i in 14:
				var a := 0.42 + i / 13.0 * (PI - 0.42)
				prof.append(Vector2(-0.0175 + cos(a) * 0.0185, -(0.036 + sin(a) * 0.0185)))
			var crumb := PackedVector2Array()
			for p in prof: crumb.append(Vector2(p.x * 0.84, (p.y + 0.028) * 0.84 - 0.028))
			mb.at(Vector3(0, 0, -0.03), Vector3(0, 0.35, 0))
			mb.push(Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0, 0)), Vector3.ZERO))
			mb.col(Color("D9954A"), 1.0, 0.1); mb.extrude(prof, 0.06, 0.006, 3, Color("E8B26A"))
			mb.col(c2, 0.5, 0.0); mb.at(Vector3(0, 0.058, 0)); mb.extrude(crumb, 0.0045, 0.0015); mb.pop()
			mb.pop(); mb.pop()
		"jar":
			var pr := MB.spline(PackedVector2Array([Vector2(0, 0.0), Vector2(0.026, 0.0), Vector2(0.032, 0.008), Vector2(0.033, 0.04), Vector2(0.027, 0.054), Vector2(0.022, 0.058), Vector2(0.0, 0.058)]), 5)
			mb.col(c, 1.0, 0.9); mb.lathe(pr, 26, Callable(), _grad(c.darkened(0.12), c.lightened(0.18)))
			mb.col(Color("B07A3E")); mb.at(Vector3(0, 0.055, 0)); mb.puck(0.025, 0.013, 0.004, 22); mb.pop()
			mb.col(Color("FFF6E0") if key == "honey" else c2, 0.5); mb.at(Vector3(0, 0.018, 0)); mb.puck(0.0336, 0.02, 0.001, 26); mb.pop()
			if key == "honey":
				mb.col(Color("FFB52E"), 0.6); mb.at(Vector3(0, 0.028, 0.0342), Vector3(PI * 0.5, 0, 0)); mb.puck(0.006, 0.0015, 0.0006, 6); mb.pop()
				mb.col(c, 0.8, 1.0); mb.tube(MB.spline3(PackedVector3Array([Vector3(0.014, 0.062, 0.017), Vector3(0.024, 0.058, 0.022), Vector3(0.028, 0.048, 0.024)]), 3), func(t: float) -> float: return 0.004 * (0.6 + t * 0.6), 7)
				mb.at(Vector3(0.028, 0.046, 0.024)); mb.sphere(0.0045, 10, 6); mb.pop()
			else:
				mb.col(Color("5A1E28"), 0.0)
				for i in 5:
					mb.at(Vector3(-0.01 + i * 0.005, 0.03 + (i % 2) * 0.004, 0.0338), Vector3(PI * 0.5, 0, 0)); mb.ellipsoid(0.002, 0.001, 0.003, 6, 3); mb.pop()
		"bar":
			mb.at(Vector3.ZERO, Vector3(0, 0.35, 0))
			mb.col(c); mb.at(Vector3(0, 0.007, 0)); mb.rbox(Vector3(0.062, 0.014, 0.088), 0.003, 2); mb.pop()
			mb.col(c.lightened(0.12), 0.6)
			for i in 3:
				for j in 2:
					mb.at(Vector3(-0.019 + i * 0.019, 0.0145, -0.033 + j * 0.019)); mb.rbox(Vector3(0.016, 0.004, 0.016), 0.002, 1); mb.pop()
			mb.col(PINK); mb.at(Vector3(0, 0.0078, 0.022)); mb.rbox(Vector3(0.064, 0.0165, 0.046), 0.004, 2); mb.pop()
			mb.col(Color.WHITE, 0.4); mb.at(Vector3(0, 0.0162, 0.022)); mb.rbox(Vector3(0.03, 0.001, 0.016), 0.001, 1); mb.pop()
			mb.pop()
		"tin":
			mb.col(c2); mb.cylinder(0.028, 0.06, 26)
			mb.col(c); mb.at(Vector3(0, 0.0, 0)); mb.puck(0.0285, 0.016, 0.002, 26); mb.pop()
			mb.col(c); mb.at(Vector3(0, 0.054, 0)); mb.puck(0.0292, 0.012, 0.003, 26); mb.pop()
			mb.col(Color("FFF8EE"), 0.5); mb.at(Vector3(0, 0.034, 0.0272), Vector3(PI * 0.5, 0, 0)); mb.puck(0.0105, 0.0026, 0.0008, 18); mb.pop()
			if key == "matcha":
				mb.col(Color("5E9A3A"), 0.4); mb.push(Transform3D(Basis.from_euler(Vector3(-PI * 0.5, 0, 0.6)), Vector3(0, 0.034, 0.0302))); mb.leaf(0.0068, 0.0038, 0.0008, 0.0); mb.pop()
			else:
				for s in [-1.0, 1.0]:
					mb.col(Color("6B4430"), 0.4); mb.at(Vector3(s * 0.0022, 0.034, 0.0298), Vector3(PI * 0.5, 0, 0.5)); mb.ellipsoid(0.0026, 0.0012, 0.0052, 8, 4); mb.pop()
		"bottle":
			if key == "soy":
				var pr := MB.spline(PackedVector2Array([Vector2(0, 0.0), Vector2(0.022, 0.0), Vector2(0.025, 0.01), Vector2(0.024, 0.05), Vector2(0.012, 0.064), Vector2(0.008, 0.076), Vector2(0, 0.077)]), 5)
				mb.col(c, 1.0, 0.8); mb.lathe(pr, 24)
				mb.col(c2); mb.at(Vector3(0, 0.072, 0)); mb.puck(0.011, 0.016, 0.004, 16, 0.008); mb.pop()
				mb.col(Color("FFF6E0"), 0.5); mb.at(Vector3(0, 0.018, 0)); mb.puck(0.0252, 0.02, 0.001, 24); mb.pop()
				mb.col(c2, 0.0); mb.at(Vector3(0, 0.028, 0.0256), Vector3(PI * 0.5, 0, 0)); mb.ellipsoid(0.006, 0.0006, 0.006, 10, 3); mb.pop()
			else:
				var pr := MB.spline(PackedVector2Array([Vector2(0, 0.0), Vector2(0.024, 0.0), Vector2(0.028, 0.02), Vector2(0.024, 0.044), Vector2(0.01, 0.06), Vector2(0.008, 0.074), Vector2(0, 0.075)]), 5)
				mb.col(c, 1.0, 0.9); mb.lathe(pr, 24, Callable(), _grad(c.darkened(0.15), c.lightened(0.25)))
				mb.col(PINK); mb.at(Vector3(0, 0.07, 0)); mb.puck(0.01, 0.012, 0.003, 14); mb.pop()
				mb.col(Color("FFF6E0"), 0.5); mb.at(Vector3(0, 0.024, 0.026), Vector3(PI * 0.5, 0, 0)); mb.rbox(Vector3(0.026, 0.002, 0.02), 0.0008, 1); mb.pop()
				mb.col(Color("E8402E"), 0.0); mb.at(Vector3(0, 0.024, 0.0275), Vector3(PI * 0.5, 0, 0)); mb.ellipsoid(0.005, 0.0006, 0.005, 8, 3); mb.pop()
		"box":
			mb.at(Vector3.ZERO, Vector3(0, 0.3, 0))
			mb.col(c); mb.at(Vector3(0, 0.028, 0)); mb.rbox(Vector3(0.075, 0.056, 0.024), 0.004, 2); mb.pop()
			mb.col(c2, 0.5); mb.at(Vector3(0, 0.026, 0.0122)); mb.rbox(Vector3(0.056, 0.036, 0.002), 0.003, 1); mb.pop()
			mb.col(Color("B8732A"), 0.4); mb.at(Vector3(0.008, 0.024, 0.0136), Vector3(PI * 0.5, 0, 0)); mb.ellipsoid(0.014, 0.0012, 0.009, 14, 4); mb.pop()
			mb.col(Color.WHITE, 0.0); mb.at(Vector3(-0.009, 0.026, 0.0142), Vector3(PI * 0.5, 0, 0)); mb.ellipsoid(0.008, 0.0012, 0.006, 12, 4); mb.pop()
			mb.pop()
		"cube":
			for p in [[Vector3(-0.016, 0.017, 0.006), Vector3(0.1, 0.4, 0.05)], [Vector3(0.018, 0.015, -0.01), Vector3(-0.05, -0.3, 0.08)], [Vector3(0.004, 0.044, 0.0), Vector3(0.3, 0.8, -0.2)]]:
				mb.at(p[0], p[1]).col(Color("CDEBFF"), 1.0, 1.0)
				mb.rbox(Vector3(0.032, 0.032, 0.032), 0.007, 2)
				mb.col(Color.WHITE, 0.0); mb.at(Vector3(-0.006, 0.0162, -0.004)); mb.rbox(Vector3(0.012, 0.0012, 0.004), 0.0005, 1); mb.pop()
				mb.pop()
		"kernel":
			var pr := PackedVector2Array([Vector2(0, 0), Vector2(0.024, 0.0), Vector2(0.025, 0.002), Vector2(0.034, 0.058), Vector2(0, 0.058)])
			mb.col(Color.WHITE)
			mb.lathe(pr, 32, Callable(), func(u: float, _v: float, _p: Vector3) -> Color: return Color("FF5A7A") if fposmod(u * 8.0, 1.0) < 0.5 else Color("FFFFFF"))
			var rng := RandomNumberGenerator.new(); rng.seed = 9
			for i in 9:
				var a := rng.randf() * TAU
				var r := sqrt(rng.randf()) * 0.024
				mb.at(Vector3(cos(a) * r, 0.062 + rng.randf() * 0.01, sin(a) * r)).col(Color("FFFBEA"), 0.7)
				mb.blob(0.011, 0.009, 0.011, 0.3, 0.6, i, 12, 8, func(_u: float, v: float, _p: Vector3) -> Color: return Color("FFE070") if v < 0.3 else Color("FFFBEA"))
				mb.pop()
		"sprink":
			mb.col(Color("EAF4FF")); mb.cylinder(0.024, 0.056, 22)
			mb.col(c); mb.at(Vector3(0, 0.054, 0)); mb.puck(0.026, 0.014, 0.004, 22); mb.pop()
			mb.col(Color.WHITE, 0.0)
			for i in 3:
				mb.at(Vector3(-0.008 + i * 0.008, 0.069, 0)); mb.puck(0.0026, 0.0012, 0.0005, 8); mb.pop()
			var cols := [Color("FF7EA6"), Color("7FD3F7"), Color("FFD24A"), Color("9BE38F"), Color("C3A6FF")]
			var rng := RandomNumberGenerator.new(); rng.seed = 5
			for i in 26:
				var a := rng.randf() * TAU
				var y := rng.randf_range(0.008, 0.046)
				mb.col(cols[i % 5], 0.0)
				mb.at(Vector3(cos(a) * 0.0242, y, sin(a) * 0.0242), Vector3(rng.randf() * TAU, -a, 0)); mb.rbox(Vector3(0.007, 0.0024, 0.0024), 0.0011, 1); mb.pop()
		_:
			mb.at(Vector3(0, 0.035, 0)); mb.sphere(0.035); mb.pop()
	mb.col(Color.WHITE, 1.0, 0.0)

static func _round(mb: MB, key: String, c: Color) -> void:
	match key:
		"apple":
			var pr := MB.spline(PackedVector2Array([Vector2(0, 0.006), Vector2(0.022, 0.0), Vector2(0.04, 0.014), Vector2(0.046, 0.036), Vector2(0.04, 0.058), Vector2(0.024, 0.07), Vector2(0.008, 0.064), Vector2(0, 0.058)]), 5)
			mb.col(c, 1.0, 0.35); mb.lathe(pr, 28, Callable(), func(u: float, v: float, _p: Vector3) -> Color:
				return Color("D8303A").lerp(Color("FF6A60"), v * 0.8).lerp(Color("FFD88A"), 0.18 * maxf(0.0, cos(u * TAU - 1.0)) * v))
			_stem(mb, Vector3(0, 0.06, 0), Vector3(0.004, 0.084, 0.0), 0.0026)
			_leaf_at(mb, Vector3(0.003, 0.078, 0), 0.8, -0.25, 0.016, 0.009)
		"orange":
			mb.col(c, 1.0, 0.2); mb.at(Vector3(0, 0.04, 0)); mb.blob(0.043, 0.04, 0.043, 0.012, 1.4, 4, 28, 16, func(_u: float, v: float, _p: Vector3) -> Color: return Color("F2861E").lerp(Color("FFB050"), v)); mb.pop()
			mb.col(Color("6BBF59")); mb.at(Vector3(0, 0.079, 0)); mb.puck(0.006, 0.004, 0.0015, 10); mb.pop()
			_leaf_at(mb, Vector3(0.002, 0.081, 0), 2.2, -0.2, 0.017, 0.009)
		"tomato":
			var pr := MB.spline(PackedVector2Array([Vector2(0, 0.004), Vector2(0.026, 0.0), Vector2(0.044, 0.018), Vector2(0.046, 0.034), Vector2(0.034, 0.054), Vector2(0.01, 0.06), Vector2(0, 0.056)]), 5)
			mb.col(c, 1.0, 0.6); mb.lathe(pr, 30, func(u: float, v: float) -> float: return 1.0 + 0.04 * cos(u * TAU * 5.0) * sin(v * PI), _grad(Color("D8301E"), Color("FF6A50")))
			for i in 5:
				_leaf_at(mb, Vector3(0, 0.056, 0), i * TAU / 5.0 + 0.3, 0.2, 0.012, 0.005, Color("5DAE4B"))
			_stem(mb, Vector3(0, 0.056, 0), Vector3(0.002, 0.066, 0.0), 0.0022, Color("5DAE4B"))

# ======================================================================= pieces
const _HALF_SETS := ["round", "lemon", "mango", "pine", "melon", "pumpkin", "cabbage", "onion", "potato", "pepper", "avo", "straw", "cherry", "cluster", "mushroom"]
const _COIN_SETS := ["long", "carrot", "banana", "corn", "sausage"]

## One chopped piece (about 3 cm), sitting on y=0.
static func piece(mb: MB, key: String, s := 1.0) -> void:
	var it: Dictionary = G.ING[key]
	var c: Color = it.c
	var c2: Color = it.c2
	var sh: String = it.sh
	mb.push(Transform3D(Basis.IDENTITY.scaled(Vector3(s, s, s)), Vector3.ZERO))
	if sh in _HALF_SETS:
		var r := 0.017
		var o := PackedVector2Array()
		var inn := PackedVector2Array()
		for i in 17:
			var a := PI * i / 16.0
			o.append(Vector2(cos(a) * r, sin(a) * r - r * 0.4))
			inn.append(Vector2(cos(a) * r * 0.8, sin(a) * r * 0.8 - r * 0.4 + 0.0006))
		var skin := Color("3E6B2E") if sh == "avo" else c
		var face := Color("FFB3C0") if sh == "straw" else c2
		_layered_extrude(mb, o, inn, 0.008, skin, face, 0.002)
		if sh == "round" and key != "apple":
			mb.col(c.lightened(0.1), 0.0)
			for i in 3:
				mb.at(Vector3((-0.007 + i * 0.007), 0.0093, -0.001)); mb.ellipsoid(0.0016, 0.0005, 0.0026, 6, 3); mb.pop()
	elif sh in _COIN_SETS:
		mb.col(c); mb.puck(0.0145, 0.008, 0.002, 18)
		mb.col(c2, 0.5); mb.at(Vector3(0, -0.0006, 0)); mb.puck(0.0105, 0.0092, 0.0015, 18); mb.pop()
		if sh == "long":
			mb.col(c.lightened(0.3), 0.0)
			for i in 3:
				var a := i * 2.1
				mb.at(Vector3(cos(a) * 0.004, 0.0088, sin(a) * 0.004)); mb.ellipsoid(0.0013, 0.0004, 0.0018, 6, 3); mb.pop()
	elif sh == "leafy":
		mb.col(c); mb.at(Vector3(0, 0.004, 0)); mb.leaf(0.016, 0.012, 0.0022, 0.6, 0.4); mb.pop()
	elif sh == "broccoli":
		mb.col(Color("9BD27E")); mb.cylinder(0.004, 0.01, 8)
		mb.col(c); mb.at(Vector3(0, 0.014, 0)); mb.blob(0.011, 0.009, 0.011, 0.2, 0.6, 3, 12, 8); mb.pop()
	elif sh in ["bread", "tortilla", "sheet"]:
		var t := PackedVector2Array([Vector2(-0.016, 0.01), Vector2(0.016, 0.01), Vector2(0.0, -0.016)])
		var rt := PackedVector2Array()
		for i in 3:
			var a := t[i]; var b := t[(i + 1) % 3]
			for k in 5: rt.append(a.lerp(b, 0.1 + 0.8 * k / 4.0))
		if sh == "bread":
			var inner := PackedVector2Array()
			for p in rt: inner.append(p * 0.78 + Vector2(0, 0.001))
			_layered_extrude(mb, rt, inner, 0.008, c, c2, 0.002)
		else:
			mb.col(c); mb.extrude(rt, 0.005 if sh == "tortilla" else 0.003, 0.0015)
	elif sh == "egg":
		mb.col(Color.WHITE); mb.at(Vector3(0, 0.003, 0)); mb.ellipsoid(0.016, 0.004, 0.013, 16, 6); mb.pop()
		mb.col(c2, 0.6); mb.at(Vector3(0, 0.0055, 0)); mb.ellipsoid(0.0065, 0.004, 0.0065, 12, 6); mb.pop()
	else:
		var top := c2 if sh in ["fillet", "steak"] else c.lightened(0.12)
		mb.col(c); mb.at(Vector3(0, 0.008, 0)); mb.rbox(Vector3(0.022, 0.016, 0.02), 0.005, 2); mb.pop()
		mb.col(top, 0.0); mb.at(Vector3(-0.003, 0.0162, -0.002)); mb.ellipsoid(0.006, 0.0006, 0.004, 8, 3); mb.pop()
	mb.pop()
	mb.col(Color.WHITE, 1.0, 0.0)
