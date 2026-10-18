## The game: you, the places you can walk (café, town, home), the cooking stations, the
## counter, the camera and the rules that tie them together.
class_name Game
extends Node3D

static var I: Game

const COUNTER_CAP := 8
const ORDER := ["board", "bowl", "blender", "mat", "pot", "pan", "oven", "micro", "freezer", "plate", "bin"]
const LABEL := {"board": "Board", "bowl": "Bowl", "blender": "Blender", "mat": "Mat", "pot": "Pot", "pan": "Pan", "oven": "Oven", "micro": "Micro", "freezer": "Freezer", "plate": "Plate", "bin": "Bin", "fridge": "Fridge", "cafe": "Walk"}

var clock := 0.0
var camera: Camera3D
var hud: Hud
var shop: Shop
var life: Life
var edit: EditMode
var player: Player
var locs := {}
var loc: Location
var cafe: CafeLocation
var city: CityLocation
var home: HomeLocation
var npc_house: NpcHomeLocation
var sneaking := false
var stations := {}
var counter: Array = []
var open_key := ""
var last_key := "board"
var guide_dirty := true
var carrying := {}          # the dish in your hands: {foods, d, q, rid, node}
var cutscene := false
var instant := false        # tests: walking happens instantly
var skip_fx := false        # tests: fades finish instantly (walking and dialogue stay real)
var focus := {}             # what E / Space would interact with right now
var _guide := {}
var _guide_t := -1.0
var _timers: Array = []
var _ptr_down := false
var _ptr_prev := Vector2.ZERO
var _ptr_station: Station = null
var _cam_pos := Vector3(0, 4, 5)
var _cam_look := Vector3.ZERO
var _cam_target_pos := Vector3(0, 4, 5)
var _cam_target_look := Vector3.ZERO
var _shake := 0.0
var hover_tag: Label3D
var _hover_key := ""
var _marker: Node3D

var weather: String:
	get: return Save.weather

func _ready() -> void:
	I = self
	camera = Camera3D.new()
	camera.fov = 40.0
	camera.near = 0.05
	camera.far = 90.0
	add_child(camera)
	camera.current = true
	shop = Shop.new()
	shop.game = self
	add_child(shop)
	life = Life.new()
	life.game = self
	add_child(life)
	cafe = CafeLocation.new()
	city = CityLocation.new()
	home = HomeLocation.new()
	npc_house = NpcHomeLocation.new()
	for l in [cafe, city, home, npc_house]:
		add_child(l)
		l.setup(self)
		locs[l.key] = l
		l.activate(false)
	stations = cafe.stations
	player = Player.new()
	add_child(player)
	player.setup_from_save()
	edit = EditMode.new()
	edit.game = self
	add_child(edit)
	hud = Hud.new()
	hud.game = self
	add_child(hud)
	_build_marker()
	Sfx.set_ambience(Save.weather == "rain" and Save.settings.get("rain", true))
	Sfx.start_music()
	_apply_fullscreen()
	travel_now(Save.location if Save.started else "home", "start")
	if Shot.arg("dev") != "":
		_dev_setup(Shot.arg("dev"))
	elif Shot.arg("shot") == "":
		hud.show_title()
	Shot.maybe_capture(get_tree(), int(Shot.arg("frames", "40")))

func _apply_fullscreen() -> void:
	if Save.settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

## Rebuilds you after the character creator or the boutique.
func rebuild_player() -> void:
	var p := player.global_position
	var y := player.rotation.y
	player.setup_from_save()
	player.global_position = p
	player.rotation.y = y
	player.set_work_clothes(loc == cafe)

# ---------------------------------------------------------------- places
## Walk out of one place and into another, with a soft fade.
func travel(to: String, entry: String) -> void:
	if cutscene: return
	if loc == cafe and to != "cafe" and shop.open and shop.customers.size():
		toast("The café is still open! Customers will wait while you're out")
	cutscene = true
	hud.fade(func(): travel_now(to, entry), func(): cutscene = false)
	Sfx.play("door" if Sfx.has("door") else "pop", 0.7)

func travel_now(to: String, entry: String) -> void:
	leave_station()
	if carrying.size() and to != "cafe": drop_carry()
	if edit.active: edit.stop()
	if loc: loc.activate(false)
	loc = locs[to]
	loc.activate(true)
	player.nav = loc.nav
	player.stop()
	player.stand_up()
	player.visible = true
	player.global_position = loc.entry_point(entry)
	player.rotation.y = loc.entry_yaw(entry)
	player.set_work_clothes(to == "cafe")
	Save.location = to
	loc.set_hour(Save.hour())
	_snap_camera()
	if to == "cafe": life.flag("visit_cafe")
	if to != "npchome": sneaking = false
	if hud: hud.location_changed()

func _snap_camera() -> void:
	_update_camera(0.0, true)

# ---------------------------------------------------------------- camera
func shake(a := 0.4) -> void:
	if Save.settings.get("shake", true): _shake = maxf(_shake, a)

