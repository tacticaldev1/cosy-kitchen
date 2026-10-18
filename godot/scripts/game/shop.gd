## The café's front of house: opening hours, customers walking in to the seats you've
## furnished, orders, patience, payment, reputation and the food critics.
class_name Shop
extends Node

const OPEN_FROM := 8 * 60.0
const LAST_ORDERS := 21.5 * 60.0
const NAMES := ["Mina", "Haru", "Sora", "Koko", "Nana", "Taro", "Emi", "Aoi", "Ken", "Rin", "Mio", "Sota", "Yui", "Daichi", "Saki", "Kaito", "Hina", "Riku", "Momo", "Natsu"]
const CRITICS := [
	{"name": "Critic Kuroda", "paper": "The Hoshizora Times", "look": {"body": "m", "skin": "F2CDB0", "hair": "3A2A2A", "shirt": "3B2340", "pants": "2E2A3A", "style": "short"}},
	{"name": "Madame Fujii", "paper": "Gourmet Monthly", "look": {"body": "f", "bottom": "dress", "skin": "FFE2D2", "hair": "C8C8D8", "shirt": "6A3E5A", "pants": "2E2A3A", "style": "bob"}},
	{"name": "Chef Lorenzo", "paper": "Food & Travel", "look": {"body": "m", "skin": "E8B896", "hair": "2E2A3A", "shirt": "E8504A", "pants": "3B4A7A", "style": "curly"}},
]
const CAT_DISHES := ["Salmon Nigiri", "Tuna Nigiri", "Salmon Onigiri", "Salmon Maki", "Fish & Chips"]

var game: Game
var open := false
var last_orders := false
var stats := {}
var customers: Array = []
var next_t := 0.0
var active := -1
var uid := 1
var special := -1   # today's special recipe id
var critic_today := false
var force_critic := false

signal changed

func new_stats() -> Dictionary:
	return {"served": 0, "walked": 0, "sales": 0, "tips": 0, "spend": 0, "stars": 0, "new_recipes": 0}

## Customer seats: bar stools plus seats at tables you've placed (lone chairs and sofas don't count).
func seat_list() -> Array:
	return game.cafe.seats().filter(func(s): return s.id in ["bar", "table2", "table4", "booth"] and game.cafe.reachable(s.approach))

func seats() -> int:
	return seat_list().size()

## A random free seat, so customers spread out over the room.
func free_seat() -> int:
	var free: Array = []
	for i in seats():
		if not customers.any(func(c): return c.seat == i and c.state != "gone"):
			free.append(i)
	return free[randi() % free.size()] if free.size() else -1

func orders() -> Array:
	return customers.filter(func(c): return c.state == "order")

func waiting() -> Array:
	return customers.filter(func(c): return c.state == "wait")

func active_cust() -> Customer:
	for c in customers:
		if c.cid == active and c.state == "order": return c
	return null

func order_for(rid: int) -> Customer:
	var best: Customer = null
	for c in orders():
		if c.order == rid and (best == null or c.patience < best.patience): best = c
	return best

func set_active(c: Customer) -> void:
	active = c.cid if c else -1
	if c:
		Save.pinned = c.order
		Save.save()
	game.guide_dirty = true
	changed.emit()

func next_active() -> void:
	var os := orders()
	os.sort_custom(func(a, b): return a.patience / a.pmax < b.patience / b.pmax)
	if os.size(): set_active(os[0])
	else:
		active = -1
		changed.emit()

func toggle() -> void:
	if not open:
		if Save.minute < OPEN_FROM:
			game.toast("It's too early! The café opens from 8:00 am")
			return
		if Save.minute >= LAST_ORDERS:
			game.toast("It's too late to open today. Go home and rest!")
			return
		if seats() == 0:
			game.toast("There's nowhere to sit! Place a table in Edit mode first")
			return
		open = true
		last_orders = false
		critic_today = false
		stats = new_stats()
		next_t = game.clock + 3.0
		special = _pick_special()
		Sfx.play("bell")
		game.cafe.set_sign(true)
		game.life.flag("open_shop")
		game.hud.show_banner("OPEN", "いらっしゃいませ · Day %d" % Save.day)
		changed.emit()
		return
	close_day()

