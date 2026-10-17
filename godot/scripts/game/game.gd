## The game: café world, stations, counter, camera and the rules that tie them together.
class_name Game
extends Node3D

static var I: Game

const COUNTER_CAP := 8
const ORDER := ["board", "bowl", "blender", "mat", "pot", "pan", "oven", "micro", "freezer", "plate", "bin"]
const LABEL := {"board": "Board", "bowl": "Bowl", "blender": "Blender", "mat": "Mat", "pot": "Pot", "pan": "Pan", "oven": "Oven", "micro": "Micro", "freezer": "Freezer", "plate": "Plate", "bin": "Bin", "fridge": "Fridge", "cafe": "Café"}
const OVERVIEW_POS := Vector3(0, 3.15, 3.55)
const OVERVIEW_LOOK := Vector3(0, 0.85, -0.85)

var clock := 0.0
var cafe: Cafe
var world: Node3D
var camera: Camera3D
var hud: Hud
var shop: Shop
var stations := {}
var counter: Array = []
var open_key := ""
var last_key := "board"
var guide_dirty := true
var _guide := {}
var _guide_t := -1.0
var _timers: Array = []
var _ptr_down := false
var _ptr_prev := Vector2.ZERO
var _ptr_station: Station = null
var _cam_pos := OVERVIEW_POS
var _cam_look := OVERVIEW_LOOK
var _cam_target_pos := OVERVIEW_POS
var _cam_target_look := OVERVIEW_LOOK
var _shake := 0.0
var extra_stools := {}
var kitty_zzz: Label3D
var hover_tag: Label3D
var _hover := ""

func _ready() -> void:
	I = self
	cafe = Cafe.new()
	add_child(cafe)
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	camera = Camera3D.new()
	camera.fov = 40.0
	camera.near = 0.05
	camera.far = 40.0
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = false
	camera.attributes = attrs
	add_child(camera)
	camera.current = true
	_build_stations()
	shop = Shop.new()
	shop.game = self
	add_child(shop)
	hud = Hud.new()
	hud.game = self
	add_child(hud)
	apply_decor()
	cafe.set_rain(Save.settings.get("rain", true))
	Sfx.set_ambience(Save.settings.get("rain", true))
	Sfx.start_music()
	set_overview(true)
	_apply_fullscreen()
	if Shot.arg("dev") != "":
		_dev_setup(Shot.arg("dev"))
	elif Shot.arg("shot") == "":
		hud.show_title()
	Shot.maybe_capture(get_tree(), int(Shot.arg("frames", "40")))

func _apply_fullscreen() -> void:
	if Save.settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

# ---------------------------------------------------------------- building
func _build_stations() -> void:
	var stove := Appl.stove()
	add_child(stove)
	stove.global_position = Vector3((cafe.mark("pot").x + cafe.mark("pan").x) * 0.5, cafe.mark("pot").y, cafe.mark("pot").z)
	var fridge := Appl.fridge()
	add_child(fridge)
	fridge.global_position = cafe.mark("fridge")
	fridge.name = "Fridge"
	var top := Vector3(0, 0.62, 0.72)
	var look := Vector3(0, 0.04, -0.05)
	_place(BoardStation.new(), Appl.board(), "board", top, look)
	_place(BowlStation.new(), Appl.bowl(), "bowl", top + Vector3(0, 0.06, 0.04), look + Vector3(0, 0.05, 0))
	_place(BlenderStation.new(), Appl.blender(), "blender", Vector3(0, 0.5, 0.82), Vector3(0, 0.2, -0.02))
	_place(MatStation.new(), Appl.mat(), "mat", top, look)
	_place(PotStation.new(), Appl.pot(), "pot", Vector3(0.05, 0.7, 0.72), Vector3(0.02, 0.1, -0.05), Vector3(0, 0.026, -0.02))
	_place(PanStation.new(), Appl.pan(), "pan", Vector3(0.05, 0.62, 0.7), Vector3(0.04, 0.03, -0.05), Vector3(0, 0.026, -0.02))
	_place(OvenStation.new(), Appl.oven(), "oven", Vector3(0, 0.78, 1.32), Vector3(0, 0.4, 0.0))
	_place(MicroStation.new(), Appl.micro(), "micro", Vector3(-0.05, 0.5, 0.82), Vector3(0, 0.16, 0.0))
	_place(FreezerStation.new(), Appl.freezer(), "freezer", Vector3(-0.25, 1.15, 1.45), Vector3(0, 0.62, 0))
	_place(PlateStation.new(), Appl.pass_plate(), "pass", Vector3(0, 0.78, 1.75), Vector3(0, 0.12, -0.25), Vector3.ZERO, "plate")
	_place(BinStation.new(), Appl.bin(), "bin", Vector3(-0.25, 1.0, 1.15), Vector3(0, 0.32, 0))
	for k in stations:
		var st: Station = stations[k]
		if st.items.is_empty(): st.on_items_changed()