func _update_camera(dt: float, snap := false) -> void:
	if edit and edit.active:
		_cam_target_pos = edit.cam_pos
		_cam_target_look = edit.cam_look
	elif open_key == "" and loc:
		var p := player.global_position
		var b := loc.cam_bounds
		var c := Vector3(clampf(p.x, b.position.x, b.end.x), 0, clampf(p.z, b.position.y, b.end.y))
		_cam_target_pos = c + loc.cam_offset
		_cam_target_look = c + loc.cam_look
	var k := 1.0 if snap else 1.0 - exp(-dt * (7.5 if open_key != "" else 5.0))
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

## Where a screen point hits the floor.
func floor_point(p: Vector2) -> Variant:
	var o := camera.project_ray_origin(p)
	var d := camera.project_ray_normal(p)
	if absf(d.y) < 0.0001: return null
	var t := -o.y / d.y
	if t < 0.0: return null
	return o + d * t

# ---------------------------------------------------------------- stations
func set_overview(_instant := false) -> void:
	leave_station()

func open_station(key: String, walk := true) -> void:
	if not stations.has(key): return
	if loc != cafe:
		toast("The kitchen is at the café")
		return
	if key == open_key: return
	if walk and not instant:
		var stand: Vector3 = cafe.stand[key]
		if player.global_position.distance_to(stand) > 0.35:
			# step back from the current station and walk over, no teleporting
			if open_key != "":
				if stations[open_key].busy(): toast("The %s keeps going while you're away" % LABEL[open_key])
				leave_station()
			player.go_to(stand, func(): _enter_station(key))
			return
	_enter_station(key)

func _enter_station(key: String) -> void:
	if carrying.size():
		toast("Your hands are full! Serve, eat or bin the dish first")
		return
	if open_key != "" and open_key != key and stations[open_key].busy():
		toast("The %s keeps going in the background" % LABEL[open_key])
	open_key = key
	last_key = key
	var st: Station = stations[key]
	var stand: Vector3 = cafe.stand[key]
	player.stop()
	player.global_position = stand
	player.rotation.y = atan2(st.global_position.x - stand.x, st.global_position.z - stand.z)
	player.visible = false
	_cam_target_pos = st.cam_pos
	_cam_target_look = st.cam_look
	Sfx.play("pop", 0.8, 0.9 + ORDER.find(key) * 0.04)
	if hud: hud.station_changed()

func leave_station() -> void:
	if open_key == "": return
	last_key = open_key
	open_key = ""
	player.visible = true
	if hud:
		hud.close_fridge()
		hud.station_changed()

func current() -> Station:
	return stations.get(open_key, null)

# ---------------------------------------------------------------- loop
func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	_read_move_keys()
	_step(dt)
	_update_camera(dt)
	_update_focus()
	_update_hover()

func _step(dt: float) -> void:
	clock += dt
	for k in ORDER:
		stations[k].step(dt)
	shop.update(dt)
	life.tick(dt)
	player.speed = life.walk_speed()
	player.tick(dt, clock)
	if loc: loc.tick(dt)
	for i in range(_timers.size() - 1, -1, -1):
		if i >= _timers.size(): continue
		if clock >= _timers[i][0]:
			var cb: Callable = _timers[i][1]
			_timers.remove_at(i)
			if cb.is_valid(): cb.call()

## Advances the simulation without waiting for frames (used by tests).
func sim(seconds: float) -> void:
	var n := int(seconds * 60.0)
	for i in n:
		_step(1.0 / 60.0)

func after(sec: float, cb: Callable) -> void:
	_timers.append([clock + sec, cb])

func paused() -> bool:
	return hud != null and hud.modal_open()

func _read_move_keys() -> void:
	var d := Vector3.ZERO
	if open_key == "" and not paused() and not cutscene and not edit.active and not hud.typing():
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): d.z -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): d.z += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): d.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): d.x += 1.0
	player.input_dir = d
	player.frozen = cutscene or open_key != ""

# ---------------------------------------------------------------- what's near you
## Everything you could interact with from here, best first: closer things and things in
## front of you win. Tab cycles through them; an arrow floats over the chosen one.
func focus_candidates() -> Array:
	var out: Array = []
	if open_key != "" or cutscene or loc == null or edit.active: return out
	var p := player.global_position
	var fwd := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
	var score := func(target: Vector3, d: float) -> float:
		var to := Vector3(target.x - p.x, 0, target.z - p.z)
		var facing := fwd.dot(to.normalized()) if to.length() > 0.05 else 1.0
		return d - 0.35 * maxf(0.0, facing)
	if loc == cafe:
		for c in shop.customers:
			if c.state != "wait" and c.state != "order" and c.state != "eat": continue
			var d := Vector2(p.x, p.z).distance_to(Vector2(c.global_position.x, c.global_position.z))
			# seated customers can also be reached from the spot beside their chair
			var app: Vector3 = c.get_meta("approach", c.global_position)
			d = minf(d, Vector2(p.x, p.z).distance_to(Vector2(app.x, app.z)) + 0.15)
			if d < 1.1: out.append({"kind": "cust", "c": c, "label": _cust_label(c), "s": score.call(c.global_position, d), "at": c.head_pos() + Vector3(0, 0.45, 0)})
	for n in loc.npcs:
		if not is_instance_valid(n) or not n.visible: continue
		var d := Vector2(p.x, p.z).distance_to(Vector2(n.global_position.x, n.global_position.z))
		if d < 1.1: out.append({"kind": "npc", "n": n, "label": "Talk to " + String(n.get_meta("label", "them")), "s": score.call(n.global_position, d) - 0.05, "at": n.global_position + Vector3(0, 1.0 * n.scale.y, 0)})
	for it in loc.interacts:
		var d := Vector2(p.x, p.z).distance_to(Vector2(it.pos.x, it.pos.z))
		if d < float(it.r):
			var obj: Vector3 = it.get("at", it.pos)
			out.append({"kind": "it", "it": it, "label": it.label, "s": score.call(obj, d) + 0.1 - float(it.get("prio", 0.0)), "at": obj + Vector3(0, 0.35, 0) if it.has("at") else it.pos + Vector3(0, float(it.get("h", 0.9)) + 0.25, 0)})
	out.sort_custom(func(a, b): return a.s < b.s)
	return out

