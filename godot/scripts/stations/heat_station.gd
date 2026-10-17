## Shared logic for pot, pan and oven: start heating, a cook level that climbs, a "perfect"
## zone, ready/burn alerts, and a live preview of the food turning into the finished dish.
class_name HeatStation
extends Station

const READY := 0.62
const DONE := 1.0
const BURN := 1.18

var run := false
var cook := 0.0
var rate := 0.12
var proc := "boil"
var verb := "Boil"
var loop_name := "boil"
var cooking_text := "Cooking…"
var snd = null
var rdy := false
var warn := false
var _preview: Node3D
var _preview_key := ""

func meter() -> Dictionary:
	if items.is_empty() or not run: return {}
	return {"v": clampf(cook / 1.4, 0.0, 1.0), "zone": Vector2(READY / 1.4, DONE / 1.4)}

func busy() -> bool: return run

func status() -> String:
	if not run: return ""
	return "burning" if cook > DONE else "ready" if cook >= READY else "cooking"

func can_start() -> bool: return true
func rate_mul() -> float: return 1.0
func on_start() -> void: pass
func on_take() -> void: pass
func prep() -> void: pass

func start() -> void:
	if items.is_empty() or run: return
	run = true
	cook = 0.0
	rdy = false
	warn = false
	snd = Sfx.loop(loop_name)
	Sfx.play("clunk")
	mood("focus")
	on_start()

func take() -> float:
	if not run: return 0.0
	run = false
	if snd: snd.stop()
	snd = null
	Sfx.play("clunk")
	var c := cook
	var f := G.merge_foods(items, proc, cook, game.clock)
	items = []
	cook = 0.0
	_clear_preview()
	refresh()
	on_take()
	mood("happy", 1.5)
	mood("idle")
	produce(f)
	return c

func btn() -> Dictionary:
	if items.is_empty(): return {}
	if run: return {"label": "Take out", "enabled": cook >= 0.25, "ready": cook >= READY and cook <= DONE}
	return {"label": verb, "enabled": can_start()}

func on_btn() -> void:
	if run: take()
	else: start()

func auto() -> void:
	if items.is_empty(): return
	if not run:
		prep()
		start()
	else:
		cook = 0.8
		take()

func state_hint() -> String:
	if not run: return ""
	if cook < READY: return cooking_text
	if cook <= DONE: return "Ready! Take it out now"
	return "Careful, it is starting to burn!"

func step(dt: float) -> void:
	if not run: return
	cook += dt * rate * rate_mul()
	if cook >= READY and not rdy:
		rdy = true
		Sfx.play("ding")
		mood("happy")
		if game.open_key != key: game.toast("The %s is ready!" % label)
	if cook >= DONE and not warn:
		warn = true
		Sfx.play("beep")
		mood("wow")
		if game.open_key != key: game.toast("Quick! The %s is about to burn" % label)
	if cook > BURN: mood("yuck")
	_update_preview()
	if cook > 1.7: take()

## While cooking, the raw items morph into the predicted dish and brown/char as cook rises.
func _update_preview() -> void:
	if cook < 0.12:
		for n in _nodes.values(): Toon.set_param(n, &"cook", cook * 0.5)
		return
	var hist: Array = []
	for f in items:
		for h in f.hist:
			if not hist.has(h): hist.append(h)
	hist.append(proc)
	var sp := G.generic_spec(G.comps_of(items), hist, {"q": G.cook_q(cook), "cook": cook, "hot": game.clock + 1.0})
	sp.burnt = false
	sp.bare = true
	var k := G.spec_key(sp)
	if k != _preview_key:
		_clear_preview()
		_preview_key = k
		_preview = FoodArt.spec_node(sp)
		_preview.scale = Vector3.ONE * preview_scale()
		_preview.position = preview_pos()
		contents.add_child(_preview)
		for n in _nodes.values(): n.visible = false
		Sfx.play("pop")
	Toon.set_param(_preview, &"cook", clampf((cook - 0.12) * 0.9, 0.0, 1.0) + maxf(0.0, cook - BURN) * 1.6)

func preview_scale() -> float: return 0.85
func preview_pos() -> Vector3: return Vector3.ZERO

func _clear_preview() -> void:
	if _preview:
		_preview.queue_free()
		_preview = null
	_preview_key = ""
	for n in _nodes.values():
		n.visible = true
		Toon.set_param(n, &"cook", 0.0)
