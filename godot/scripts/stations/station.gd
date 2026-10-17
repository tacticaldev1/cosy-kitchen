## Base class for every kitchen station (board, bowl, pot...). Holds food items, shows them
## as 3D models on the appliance, and reacts to pointer gestures in screen space.
class_name Station
extends Node3D

var key := ""
var label := ""
var cap := 4
var items: Array = []
var game: Game
var model: Node3D
var contents: Node3D
var face: Face
var item_scale := 1.0
var cam_pos := Vector3.ZERO
var cam_look := Vector3.ZERO
var _nodes := {}

func _init(k := "", lab := "", c := 4) -> void:
	key = k
	label = lab
	cap = c
	name = lab

func attach(m: Node3D) -> void:
	model = m
	add_child(m)
	contents = m.find_child("Contents", true, false) as Node3D
	if contents == null:
		contents = Node3D.new()
		contents.name = "Contents"
		m.add_child(contents)
	face = m.find_child("Face", true, false) as Face

# ---------------------------------------------------------------- interface (override)
func hint() -> String: return ""
func btn() -> Dictionary: return {}
func on_btn() -> void: pass
func busy() -> bool: return false
func meter() -> Dictionary: return {}
func pointer_down(_p: Vector2) -> void: pass
func pointer_move(_p: Vector2, _prev: Vector2) -> void: pass
func pointer_up(_p: Vector2) -> void: pass
func step(_dt: float) -> void: pass
func auto() -> void: pass
## "" | cooking | ready | burning, for the toolbar badge
func status() -> String: return "cooking" if busy() else ""
## Local position of item i of n on this appliance.
func slot(_i: int, _n: int) -> Vector3: return Vector3.ZERO
func accepts() -> bool: return not busy() and items.size() < cap
func on_items_changed() -> void: pass

# ---------------------------------------------------------------- items
func add_item(f: Dictionary, delay := 0.0) -> void:
	items.append(f)
	on_items_changed()
	refresh(delay)

func clear_items() -> Array:
	var out := items
	items = []
	on_items_changed()
	refresh()
	return out

func world_slot(i: int, n: int) -> Vector3:
	return contents.global_transform * slot(i, n)

func item_node(f: Dictionary) -> Node3D:
	return _nodes.get(f.uid, null)

## Rebuilds the 3D models for the items (only the ones whose look changed).
func refresh(delay := 0.0) -> void:
	var keep := {}
	var n := items.size()
	for i in n:
		var f: Dictionary = items[i]
		keep[f.uid] = true
		var sk := G.spec_key(G.food_spec(f))
		var node: Node3D = _nodes.get(f.uid, null)
		var fresh := false
		if node == null or node.get_meta("spec", "") != sk:
			if node:
				node.queue_free()
			node = FoodArt.food_node(f)
			node.set_meta("spec", sk)
			contents.add_child(node)
			_nodes[f.uid] = node
			fresh = true
		var target := slot(i, n)
		var s := item_scale * item_size_for(n)
		if fresh:
			node.position = target
			node.scale = Vector3.ONE * 0.001
			var tw := node.create_tween()
			tw.tween_interval(delay)
			tw.tween_property(node, "scale", Vector3.ONE * s, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			var tw := node.create_tween().set_parallel()
			tw.tween_property(node, "position", target, 0.2).set_trans(Tween.TRANS_SINE)
			tw.tween_property(node, "scale", Vector3.ONE * s, 0.2)
	for uid in _nodes.keys():
		if not keep.has(uid):
			(_nodes[uid] as Node3D).queue_free()
			_nodes.erase(uid)

func item_size_for(n: int) -> float:
	return 1.0 if n <= 1 else 0.85 if n == 2 else 0.72

# ---------------------------------------------------------------- helpers
func cam() -> Camera3D: return game.camera

func screen_of(world: Vector3) -> Vector2:
	return cam().unproject_position(world)

## Pixel radius of a world-space sphere at pos.
func screen_radius(world: Vector3, r: float) -> float:
	var c := cam()
	var a := c.unproject_position(world)
	var b := c.unproject_position(world + c.global_transform.basis.x * r)
	return a.distance_to(b)

## Point on a horizontal plane under the pointer.
func on_plane(p: Vector2, y: float) -> Variant:
	var c := cam()
	return Plane(Vector3.UP, y).intersects_ray(c.project_ray_origin(p), c.project_ray_normal(p))

func hit_item(p: Vector2, radius := 0.07) -> int:
	var best := -1
	var bd := INF
	for i in items.size():
		var w := world_slot(i, items.size()) + Vector3(0, 0.03, 0)
		var d := screen_of(w).distance_to(p)
		var r := screen_radius(w, radius * item_size_for(items.size()) * item_scale)
		if d < r and d < bd:
			bd = d
			best = i
	return best

func mood(m: String, hold := 0.0) -> void:
	if face: face.set_mood(m, hold)

func produce(f: Dictionary, from := Vector3.INF) -> void:
	game.produce(f, global_position + Vector3(0, 0.15, 0) if from == Vector3.INF else from)