var _focus_pick := 0
var _focus_key := ""
var focus_arrow: Label3D

func _update_focus() -> void:
	var cands := focus_candidates()
	var keys := cands.map(_focus_id)
	var k := ",".join(keys)
	if k != _focus_key:
		_focus_key = k
		_focus_pick = 0
	focus = cands[_focus_pick % cands.size()] if cands.size() else {}
	focus["more"] = cands.size() > 1
	if cands.is_empty(): focus = {}
	_update_arrow()

func _focus_id(f: Dictionary) -> String:
	match f.kind:
		"cust": return "c%d" % f.c.cid
		"npc": return "n%d" % f.n.get_instance_id()
	return "i" + String(f.it.id)

## Tab: aim at the next thing nearby (the stove has a pot, a pan and an oven side by side).
func cycle_focus() -> void:
	_focus_pick += 1
	_update_focus()
	Sfx.play("tick", 0.6)

func _update_arrow() -> void:
	if focus_arrow == null:
		focus_arrow = Label3D.new()
		focus_arrow.text = "▼"
		focus_arrow.font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
		focus_arrow.font_size = 72
		focus_arrow.pixel_size = 0.003
		focus_arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		focus_arrow.no_depth_test = true
		focus_arrow.modulate = Color("FF7EA6")
		focus_arrow.outline_modulate = Color.WHITE
		focus_arrow.outline_size = 14
		focus_arrow.render_priority = 9
		add_child(focus_arrow)
	focus_arrow.visible = focus.size() > 0 and not paused()
	if focus_arrow.visible:
		var at: Vector3 = focus.at
		focus_arrow.global_position = at + Vector3(0, 0.06 * sin(clock * 5.0), 0)
		focus_arrow.pixel_size = 0.003 if loc != city else 0.005

func _cust_label(c: Customer) -> String:
	match c.state:
		"wait": return "Take %s's order" % c.cname
		"order":
			if carrying.size() and carrying.rid == c.order: return "Serve %s the %s" % [c.cname, G.RECIPES[c.order].n]
			return "Check %s's order" % c.cname
	return "%s is eating" % c.cname

func interact() -> void:
	match focus.get("kind", ""):
		"cust": customer_tap(focus.c)
		"npc": talk_to(focus.n)
		"it": focus.it.act.call()

func _build_marker() -> void:
	_marker = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.12
	tm.outer_radius = 0.17
	(_marker as MeshInstance3D).mesh = tm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.5, 0.66, 0.85)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	(_marker as MeshInstance3D).material_override = m
	_marker.visible = false
	add_child(_marker)

func _show_marker(p: Vector3) -> void:
	_marker.global_position = Vector3(p.x, 0.02, p.z)
	_marker.visible = true
	_marker.scale = Vector3.ONE * 1.4
	var tw := _marker.create_tween()
	tw.tween_property(_marker, "scale", Vector3.ONE * 0.6, 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func(): _marker.visible = false)

## Walks up to something and then does the thing.
func go_and(target: Vector3, dist: float, cb: Callable) -> void:
	var p := player.global_position
	var flat := Vector3(target.x, 0, target.z)
	var away := Vector3(p.x, 0, p.z) - flat
	if away.length() < 0.05: away = Vector3(0, 0, 1)
	var stand := flat + away.normalized() * dist
	if loc and loc.nav: stand = loc.nav.nearest_free(stand)
	var face := func():
		player.rotation.y = atan2(target.x - player.global_position.x, target.z - player.global_position.z)
		cb.call()
	if instant or Vector2(p.x, p.z).distance_to(Vector2(target.x, target.z)) <= dist + 0.3:
		face.call()
		return
	player.go_to(stand, face)

# ---------------------------------------------------------------- input
func _unhandled_input(e: InputEvent) -> void:
	if edit.active:
		edit.handle(e)
		return
	if e is InputEventKey and e.pressed and not e.echo:
		_key(e)
		return
	if cutscene: return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed: _pointer_down(e.position)
		else: _pointer_up(e.position)
	elif e is InputEventMouseMotion and _ptr_down:
		_pointer_move(e.position)

