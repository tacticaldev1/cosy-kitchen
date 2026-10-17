## The café's front of house: opening hours, customers, orders, patience and payment.
class_name Shop
extends Node

const DAY_LEN := 330.0
const NAMES := ["Mina", "Haru", "Sora", "Koko", "Nana", "Taro", "Emi", "Ren", "Aoi", "Ken", "Rin", "Mio", "Sota", "Yui", "Daichi", "Saki", "Kaito", "Hina"]
const REGULARS := [
	{"name": "Hana", "fav": "Matcha Latte", "look": {"skin": "FFE6D6", "hair": "2E3A5A", "shirt": "B7E3A0", "style": "buns"}},
	{"name": "Riku", "fav": "Shoyu Ramen", "look": {"skin": "F2CDB0", "hair": "3A2A2A", "shirt": "A9C8FF", "style": "short"}},
	{"name": "Momo", "fav": "Strawberry Shortcake", "look": {"skin": "FFEADF", "hair": "F2B8C8", "shirt": "FF9EBB", "style": "twin"}},
	{"name": "Kai", "fav": "Katsu Curry", "look": {"skin": "E8B896", "hair": "8A4A2A", "shirt": "FFB86A", "style": "bob"}},
	{"name": "Yuki", "fav": "Fluffy Pancakes", "look": {"skin": "FFE2D2", "hair": "F2F2F8", "shirt": "C3A6FF", "style": "long"}},
]
const CAT_DISHES := ["Salmon Nigiri", "Tuna Nigiri", "Salmon Onigiri", "Salmon Maki", "Fish & Chips"]

var game: Game
var open := false
var day_t := 0.0
var last_orders := false
var stats := {}
var customers: Array = []
var next_t := 0.0
var active := -1
var uid := 1
var special := -1   # today's special recipe id

signal changed

func new_stats() -> Dictionary:
	return {"served": 0, "walked": 0, "sales": 0, "tips": 0, "spend": 0, "stars": 0, "new_recipes": 0}

func seats() -> int:
	var lv := Save.level()
	return 3 + (1 if lv >= 4 else 0) + (1 if lv >= 7 else 0)

func seat_pos(i: int) -> Vector3:
	return game.cafe.mark("seat_%d" % i)

func free_seat() -> int:
	for i in seats():
		if not customers.any(func(c): return c.seat == i and c.state != "gone"):
			return i
	return -1

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
		open = true
		last_orders = false
		day_t = 0.0
		stats = new_stats()
		next_t = game.clock + 2.0
		special = _pick_special()
		Sfx.play("bell")
		game.toast("Day %d: the shop is open!" % Save.day)
		game.hud.show_banner("Day %d" % Save.day, "いらっしゃいませ · the café is open")
		changed.emit()
		return
	close_day()

func close_day() -> void:
	open = false
	for c in customers:
		if c.state != "leave" and c.state != "gone": leave(c, false, true)
	active = -1
	var profit: int = stats.sales + stats.tips - stats.spend
	if profit > Save.best_day: Save.best_day = profit
	game.hud.show_summary(stats, Save.day)
	Save.day += 1
	Save.save()
	changed.emit()

func _pick_special() -> int:
	var pool: Array = G.RECIPES.filter(func(r): return not Save.is_found(r.id) and G.build_steps(r).size() <= _max_steps() + 1)
	if pool.is_empty(): pool = G.RECIPES
	return pool[randi() % pool.size()].id

func _max_steps() -> int:
	var served: int = stats.get("served", 0)
	return clampi(3 + Save.level() + served / 4, 4, 9)

func pick_order(kind: String, fav := "") -> int:
	if kind == "cat":
		var r = G.RECIPES.filter(func(x): return CAT_DISHES.has(x.n))
		return r[randi() % r.size()].id
	if fav != "" and randf() < 0.6:
		for r in G.RECIPES:
			if r.n == fav: return r.id
	var lim := _max_steps() + (2 if kind == "critic" else 0)
	var pool: Array = G.RECIPES.filter(func(r): return G.build_steps(r).size() <= lim)
	if kind == "critic":
		pool = pool.filter(func(r): return G.build_steps(r).size() >= 4)
	if special >= 0 and randf() < 0.18: return special
	var w: Array = pool.map(func(r): return (1.4 if Save.is_found(r.id) else 1.0) / maxf(1.0, G.build_steps(r).size() - 2))
	var tot := 0.0
	for x in w: tot += x
	var x := randf() * tot
	for i in pool.size():
		x -= w[i]
		if x <= 0.0: return pool[i].id
	return pool[0].id

