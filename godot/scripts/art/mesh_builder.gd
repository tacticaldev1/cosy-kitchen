## Procedural mesh toolkit. Accumulates many small shapes (with a transform stack, a current
## colour, outline width and gloss) into ONE ArrayMesh with vertex colours. A whole dish
## becomes a single mesh drawn with a single toon material.
##
## Winding: Godot treats clockwise triangles as front faces. Every generator here builds
## parametric grids where u runs around a shape and v runs bottom→top, and emits
## (a, b, c), (a, c, d) so the outside faces the camera.
class_name MB
extends RefCounted

var verts := PackedVector3Array()
var norms := PackedVector3Array()
var cols := PackedColorArray()
var uv1 := PackedVector2Array()
var uv2 := PackedVector2Array()
var idx := PackedInt32Array()

var _layers := {}
var _cur := 0

var xf := Transform3D.IDENTITY
var color := Color.WHITE
var outline := 1.0
var gloss := 0.0
var _stack: Array = []

# ------------------------------------------------------------------ state helpers
func push(t: Transform3D) -> MB:
	_stack.push_back([xf, color, outline, gloss])
	xf = xf * t
	return self

var unbalanced := 0

func pop() -> MB:
	if _stack.is_empty():
		unbalanced += 1
		return self
	var s: Array = _stack.pop_back()
	xf = s[0]; color = s[1]; outline = s[2]; gloss = s[3]
	return self

func at(pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MB:
	var b := Basis.from_euler(rot).scaled(scl)
	return push(Transform3D(b, pos))

func col(c: Color, ol := -1.0, gl := -1.0) -> MB:
	color = c
	if ol >= 0.0: outline = ol
	if gl >= 0.0: gloss = gl
	return self

func is_empty() -> bool:
	return verts.is_empty()

## Switch the geometry layer: 0 = opaque toon, 1 = glass. Transform/colour state is shared.
func layer(n: int) -> MB:
	if n == _cur:
		return self
	_layers[_cur] = [verts, norms, cols, uv1, uv2, idx]
	if _layers.has(n):
		var a: Array = _layers[n]
		verts = a[0]; norms = a[1]; cols = a[2]; uv1 = a[3]; uv2 = a[4]; idx = a[5]
	else:
		verts = PackedVector3Array(); norms = PackedVector3Array(); cols = PackedColorArray()
		uv1 = PackedVector2Array(); uv2 = PackedVector2Array(); idx = PackedInt32Array()
	_cur = n
	return self

func current_layer() -> int:
	return _cur

func stack_depth() -> int:
	return _stack.size()

# ------------------------------------------------------------------ low level
func _nb() -> Basis:
	return xf.basis.inverse().transposed()

## Adds a parametric grid surface. fn(u, v) -> Vector3 in local space.
## color_fn(u, v, p) -> Color is optional. Normals are area-weighted face normals,
## shared across the u seam, with collapsed rings (poles) averaged.
func grid(fn: Callable, nu: int, nv: int, wrap_u := true, color_fn: Callable = Callable()) -> void:
	var cn := nu if wrap_u else nu + 1
	var pos := PackedVector3Array()
	pos.resize(cn * (nv + 1))
	for j in nv + 1:
		var v := float(j) / nv
		for i in cn:
			pos[j * cn + i] = fn.call(float(i) / nu, v)
	var nrm := PackedVector3Array()
	nrm.resize(pos.size())
	var tri := PackedInt32Array()
	for j in nv:
		for i in nu:
			var i1 := (i + 1) % cn if wrap_u else i + 1
			var a := j * cn + i
			var b := j * cn + i1
			var c := (j + 1) * cn + i1
			var d := (j + 1) * cn + i
			for t in [[a, b, c], [a, c, d]]:
				var p0 := pos[t[0]]; var p1 := pos[t[1]]; var p2 := pos[t[2]]
				var fnrm := (p2 - p0).cross(p1 - p0)
				nrm[t[0]] += fnrm; nrm[t[1]] += fnrm; nrm[t[2]] += fnrm
				tri.append(t[0]); tri.append(t[1]); tri.append(t[2])
	# collapsed rows (poles): share one averaged normal
	for j in nv + 1:
		var p0 := pos[j * cn]
		var collapsed := true
		for i in range(1, cn):
			if pos[j * cn + i].distance_squared_to(p0) > 1e-12:
				collapsed = false
				break
		if collapsed:
			var s := Vector3.ZERO
			for i in cn: s += nrm[j * cn + i]
			for i in cn: nrm[j * cn + i] = s
	var nb := _nb()
	var base := verts.size()
	var uvo := Vector2(outline, gloss)
	for j in nv + 1:
		for i in cn:
			var k := j * cn + i
			var p := pos[k]
			verts.append(xf * p)
			var n := nrm[k]
			norms.append((nb * n).normalized() if n.length_squared() > 1e-20 else xf.basis.y.normalized())
			cols.append(color_fn.call(float(i) / nu, float(j) / nv, p) if color_fn.is_valid() else color)
			uv1.append(Vector2(float(i) / nu, float(j) / nv))
			uv2.append(uvo)
	for t in tri:
		idx.append(base + t)

## Adds a flat polygon fan/triangulation (local points, all sharing normal n).
func polygon(pts: PackedVector3Array, n: Vector3) -> void:
	# project to 2D on the plane to triangulate
	var tb := Basis.looking_at(-n, Vector3.UP if absf(n.y) < 0.99 else Vector3.FORWARD)
	var p2 := PackedVector2Array()
	var inv := tb.inverse()
	for p in pts:
		var q := inv * p
		p2.append(Vector2(q.x, q.y))
	var tris := Geometry2D.triangulate_polygon(p2)
	if tris.is_empty():
		return
	var base := verts.size()
	var nn := (_nb() * n).normalized()
	for p in pts:
		verts.append(xf * p); norms.append(nn); cols.append(color); uv1.append(Vector2.ZERO); uv2.append(Vector2(outline, gloss))
	# looking_at(-n) puts the viewer on the +n side with x right / y up, so a front face
	# must be clockwise (negative signed area) in this projection.
	for t in range(0, tris.size(), 3):
		var a := p2[tris[t]]; var b := p2[tris[t + 1]]; var c := p2[tris[t + 2]]
		var area := (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)
		if area < 0.0:
			idx.append(base + tris[t]); idx.append(base + tris[t + 1]); idx.append(base + tris[t + 2])
		else:
			idx.append(base + tris[t]); idx.append(base + tris[t + 2]); idx.append(base + tris[t + 1])

func append_mesh(other: MB) -> void:
	var base := verts.size()
	var nb := _nb()
	for k in other.verts.size():
		verts.append(xf * other.verts[k])
		norms.append((nb * other.norms[k]).normalized())
		cols.append(other.cols[k])
		uv1.append(other.uv1[k])
		uv2.append(other.uv2[k])
	for t in other.idx:
		idx.append(base + t)

func build(existing: ArrayMesh = null) -> ArrayMesh:
	var m := existing if existing else ArrayMesh.new()
	if verts.is_empty():
		return m
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_TEX_UV] = uv1
	arr[Mesh.ARRAY_TEX_UV2] = uv2
	arr[Mesh.ARRAY_INDEX] = idx
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