func _key(e: InputEventKey) -> void:
	if e.keycode == KEY_QUOTELEFT:
		hud.open_console()
		return
	if hud.modal_open():
		if e.keycode == KEY_ESCAPE: hud.close_top()
		elif e.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]: hud.advance_dialogue()
		return
	if cutscene: return
	match e.keycode:
		KEY_E, KEY_SPACE, KEY_ENTER:
			var st := current()
			if st: st.auto()
			else: interact()
		KEY_F:
			if loc == cafe: hud.open_fridge()
		KEY_B: hud.open_book()
		KEY_J: hud.open_journal()
		KEY_Q:
			if carrying.size(): eat_carried()
		KEY_ESCAPE, KEY_TAB:
			if open_key != "": leave_station()
			elif e.keycode == KEY_TAB: cycle_focus()
			else: hud.open_settings()
		KEY_RIGHT, KEY_LEFT:
			if open_key != "":
				var i := ORDER.find(open_key)
				i = (i + (1 if e.keycode == KEY_RIGHT else -1) + ORDER.size()) % ORDER.size()
				open_station(ORDER[i])
		_:
			if open_key != "" and e.keycode >= KEY_1 and e.keycode <= KEY_8:
				counter_tap(e.keycode - KEY_1)

func _pointer_down(p: Vector2) -> void:
	if open_key != "":
		_ptr_down = true
		_ptr_prev = p
		_ptr_station = current()
		if _ptr_station: _ptr_station.pointer_down(p)
		return
	if loc == cafe:
		var c := shop.pick(p)
		if c:
			walk_to_customer(c)
			return
	var n := loc.pick_npc(p, camera)
	if n:
		go_and(n.global_position, 0.75, func(): talk_to(n))
		return
	var it := loc.pick_interact(p, camera)
	if it.size():
		var pos: Vector3 = it.pos
		player.go_to(pos, func(): it.act.call())
		if instant: it.act.call()
		return
	var w = floor_point(p)
	if w != null and loc.nav:
		var target: Vector3 = loc.nav.nearest_free(w)
		_show_marker(target)
		player.go_to(target)

func _pointer_move(p: Vector2) -> void:
	if _ptr_station: _ptr_station.pointer_move(p, _ptr_prev)
	_ptr_prev = p

func _pointer_up(p: Vector2) -> void:
	_ptr_down = false
	if _ptr_station: _ptr_station.pointer_up(p)
	_ptr_station = null

## A floating name over whatever the mouse is on (stations, doors, people).
func _update_hover() -> void:
	var key := ""
	var label := ""
	var at := Vector3.ZERO
	if open_key == "" and not paused() and not cutscene and not edit.active and loc:
		var mp := get_viewport().get_mouse_position()
		var c: Customer = shop.pick(mp) if loc == cafe else null
		if c:
			key = "c%d" % c.cid
		else:
			var n := loc.pick_npc(mp, camera)
			if n:
				key = "n" + str(n.get_instance_id())
				label = String(n.get_meta("label", ""))
				at = n.global_position + Vector3(0, 1.05 * n.scale.y, 0)
			else:
				var it := loc.pick_interact(mp, camera)
				if it.size():
					key = it.id
					label = it.label
					at = it.pos + Vector3(0, it.get("h", 0.9) + 0.25, 0)
	if key != _hover_key:
		_hover_key = key
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if key != "" else Input.CURSOR_ARROW)
		if hover_tag == null:
			hover_tag = Label3D.new()
			hover_tag.font = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
			hover_tag.font_size = 56
			hover_tag.pixel_size = 0.0018
			hover_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			hover_tag.no_depth_test = true
			hover_tag.modulate = Color("FFF8EE")
			hover_tag.outline_modulate = Color("3B2340")
			hover_tag.outline_size = 16
			hover_tag.render_priority = 8
			hover_tag.outline_render_priority = 7
			add_child(hover_tag)
		if label != "": Sfx.play("tick", 0.4)
	if hover_tag:
		hover_tag.visible = label != ""
		if hover_tag.visible:
			hover_tag.text = label
			hover_tag.global_position = at
			hover_tag.scale = Vector3.ONE * (1.0 + 0.04 * sin(clock * 6.0)) * (1.6 if loc == city else 1.0)

# ---------------------------------------------------------------- customers & serving
## Walks to the spot beside a customer's seat (always reachable), then serves or takes the order.
func walk_to_customer(c: Customer) -> void:
	if not c.has_meta("approach") or not c.sitting:
		go_and(c.global_position, 0.7, func(): customer_tap(c))
		return
	var app: Vector3 = c.get_meta("approach")
	var done := func():
		player.rotation.y = atan2(c.global_position.x - player.global_position.x, c.global_position.z - player.global_position.z)
		customer_tap(c)
	if instant or Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(app.x, app.z)) < 0.3:
		done.call()
	else:
		player.go_to(app, done)

