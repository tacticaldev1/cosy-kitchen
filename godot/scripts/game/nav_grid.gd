## A walkability grid on the floor (x/z) with A* pathfinding and string-pulled paths.
## Locations block rectangles for counters, furniture and walls; characters ask for paths.
class_name NavGrid
extends RefCounted

var x0 := 0.0
var z0 := 0.0
var cell := 0.15
var w := 1
var h := 1
var blocked := PackedByteArray()
var _static := PackedByteArray()

func _init(bounds: Rect2 = Rect2(-1, -1, 2, 2), cell_size := 0.15) -> void:
	cell = cell_size
	x0 = bounds.position.x
	z0 = bounds.position.y
	w = maxi(1, ceili(bounds.size.x / cell))
	h = maxi(1, ceili(bounds.size.y / cell))
	blocked.resize(w * h)
	blocked.fill(0)

## Remember the current blocks as the permanent layout (furniture is layered on top).
func freeze_static() -> void:
	_static = blocked.duplicate()

func reset_to_static() -> void:
	if _static.size() == blocked.size():
		blocked = _static.duplicate()

func cell_of(p: Vector3) -> Vector2i:
	return Vector2i(clampi(int((p.x - x0) / cell), 0, w - 1), clampi(int((p.z - z0) / cell), 0, h - 1))

func center_of(c: Vector2i) -> Vector3:
	return Vector3(x0 + (c.x + 0.5) * cell, 0.0, z0 + (c.y + 0.5) * cell)

func inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h

func free_cell(c: Vector2i) -> bool:
	return inside(c) and blocked[c.y * w + c.x] == 0

func is_free(p: Vector3) -> bool:
	return free_cell(cell_of(p))

## Block an axis-aligned rectangle (centre cx/cz, size rw x rd), grown by pad (character radius).
func block_rect(cx: float, cz: float, rw: float, rd: float, pad := 0.18, value := 1) -> void:
	var a := cell_of(Vector3(cx - rw * 0.5 - pad, 0, cz - rd * 0.5 - pad))
	var b := cell_of(Vector3(cx + rw * 0.5 + pad, 0, cz + rd * 0.5 + pad))
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			blocked[y * w + x] = value

func block_border(pad := 0.18) -> void:
	var n := ceili(pad / cell)
	for y in h:
		for x in w:
			if x < n or y < n or x >= w - n or y >= h - n:
				blocked[y * w + x] = 1

func nearest_free(p: Vector3) -> Vector3:
	var c := cell_of(p)
	if free_cell(c): return p
	for r in range(1, maxi(w, h)):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r: continue
				var n := c + Vector2i(dx, dy)
				if free_cell(n): return center_of(n)
	return p

func line_free(a: Vector3, b: Vector3) -> bool:
	var d := b - a
	d.y = 0
	var steps := int(d.length() / (cell * 0.5)) + 1
	for i in steps + 1:
		if not is_free(a + d * (float(i) / steps)): return false
	return true

## A* (8-directional) from a to b; returns world points (y = 0), smoothed by line of sight.
func path(a: Vector3, b: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	var start := cell_of(nearest_free(a))
	var goal := cell_of(nearest_free(b))
	if start == goal:
		out.append(Vector3(b.x, 0, b.z))
		return out
	var open := [start]
	var came := {}
	var g := {start: 0.0}
	var f := {start: start.distance_to(goal)}
	var closed := {}
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	var guard := 0
	while open.size() and guard < 20000:
		guard += 1
		var bi := 0
		for i in range(1, open.size()):
			if f[open[i]] < f[open[bi]]: bi = i
		var cur: Vector2i = open[bi]
		open.remove_at(bi)
		if cur == goal: break
		closed[cur] = true
		for d in dirs:
			var n: Vector2i = cur + d
			if closed.has(n) or not free_cell(n): continue
			if d.x != 0 and d.y != 0 and (not free_cell(cur + Vector2i(d.x, 0)) or not free_cell(cur + Vector2i(0, d.y))): continue
			var ng: float = g[cur] + (1.4142 if d.x != 0 and d.y != 0 else 1.0)
			if not g.has(n) or ng < g[n]:
				g[n] = ng
				f[n] = ng + Vector2(n).distance_to(Vector2(goal))
				came[n] = cur
				if not open.has(n): open.append(n)
	if not came.has(goal):
		out.append(Vector3(b.x, 0, b.z))
		return out
	var cells: Array = [goal]
	var c: Vector2i = goal
	while came.has(c):
		c = came[c]
		cells.push_front(c)
	# string pulling
	var pts: Array = []
	for cc in cells: pts.append(center_of(cc))
	pts[pts.size() - 1] = Vector3(b.x, 0, b.z) if is_free(b) else pts[pts.size() - 1]
	var smooth: Array = [Vector3(a.x, 0, a.z)]
	var i := 0
	while i < pts.size() - 1:
		var j := pts.size() - 1
		while j > i + 1 and not line_free(smooth[smooth.size() - 1], pts[j]):
			j -= 1
		smooth.append(pts[j])
		i = j
	for k in range(1, smooth.size()): out.append(smooth[k])
	return out