# ------------------------------------------------------------------ primitives
## Surface of revolution. profile: Vector2(radius, height) from bottom (v=0) to top (v=1).
## rmod(u, v) -> radius multiplier (lobes, ridges). Evenly resampled by arc length.
func lathe(profile: PackedVector2Array, segs := 28, rmod: Callable = Callable(), color_fn: Callable = Callable(), rows := -1) -> void:
	var cum := PackedFloat32Array([0.0])
	for i in range(1, profile.size()):
		cum.append(cum[i - 1] + profile[i].distance_to(profile[i - 1]))
	var total := maxf(cum[cum.size() - 1], 1e-6)
	var nv := rows if rows > 0 else clampi(profile.size() - 1, 4, 40)
	var sample := func(v: float) -> Vector2:
		var d := v * total
		var k := 1
		while k < cum.size() - 1 and cum[k] < d:
			k += 1
		var seg := maxf(cum[k] - cum[k - 1], 1e-9)
		return profile[k - 1].lerp(profile[k], clampf((d - cum[k - 1]) / seg, 0.0, 1.0))
	grid(func(u: float, v: float) -> Vector3:
		var p: Vector2 = sample.call(v)
		var r := p.x
		if rmod.is_valid():
			r *= rmod.call(u, v)
		var a := u * TAU
		return Vector3(cos(a) * r, p.y, sin(a) * r), segs, nv, true, color_fn)

func ellipsoid(rx: float, ry: float, rz: float, nu := 24, nv := 14, color_fn: Callable = Callable()) -> void:
	grid(func(u: float, v: float) -> Vector3:
		var a := u * TAU
		var ph := v * PI
		return Vector3(sin(ph) * cos(a) * rx, -cos(ph) * ry, sin(ph) * sin(a) * rz), nu, nv, true, color_fn)

func sphere(r: float, nu := 20, nv := 12, color_fn: Callable = Callable()) -> void:
	ellipsoid(r, r, r, nu, nv, color_fn)