func close_day(quiet := false) -> void:
	if not open: return
	open = false
	for c in customers:
		if c.state != "leave" and c.state != "gone": leave(c, false, true)
	active = -1
	game.cafe.set_sign(false)
	var profit: int = stats.sales + stats.tips - stats.spend
	if profit > Save.best_day: Save.best_day = profit
	if not quiet: game.hud.show_summary(stats, Save.day)
	Save.save()
	changed.emit()

func _pick_special() -> int:
	var pool: Array = G.RECIPES.filter(func(r): return not Save.is_found(r.id) and G.difficulty(r) <= _max_diff())
	if pool.is_empty(): pool = G.RECIPES
	return pool[randi() % pool.size()].id

## How hard the orders can get: grows with café level, rating and how the day is going.
func _max_diff() -> int:
	var served: int = stats.get("served", 0)
	return clampi(1 + Save.level() / 2 + int(Save.reputation / 2.0) + served / 6, 2, 5)

func pick_order(kind: String, fav := "") -> int:
	if kind == "cat":
		var r = G.RECIPES.filter(func(x): return CAT_DISHES.has(x.n))
		return r[randi() % r.size()].id
	if fav != "" and randf() < 0.6:
		for r in G.RECIPES:
			if r.n == fav: return r.id
	var lim := _max_diff() + (1 if kind == "critic" else 0)
	var pool: Array = G.RECIPES.filter(func(r): return G.difficulty(r) <= lim)
	if kind == "critic":
		pool = pool.filter(func(r): return G.difficulty(r) >= 3)
	if special >= 0 and randf() < 0.18: return special
	var sweet: bool = Save.flags.get("event", "") == "sweet"
	var w: Array = pool.map(func(r): return (1.4 if Save.is_found(r.id) else 1.0) / maxf(1.0, G.difficulty(r) - 1.0) * (3.0 if sweet and r.cat in ["desserts", "drinks"] else 1.0))
	var tot := 0.0
	for x in w: tot += x
	var x := randf() * tot
	for i in pool.size():
		x -= w[i]
		if x <= 0.0: return pool[i].id
	return pool[0].id

func _want_critic() -> bool:
	if force_critic:
		force_critic = false
		return true
	if critic_today: return false
	if Story.active() and Save.chapter == 3 and not Save.flags.get("critic4", false): return stats.get("served", 0) >= 2
	if Save.flags.get("event", "") == "critics": return randf() < 0.3
	return Save.reputation >= 1.5 and randf() < 0.06 + Save.reputation * 0.01

