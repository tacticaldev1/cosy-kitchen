## Chopping board: tap or saw across food; three chops and it falls into pieces.
class_name BoardStation
extends Station

var chops := {}
var inside := {}
var queue := false
var q_t := 0.0
var knife: Node3D
var knife_t := 9.0
var knife_target := Vector3.ZERO
const KNIFE_REST := Vector3(0.17, 0.09, -0.06)

func _init() -> void:
	super("board", "Board", 4)

func attach(m: Node3D) -> void:
	super(m)
	knife = m.get_node("Knife")
	knife.position = KNIFE_REST

func slot(i: int, n: int) -> Vector3:
	var p: Array = [[Vector3.ZERO], [Vector3(-0.08, 0, 0), Vector3(0.08, 0, 0)], [Vector3(-0.1, 0, -0.045), Vector3(0.1, 0, -0.045), Vector3(0, 0, 0.065)],
		[Vector3(-0.1, 0, -0.055), Vector3(0.1, 0, -0.055), Vector3(-0.1, 0, 0.065), Vector3(0.1, 0, 0.065)]]
	return p[clampi(n, 1, 4) - 1][i % 4] + Vector3(0, 0.027, 0)

func hint() -> String:
	return "Tap or saw back and forth to chop, or press <b>Chop all</b>" if items.size() else "Chop things here. Tap food on the counter, or grab some from the Fridge."

func _unchopped() -> Array:
	return items.filter(func(f): return f.hist.is_empty() or f.hist[f.hist.size() - 1] != "chop")

func btn() -> Dictionary:
	var n := _unchopped().size()
	if n == 0: return {}
	return {"label": "Chopping…" if queue else "Chop all", "enabled": not queue}

func on_btn() -> void:
	queue = true
	q_t = 0.0

func busy() -> bool: return queue

func pointer_down(p: Vector2) -> void:
	inside.clear()
	var i := hit_item(p)
	if i >= 0:
		inside[items[i].uid] = true
		chop(i)

func pointer_move(p: Vector2, _prev: Vector2) -> void:
	var i := hit_item(p)
	var id = items[i].uid if i >= 0 else null
	for u in inside.keys():
		if u != id: inside.erase(u)
	if id != null and not inside.has(id):
		inside[id] = true
		chop(i)

func chop(i: int) -> void:
	var f: Dictionary = items[i]
	if f.hist.size() and f.hist[f.hist.size() - 1] == "chop":
		game.toast("That is already chopped")
		return
	var n: int = chops.get(f.uid, 0) + 1
	chops[f.uid] = n
	var pos := slot(i, items.size())
	knife_target = pos
	knife_t = 0.0
	Sfx.play("chop")
	var node := item_node(f)
	var w := contents.global_transform * pos
	game.burst(w + Vector3(0, 0.04, 0), [G.ING[f.comps[0].ing].c2, Color.WHITE], 6, 0.6)
	mood("focus", 0.4)
	if node:
		var s := node.scale
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(s.x * 1.08, s.y * 0.82, s.z * 1.08), 0.05)
		tw.tween_property(node, "scale", s, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if n >= 3:
		items.remove_at(i)
		chops.erase(f.uid)
		G.apply_proc(f, "chop", 0.0, game.clock)
		refresh()
		mood("happy", 0.8)
		produce(f, w)

func auto() -> void:
	var u := _unchopped()
	if u.is_empty(): return
	for k in 3:
		var i := items.find(u[0])
		if i < 0: break
		chop(i)

func step(dt: float) -> void:
	knife_t += dt
	if knife and is_instance_valid(knife):
		if knife_t < 0.24:
			var k := knife_t / 0.24
			var down := sin(k * PI)
			knife.position = (knife_target + Vector3(0.02, 0.0, 0.0)).lerp(knife_target + Vector3(0.03, 0.14, 0.0), 1.0 - down)
			knife.rotation = Vector3(0, 0, -0.3 * (1.0 - down))
		else:
			var rest := KNIFE_REST + Vector3(0, sin(game.clock * 3.0) * 0.006, 0)
			knife.position = knife.position.lerp(rest, minf(1.0, dt * 8.0))
			knife.rotation = knife.rotation.lerp(Vector3(0, 0, -0.25), minf(1.0, dt * 8.0))
	if queue:
		q_t -= dt
		if q_t <= 0.0:
			q_t = 0.15
			var u := _unchopped()
			if u.is_empty():
				queue = false
			else:
				chop(items.find(u[0]))