func _place(st: Station, model: Node3D, mark: String, cam_off: Vector3, look_off: Vector3, nudge := Vector3.ZERO, key := "") -> void:
	st.game = self
	add_child(st)
	st.attach(model)
	var p := cafe.mark(mark) + nudge
	st.global_position = p
	st.cam_pos = p + cam_off
	st.cam_look = p + look_off
	stations[key if key != "" else st.key] = st

func apply_decor() -> void:
	for k in cafe.decor:
		cafe.set_decor(k, Save.decor.has(k) and Save.decor_on.get(k, true))
	if cafe.decor.has("cat_bed") and cafe.decor.cat_bed.visible and kitty_zzz == null:
		kitty_zzz = Label3D.new()
		kitty_zzz.text = "z z Z"
		kitty_zzz.font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
		kitty_zzz.font_size = 48
		kitty_zzz.pixel_size = 0.002
		kitty_zzz.modulate = Color("C3A6FF")
		kitty_zzz.outline_modulate = Color("3B2340")
		kitty_zzz.outline_size = 10
		kitty_zzz.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(kitty_zzz)
		kitty_zzz.global_position = cafe.mark("kitty") + Vector3(0.1, 0.25, 0)
	if kitty_zzz: kitty_zzz.visible = cafe.decor.has("cat_bed") and cafe.decor.cat_bed.visible
	for i in [3, 4]:
		var need: bool = i < shop.seats() if shop else false
		if need and not extra_stools.has(i):
			var mb := MB.new()
			mb.col(Color("C8C8D8")); mb.puck(0.18, 0.04, 0.01, 24)
			mb.col(Color("C8C8D8")); mb.tube(PackedVector3Array([Vector3(0, 0.04, 0), Vector3(0, 0.7, 0)]), 0.035, 10)
			mb.col(Color("FF9EBB")); mb.at(Vector3(0, 0.7, 0)); mb.puck(0.2, 0.08, 0.03, 28); mb.pop()
			var n := FoodArt.mesh_node(FoodArt.finish(mb))
			add_child(n)
			n.global_position = cafe.mark("seat_%d" % i)
			extra_stools[i] = n

# ---------------------------------------------------------------- camera
func set_overview(instant := false) -> void:
	if open_key != "": last_key = open_key
	open_key = ""
	_cam_target_pos = OVERVIEW_POS
	_cam_target_look = OVERVIEW_LOOK
	if instant:
		_cam_pos = _cam_target_pos
		_cam_look = _cam_target_look
	if hud: hud.station_changed()

func open_station(key: String) -> void:
	if not stations.has(key): return
	if open_key != "" and open_key != key and stations[open_key].busy():
		toast("The %s keeps going in the background" % LABEL[open_key])
	open_key = key
	last_key = key
	var st: Station = stations[key]
	_cam_target_pos = st.cam_pos
	_cam_target_look = st.cam_look
	Sfx.play("pop", 0.8, 0.9 + ORDER.find(key) * 0.04)
	if hud: hud.station_changed()

func current() -> Station:
	return stations.get(open_key, null)

func shake(a := 0.4) -> void:
	if Save.settings.get("shake", true): _shake = maxf(_shake, a)

func _update_camera(dt: float) -> void:
	var k := 1.0 - exp(-dt * 7.5)
	_cam_pos = _cam_pos.lerp(_cam_target_pos, k)
	_cam_look = _cam_look.lerp(_cam_target_look, k)
	var off := Vector3.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - dt * 2.5)
		off = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.01
	camera.global_position = _cam_pos + off
	camera.look_at(_cam_look + off * 0.5, Vector3.UP)

func screen_pos(world_pos: Vector3) -> Vector2:
	return camera.unproject_position(world_pos)