func spawn() -> void:
	var seat := free_seat()
	if seat < 0: return
	var used := customers.map(func(c): return c.cname)
	var info := {"id": uid, "seat": seat, "kind": "normal"}
	uid += 1
	var roll := randf()
	var locals: Array = People.NPCS.keys().filter(func(k): return not used.has(People.npc_name(k)))
	if _want_critic():
		var cr: Dictionary = CRITICS[randi() % CRITICS.size()]
		critic_today = true
		info.kind = "critic"
		info.name = cr.name
		info.paper = cr.paper
		info.look = cr.look
	elif Save.level() >= 2 and roll < 0.1 and not used.has("Mochi"):
		info.kind = "cat"
		info.name = "Mochi"
		info.look = {"hair": "FFB86A"}
	elif roll < 0.32 and locals.size():
		var id: String = locals[randi() % locals.size()]
		info.kind = "regular"
		info.npc = id
		info.name = People.npc_name(id)
		info.fav = People.NPCS[id].fav
		info.look = People.NPCS[id].look
	else:
		var names: Array = NAMES.filter(func(n): return not used.has(n))
		info.name = names[randi() % names.size()]
		info.look = Chibi.random_look()
	var c := Customer.new()
	c.setup(info)
	c.npc = info.get("npc", "")
	c.set_meta("fav", info.get("fav", ""))
	c.set_meta("paper", info.get("paper", ""))
	game.cafe.add_child(c)
	var s: Dictionary = seat_list()[seat]
	c.seat_pos = s.pos
	c.seat_yaw = s.yaw
	c.seat_h = s.h if c.ckind != "cat" else s.h + 0.2
	c.table_y = 1.056 if s.id == "bar" else (0.775 if s.id != "table4" else 0.77)
	c.table_d = 0.42 if s.id == "bar" else 0.3
	var door := game.cafe.room.mark("door")
	c.global_position = game.cafe.room.mark("door_out")
	c.set_meta("approach", s.approach)
	var path := PackedVector3Array([door])
	path.append_array(game.cafe.nav.path(door, s.approach))
	path.append(Vector3(s.pos.x, 0, s.pos.z))
	c.walk_path(path)
	c.state = "enter"
	c.patience = (70.0 + Save.reputation * 4.0) * (1.3 if c.ckind == "regular" else 1.0)
	c.pmax = c.patience
	customers.append(c)
	Sfx.play("bell")
	if c.ckind == "critic": game.toast("%s from %s just walked in… make it perfect!" % [c.cname, info.paper])
	elif c.ckind == "cat": game.toast("Mochi the neighbourhood cat wants a fishy snack!")
	elif c.ckind == "regular": game.toast("%s dropped by the café!" % c.cname)
	changed.emit()

func take_order(c: Customer) -> void:
	var rid := pick_order(c.ckind, c.get_meta("fav", ""))
	var r: Dictionary = G.RECIPES[rid]
	c.order = rid
	c.state = "order"
	c.pmax = (140.0 + 40.0 * (G.difficulty(r) - 1) + G.build_steps(r).size() * 9.0) * (1.3 if c.ckind == "regular" else 0.85 if c.ckind == "critic" else 1.0)
	if game.cafe.furni.has_item("record"): c.pmax *= 1.25
	c.patience = c.pmax
	c.t = 0.0
	c.set_bubble("order")
	c.feel("happy", 1.2)
	Sfx.play("note")
	set_active(c)
	game.hud.open_ticket(rid, c)

func leave(c: Customer, sad: bool, quiet := false) -> void:
	c.state = "leave"
	c.t = 0.0
	c.set_bubble("heart" if not sad and c.stars >= 2 else "")
	c.feel("yuck" if sad else "happy", 3.0)
	var was_seated := c.sitting
	c.stand_up()
	var door := game.cafe.room.mark("door")
	var app: Vector3 = c.get_meta("approach", c.global_position)
	var path := PackedVector3Array()
	if was_seated: path.append(app)
	path.append_array(game.cafe.nav.path(app if was_seated else c.global_position, door))
	path.append(game.cafe.room.mark("door_out"))
	c.walk_path(path)
	if c.meal:
		c.meal.queue_free()
		c.meal = null
	if active == c.cid: next_active()
	if not quiet: changed.emit()