## Ellipsoid displaced by smooth noise: potatoes, florets, popcorn, cream dollops.
func blob(rx: float, ry: float, rz: float, amp: float, freq: float, seed_: int, nu := 22, nv := 14, color_fn: Callable = Callable()) -> void:
	var n := FastNoiseLite.new()
	n.seed = seed_
	n.frequency = freq
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	grid(func(u: float, v: float) -> Vector3:
		var a := u * TAU
		var ph := v * PI
		var d := Vector3(sin(ph) * cos(a), -cos(ph), sin(ph) * sin(a))
		var k := 1.0 + amp * n.get_noise_3dv(d * 10.0)
		return Vector3(d.x * rx, d.y * ry, d.z * rz) * k, nu, nv, true, color_fn)

## Rounded box centred on the origin. size = full size; r = corner radius.
func rbox(size: Vector3, r: float, seg := 3) -> void:
	var h := size * 0.5
	r = minf(r, minf(h.x, minf(h.y, h.z)) * 0.999)
	var inner := h - Vector3(r, r, r)
	# coordinates along one face axis: arc-spaced near the edges, plus the flat middle
	var coords := func(hh: float, inn: float) -> PackedFloat32Array:
		var out := PackedFloat32Array()
		for k in range(seg, -1, -1):
			out.append(-inn - r * tan(float(k) / seg * PI * 0.25))
		for k in range(0, seg + 1):
			out.append(inn + r * tan(float(k) / seg * PI * 0.25))
		return out
	var cx: PackedFloat32Array = coords.call(h.x, inner.x)
	var cy: PackedFloat32Array = coords.call(h.y, inner.y)
	var cz: PackedFloat32Array = coords.call(h.z, inner.z)
	# faces: axis index, sign
	var faces := [[0, 1], [0, -1], [1, 1], [1, -1], [2, 1], [2, -1]]
	var nb := _nb()
	for f in faces:
		var ax: int = f[0]
		var sg: int = f[1]
		var a1 := (ax + 1) % 3
		var a2 := (ax + 2) % 3
		var ca: PackedFloat32Array = [cx, cy, cz][a1]
		var cb: PackedFloat32Array = [cx, cy, cz][a2]
		var base := verts.size()
		for j in cb.size():
			for i in ca.size():
				var q := Vector3.ZERO
				q[ax] = h[ax] * sg
				q[a1] = clampf(ca[i], -h[a1] * 3.0, h[a1] * 3.0)
				q[a2] = cb[j]
				var inn := Vector3(clampf(q.x, -inner.x, inner.x), clampf(q.y, -inner.y, inner.y), clampf(q.z, -inner.z, inner.z))
				var n := (q - inn).normalized()
				var p := inn + n * r
				verts.append(xf * p); norms.append((nb * n).normalized()); cols.append(color)
				uv1.append(Vector2(float(i) / (ca.size() - 1), float(j) / (cb.size() - 1))); uv2.append(Vector2(outline, gloss))
		var w := ca.size()
		for j in cb.size() - 1:
			for i in w - 1:
				var a := base + j * w + i
				var b := a + 1
				var c := a + w + 1
				var d := a + w
				# orientation depends on axis handedness and sign
				var flip := sg < 0
				if not flip:
					idx.append(a); idx.append(c); idx.append(b); idx.append(a); idx.append(d); idx.append(c)
				else:
					idx.append(a); idx.append(b); idx.append(c); idx.append(a); idx.append(c); idx.append(d)

## Puck / rounded cylinder sitting on y=0: pancakes, plates' feet, lids, cookies.
func puck(r: float, h: float, bevel: float, segs := 28, r_top := -1.0, color_fn: Callable = Callable()) -> void:
	var rt := r if r_top < 0 else r_top
	bevel = minf(bevel, minf(h * 0.5, minf(r, rt)) * 0.99)
	var pr := PackedVector2Array([Vector2(0, 0)])
	var steps := 4
	for k in range(steps + 1):
		var a := -PI * 0.5 + float(k) / steps * PI * 0.5
		pr.append(Vector2(r - bevel + cos(a) * bevel, bevel + sin(a) * bevel))
	for k in range(steps + 1):
		var a := float(k) / steps * PI * 0.5
		pr.append(Vector2(rt - bevel + cos(a) * bevel, h - bevel + sin(a) * bevel))
	pr.append(Vector2(0, h))
	lathe(pr, segs, Callable(), color_fn, 14)

func cylinder(r: float, h: float, segs := 20, r_top := -1.0) -> void:
	puck(r, h, minf(r, h) * 0.12, segs, r_top)

