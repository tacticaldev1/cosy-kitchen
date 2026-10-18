## The placed furniture in one room (café or home): builds the models, blocks the walk grid,
## lists seats, and supports moving / rotating / storing items in edit mode.
class_name FurnitureLayer
extends Node3D

signal changed

var loc_key := "cafe"
var area := Rect2(-1, -1, 2, 2)
var nav: NavGrid
var items: Array = []        # [{id, x, z, rot, node}]

func setup(key: String, place_area: Rect2, grid: NavGrid) -> void:
	loc_key = key
	area = place_area
	nav = grid
	load_layout()

func load_layout() -> void:
	for it in items:
		if is_instance_valid(it.node): it.node.queue_free()
	items.clear()
	for d in Save.layouts.get(loc_key, []):
		if Furni.CATALOG.has(d.id):
			_spawn(d.id, float(d.x), float(d.z), int(d.rot))
	rebuild_nav()

func save_layout() -> void:
	var out: Array = []
	for it in items:
		out.append({"id": it.id, "x": snappedf(it.x, 0.01), "z": snappedf(it.z, 0.01), "rot": it.rot})
	Save.layouts[loc_key] = out
	Save.save()

func _spawn(id: String, x: float, z: float, rot: int) -> Dictionary:
	var n := Furni.node(id)
	add_child(n)
	n.position = Vector3(x, 0, z)
	n.rotation.y = rot * PI * 0.5
	var it := {"id": id, "x": x, "z": z, "rot": rot, "node": n}
	items.append(it)
	return it

func add(id: String, x: float, z: float, rot := 0) -> Dictionary:
	var it := _spawn(id, x, z, rot)
	rebuild_nav()
	save_layout()
	changed.emit()
	return it

func remove(it: Dictionary) -> void:
	items.erase(it)
	if is_instance_valid(it.node): it.node.queue_free()
	rebuild_nav()
	save_layout()
	changed.emit()

func move(it: Dictionary, x: float, z: float, rot: int) -> void:
	it.x = x
	it.z = z
	it.rot = rot
	it.node.position = Vector3(x, 0, z)
	it.node.rotation.y = rot * PI * 0.5
	rebuild_nav()
	save_layout()
	changed.emit()

static func size_of(id: String, rot: int) -> Vector2:
	var f := Furni.info(id)
	return Vector2(f.w, f.d) if rot % 2 == 0 else Vector2(f.d, f.w)

func rect_of(id: String, x: float, z: float, rot: int) -> Rect2:
	var s := size_of(id, rot)
	return Rect2(x - s.x * 0.5, z - s.y * 0.5, s.x, s.y)

func rebuild_nav() -> void:
	if nav == null: return
	nav.reset_to_static()
	for it in items:
		if Furni.walkable(it.id): continue
		var s := size_of(it.id, it.rot)
		nav.block_rect(it.x, it.z, s.x, s.y, 0.16)

## Can this item go here? It must sit inside the room, off counters and other furniture.
func can_place(id: String, x: float, z: float, rot: int, ignore: Dictionary = {}) -> bool:
	var r := rect_of(id, x, z, rot)
	if not area.encloses(r): return false
	if not Furni.walkable(id):
		for it in items:
			if it == ignore or Furni.walkable(it.id): continue
			if rect_of(it.id, it.x, it.z, it.rot).grow(0.02).intersects(r): return false
		# don't cover the fixed counters / doors (static grid without padding check at centre + corners)
		for p in [Vector3(r.position.x + 0.05, 0, r.position.y + 0.05), Vector3(r.end.x - 0.05, 0, r.position.y + 0.05), Vector3(r.position.x + 0.05, 0, r.end.y - 0.05), Vector3(r.end.x - 0.05, 0, r.end.y - 0.05), Vector3(x, 0, z)]:
			if not _static_free(p): return false
	return true

func _static_free(p: Vector3) -> bool:
	if nav._static.is_empty(): return true
	var c := nav.cell_of(p)
	return nav._static[c.y * nav.w + c.x] == 0 or _only_padding(c)

func _only_padding(c: Vector2i) -> bool:
	# padding cells near walls are fine; real obstacles are blocked in a wider area
	var n := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cc := c + Vector2i(dx, dy)
			if nav.inside(cc) and nav._static[cc.y * nav.w + cc.x] == 0: n += 1
	return n >= 3

func pick(p: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var bd := INF
	for it in items:
		var r := rect_of(it.id, it.x, it.z, it.rot)
		if r.grow(0.1).has_point(Vector2(p.x, p.z)):
			var d := Vector2(it.x, it.z).distance_to(Vector2(p.x, p.z))
			if d < bd:
				bd = d
				best = it
	return best

## Seats for customers / family: [{pos (world), yaw, h, id}]
func seats() -> Array:
	var out: Array = []
	for it in items:
		for s in Furni.seats(it.id):
			var b := Basis.from_euler(Vector3(0, it.rot * PI * 0.5, 0))
			var p: Vector3 = global_transform * (Vector3(it.x, 0, it.z) + b * s[0])
			out.append({"pos": p, "yaw": s[1] + it.rot * PI * 0.5, "h": s[2], "id": it.id})
	return out

func count(id: String) -> int:
	return items.filter(func(it): return it.id == id).size()

func has_item(id: String) -> bool:
	return count(id) > 0

func first(id: String) -> Dictionary:
	for it in items:
		if it.id == id: return it
	return {}