# ---------------------------------------------------------------- loop
func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	clock += dt
	_update_camera(dt)
	for k in ORDER:
		stations[k].step(dt)
	shop.update(dt)
	for i in range(_timers.size() - 1, -1, -1):
		if clock >= _timers[i][0]:
			var cb: Callable = _timers[i][1]
			_timers.remove_at(i)
			if cb.is_valid(): cb.call()
	_update_hover()
	if kitty_zzz and kitty_zzz.visible:
		kitty_zzz.position.y = cafe.mark("kitty").y + 0.25 + sin(clock * 1.5) * 0.03
		kitty_zzz.modulate.a = 0.6 + 0.4 * sin(clock * 1.5)

## In the café view, the station under the mouse gets a floating name tag.
func _update_hover() -> void:
	var key := ""
	if open_key == "" and not paused():
		var mp := get_viewport().get_mouse_position()
		key = _pick_station(mp)
		if key == "" and shop.pick(mp): key = "cust"
	if key != _hover:
		_hover = key
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if key != "" else Input.CURSOR_ARROW)
		if hover_tag == null:
			hover_tag = Label3D.new()
			hover_tag.font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
			hover_tag.font_size = 56
			hover_tag.pixel_size = 0.0016
			hover_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			hover_tag.no_depth_test = true
			hover_tag.modulate = Color("FFF8EE")
			hover_tag.outline_modulate = Color("3B2340")
			hover_tag.outline_size = 16
			hover_tag.render_priority = 8
			hover_tag.outline_render_priority = 7
			add_child(hover_tag)
		hover_tag.visible = key != "" and key != "cust"
		if hover_tag.visible:
			var w: Vector3 = cafe.mark("fridge") + Vector3(0, 1.95, 0) if key == "fridge" else stations[key].global_position + Vector3(0, 0.95 if key in ["oven", "bin"] else (1.45 if key == "freezer" else 0.42), 0)
			hover_tag.global_position = w
			hover_tag.text = LABEL[key]
			Sfx.play("tick", 0.5)
	if hover_tag and hover_tag.visible:
		hover_tag.scale = Vector3.ONE * (1.0 + 0.04 * sin(clock * 6.0))

## Advances the simulation without waiting for frames (used by tests).
func sim(seconds: float) -> void:
	var n := int(seconds * 60.0)
	for i in n:
		clock += 1.0 / 60.0
		for k in ORDER: stations[k].step(1.0 / 60.0)
		shop.update(1.0 / 60.0)
		for j in range(_timers.size() - 1, -1, -1):
			if clock >= _timers[j][0]:
				var cb: Callable = _timers[j][1]
				_timers.remove_at(j)
				if cb.is_valid(): cb.call()

func after(sec: float, cb: Callable) -> void:
	_timers.append([clock + sec, cb])

func paused() -> bool:
	return hud != null and hud.modal_open()

# ---------------------------------------------------------------- input
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed: _pointer_down(e.position)
		else: _pointer_up(e.position)
	elif e is InputEventMouseMotion and _ptr_down:
		_pointer_move(e.position)
	elif e is InputEventKey and e.pressed and not e.echo:
		_key(e)

func _key(e: InputEventKey) -> void:
	if hud.modal_open():
		if e.keycode == KEY_ESCAPE: hud.close_top()
		return
	match e.keycode:
		KEY_SPACE, KEY_ENTER:
			var st := current()
			if st: st.auto()
		KEY_F: hud.open_fridge()
		KEY_B: hud.open_book()
		KEY_ESCAPE, KEY_TAB: set_overview()
		KEY_RIGHT, KEY_LEFT:
			var i := ORDER.find(open_key if open_key != "" else last_key)
			i = (i + (1 if e.keycode == KEY_RIGHT else -1) + ORDER.size()) % ORDER.size()
			open_station(ORDER[i])
		_:
			if e.keycode >= KEY_1 and e.keycode <= KEY_8:
				counter_tap(e.keycode - KEY_1)

func _pointer_down(p: Vector2) -> void:
	_ptr_down = true
	_ptr_prev = p
	var c := shop.pick(p)
	if c:
		customer_tap(c)
		_ptr_down = false
		return
	if open_key == "":
		var key := _pick_station(p)
		if key == "fridge": hud.open_fridge()
		elif key != "": open_station(key)
		_ptr_down = false
		return
	_ptr_station = current()
	if _ptr_station: _ptr_station.pointer_down(p)