func torus(big_r: float, small_r: float, nu := 28, nv := 12) -> void:
	grid(func(u: float, v: float) -> Vector3:
		var a := u * TAU
		var b := v * TAU
		var rr := big_r + cos(b) * small_r
		return Vector3(cos(a) * rr, sin(b) * small_r, sin(a) * rr), nu, nv, true)

func cone(r: float, h: float, segs := 18) -> void:
	lathe(PackedVector2Array([Vector2(0, 0), Vector2(r, 0.0001), Vector2(r * 0.98, h * 0.05), Vector2(0, h)]), segs)

## Tube along a path. radius_fn(t) -> radius (t in 0..1) or a float. Parallel-transport frames.
## Ends close to a point when the radius there is ~0; otherwise they are capped.
func tube(path: PackedVector3Array, radius, sides := 10, color_fn: Callable = Callable(), squash := 1.0, normal0 := Vector3.ZERO) -> void:
	var n := path.size()
	if n < 2:
		return
	var tangents := PackedVector3Array()
	for i in n:
		var t := (path[mini(i + 1, n - 1)] - path[maxi(i - 1, 0)]).normalized()
		tangents.append(t)
	var normals := PackedVector3Array()
	var up := Vector3.UP if absf(tangents[0].dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var nrm := tangents[0].cross(up).normalized()
	if normal0 != Vector3.ZERO:
		nrm = (normal0 - tangents[0] * tangents[0].dot(normal0)).normalized()
	for i in n:
		if i > 0:
			var axis := tangents[i - 1].cross(tangents[i])
			if axis.length() > 1e-6:
				nrm = nrm.rotated(axis.normalized(), tangents[i - 1].angle_to(tangents[i]))
		normals.append(nrm)
	var rf := func(t: float) -> float: return float(radius) if typeof(radius) != TYPE_CALLABLE else (radius as Callable).call(t)
	grid(func(u: float, v: float) -> Vector3:
		var fi := v * (n - 1)
		var i0 := mini(int(fi), n - 2)
		var f := fi - i0
		var c := path[i0].lerp(path[i0 + 1], f)
		var tn := tangents[i0].lerp(tangents[i0 + 1], f).normalized()
		var nn := normals[i0].lerp(normals[i0 + 1], f).normalized()
		var bn := nn.cross(tn).normalized()
		var a := u * TAU
		var r: float = rf.call(v)
		return c + (nn * cos(a) * squash + bn * sin(a)) * r, sides, (n - 1) * 2, true, color_fn)
	# caps for blunt ends
	for e in [0, 1]:
		var r: float = rf.call(float(e))
		if r > 1e-4:
			var i := 0 if e == 0 else n - 1
			var pts := PackedVector3Array()
			var tn := tangents[i]
			var nn := normals[i]
			var bn := nn.cross(tn).normalized()
			for k in sides:
				var a := float(k) / sides * TAU
				pts.append(path[i] + (nn * cos(a) * squash + bn * sin(a)) * r)
			polygon(pts, -tn if e == 0 else tn)

## Extruded 2D outline (x, z) with rounded top/bottom edges. Sits on y=0.
func extrude(outline_pts: PackedVector2Array, h: float, bevel := 0.004, bsteps := 3, top_color := Color(0, 0, 0, 0)) -> void:
	var m := outline_pts.size()
	if m < 3:
		return
	# make CCW in (x, z) as seen from above (+y): signed area with z down
	var area := 0.0
	for i in m:
		var a := outline_pts[i]; var b := outline_pts[(i + 1) % m]
		area += a.x * b.y - b.x * a.y
	var pts := outline_pts.duplicate()
	if area < 0:
		pts.reverse()
	# per-vertex outward 2D normals
	var n2 := PackedVector2Array()
	for i in m:
		var a := pts[(i - 1 + m) % m]; var b := pts[i]; var c := pts[(i + 1) % m]
		var e1 := (b - a).normalized(); var e2 := (c - b).normalized()
		var na := Vector2(e1.y, -e1.x); var nc := Vector2(e2.y, -e2.x)
		var nn := (na + nc).normalized()
		n2.append(nn)
	bevel = minf(bevel, h * 0.49)
	# profile rows: (inset, y)
	var prof: Array[Vector2] = []
	for k in range(bsteps + 1):
		var t := float(k) / bsteps * PI * 0.5
		prof.append(Vector2(bevel * (1.0 - sin(t)), bevel * (1.0 - cos(t))))
	for k in range(bsteps + 1):
		var t := float(k) / bsteps * PI * 0.5
		prof.append(Vector2(bevel * (1.0 - cos(t)), h - bevel + bevel * sin(t)))
	# orientation check: grid wants u to go one way around; test with the first face
	grid(func(u: float, v: float) -> Vector3:
		var i := int(round(u * m)) % m
		var pi := int(round(v * (prof.size() - 1)))
		var pr: Vector2 = prof[pi]
		var p := pts[i] - n2[i] * pr.x
		return Vector3(p.x, pr.y, p.y), m, prof.size() - 1, true)
	var c0 := color
	if top_color.a > 0.0:
		color = top_color
	var top := PackedVector3Array()
	var bot := PackedVector3Array()
	for i in m:
		var pt := pts[i] - n2[i] * bevel
		top.append(Vector3(pt.x, h, pt.y))
		bot.append(Vector3(pt.x, 0.0, pt.y))
	polygon(top, Vector3.UP)
	color = c0
	polygon(bot, Vector3.DOWN)

## A thin leaf with a slight curl: flattened ellipsoid bent along its length.
## Lies along z (tip at +length, base at -length). ruffle adds a wavy edge.
func leaf(length: float, width: float, thick := 0.0025, curl := 0.25, ruffle := 0.0, color_fn: Callable = Callable()) -> void:
	grid(func(u: float, v: float) -> Vector3:
		var a := u * TAU
		var ph := v * PI
		var x := sin(ph) * cos(a) * width
		var y := sin(ph) * sin(a) * thick
		var z := cos(ph) * length
		var t := (z / length)
		y += curl * length * (1.0 - t * t) * 0.3 + curl * x * x / maxf(width, 1e-4) * 0.6
		if ruffle > 0.0:
			var e := absf(x) / maxf(width, 1e-4)
			y += ruffle * sin(v * PI * 9.0 + signf(x) * 1.3) * e * e * width
		return Vector3(x, y, z), 16, 12, true, color_fn)

# ------------------------------------------------------------------ helpers
## Points of a circle in (x, z), counter-clockwise from above.
static func circle_pts(r: float, n := 32, rx := -1.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := float(i) / n * TAU
		out.append(Vector2(cos(a) * (r if rx < 0 else rx), -sin(a) * r))
	return out

## Rounded rectangle outline in (x, z).
static func rrect_pts(w: float, d: float, r: float, steps := 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	r = minf(r, minf(w, d) * 0.5)
	var cs := [Vector2(w * 0.5 - r, -d * 0.5 + r), Vector2(-w * 0.5 + r, -d * 0.5 + r), Vector2(-w * 0.5 + r, d * 0.5 - r), Vector2(w * 0.5 - r, d * 0.5 - r)]
	for k in 4:
		for s in range(steps + 1):
			var a := (k * 0.25 + float(s) / steps * 0.25) * TAU
			out.append(cs[k] + Vector2(cos(a), -sin(a)) * r)
	return out

## Smooth closed profile helper: Catmull-Rom through control points.
static func spline(ctrl: PackedVector2Array, per := 6) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := ctrl.size()
	for i in n - 1:
		var p0 := ctrl[maxi(i - 1, 0)]; var p1 := ctrl[i]; var p2 := ctrl[i + 1]; var p3 := ctrl[mini(i + 2, n - 1)]
		for s in per:
			var t := float(s) / per
			var t2 := t * t; var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(ctrl[n - 1])
	return out

static func spline3(ctrl: PackedVector3Array, per := 6) -> PackedVector3Array:
	var out := PackedVector3Array()
	var n := ctrl.size()
	for i in n - 1:
		var p0 := ctrl[maxi(i - 1, 0)]; var p1 := ctrl[i]; var p2 := ctrl[i + 1]; var p3 := ctrl[mini(i + 2, n - 1)]
		for s in per:
			var t := float(s) / per
			var t2 := t * t; var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(ctrl[n - 1])
	return out

## A transform that sits on a lathe surface at (u, v), y-axis along the surface normal.
static func frame_on(fn: Callable, u: float, v: float) -> Transform3D:
	var e := 0.002
	var p: Vector3 = fn.call(u, v)
	var pu: Vector3 = fn.call(u + e, v) - fn.call(u - e, v)
	var pv: Vector3 = fn.call(u, minf(v + e, 1.0)) - fn.call(u, maxf(v - e, 0.0))
	var n := pv.cross(pu).normalized()
	if n.length_squared() < 0.5:
		n = Vector3.UP
	var x := pu.normalized()
	var z := x.cross(n).normalized()
	x = n.cross(z).normalized()
	return Transform3D(Basis(x, n, z), p)