func customer_tap(c: Customer) -> void:
	match c.state:
		"wait": shop.take_order(c)
		"order":
			if carrying.size() and carrying.rid == c.order:
				deliver(c)
			elif carrying.size():
				toast("%s ordered %s, not that!" % [c.cname, G.RECIPES[c.order].n])
				c.feel("yuck", 1.0)
			else:
				shop.set_active(c)
				hud.open_ticket(c.order, c)
		"eat": toast("%s is enjoying the food" % c.cname)

## Plates up whatever is on the pass and puts it in your hands.
func serve() -> void:
	var st: PlateStation = stations.plate
	var foods: Array = st.items.duplicate()
	if foods.is_empty(): return
	var comps := G.comps_of(foods)
	var d := G.detect(comps)
	var q := ""
	for f in foods: q = G.worst_q(q, f.q)
	var rid: int = d.match.r.id if d.has("match") else -1
	var cust: Customer = shop.order_for(rid) if rid >= 0 else null
	var sp := G.recipe_spec(d.match.r, foods) if d.has("match") else (G.food_spec(foods[0], clock) if foods.size() == 1 else G.generic_spec(comps, _hist_of(foods), {"q": q}))
	var dish := FoodArt.spec_node(sp)
	st.items = []
	st.refresh()
	st.ring_bell()
	Sfx.play("nom")
	guide_dirty = true
	carrying = {"foods": foods, "d": d, "q": q, "rid": rid, "node": dish}
	leave_station()
	player.carry(dish)
	if cust:
		toast("Take the %s to %s!" % [d.match.r.n, cust.cname])
		cust.feel("wow", 1.5)
		return
	# nobody ordered it: it's yours (a staff meal), and a new recipe still gets stamped
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
	carrying.name = d.match.r.n if d.has("match") else res.name
	Save.save()
	after(0.5, func(): hud.show_result(res))

func deliver(c: Customer) -> void:
	if carrying.is_empty(): return
	var dish: Node3D = player.drop()
	if dish == null: dish = carrying.node
	cafe.add_child(dish)
	var fwd := Vector3(sin(c.seat_yaw), 0, cos(c.seat_yaw))
	dish.global_position = Vector3(c.seat_pos.x, c.table_y, c.seat_pos.z) + fwd * c.table_d
	dish.rotation = Vector3.ZERO
	dish.scale = Vector3.ONE * 0.9
	c.meal = dish
	var cf: Dictionary = carrying
	carrying = {}
	shop.serve_order(c, cf.foods, cf.d, cf.q)
	Sfx.play("plunk")
	after(0.4, func(): Sfx.play("nom"))
	hud.carry_changed()

func eat_carried() -> void:
	if carrying.is_empty(): return
	var dish: Node3D = player.drop()
	var cf: Dictionary = carrying
	carrying = {}
	var boost := 10.0
	if cf.rid >= 0: boost = 14.0 + G.difficulty(G.RECIPES[cf.rid]) * 5.0
	if cf.q == "burnt": boost *= 0.5
	life.eat(boost)
	life.flag("staff_meal")
	if dish:
		add_child(dish)
		dish.global_position = player.global_position + Vector3(0, 0.45, 0) + Vector3(sin(player.rotation.y), 0, cos(player.rotation.y)) * 0.2
		var tw := dish.create_tween()
		tw.tween_property(dish, "scale", Vector3.ONE * 0.05, 1.2)
		tw.tween_callback(dish.queue_free)
	player.feel("happy", 2.0)
	player.set_eating(true)
	after(1.3, func(): player.set_eating(false))
	Sfx.play("nom")
	toast("Itadakimasu! +%d energy" % int(boost))
	hud.carry_changed()

func bin_carried() -> void:
	drop_carry()
	Sfx.play("plunk", 0.7, 0.8)
	toast("Into the bin it goes")

func drop_carry() -> void:
	if carrying.is_empty(): return
	var dish := player.drop()
	if dish: dish.queue_free()
	elif is_instance_valid(carrying.node): carrying.node.queue_free()
	carrying = {}
	if hud: hud.carry_changed()

# ---------------------------------------------------------------- counter & food flow
func counter_tap(i: int) -> void:
	if i < 0 or i >= counter.size(): return
	var f: Dictionary = counter[i]
	var key := open_key if open_key != "" else last_key
	if open_key == "": open_station(key, false)
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
	life.use_energy(0.5)
	life.flag("cook_any")
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

## Takes an ingredient from your pantry if you stocked it at the market, otherwise pays
## the delivery price.
func charge(key: String) -> int:
	if Life.cheat_on("freefood"): return 0
	if int(Save.pantry.get(key, 0)) > 0:
		Save.pantry[key] = int(Save.pantry[key]) - 1
		if Save.pantry[key] <= 0: Save.pantry.erase(key)
		return 0
	var cost: int = G.ING_COST.get(key, 0)
	Save.wallet -= cost
	if shop.open and shop.stats.has("spend"): shop.stats.spend += cost
	return cost