## Called by Game.deliver when you hand a customer the dish they ordered.
func serve_order(c: Customer, foods: Array, d: Dictionary, q: String) -> void:
	var r: Dictionary = d.match.r
	var fresh := Save.mark_found(r.id)
	var stars := 1 if q == "burnt" else 2 if q == "under" else 3
	var quick := c.patience / c.pmax > 0.5
	c.stars = stars
	c.quick = quick
	c.state = "eat"
	c.t = 0.0
	c.set_bubble("")
	var price: int = r.price
	var tip := 0
	if c.ckind == "critic": price *= 2
	if stars == 3:
		tip += int(round(r.price * G.diff_bonus(r)))
		if quick: tip += int(round(r.price * 0.1))
	tip += int(round(r.price * 0.05 * Save.cookbooks))
	tip += int(round(r.price * Save.reputation * 0.02))
	if r.id == special: tip += int(round(r.price * 0.5))
	if game.cafe.furni.has_item("lucky_cat"): tip += int(round(r.price * 0.05))
	match Save.flags.get("event", ""):
		"festival": tip += int(round((price + tip) * 0.5))
		"sweet":
			if r.cat in ["desserts", "drinks"]: tip += int(round(r.price * 0.3))
	Save.wallet += price + tip
	Save.served_total += 1
	Save.stars_total += stars + (2 if c.ckind == "critic" and stars == 3 else 0)
	stats.served += 1
	stats.sales += price
	stats.tips += tip
	stats.stars += stars
	if fresh: stats.new_recipes += 1
	if G.difficulty(r) >= 4 and stars >= 2: game.life.flag("diff4")
	# reputation drifts with every happy (or unhappy) meal
	Save.reputation = clampf(Save.reputation + (0.04 if stars == 3 and quick else 0.02 if stars == 3 else 0.0 if stars == 2 else -0.05) * (1.0 + G.difficulty(r) * 0.15), 0.0, 5.0)
	var hearts := 0.0
	if c.npc != "" and stars >= 2:
		hearts = 1.0 if r.n == c.get_meta("fav", "") else 0.5
		Save.add_hearts(c.npc, hearts)
	var review := {}
	if c.ckind == "critic": review = _review(c, r, q, quick)
	Save.save()
	c.feel("yuck" if stars == 1 else "wow" if fresh or (stars == 3 and quick) else "happy", 3.2)
	var line := ""
	if c.ckind == "critic":
		line = "%s scribbles in a little notebook… (%d★ review in tomorrow's paper)" % [c.cname, review.stars]
	elif c.ckind == "cat":
		line = "Mochi: \"Nyaa~!\" (purrs loudly)"
	elif c.npc != "" and r.n == c.get_meta("fav", ""):
		line = "%s: \"My favourite! You remembered!\"" % c.cname
	elif stars == 3:
		line = "%s: \"So fast and so tasty!\"" % c.cname if quick else "%s: \"Delicious, thank you!\"" % c.cname
	elif stars == 2:
		line = "%s: \"Nice, but a little undercooked\"" % c.cname
	else:
		line = "%s: \"Hmm… a bit burnt\"" % c.cname
	game.after(0.9, func():
		Sfx.play("coin")
		game.float_text("+" + G.yen(price + tip), c.global_position + Vector3(0, 1.2, 0))
		game.burst(c.global_position + Vector3(0, 1.0, 0), [Color("FFD24A"), Color.WHITE], 14)
		game.toast(line)
		if hearts > 0.0: game.burst(c.global_position + Vector3(0, 1.1, 0), [Color("FF7EA6"), Color("FFC2D6")], 10))
	if active == c.cid: next_active()
	if fresh:
		game.after(1.6, func(): game.hud.show_result({"foods": foods, "q": q, "r": r, "is_new": true, "stars": stars, "extras": d.match.extras, "paid": price + tip, "cust": c.cname}))
	changed.emit()

## A critic's verdict, 1..5 stars: cooking quality, speed and ambition (recipe difficulty).
func _review(c: Customer, r: Dictionary, q: String, quick: bool) -> Dictionary:
	var s := {"burnt": 1, "under": 2, "": 3, "ok": 3, "perfect": 4}.get(q, 3) as int
	if G.difficulty(r) >= 4 and q != "burnt": s += 1
	if G.difficulty(r) <= 1: s -= 1
	if not quick: s -= 1
	if game.cafe.furni.items.size() >= 8: s += 1 if randf() < 0.5 else 0
	s = clampi(s, 1, 5)
	var quotes := {
		1: ["I have eaten happier cardboard.", "The %s was a tragedy in three acts." % r.n, "I will not be returning. My tongue may never forgive me."],
		2: ["The %s showed promise, then lost its nerve." % r.n, "Charming room. Confused kitchen.", "Edible. I suppose that is something."],
		3: ["A perfectly pleasant %s. Neither a revelation nor a regret." % r.n, "Cosy, warm, competent. The town could do worse.", "Solid cooking with room to grow."],
		4: ["The %s was genuinely lovely. I scraped the plate." % r.n, "A kitchen with real heart. I will return.", "I came for a critique and stayed for seconds."],
		5: ["The finest %s I have eaten in twenty years. Run, do not walk." % r.n, "Perfection in a tiny café. I wept a little. Do not tell anyone.", "Five stars. I have nothing clever to say. Just go."],
	}
	var pool: Array = quotes[s]
	var rv := {"day": Save.day, "critic": c.cname, "paper": c.get_meta("paper", "The Hoshizora Times"), "stars": s, "dish": r.n, "quote": pool[randi() % pool.size()], "read": false}
	Save.reviews.append(rv)
	if Save.reviews.size() > 30: Save.reviews.pop_front()
	Save.reputation = clampf(Save.reputation + (s - 3) * 0.3, 0.0, 5.0)
	if s >= 4: game.life.flag("critic4")
	return rv