func spawn() -> void:
	var seat := free_seat()
	if seat < 0: return
	var lv := Save.level()
	var used := customers.map(func(c): return c.cname)
	var info := {"id": uid, "seat": seat, "kind": "normal"}
	uid += 1
	var roll := randf()
	var regs: Array = REGULARS.filter(func(r): return not used.has(r.name))
	if lv >= 3 and roll < 0.07:
		info.kind = "critic"
		info.name = "Critic Kuroda"
		info.look = {"skin": Color("F2CDB0"), "hair": Color("3A2A2A"), "shirt": Color("3B2340"), "style": "short"}
	elif lv >= 2 and roll < 0.12 and not used.has("Mochi"):
		info.kind = "cat"
		info.name = "Mochi"
		info.look = {}
	elif lv >= 2 and roll < 0.4 and regs.size():
		var rg: Dictionary = regs[randi() % regs.size()]
		info.kind = "regular"
		info.name = rg.name
		info.fav = rg.fav
		info.look = {"skin": Color(rg.look.skin), "hair": Color(rg.look.hair), "shirt": Color(rg.look.shirt), "style": rg.look.style}
	else:
		var names: Array = NAMES.filter(func(n): return not used.has(n))
		info.name = names[randi() % names.size()]
		info.look = {"skin": Customer.SKINS[randi() % Customer.SKINS.size()], "hair": Customer.HAIRS[randi() % Customer.HAIRS.size()],
			"shirt": Customer.SHIRTS[randi() % Customer.SHIRTS.size()], "style": Customer.STYLES[randi() % Customer.STYLES.size()]}
	var c := Customer.new()
	c.setup(info)
	c.set_meta("fav", info.get("fav", ""))
	game.world.add_child(c)
	var door := game.cafe.mark("door")
	var sp := seat_pos(seat)
	c.seat_pos = Vector3(sp.x, 0.6 if c.kind != "cat" else 0.8, sp.z)
	c.position = Vector3(door.x - 0.7, 0.0, door.z)
	c.walk_to([Vector3(door.x + 0.4, 0, door.z), Vector3(door.x + 0.7, 0, -1.98), Vector3(sp.x, 0, -1.98), Vector3(sp.x, 0, sp.z)])
	c.state = "enter"
	c.patience = 75.0 * (1.3 if c.kind == "regular" else 1.0)
	c.pmax = c.patience
	customers.append(c)
	Sfx.play("bell")
	if c.kind == "critic": game.toast("A food critic just walked in… make it perfect!")
	elif c.kind == "cat": game.toast("Mochi the café cat wants a fishy snack!")
	elif c.kind == "regular": game.toast("%s, a regular, is here!" % c.cname)
	changed.emit()

func take_order(c: Customer) -> void:
	var rid := pick_order(c.kind, c.get_meta("fav", ""))
	var steps := G.build_steps(G.RECIPES[rid]).size()
	c.order = rid
	c.state = "order"
	c.pmax = (100.0 + 30.0 * maxi(0, steps - 2)) * (1.3 if c.kind == "regular" else 0.8 if c.kind == "critic" else 1.0)
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
	c.stand()
	var door := game.cafe.mark("door")
	var sp := seat_pos(c.seat)
	c.walk_to([Vector3(sp.x, 0, -1.98), Vector3(door.x + 0.7, 0, -1.98), Vector3(door.x + 0.4, 0, door.z), Vector3(door.x - 0.8, 0, door.z)])
	if c.meal:
		c.meal.queue_free()
		c.meal = null
	if active == c.cid: next_active()
	if not quiet: changed.emit()

