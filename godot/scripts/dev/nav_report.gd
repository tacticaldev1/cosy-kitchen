## Dev tool: checks every location's walk grid. Flood-fills from the entrance and reports free
## areas you can't reach and interaction points (doors, stations, seats) you can't walk to.
##   tools/gd.sh run --headless -- --dev=navreport
class_name NavReport
extends RefCounted

static func reach(nav: NavGrid, from: Vector3) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(nav.w * nav.h)
	var start := nav.cell_of(nav.nearest_free(from))
	var q: Array = [start]
	seen[start.y * nav.w + start.x] = 1
	while q.size():
		var c: Vector2i = q.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if nav.free_cell(n) and seen[n.y * nav.w + n.x] == 0:
				seen[n.y * nav.w + n.x] = 1
				q.append(n)
	return seen

## Returns a list of problems; prints an ASCII map when verbose.
static func check(loc: Location, entry: Vector3, points: Dictionary, verbose := false) -> Array:
	var nav := loc.nav
	var seen := reach(nav, entry)
	var problems: Array = []
	var island := 0
	for i in seen.size():
		if nav.blocked[i] == 0 and seen[i] == 0: island += 1
	if island > 0: problems.append("%s: %d free cells can't be reached from the entrance" % [loc.key, island])
	var marks := {}
	for k in points:
		var p: Vector3 = points[k]
		var c := nav.cell_of(nav.nearest_free(p))
		var dist := nav.center_of(c).distance_to(Vector3(p.x, 0, p.z))
		if seen[c.y * nav.w + c.x] == 0 or dist > 0.6:
			problems.append("%s: '%s' at (%.2f, %.2f) is unreachable (nearest free cell %.2fm away)" % [loc.key, k, p.x, p.z, dist])
		marks[c] = k
	if verbose:
		print("== ", loc.key, " ", nav.w, "x", nav.h)
		for y in nav.h:
			var line := ""
			for x in nav.w:
				var c := Vector2i(x, y)
				var i := y * nav.w + x
				if marks.has(c): line += "@"
				elif nav.blocked[i] != 0: line += "#"
				elif seen[i] == 0: line += "o"
				else: line += "."
			print(line)
	return problems

static func points_for(loc: Location) -> Dictionary:
	var pts := {}
	for it in loc.interacts: pts[it.id] = it.pos
	if loc is CafeLocation:
		var c := loc as CafeLocation
		for k in c.stand: pts["stand_" + k] = c.stand[k]
		var i := 0
		for s in c.seats():
			pts["seat_%d_%s" % [i, s.id]] = s.approach
			i += 1
	return pts