func add_ingredient(key: String) -> void:
	var f := G.new_food(key)
	var stocked := int(Save.pantry.get(key, 0)) > 0
	var price := "from the pantry" if stocked else G.yen(G.ING_COST.get(key, 0))
	var st := current()
	if st and st.key != "bin" and st.accepts():
		st.add_item(f, 0.05)
		toast("%s %s → %s" % [G.ING[key].n, price, LABEL[st.key]])
		Sfx.play("plunk")
	elif counter.size() < COUNTER_CAP:
		counter.append(f)
		toast("%s %s → counter" % [G.ING[key].n, price])
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
	elif n: toast("Got %d ingredient%s for %s%s" % [n, "s" if n > 1 else "", G.yen(spent), " · into the " + LABEL[tool] if to_st and tool != "" else ""])
	else: toast("Everything is already here")

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

# ---------------------------------------------------------------- people
func talk_to(n: Node3D) -> void:
	var id := String(n.get_meta("npc", ""))
	if id == "": return
	if n is Chibi and not (n as Chibi).sitting:
		n.rotation.y = atan2(player.global_position.x - n.global_position.x, player.global_position.z - n.global_position.z)
		(n as Chibi).wave()
	if n.has_meta("busy"): n.set_meta("pause", 6.0)
	if id == "partner" or id.begins_with("kid:"): life.talk_family(id)
	else: life.talk(id)

func npc_node(id: String) -> Chibi:
	if loc == null: return null
	for n in loc.npcs:
		if not is_instance_valid(n): continue
		var nid := String(n.get_meta("npc", ""))
		if nid == id or (id == Save.partner and nid == "partner"): return n
	return null

func npc_react(id: String, mood: String) -> void:
	var n := npc_node(id)
	if n:
		n.feel(mood, 2.5)
		n.wave()

func hearts_fx(id: String) -> void:
	var n := npc_node(id)
	var at := (n.global_position + Vector3(0, 0.95 * n.scale.y, 0)) if n else player.global_position + Vector3(0, 1.0, 0)
	burst(at, [Color("FF7EA6"), Color("FFC2D6"), Color.WHITE], 16, 1.2)
	float_text("♥", at + Vector3(0, 0.1, 0))
	Sfx.play("sparkle", 0.8, 1.2)

func visit_house(id: String) -> void:
	life.visit_house(id)

## Walk into a townsperson's cottage (knocked politely, or sneaking in).
func enter_house(id: String, sneak: bool) -> void:
	sneaking = sneak
	npc_house.set_host(id)
	travel("npchome", "door")

func leave_house() -> void:
	var id := npc_house.host
	sneaking = false
	travel("city", "house_" + id)

func open_shop_ui(id: String) -> void:
	hud.open_shop(id)

## A date: you meet at the park fountain in the evening and sit on a bench together.
## A date: you both go to the place (park bench, picnic blanket, fountain, a shop front, your
## café or your home) and the scene is set before the conversation starts.
var _date_guest: Chibi

func start_date(id: String, type: String, then: Callable) -> void:
	var spot: String = People.DATE_TYPES.get(type, {"spot": "bench"}).spot
	cutscene = true
	hud.fade(func(): _stage_date(id, spot), func():
		cutscene = false
		then.call())

func _stage_date(id: String, spot: String) -> void:
	match spot:
		"cafe":
			travel_now("cafe", "door")
			_seat_guest(id, cafe.furni.seats().filter(func(st): return st.id in ["table2", "table4", "booth"]))
		"home":
			travel_now("home", "start")
			_seat_guest(id, home.furni.seats())
		_:
			travel_now("city", "park" if spot in ["bench", "picnic", "fountain"] else spot)
			city.stage_couple(id, spot)

func _seat_guest(id: String, seat_list: Array) -> void:
	_date_guest = loc.make_person(id, People.look_of(id), People.npc_name(id))
	_date_guest.set_meta("date_guest", true)
	# two seats close together (same table / sofa), else stand face to face
	for a in seat_list:
		for b in seat_list:
			if a != b and a.pos.distance_to(b.pos) < 1.3:
				_date_guest.sit_at(a.pos, a.yaw, a.h)
				player.sit_at(b.pos, b.yaw, b.h)
				_date_guest.feel("happy", 30.0)
				return
	# no sofa or table: sit together on the floor (or the rug)
	var c := loc.nav.nearest_free(Vector3(0.2, 0, 0.5))
	_date_guest.sit_at(c + Vector3(0.3, 0, 0), -PI * 0.5 + 0.4, 0.06)
	player.sit_at(c - Vector3(0.3, 0, 0), PI * 0.5 - 0.4, 0.06)
	_date_guest.feel("happy", 30.0)

func end_date() -> void:
	city.end_couple()
	if _date_guest and is_instance_valid(_date_guest):
		loc.npcs.erase(_date_guest)
		_date_guest.queue_free()
	_date_guest = null
	player.stand_up()
	if loc.nav: player.global_position = loc.nav.nearest_free(player.global_position)

func start_wedding(then: Callable) -> void:
	cutscene = true
	hud.fade(func():
		travel_now("city", "park")
		city.wedding(true), func():
		cutscene = false
		then.call())

