## Microwave: type a time (about 0:50) on the keypad or press Start. Popcorn pops!
class_name MicroStation
extends Station

const READY := 0.62
var run := false
var buf := ""
var el := 0.0
var set_sec := 0
var snd = null
var rdy := false
var warn := false
var turntable: Node3D
var display: Label3D
var glow: OmniLight3D
var keys: Array = []
var _preview: Node3D
var _preview_key := ""
var pops: Array = []

func _init() -> void:
	super("micro", "Micro", 3)
	item_scale = 0.62

func attach(mo: Node3D) -> void:
	super(mo)
	turntable = mo.get_node("Turntable")
	display = mo.get_node("Display")
	glow = mo.get_node("Glow")
	for k in mo.get_node("Keys").get_children():
		keys.append(k)
	_disp()

func ck() -> float: return el * 8.0 / 60.0

func slot(i: int, n: int) -> Vector3:
	return Vector3((i - (n - 1) * 0.5) * 0.07, 0, 0)

static func fmt(b: String) -> String:
	var d := ("000" + b).right(3)
	return "%d:%s" % [int(d[0]), d.substr(1)]

func hint() -> String:
	if run:
		var c := ck()
		return "Warming up… press Stop any time" if c < READY else "Ready! Press Stop now" if c <= 1.0 else "Careful, it is starting to burn!"
	return "Press <b>Start</b> (0:50 is about right), or type a time on the keypad" if items.size() else "Warm drinks, melt things and pop popcorn"

func meter() -> Dictionary:
	return {"v": clampf(ck() / 1.4, 0.0, 1.0), "zone": Vector2(READY / 1.4, 1.0 / 1.4)} if run else {}

func btn() -> Dictionary:
	if run: return {"label": "Stop", "enabled": true, "ready": ck() >= READY and ck() <= 1.0}
	return {"label": "Start " + fmt(buf if buf != "" else "50"), "enabled": true, "ready": true} if items.size() else {}

func busy() -> bool: return run

func status() -> String:
	if not run: return ""
	var c := ck()
	return "burning" if c > 1.0 else "ready" if c >= READY else "cooking"

func on_btn() -> void:
	if run: finish()
	elif items.size():
		if buf == "": buf = "50"
		start()

func pointer_down(p: Vector2) -> void:
	if not run:
		for i in keys.size():
			var kn: Node3D = keys[i]
			if p.distance_to(screen_of(kn.global_position)) < maxf(16.0, screen_radius(kn.global_position, 0.014)):
				press(i)
				return
	elif p.distance_to(screen_of(turntable.global_position)) < screen_radius(turntable.global_position, 0.16):
		finish()

func press(i: int) -> void:
	var k: String = Appl.KEYS[i]
	var kn: Node3D = keys[i]
	var tw := kn.create_tween()
	tw.tween_property(kn, "position:z", kn.position.z - 0.004, 0.04)
	tw.tween_property(kn, "position:z", kn.position.z, 0.08)
	Sfx.play("key")
	if k == "C": buf = ""
	elif k == "▶":
		if items.is_empty(): game.toast("Put something in first")
		elif buf == "": game.toast("Type a time first")
		else: start()
	elif buf.length() < 3: buf += k
	_disp()

func _disp() -> void:
	if not display: return
	if run:
		var r := maxi(0, ceili(set_sec - el * 8.0))
		display.text = "%d:%02d" % [r / 60, r % 60]
	else:
		display.text = fmt(buf)

func start() -> void:
	var v := int(buf)
	set_sec = (v / 100) * 60 + v % 100
	if set_sec <= 0: return
	run = true
	el = 0.0
	rdy = false
	warn = false
	snd = Sfx.loop("hum")
	Sfx.play("clunk")
	mood("focus")

func finish() -> void:
	if not run: return
	run = false
	if snd: snd.stop()
	snd = null
	Sfx.play("beep")
	var f := G.merge_foods(items, "zap", ck(), game.clock)
	items = []
	buf = ""
	_clear_preview()
	refresh()
	for p in pops: p.queue_free()
	pops.clear()
	_disp()
	mood("happy", 1.5)
	mood("idle")
	glow.light_energy = 0.0
	produce(f, turntable.global_position + Vector3(0, 0.1, 0))

func auto() -> void:
	if items.is_empty(): return
	if not run:
		buf = "50"
		start()
	else:
		el = 50.0 / 8.0
		finish()

func on_items_changed() -> void:
	mood("sleepy" if items.is_empty() else "idle")

func step(dt: float) -> void:
	_disp()
	for i in range(pops.size() - 1, -1, -1):
		var pp: Node3D = pops[i]
		var v: Vector3 = pp.get_meta("v")
		v.y -= 3.2 * dt
		pp.set_meta("v", v)
		pp.position += v * dt
		if pp.position.y < 0.01:
			pp.position.y = 0.01
			pp.set_meta("v", Vector3.ZERO)
	if not run: return
	el += dt
	turntable.rotation.y += dt * 2.0
	glow.light_energy = 1.2
	var c := ck()
	var pop := items.any(func(f): return f.comps.any(func(x): return x.ing == "kernels"))
	if pop:
		var rate := 0.0 if c < 0.12 else (22.0 * pow(sin(PI * minf(1.0, (c - 0.12) / 0.95)), 1.3) + 1.0) if c < 1.0 else 1.2
		if randf() < rate * dt:
			Sfx.play("kernel")
			_pop()
	if c >= READY and not rdy:
		rdy = true
		Sfx.play("ding")
		if game.open_key != key: game.toast("The microwave is ready!")
	if c >= 1.0 and not warn:
		warn = true
		Sfx.play("beep")
		if game.open_key != key: game.toast("Quick! The microwave is about to burn it")
	_update_preview(c)
	if set_sec - el * 8.0 <= 0.0: finish()

func _pop() -> void:
	if pops.size() > 40: return
	var mb := MB.new()
	mb.col(Color("FFFBEA"), 0.6)
	mb.blob(0.009, 0.008, 0.009, 0.3, 0.6, randi() % 50, 10, 6)
	var mi := FoodArt.mesh_node(FoodArt.finish(mb))
	mi.position = Vector3(randf_range(-0.05, 0.05), 0.03, randf_range(-0.05, 0.05))
	mi.set_meta("v", Vector3(randf_range(-0.3, 0.3), randf_range(0.6, 1.0), randf_range(-0.2, 0.2)))
	turntable.add_child(mi)
	pops.append(mi)

func _update_preview(c: float) -> void:
	if c < 0.12 or items.is_empty(): return
	var hist: Array = []
	for f in items:
		for h in f.hist:
			if not hist.has(h): hist.append(h)
	hist.append("zap")
	var sp := G.generic_spec(G.comps_of(items), hist, {"cook": c, "q": G.cook_q(c)})
	sp.burnt = false
	sp.bare = true
	sp.steam = false
	var k := G.spec_key(sp)
	if k != _preview_key:
		_clear_preview()
		_preview_key = k
		_preview = FoodArt.spec_node(sp)
		_preview.scale = Vector3.ONE * 0.6
		contents.add_child(_preview)
		for n in _nodes.values(): n.visible = false
	Toon.set_param(_preview, &"cook", clampf((c - 0.12) * 0.9, 0.0, 1.0) + maxf(0.0, c - 1.18) * 1.6)

func _clear_preview() -> void:
	if _preview: _preview.queue_free()
	_preview = null
	_preview_key = ""
	for n in _nodes.values(): n.visible = true