## Called by Game.serve when the plate's dish matches this customer's order.
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
	if c.kind == "critic": price *= 2
	if stars == 3 and quick: tip += int(round(r.price * 0.1))
	if c.kind == "regular" and Save.friends.get(c.cname, 0) >= 5: tip += int(round(r.price * 0.25))
	if r.id == special: tip += int(round(r.price * 0.5))
	if Save.decor.has("lucky_cat") and Save.decor_on.get("lucky_cat", true): tip += int(round(r.price * 0.05))
	Save.wallet += price + tip
	Save.served_total += 1
	Save.stars_total += stars + (2 if c.kind == "critic" and stars == 3 else 0)
	stats.served += 1
	stats.sales += price
	stats.tips += tip
	stats.stars += stars
	if fresh: stats.new_recipes += 1
	var hearts := 0
	if c.kind == "regular" and stars >= 2:
		hearts = 2 if r.n == c.get_meta("fav", "") else 1
		Save.friends[c.cname] = mini(int(Save.friends.get(c.cname, 0)) + hearts, 10)
	Save.save()
	c.feel("yuck" if stars == 1 else "wow" if fresh or (stars == 3 and quick) else "happy", 3.2)
	var line := ""
	if c.kind == "critic":
		line = "Critic Kuroda: \"Exquisite. Five stars!\"" if stars == 3 else "Critic Kuroda: \"Hmm. Not quite.\""
	elif c.kind == "cat":
		line = "Mochi: \"Nyaa~!\" (purrs loudly)"
	elif stars == 3:
		line = "%s: \"So fast and so tasty!\"" % c.cname if quick else "%s: \"Delicious, thank you!\"" % c.cname
	elif stars == 2:
		line = "%s: \"Nice, but a little undercooked\"" % c.cname
	else:
		line = "%s: \"Hmm… a bit burnt\"" % c.cname
	game.after(0.9, func():
		Sfx.play("coin")
		game.float_text("+" + G.yen(price + tip), c.global_position + Vector3(0, 1.3, 0))
		game.burst(c.global_position + Vector3(0, 1.1, 0), [Color("FFD24A"), Color.WHITE], 14)
		game.toast(line)
		if hearts: game.toast("%s's friendship %s" % [c.cname, "♥".repeat(mini(int(Save.friends[c.cname]), 10))]))
	if active == c.cid: next_active()
	if fresh:
		game.after(1.6, func(): game.hud.show_result({"foods": foods, "q": q, "r": r, "is_new": true, "stars": stars, "extras": d.match.extras, "paid": price + tip, "cust": c.cname}))
	changed.emit()

func update(dt: float) -> void:
	var stop: bool = game.paused()
	if open and not stop:
		day_t += dt / DAY_LEN
		if day_t >= 1.0 and not last_orders:
			last_orders = true
			game.toast("Last orders! No new customers today")
			Sfx.play("chime")
			changed.emit()
		var gap := 16.0 + randf() * 16.0 - Save.level() * 0.8
		if not last_orders and game.clock > next_t and free_seat() >= 0:
			spawn()
			next_t = game.clock + maxf(8.0, gap) * (0.85 if Save.decor.has("flowers") and Save.decor_on.get("flowers", true) else 1.0)
		if last_orders and customers.is_empty():
			close_day()
	game.cafe.set_time_of_day(clampf(day_t, 0.0, 1.0) if open else 0.25)
	for c in customers.duplicate():
		c.tick(dt, game.clock)
		match c.state:
			"enter":
				if c.path.is_empty():
					c.sit()
					c.state = "wait"
					c.t = 0.0
					c.set_bubble("wait")
					changed.emit()
			"wait", "order":
				if not stop:
					var calm := 0.75 if Save.decor.has("record_player") and Save.decor_on.get("record_player", true) else 1.0
					c.patience -= dt * calm
				if c.patience / c.pmax < 0.25 and c.face and c.face.mood == "idle": c.feel("sleepy", 0.5)
				if c.patience <= 0.0:
					game.toast("%s couldn't wait to order and left" % c.cname if c.state == "wait" else "%s got tired of waiting" % c.cname)
					Sfx.play("sigh")
					if stats.has("walked"): stats.walked += 1
					leave(c, true)
			"eat":
				if c.meal:
					var k := clampf(c.t / 3.2, 0.0, 1.0)
					c.meal.scale = Vector3.ONE * lerpf(1.0, 0.25, k)
				if c.t > 3.4:
					leave(c, false)
			"leave":
				if c.path.is_empty():
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
		var head: Vector3 = c.global_position + Vector3(0, 0.55, 0)
		if not game.camera.is_position_in_frustum(head): continue
		var d := game.camera.unproject_position(head).distance_to(p)
		var r := maxf(40.0, game.camera.unproject_position(head).distance_to(game.camera.unproject_position(head + game.camera.global_transform.basis.x * 0.25)))
		if d < r and d < bd + r:
			bd = d
			best = c
	return best