func family_scene(then: Callable) -> void:
	hud.heart_fade(then)

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
	l.pixel_size = 0.0012 if open_key != "" else 0.0022
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
func _dev_setup(what: String) -> void:
	hud.hide_title()
	if not Save.started or Shot.arg("fresh") != "":
		Save.new_game("story", "Chef", {"skin": "FFE6D6", "hair": "4B2E5A", "shirt": "FF9EBB", "pants": "5A4A70", "style": "bob", "acc": ""})
		Save.flags["intro_0"] = true
		rebuild_player()
		home.reload()
		cafe.furni.load_layout()
	var parts := what.split(":")
	match parts[0]:
		"title": hud.show_title()
		"creator": hud.open_creator("story")
		"home":
			travel_now("home", "start")
			if parts.size() > 1 and parts[1] == "family":
				Save.partner = "hana"; Save.married = true
				Save.layouts.home.append({"id": "crib", "x": 2.6, "z": 0.9, "rot": 0})
				Save.family.kids = [{"name": "Sora", "born": Save.day - 12, "look": Chibi.random_look()}, {"name": "Mio", "born": Save.day - 5, "look": Chibi.random_look()}, {"name": "Hina", "born": Save.day, "look": Chibi.random_look()}]
				home.reload()
				Save.minute = 20 * 60
				home.set_hour(Save.hour())
		"city":
			travel_now("city", "cafe")
			if parts.size() > 1:
				player.global_position = Vector3(float(parts[1]), 0, -2.6)
			Save.minute = float(Shot.arg("minute", "600"))
			city.set_hour(Save.hour())
			sim(0.5)
		"park":
			travel_now("city", "park")
			sim(0.5)
		"wedding":
			Save.partner = "yuki"
			travel_now("city", "park")
			city.wedding(true)
			sim(1.0)
		"date":
			Save.r("hana").hearts = 5.0
			start_date("hana", Shot.arg("type", "picnic"), func(): pass)
		"cafe":
			travel_now("cafe", "door")
			player.global_position = Vector3(0.6, 0, 0.6)
		"service":
			travel_now("cafe", "door")
			Save.stars_total = 80
			Save.minute = 690.0
			shop.toggle()
			hud.close_all()
			for i in 4: shop.spawn()
			sim(12.0)
			for c in shop.customers:
				if c.state == "wait" and c != shop.customers[0]: shop.take_order(c)
			hud.close_all()
			sim(0.5)
			player.global_position = Vector3(-0.2, 0, -0.4)
			if parts.size() > 1 and parts[1] == "carry":
				var f := G.merge_foods([G.new_food("egg"), G.new_food("flour"), G.new_food("milk")], "mix")
				G.apply_proc(f, "fry", 0.8)
				stations.plate.add_item(f)
				serve()
				hud.close_all()
		"edit":
			travel_now("cafe", "door")
			Save.furni_inv = {"table4": 1, "booth": 1, "lucky_cat": 1, "big_plant": 2}
			edit.start()
		"book":
			for i in [0, 2, 5, 18, 26, 35, 40, 44, 46, 60, 62, 77, 84, 89, 92]: Save.mark_found(i)
			hud.open_book()
		"detail": hud.open_book(44)
		"ticket":
			travel_now("cafe", "door")
			hud.open_ticket(44, null)
		"shop":
			travel_now("city", parts[1] if parts.size() > 1 else "market")
			Save.wallet = 25000
			hud.open_shop(parts[1] if parts.size() > 1 else "market")
		"dialogue":
			Save.minute = 600.0
			travel_now("city", "florist")
			Save.r("hana").hearts = 6.5
			Save.r("hana").dates = 1
			life.talk("hana")
		"journal":
			hud.open_journal()
		"news":
			Save.reviews = [{"day": 3, "critic": "Critic Kuroda", "stars": 4, "dish": "Katsu Curry", "quote": "The crust shattered like autumn leaves. I will return.", "read": false}]
			hud.open_newspaper(Save.reviews)
		"result":
			var f := G.merge_foods([G.new_food("egg"), G.new_food("flour"), G.new_food("milk")], "mix")
			G.apply_proc(f, "fry", 0.8)
			hud.show_result({"foods": [f], "q": "perfect", "r": G.RECIPES[0], "is_new": true, "stars": 3, "extras": [], "paid": 1210, "cust": "Hana"})
		"summary":
			hud.show_summary({"served": 7, "walked": 1, "sales": 7450, "tips": 820, "spend": 1630, "stars": 19, "new_recipes": 3}, 2)
		"console":
			hud.open_console()
		"house":
			Save.minute = float(Shot.arg("minute", "1320"))
			Save.r(parts[1]).hearts = 8.0
			Save.r(parts[1]).romance = true
			instant = true
			enter_house(parts[1], false)
			instant = false
			if Shot.arg("talk") != "": life.talk(parts[1])
		"festival":
			Save.flags["event"] = "festival"
			Save.minute = float(Shot.arg("minute", "1245"))
			travel_now("city", "cafe")
			player.global_position = Vector3(-2.0, 0, 0.3)
			sim(3.0)
			if parts.size() > 1 and parts[1] == "tako":
				life.festival_job()
				hud.advance_dialogue(); hud.advance_dialogue()
				for i in 5: hud.minigames._tako_click(hud.minigames._state.holes[i])
				for i in 3: hud.minigames._tako_tick(1.4)
				for i in [5, 6]: hud.minigames._tako_click(hud.minigames._state.holes[i])
		"delivery":
			Save.minute = 600.0
			travel_now("city", "market")
			life.start_job("delivery")
			sim(1.0)
		"jobs":
			Save.minute = 600.0
			travel_now("city", parts[1])
			life.start_job({"bookshop": "books", "florist": "bouquets"}[parts[1]])
		"myhouse":
			Save.wallet = 200000
			life.buy_house()
			travel_now("home", "start")
		"partnered":
			Save.partner = "hana"; Save.married = true
			Save.minute = 600.0
			Save.r("ren").hearts = 6.0
			travel_now("city", "bookshop")
			life.talk("ren")
		"lineup":
			travel_now("home", "start")
			player.global_position = Vector3(0, 0, -0.6)
			home.cam_offset = Vector3(0, 0.9, 2.3)
			home.cam_look = Vector3(0, 0.38, 0.6)
			home.cam_bounds = Rect2(0, -0.6, 0.01, 0.01)
			var looks := [People.NPCS.hana.look, People.NPCS.kai.look, People.NPCS.yuki.look, People.NPCS.ren.look, Chibi.random_look(null, "f"), Chibi.random_look(null, "m")]
			looks[4].bottom = "dress"
			if parts.size() > 1 and parts[1] == "hair":
				looks = []
				var only := Chibi.STYLES.slice(18) if Shot.arg("new") != "" else Chibi.STYLES
				for st in only:
					var lk := Chibi.random_look(null, "m" if st in Chibi.M_STYLES and not st in Chibi.F_STYLES else "f")
					lk.style = st
					looks.append(lk)
				home.cam_offset = Vector3(0, 1.6, 3.6)
				for i in looks.size():
					var c := Chibi.new()
					home.add_child(c)
					c.build(looks[i], "adult")
					c.global_position = Vector3(-1.6 + (i % 9) * 0.4, 0, 0.1 + (i / 9) * 0.6)
					c.rotation.y = 0.35
					c.feel("happy", 99.0)
					var l := Label3D.new()
					l.text = looks[i].style
					l.font_size = 40
					l.pixel_size = 0.002
					l.outline_size = 8
					home.add_child(l)
					l.global_position = c.global_position + Vector3(0, 0.03, 0.22)
				_update_camera(0.0, true)
				return
			for i in looks.size():
				var c := Chibi.new()
				home.add_child(c)
				c.build(looks[i], "adult")
				c.global_position = Vector3(-1.0 + i * 0.4, 0, 0.1)
				c.feel("happy", 99.0)
			_update_camera(0.0, true)
		"navreport":
			if Shot.arg("obs") != "":
				for l in [cafe, city, home]:
					for o in l.room.world_obstacles(): print("OBS ", l.key, " ", o)
			var all: Array = []
			for l in [cafe, city, home]:
				all.append_array(NavReport.check(l, l.entry_point("door" if l != city else "home"), NavReport.points_for(l), Shot.arg("map") != ""))
			home.move_to("house")
			all.append_array(NavReport.check(home, home.entry_point("door"), NavReport.points_for(home), Shot.arg("map") != "").map(func(p): return "house: " + p))
			for id in People.NPCS:
				npc_house.set_host(id)
				all.append_array(NavReport.check(npc_house, npc_house.entry_point("door"), NavReport.points_for(npc_house), Shot.arg("map") != "").map(func(p): return id + "'s " + p))
			for pr in all: print("NAV ", pr)
			for st in cafe.seats(): print("SEAT ", st.id, " ", st.pos, " app ", st.approach, " free ", cafe.nav.is_free(st.approach))
			print("NAV done: %d problems" % all.size())
			get_tree().quit()
		_:
			if stations.has(parts[0]):
				var w: String = parts[0]
				travel_now("cafe", "door")
				open_station(w, false)
				_update_camera(0.0, true)
				var demo := {"board": ["tomato", "cucumber", "carrot"], "bowl": ["egg", "flour", "milk", "strawberry"], "blender": ["strawberry", "banana", "milk"],
					"mat": ["nori", "rice", "salmon", "avocado"], "pot": ["noodles", "soy", "egg"], "pan": ["egg"], "oven": ["flour", "butter", "sugar", "chocolate"],
					"micro": ["kernels"], "freezer": ["mango", "sugar"], "plate": [], "bin": []}
				for k in demo.get(w, []):
					stations[w].add_item(G.new_food(k))
				if w == "plate":
					var f := G.merge_foods([G.new_food("egg"), G.new_food("flour"), G.new_food("milk")], "mix")
					G.apply_proc(f, "fry", 0.8)
					stations.plate.add_item(f)
				if w == "pan" or w == "pot" or w == "oven":
					stations[w].start()
					sim(9.0 if w != "oven" else 14.0)
				if w == "micro":
					stations.micro.on_btn()
					sim(5.0)
				for k in ["egg", "tomato", "strawberry"]:
					counter.append(G.new_food(k))
				hud.counter_changed()