func _pointer_move(p: Vector2) -> void:
	if _ptr_station: _ptr_station.pointer_move(p, _ptr_prev)
	_ptr_prev = p

func _pointer_up(p: Vector2) -> void:
	_ptr_down = false
	if _ptr_station: _ptr_station.pointer_up(p)
	_ptr_station = null

func _pick_station(p: Vector2) -> String:
	var best := ""
	var bd := 90.0
	var anchors := {"fridge": cafe.mark("fridge") + Vector3(0, 1.0, 0)}
	for k in stations:
		var st: Station = stations[k]
		anchors[k] = st.global_position + Vector3(0, 0.12 if k != "oven" and k != "freezer" and k != "bin" else 0.4, 0)
	for k in anchors:
		var w: Vector3 = anchors[k]
		if not camera.is_position_in_frustum(w): continue
		var d := screen_pos(w).distance_to(p)
		if d < bd:
			bd = d
			best = k
	return best

func customer_tap(c: Customer) -> void:
	match c.state:
		"wait": shop.take_order(c)
		"order":
			shop.set_active(c)
			hud.open_ticket(c.order, c)
		"eat": toast("%s is enjoying the food" % c.cname)

# ---------------------------------------------------------------- counter & food flow
func counter_tap(i: int) -> void:
	if i < 0 or i >= counter.size(): return
	var f: Dictionary = counter[i]
	var key := open_key if open_key != "" else last_key
	if open_key == "": open_station(key)
	if key == "bin":
		counter.remove_at(i)
		stations.bin.eat()
		hud.counter_changed()
		guide_dirty = true
		return
	var st: Station = stations[key]
	if st.busy():
		toast("The %s is busy" % LABEL[key])
		return
	if st.items.size() >= st.cap:
		toast("The %s is full" % LABEL[key])
		return
	counter.remove_at(i)
	hud.fly_from_slot(f, i, screen_pos(st.world_slot(st.items.size(), st.items.size() + 1)))
	st.add_item(f, 0.3)
	Sfx.play("plunk")
	hud.counter_changed()
	guide_dirty = true

func produce(food: Dictionary, from: Vector3) -> void:
	var st := current()
	if counter.size() >= COUNTER_CAP:
		var back: Station = st if st and st.cap > 0 else stations.board
		back.add_item(food)
		toast("The counter is full, so it stays here")
	else:
		counter.append(food)
		hud.fly_to_counter(food, screen_pos(from), counter.size() - 1)
	burst(from, [Color.WHITE, Color("FF7EA6"), Color("FFE27A")], 10)
	if food.recipe >= 0:
		var r: Dictionary = G.RECIPES[food.recipe]
		float_text(r.n + "!", from + Vector3(0, 0.12, 0))
		Sfx.play("sparkle")
		toast("That's %s!" % r.n)
	elif food.q == "burnt":
		float_text("Oops, burnt!", from + Vector3(0, 0.12, 0))
	elif food.q == "perfect":
		float_text("Perfect!", from + Vector3(0, 0.12, 0))
	guide_dirty = true
	hud.counter_changed()

func empty_station() -> void:
	var st := current()
	if st == null or st.busy(): return
	while st.items.size() and counter.size() < COUNTER_CAP:
		var f: Dictionary = st.items.pop_front()
		counter.append(f)
		hud.fly_to_counter(f, screen_pos(st.global_position + Vector3(0, 0.1, 0)), counter.size() - 1)
	st.on_items_changed()
	st.refresh()
	if st.items.size(): toast("The counter is full")
	if "p" in st: st.p = 0.0
	if "m" in st: st.m = 0.0
	Sfx.play("pop", 0.8, 1.1)
	hud.counter_changed()
	guide_dirty = true

func all_foods() -> Array:
	var out := counter.duplicate()
	for k in stations: out.append_array(stations[k].items)
	return out

func on_hand() -> Dictionary:
	var s := {}
	for c in G.comps_of(all_foods()): s[c.ing] = true
	return s

func charge(key: String) -> int:
	var cost: int = G.ING_COST.get(key, 0)
	Save.wallet -= cost
	if shop.open and shop.stats.has("spend"): shop.stats.spend += cost
	return cost