func update(dt: float) -> void:
	var stop: bool = game.paused()
	if open and not stop:
		if Save.minute >= LAST_ORDERS and not last_orders:
			last_orders = true
			game.toast("Last orders! No new customers tonight")
			Sfx.play("chime")
			changed.emit()
		var gap := maxf(7.0, 24.0 - Save.reputation * 3.0 - Save.level() * 0.6 + randf() * 10.0)
		if game.cafe.furni.has_item("flowers"): gap *= 0.85
		if Save.flags.get("event", "") == "festival": gap *= 0.7
		if Save.weather == "rain": gap *= 1.15
		if not last_orders and game.clock > next_t and free_seat() >= 0:
			spawn()
			next_t = game.clock + gap
		if last_orders and customers.is_empty():
			close_day()
	for c in customers.duplicate():
		c.tick(dt, game.clock)
		match c.state:
			"enter":
				if not c.walking:
					c.sit_at(c.seat_pos, c.seat_yaw, c.seat_h)
					c.state = "wait"
					c.t = 0.0
					c.set_bubble("wait")
					changed.emit()
			"wait", "order":
				if not stop and not Life.cheat_on("zen"):
					c.patience -= dt
				if c.patience / c.pmax < 0.25 and c.face and c.face.mood == "idle": c.feel("sleepy", 0.5)
				if c.patience <= 0.0:
					game.toast("%s couldn't wait to order and left" % c.cname if c.state == "wait" else "%s got tired of waiting" % c.cname)
					Sfx.play("sigh")
					if stats.has("walked"): stats.walked += 1
					Save.reputation = clampf(Save.reputation - 0.06, 0.0, 5.0)
					if c.ckind == "critic":
						Save.reviews.append({"day": Save.day, "critic": c.cname, "paper": c.get_meta("paper", ""), "stars": 1, "dish": "nothing at all", "quote": "I waited and waited. Nobody came. One star, for the chair.", "read": false})
						Save.reputation = clampf(Save.reputation - 0.4, 0.0, 5.0)
					leave(c, true)
			"eat":
				if c.meal:
					var k := clampf(c.t / 6.0, 0.0, 1.0)
					c.meal.scale = Vector3.ONE * lerpf(0.9, 0.25, k)
				if c.t > 6.5:
					leave(c, false)
			"leave":
				if not c.walking:
					c.state = "gone"
					c.queue_free()
	var before := customers.size()
	customers = customers.filter(func(c): return c.state != "gone")
	if customers.size() != before: changed.emit()

## Screen-space pick of a customer in the 3D view.
func pick(p: Vector2) -> Customer:
	var best: Customer = null
	var bd := 60.0
	for c in customers:
		if c.state != "wait" and c.state != "order" and c.state != "eat": continue
		var head: Vector3 = c.head_pos()
		if not game.camera.is_position_in_frustum(head): continue
		var sp := game.camera.unproject_position(head)
		var d := sp.distance_to(p)
		var r := maxf(40.0, sp.distance_to(game.camera.unproject_position(head + game.camera.global_transform.basis.x * 0.25)))
		if d < r and d < bd + r:
			bd = d
			best = c
	return best