func add_ingredient(key: String) -> void:
	var f := G.new_food(key)
	var st := current()
	if st and st.key != "bin" and st.accepts():
		st.add_item(f, 0.05)
		toast("%s %s → %s" % [G.ING[key].n, G.yen(G.ING_COST.get(key, 0)), LABEL[st.key]])
		Sfx.play("plunk")
	elif counter.size() < COUNTER_CAP:
		counter.append(f)
		toast("%s %s → counter" % [G.ING[key].n, G.yen(G.ING_COST.get(key, 0))])
		Sfx.play("pop", 0.8, 1.2)
		hud.counter_changed()
	else:
		toast("No room! Clear the counter first")
		return
	charge(key)
	Save.save()
	guide_dirty = true

## Buys whatever a recipe still needs, dropping the first step's ingredients into its station.
func buy_for(r: Dictionary, cust: Customer = null) -> void:
	if cust and cust.state == "order": shop.set_active(cust)
	var have := on_hand()
	var missing: Array = r.need.filter(func(k): return not have.has(k))
	var list: Array = missing if missing.size() else r.need.duplicate()
	var steps := G.build_steps(r)
	var first = null
	for s in steps:
		if s.check.type == "tag":
			first = s
			break
	var tool: String = first.tool if first and stations.has(first.tool) else ""
	var st: Station = stations.get(tool, null)
	var into := {}
	if st and not st.busy():
		for k in first.check.ings: into[k] = true
	var spent := 0
	var n := 0
	var to_st := 0
	var full := false
	if st and into.size():
		for i in range(counter.size() - 1, -1, -1):
			var f: Dictionary = counter[i]
			if f.hist.is_empty() and f.comps.size() == 1 and into.has(f.comps[0].ing) and st.items.size() < st.cap:
				counter.remove_at(i)
				st.add_item(f, 0.4)
				to_st += 1
	for k in list:
		var f := G.new_food(k)
		if st and into.has(k) and st.items.size() < st.cap:
			st.add_item(f, 0.4 + n * 0.06)
			to_st += 1
		elif counter.size() < COUNTER_CAP:
			counter.append(f)
		else:
			full = true
			continue
		spent += charge(k)
		n += 1
	if shop.active_cust() == null:
		Save.pinned = r.id
	guide_dirty = true
	if to_st and tool != "": open_station(tool)
	if n: Sfx.play("coin")
	Save.save()
	hud.counter_changed()
	if full: toast("Bought %d for %s, but the counter is full" % [n, G.yen(spent)])
	elif n: toast("Bought %d ingredient%s for %s%s" % [n, "s" if n > 1 else "", G.yen(spent), " · into the " + LABEL[tool] if to_st and tool != "" else ""])
	else: toast("Everything is already here")

# ---------------------------------------------------------------- serving
func serve() -> void:
	var st: PlateStation = stations.plate
	var foods: Array = st.items.duplicate()
	if foods.is_empty(): return
	var comps := G.comps_of(foods)
	var d := G.detect(comps)
	var q := ""
	for f in foods: q = G.worst_q(q, f.q)
	var cust: Customer = shop.order_for(d.match.r.id) if d.has("match") else null
	var sp := G.recipe_spec(d.match.r, foods) if d.has("match") else (G.food_spec(foods[0], clock) if foods.size() == 1 else G.generic_spec(comps, _hist_of(foods), {"q": q}))
	var dish := FoodArt.spec_node(sp)
	add_child(dish)
	dish.global_position = st.global_position + Vector3(0, 0.012, 0)
	dish.scale = Vector3.ONE * 1.1
	st.items = []
	st.refresh()
	st.ring_bell()
	Sfx.play("nom")
	if cust:
		var to: Vector3 = cust.seat_pos + Vector3(0, 0, 0)
		to = Vector3(cust.seat_pos.x, 1.05, -1.3)
		var tw := dish.create_tween()
		tw.tween_property(dish, "global_position", to, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(dish, "scale", Vector3.ONE * 0.9, 0.6)
		cust.meal = dish
		shop.serve_order(cust, foods, d, q)
		after(0.7, func(): Sfx.play("nom"))
		return
	var tw2 := dish.create_tween()
	tw2.tween_property(dish, "global_position", dish.global_position + Vector3(0, 0.25, 0.1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw2.tween_property(dish, "scale", Vector3.ONE * 0.01, 0.6).set_delay(0.4)
	tw2.tween_callback(dish.queue_free)
	var res := {"foods": foods, "q": q, "near": d.get("near", null)}
	if d.has("match"):
		var r: Dictionary = d.match.r
		res.r = r
		res.is_new = Save.mark_found(r.id)
		res.stars = 1 if q == "burnt" else 2 if q == "under" else 3
		res.extras = d.match.extras
		if Save.pinned == r.id and shop.active_cust() == null: Save.pinned = -1
	else:
		res.stars = 1 if q == "burnt" else 2
		res.name = G.invent_name(foods)
	Save.save()
	guide_dirty = true
	after(1.2, func(): hud.show_result(res))

func _hist_of(foods: Array) -> Array:
	var h: Array = []
	for f in foods:
		for x in f.hist:
			if not h.has(x): h.append(x)
	return h

# ---------------------------------------------------------------- recipe guide
func step_done(s: Dictionary) -> bool:
	var ck: Dictionary = s.check
	var comps := G.comps_of(all_foods())
	if ck.type == "have":
		return ck.ings.all(func(k): return comps.any(func(c): return c.ing == k))
	if ck.type == "tag":
		return ck.ings.all(func(k): return comps.any(func(c): return c.ing == k and G.tag_ok(c, ck.tag)))
	var pc := G.comps_of(stations.plate.items)
	return ck.ings.all(func(k): return pc.any(func(c): return c.ing == k))

func guide() -> Dictionary:
	if Save.pinned < 0: return {}
	if guide_dirty or clock - _guide_t > 0.4 or _guide.get("id", -1) != Save.pinned:
		var steps := G.build_steps(G.RECIPES[Save.pinned])
		var done: Array = steps.map(step_done)
		var cur := done.find(false)
		if cur < 0: cur = steps.size() - 1
		_guide = {"id": Save.pinned, "steps": steps, "done": done, "cur": cur}
		_guide_t = clock
		guide_dirty = false
	return _guide

func next_hint() -> Dictionary:
	var gd := guide()
	if gd.is_empty(): return {}
	var s: Dictionary = gd.steps[gd.cur]
	if s.check.type == "have": return {"label": "Buy ingredients", "act": "ticket"}
	var tool: String = s.get("tool", "")
	if tool == "" or tool == open_key or not stations.has(tool): return {}
	return {"label": "Next: " + LABEL[tool], "tool": tool, "act": "station"}

# ---------------------------------------------------------------- feedback
func toast(msg: String) -> void:
	if hud: hud.toast(msg)

func burst(pos: Vector3, cols: Array, n := 10, s := 1.0) -> void:
	Fx.burst(self, pos, cols, n, s)

func puff(pos: Vector3) -> void:
	Fx.puff(self, pos)

func float_text(text: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
	l.font_size = 64
	l.pixel_size = 0.0012
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.modulate = Color("FFF8C2")
	l.outline_modulate = Color("3B2340")
	l.outline_size = 18
	l.render_priority = 10
	l.outline_render_priority = 9
	add_child(l)
	l.global_position = pos
	l.scale = Vector3.ONE * 0.3
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "global_position", pos + Vector3(0, 0.25, 0), 1.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)

# ---------------------------------------------------------------- dev scenes for screenshots
## Clicks the board through real OS-level input events to prove 3D picking matches the window.
func _input_check() -> void:
	open_station("board")
	_cam_pos = _cam_target_pos
	_cam_look = _cam_target_look
	var st: BoardStation = stations.board
	st.add_item(G.new_food("tomato"))
	await get_tree().process_frame
	await get_tree().process_frame
	var base := get_viewport().get_visible_rect().size
	var win := Vector2(DisplayServer.window_get_size())
	var target := screen_pos(st.world_slot(0, 1) + Vector3(0, 0.03, 0))
	var wp := target * win / base
	print("INPUT base=", base, " win=", win, " target=", target, " window_px=", wp)
	for i in 3:
		for pressed in [true, false]:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT
			e.pressed = pressed
			e.position = wp
			e.global_position = wp
			Input.parse_input_event(e)
			await get_tree().process_frame
	await get_tree().process_frame
	print("INPUT chopped=", st.items.is_empty() and counter.size() > 0)
	# a HUD button: open the fridge via the toolbar
	var fb: Button = hud.tool_btns.fridge.b
	var c := (fb.global_position + fb.size * 0.5) * win / base
	for pressed in [true, false]:
		var e2 := InputEventMouseButton.new()
		e2.button_index = MOUSE_BUTTON_LEFT
		e2.pressed = pressed
		e2.position = c
		e2.global_position = c
		Input.parse_input_event(e2)
		await get_tree().process_frame
	await get_tree().process_frame
	print("INPUT fridge_open=", hud.fridge != null and hud.fridge.visible)
	get_tree().quit()

func _dev_setup(what: String) -> void:
	hud.hide_title()
	match what:
		"input":
			_input_check.call_deferred()
		"title":
			hud.show_title()
		"book":
			for i in [0, 2, 5, 18, 26, 35, 40, 44, 46, 60, 62, 77, 84, 89, 92]: Save.mark_found(i)
			hud.open_book()
		"detail":
			hud.open_book(44)
		"result":
			var f := G.merge_foods([G.new_food("egg"), G.new_food("flour"), G.new_food("milk")], "mix")
			G.apply_proc(f, "fry", 0.8)
			hud.show_result({"foods": [f], "q": "perfect", "r": G.RECIPES[0], "is_new": true, "stars": 3, "extras": [], "paid": 1210, "cust": "Hana"})
		"decor":
			Save.wallet = 20000
			Save.stars_total = 60
			Save.decor = {"lucky_cat": true, "flowers": true}
			apply_decor()
			hud.open_decor()
		"service", "service_over":
			Save.stars_total = 120
			for k in cafe.decor: Save.decor[k] = true
			apply_decor()
			shop.open = true
			shop.stats = shop.new_stats()
			for i in 3: shop.spawn()
			sim(14.0)
			for c in shop.customers:
				if c.seat != 2: shop.take_order(c)
			hud.close_all()
			sim(0.5)
			if what == "service":
				open_station("plate")
				_cam_pos = _cam_target_pos
				_cam_look = _cam_target_look
				var f := G.merge_foods([G.new_food("egg"), G.new_food("flour"), G.new_food("milk")], "mix")
				G.apply_proc(f, "fry", 0.8)
				stations.plate.add_item(f)
			else:
				_cam_pos = _cam_target_pos
				_cam_look = _cam_target_look
			if Shot.arg("fps") != "":
				await get_tree().create_timer(4.0).timeout
				var t0 := Time.get_ticks_usec()
				var frames := 0
				while Time.get_ticks_usec() - t0 < 3000000:
					await get_tree().process_frame
					frames += 1
				print("FPS avg=", frames / 3.0, " photo_queue=", Photo._queue.size(), " cached=", Photo._cache.size(), " fps_engine=", Engine.get_frames_per_second(), " draw_calls=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " prims=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
				get_tree().quit()
		"summary":
			hud.show_summary({"served": 7, "walked": 1, "sales": 7450, "tips": 820, "spend": 1630, "stars": 19, "new_recipes": 3}, 2)
		"overview":
			shop.open = true
			shop.stats = shop.new_stats()
			for i in 3:
				shop.spawn()
			sim(14.0)
			for c in shop.customers:
				if c.state == "wait" and c.seat != 1: shop.take_order(c)
			hud.close_all()
			sim(1.0)
		_:
			if stations.has(what):
				open_station(what)
				_cam_pos = _cam_target_pos
				_cam_look = _cam_target_look
				var demo := {"board": ["tomato", "cucumber", "carrot"], "bowl": ["egg", "flour", "milk", "strawberry"], "blender": ["strawberry", "banana", "milk"],
					"mat": ["nori", "rice", "salmon", "avocado"], "pot": ["noodles", "soy", "egg"], "pan": ["egg"], "oven": ["flour", "butter", "sugar", "chocolate"],
					"micro": ["kernels"], "freezer": ["mango", "sugar"], "plate": [], "bin": []}
				for k in demo.get(what, []):
					stations[what].add_item(G.new_food(k))
				if what == "plate":
					var f := G.merge_foods([G.new_food("egg"), G.new_food("flour"), G.new_food("milk")], "mix")
					G.apply_proc(f, "fry", 0.8)
					stations.plate.add_item(f)
				if what == "pan" or what == "pot" or what == "oven":
					stations[what].start()
					sim(4.0 if what != "oven" else 6.0)
				if what == "micro":
					stations.micro.on_btn()
					sim(2.5)
				for k in ["egg", "tomato", "strawberry"]:
					counter.append(G.new_food(k))
				hud.counter_changed()
