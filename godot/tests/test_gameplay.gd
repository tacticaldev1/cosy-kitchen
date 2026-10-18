extends Node
## Plays the game through its real stations, shop, town and life systems, headless.

func run(t) -> void:
	var game: Game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.instant = true
	game.hud.hide_title()
	Save.new_game("story", "Tester", Chibi.random_look())
	Save.flags["intro_0"] = true
	game.home.reload()
	game.cafe.furni.load_layout()
	t.check(game.loc == game.home and Save.started, "a new life starts at home")
	# ---- difficulty ratings
	var per := [0, 0, 0, 0, 0, 0]
	for r in G.RECIPES: per[G.difficulty(r)] += 1
	t.check(per[0] == 0 and per.slice(1).all(func(n): return n >= 15), "every recipe gets 1-5 chef hats, spread across the menu %s" % str(per.slice(1)))
	var easy: Dictionary = G.RECIPES.filter(func(r): return r.n == "Popcorn")[0]
	var hard: Array = G.RECIPES.filter(func(r): return G.difficulty(r) == 5)
	t.check(G.difficulty(easy) <= 2 and G.build_steps(hard[0]).size() >= G.build_steps(easy).size(), "popcorn is easy, 5-hat dishes take more steps")
	# ---- walk to the café and open
	game.travel_now("city", "home")
	t.check(game.loc == game.city and game.player.nav == game.city.nav, "out the door into town")
	game.travel_now("cafe", "door")
	t.check(game.loc == game.cafe and Story.done("visit_cafe"), "into the café (story quest ticks)")
	t.check(game.shop.seats() >= 9, "bar stools plus the starting tables give seats (%d)" % game.shop.seats())
	Save.minute = 600.0
	var w0: int = Save.wallet
	game.shop.toggle()
	t.check(game.shop.open and Story.done("open_shop"), "flipping the sign opens the café")
	game.hud.close_all()
	game.shop.spawn()
	var c: Customer = game.shop.customers[0]
	game.sim(16.0)
	t.check(c.state == "wait" and c.sitting, "a customer walks in through the door and sits down (%s)" % c.state)
	t.check(Vector2(c.global_position.x, c.global_position.z).distance_to(Vector2(c.seat_pos.x, c.seat_pos.z)) < 0.05, "…at their seat")
	game.go_and(c.global_position, 0.7, func(): game.customer_tap(c))
	t.check(c.state == "order", "walking up to them takes the order")
	game.hud.close_all()
	var pancakes: Dictionary = G.RECIPES.filter(func(r): return r.n == "Fluffy Pancakes")[0]
	c.order = pancakes.id
	game.shop.set_active(c)
	game.buy_for(pancakes, c)
	t.check(game.stations.bowl.items.size() == 3, "Buy all puts egg, flour and milk into the bowl (%d)" % game.stations.bowl.items.size())
	t.check(game.open_key == "bowl" and not game.player.visible, "you step up to the bowl")
	var bowl: BowlStation = game.stations.bowl
	game._update_camera(0.0, true)
	var center := game.screen_pos(bowl.global_position + Vector3(0, 0.06, 0))
	bowl.pointer_down(center + Vector2(80, 0))
	var prev := center + Vector2(80, 0)
	for i in 160:
		var a := i * 0.25
		var p := center + Vector2(cos(a), sin(a)) * 80.0
		bowl.pointer_move(p, prev)
		prev = p
		if bowl.items.is_empty(): break
	bowl.pointer_up(prev)
	t.check(bowl.items.is_empty() and game.counter.size() == 1, "stirring in circles makes batter on the counter")
	t.check(Story.done("cook_any"), "cooking ticks the story quest")
	game.open_station("pan")
	game.counter_tap(0)
	var pan: PanStation = game.stations.pan
	pan.on_btn()
	game.sim(11.0)
	pan.on_btn()
	var f: Dictionary = game.counter[0]
	t.check(f.recipe == pancakes.id and f.q == "perfect", "perfect Fluffy Pancakes come out of the pan")
	game.open_station("plate")
	game.counter_tap(0)
	t.check(game.stations.plate.btn().get("label", "").begins_with("Serve "), "the plate offers to serve the customer")
	game.serve()
	t.check(game.carrying.get("rid", -1) == pancakes.id and game.open_key == "" and game.player.carried != null, "picking up the plate puts the dish in your hands")
	t.check(game._cust_label(c).begins_with("Serve"), "walking up to the customer offers to serve")
	game.customer_tap(c)
	t.check(c.state == "eat" and c.meal != null and game.carrying.is_empty(), "handing it over: the customer eats at their table")
	game.sim(2.0)
	t.check(Save.wallet - w0 > 900, "the customer paid (net %s after ingredients)" % G.yen(Save.wallet - w0))
	t.check(Save.reputation > 1.0, "a perfect quick meal lifts the café rating (%.2f)" % Save.reputation)
	game.sim(14.0)
	t.check(not game.shop.customers.has(c), "the customer walks back out the door")
	# ---- staff meal restores energy
	Save.energy = 40.0
	var g2 := G.merge_foods([G.new_food("egg"), G.new_food("flour"), G.new_food("milk")], "mix")
	G.apply_proc(g2, "fry", 0.8)
	game.stations.plate.add_item(g2)
	game.serve()
	game.hud.close_all()
	game.eat_carried()
	t.check(Save.energy > 55.0 and game.carrying.is_empty(), "eating a staff meal gives energy (%.0f)" % Save.energy)
	# ---- other stations
	game.open_station("board")
	var board: BoardStation = game.stations.board
	board.add_item(G.new_food("tomato"))
	game._update_camera(0.0, true)
	var tp := game.screen_pos(board.world_slot(0, 1) + Vector3(0, 0.03, 0))
	for i in 3:
		board.pointer_down(tp)
		board.pointer_up(tp)
	t.check(board.items.is_empty() and game.counter.back().hist.has("chop"), "three taps chop a tomato")
	var micro: MicroStation = game.stations.micro
	game.open_station("micro")
	micro.add_item(G.new_food("kernels"))
	micro.press(4); micro.press(10)
	micro.press(11)
	game.sim(15.0)
	t.check(game.counter.back().recipe >= 0 and G.RECIPES[game.counter.back().recipe].n == "Popcorn", "the microwave pops Popcorn")
	# ---- pantry
	game.counter.clear()
	Save.pantry = {"egg": 2}
	var w1 := Save.wallet
	game.add_ingredient("egg")
	t.check(Save.wallet == w1 and int(Save.pantry.get("egg", 0)) == 1, "market pantry stock is used before paying for delivery")
	game.counter.append(G.new_food("tomato"))
	game.open_station("bin")
	var n0 := game.counter.size()
	game.counter_tap(0)
	t.check(game.counter.size() == n0 - 1, "the bin throws food away")
	# ---- critic
	var cr := Customer.new()
	cr.setup({"id": 99, "name": "Critic Kuroda", "kind": "critic", "look": Shop.CRITICS[0].look})
	cr.set_meta("paper", "The Hoshizora Times")
	game.cafe.add_child(cr)
	var rep0 := Save.reputation
	var rv: Dictionary = game.shop._review(cr, hard[0], "perfect", true)
	t.check(rv.stars >= 4 and Save.reputation > rep0 and Story.done("critic4"), "a perfect, quick, ambitious dish earns a %d-star review" % rv.stars)
	var rv2: Dictionary = game.shop._review(cr, easy, "burnt", false)
	t.check(rv2.stars == 1, "burnt, slow and easy gets one star")
	cr.queue_free()
	game.shop.close_day()
	t.check(game.hud.modal_open() and not game.shop.open, "closing shows the day summary")
	game.hud.close_all()
	# ---- edit mode
	Save.furni_inv = {"table2": 1}
	var seats0 := game.shop.seats()
	t.check(game.edit.start(), "edit mode opens in the café when it's closed")
	game.edit.hold_new("table2")
	game.edit._update_ghost(Vector3(2.9, 0, 0.6))
	var ok := game.edit._ok
	game.edit._place()
	game.edit.stop()
	t.check(ok and game.shop.seats() == seats0 + 2 and not Save.furni_inv.has("table2"), "placing a new table adds two seats (%d → %d)" % [seats0, game.shop.seats()])
	game.edit.start()
	var it := game.cafe.furni.pick(Vector3(2.9, 0, 0.6))
	game.edit._pick_up(it)
	game.edit.store()
	game.edit.stop()
	t.check(game.shop.seats() == seats0 and Save.furni_inv.get("table2", 0) == 1, "storing it takes it back")
	# ---- town life
	game.travel_now("city", "cafe")
	Save.rel = {}
	game.life.chat("hana")
	t.check(Save.hearts("hana") == 0.5 and Save.r("hana").talks == 1, "chatting with Hana: +½ heart")
	game.life.chat("hana")
	t.check(Save.hearts("hana") == 0.5, "only the first chat each day counts")
	Save.gifts = {"roses": 1}
	game.life.give("hana", "roses")
	t.check(Save.hearts("hana") == 2.5 and Save.gifts.is_empty() and Story.done("gift"), "roses are Hana's favourite: +2 hearts")
	Save.r("hana").hearts = 4.5
	Save.wallet = 50000
	Save.minute = 900.0
	game.life.go_date("hana", "picnic")
	t.check(game.loc == game.city and game.city._couple == "hana" and game.player.sitting and game.city._blanket.visible, "a picnic date: sitting on a blanket under the cherry trees")
	for k in 2:
		var q: Array = game.life._date_state.qs[game.life._date_state.i]
		game.life._date_answer("hana", int(q[2]), q)
	t.check(int(Save.r("hana").dates) == 1 and Save.hearts("hana") >= 6.5 and not game.player.sitting, "two great answers on Hana's favourite kind of date (%.1f hearts)" % Save.hearts("hana"))
	# every kind of date stages its scene
	var staged := []
	for ty in People.DATE_TYPES:
		Save.wallet = 50000
		game.life.go_date("kai", ty)
		var st_ok: bool = (game.city._couple == "kai" and game.player.sitting or game.city._couple == "kai") if game.loc == game.city else (game._date_guest != null and game._date_guest.visible)
		if st_ok: staged.append(ty)
		for k in 2:
			var q: Array = game.life._date_state.qs[game.life._date_state.i]
			game.life._date_answer("kai", 0, q)
	t.check(staged.size() == People.DATE_TYPES.size() and game._date_guest == null, "all %d date types set their scene (%s)" % [People.DATE_TYPES.size(), ", ".join(staged)])
	game.travel_now("city", "park")
	Save.r("kai").hearts = 2.0
	Save.r("kai").romance = false
	game.life.ask_partner("hana")
	t.check(Save.partner == "hana", "Hana says yes to being partners")
	Save.has_ring = true
	game.life.propose("hana")
	t.check(Save.flags.get("wedding", false) and not Save.has_ring, "proposing with the ring sets a wedding date")
	game.life.new_day()
	game.life.morning()
	game.sim(1.0)
	t.check(Save.married and Story.done("married"), "the wedding in the park the next morning")
	game.city.wedding(false)
	# ---- family
	game.travel_now("home", "door")
	t.check(game.home.family.size() == 1, "your spouse lives with you now")
	game.home.furni.add("bed", -2.6, -0.3, 0)
	game.home.furni.add("crib", 2.6, -2.0, 0)
	Save.minute = 21 * 60.0
	var d0 := Save.day
	game.life.start_family()
	t.check(int(Save.family.expecting) == d0 + 4 and Save.day == d0 + 1 and game.loc == game.home, "the family talk at bedtime: fade to black, and a baby is on the way")
	for i in 3:
		game.life.new_day()
		game.life.morning()
	game.sim(1.5)
	t.check(Save.family.kids.size() == 1 and int(Save.family.expecting) == -1 and game.home.family.size() == 2, "the baby is born and named (%d kids)" % Save.family.kids.size())
	t.check(Life.kid_stage(Save.family.kids[0]) == "baby", "newborns are babies")
	for i in 10: game.life.new_day()
	t.check(Life.kid_stage(Save.family.kids[0]) == "child", "…and grow into children")
	# ---- drama: flirting, secrets, getting caught, divorce, gossip, houses
	game.hud.close_all()
	game.travel_now("city", "home")
	Save.minute = 11 * 60.0
	Save.r("ren").hearts = 4.0
	game.life.rng.seed = 3
	for i in 6:
		Save.r("ren").flirted = -1
		game.life.flirt("ren")
	t.check(Save.hearts("ren") >= 5.0 and game.life.is_lover("ren") and game.life.cheating_with("ren"), "flirting while married: Ren becomes your secret sweetheart (%.1f)" % Save.hearts("ren"))
	Save.r("ren").dated = -1
	game.life.go_date("ren", "books")
	for k in 2:
		var q: Array = game.life._date_state.qs[game.life._date_state.i]
		game.life._date_answer("ren", 1, q)
	t.check(int(Save.r("ren").dates) >= 1, "a secret date with Ren")
	var dr_h0 := Save.hearts("hana")
	game.life.caught("ren", "on a date with")
	game.life._after_caught("hana", "ren", -3.0, true)
	t.check(Save.hearts("hana") <= dr_h0 - 3.0 + 0.01 and not game.life.is_lover("ren") and Save.married, "getting caught: Hana is hurt, you promise to stop (%.1f → %.1f)" % [dr_h0, Save.hearts("hana")])
	Save.r("hana").cheated = 2
	game.life.caught("kai", "flirting with")
	game.life._after_caught("hana", "kai", -4.0, false)
	t.check(not Save.married and Save.partner == "" and Save.r("hana").ex and game.home.family.size() == Save.family.kids.size(), "caught a third time: divorce, Hana moves out, the kids stay")
	# gossip about a friend gets back to them
	Save.r("kai").hearts = 5.0
	Save.r("yuki").hearts = 5.0
	game.life.rng.seed = 1
	var dr_heard := false
	for i in 12:
		Save.r("kai").gossiped = -1
		game.life.gossip("kai", "yuki")
		if Save.r("yuki").has("heard_from"):
			dr_heard = true
			break
	t.check(dr_heard and Save.hearts("kai") > 5.0, "gossiping with Kai about Yuki (Kai likes it)")
	var dr_y0 := Save.hearts("yuki")
	game.life.talk("yuki")
	t.check(Save.hearts("yuki") < dr_y0 and not Save.r("yuki").has("heard_from"), "…and Yuki finds out what you said")
	# a night at Kai's place and a surprise baby
	game.life.cheat("fertile")
	Save.r("kai").hearts = 8.0
	Save.r("kai").romance = true
	Save.minute = 21.5 * 60.0
	game.enter_house("kai", false)
	t.check(game.loc == game.npc_house and game.npc_house.host == "kai" and game.npc_house.host_node != null, "knock at Kai's cottage at night and go in")
	var dr_kids0: int = Save.family.kids.size()
	game.life.stay_night("kai")
	t.check(Save.family.get("others", []).size() == 1 and game.loc == game.npc_house, "stay the night (fade to black), wake up at Kai's")
	for i in 5:
		game.life.new_day()
		game.life.morning()
		game.sim(1.2)
	t.check(Save.family.kids.size() >= dr_kids0 + 1 and Save.family.kids.back().get("parent", "") == "kai", "days later Kai arrives with your baby")
	game.life.cheat("fertile")
	# town drama: townsfolk pair up and have babies; your partner strays
	game.life.cheat("matchmaker")
	Save.flags.erase("couples")
	var news: Array = game.life.drama_day()
	game.life.cheat("matchmaker")
	var couples: Array = Save.flags.get("couples", [])
	t.check(couples.size() == 1 and news.size() >= 1, "two townsfolk fall for each other: %s" % (news[0][1] if news.size() else "nothing"))
	couples[0][2] = Save.day - 10
	game.life.rng.seed = 2
	for i in 30:
		game.life.drama_day()
		if Save.flags.get("npc_babies", []).size() or Save.flags.get("npc_kids", []).size(): break
	t.check(Save.flags.get("npc_babies", []).size() + Save.flags.get("npc_kids", []).size() >= 1, "a townsfolk couple has a baby on the way")
	Save.day += 6
	game.life.drama_day()
	Save.day -= 6
	t.check(Save.flags.get("npc_kids", []).size() >= 1, "…and the baby is born")
	Save.partner = "yuki"
	Save.r("yuki").hearts = 3.0
	Save.flags.erase("affair")
	game.life.cheat("drama")
	game.life.drama_day()
	t.check(Save.flags.get("affair", {}).size() > 0, "a neglected partner starts seeing someone else (%s)" % Save.flags.get("affair", {}).get("with", "?"))
	Save.minute = 14 * 60.0
	game.travel_now("city", "park")
	game.life._check_affair()
	var yn: Chibi = game.city.people.yuki
	t.check(yn.visible and yn.global_position.distance_to(Vector3(-0.3, 0, 10.4)) < 0.1, "you can spot them together by the fountain in the afternoon")
	game.life.spot_affair()
	t.check(Save.flags.affair.seen, "spotting them triggers the scene")
	Save.flags.affair.day = Save.day - 5
	game.life.drama_day()
	game.life.cheat("drama")
	t.check(Save.flags.get("affair_baby_reveal", false), "…and later there's going to be a baby")
	game.life.break_up(true)
	game.city.affair_scene(false)
	Save.flags.erase("affair")
	Save.flags.erase("affair_baby_reveal")
	# sneaking into Yuki's house
	game.hud.close_all()
	Save.minute = 23.5 * 60.0
	game.life.cheat("sneaky")
	game.travel_now("city", "home")
	game.life.sneak("yuki")
	t.check(game.loc == game.npc_house and game.sneaking and Life.npc_asleep("yuki"), "sneak into Yuki's house while she sleeps")
	var dr_w0 := Save.wallet
	game.life.rng.seed = 5
	game.life.snoop("yuki")
	t.check(int(Save.r("yuki").snooped) == Save.day, "snoop around (found something: %s)" % ("money" if Save.wallet > dr_w0 else "a secret"))
	game.life.cheat("sneaky")
	var dr_y1 := Save.hearts("yuki")
	game.life.caught_sneaking("yuki")
	t.check(game.loc == game.city and Save.hearts("yuki") <= maxf(0.0, dr_y1 - 2.9) and not game.sneaking, "caught sneaking: thrown out, hearts lost (%s, %.1f→%.1f, sneaking %s, cutscene %s)" % [game.loc.key, dr_y1, Save.hearts("yuki"), game.sneaking, game.cutscene])
	game.hud.close_all()
	# ---- festival night, jobs, moving in, a baby with a sweetheart, buying a house
	game.hud.close_all()
	Save.flags["event"] = "festival"
	Save.minute = 19 * 60.0
	game.travel_now("city", "cafe")
	game.city.tick(0.1)
	t.check(game.city.festival_on and game.city.interacts.any(func(it): return it.id == "fest_takoyaki") and game.city.reachable(Vector3(-9, 0, 2.1)), "festival night: stalls on Main Street you can walk up to")
	var mg: Minigames = game.hud.minigames
	var w_t := Save.wallet
	game.life.festival_job()
	t.check(mg.active == "takoyaki", "run the takoyaki stall")
	for i in 8: mg._tako_click(mg._state.holes[i])
	mg._tako_tick(4.5)
	for i in 8: mg._tako_click(mg._state.holes[i])
	mg._state.orders[0].n = 6
	mg._tako_serve()
	mg._finish()
	t.check(Save.wallet > w_t + 500 and mg.active == "", "a box of perfect takoyaki earns money (%s)" % G.yen(Save.wallet - w_t))
	Save.wallet = 5000
	game.life.festival_game()
	for i in 20:
		if mg.active != "goldfish": break
		if mg._state.fish.size(): mg._scoop(mg._state.fish[0])
	if mg.active != "": mg._finish()
	t.check(Save.wallet == 4700, "goldfish scooping costs ¥300")
	game.life.festival_mask()
	t.check(Save.player_look.acc == "fox", "a fox mask from the festival")
	Save.flags["event"] = ""
	Save.minute = 10 * 60.0
	Save.energy = 100.0
	w_t = Save.wallet
	game.life.start_job("books")
	for n in range(1, 9):
		for b in mg._state.row.get_children():
			if b is Button and b.text == str(n) and not b.disabled:
				b.pressed.emit()
				break
	mg._finish()
	t.check(Save.wallet >= w_t + 350 and game.life.job_done_today("books"), "a shelving shift at Ren's pays")
	game.life.start_job("bouquets")
	mg._state.pick = mg._state.want.duplicate()
	mg._bq_submit()
	t.check(int(mg._state.made) == 1, "a bouquet made exactly as asked")
	mg._finish()
	w_t = Save.wallet
	game.life.start_job("delivery")
	t.check(game.life.delivery.queue.size() == 3 and game.player.carried != null and game.city.interacts.any(func(it): return it.id == "delivery"), "a delivery shift: carry a crate to a door across town")
	for i in 3: game.life.deliver_crate()
	t.check(Save.wallet >= w_t + 1050 and game.life.delivery.is_empty() and game.player.carried == null, "three deliveries done (%s)" % G.yen(Save.wallet - w_t))
	game.life.start_job("delivery")
	t.check(game.life.delivery.is_empty(), "one delivery shift per day")
	# moving in with a sweetheart, and asking for a baby
	game.hud.close_all()
	Save.r("kai").hearts = 9.0
	Save.r("kai").romance = true
	game.life.move_in("kai")
	t.check(Save.partner == "kai" and Save.flags.get("live_with", "") == "kai", "move in with Kai")
	game.life.sleep()
	t.check(game.loc == game.npc_house and game.npc_house.host == "kai" and game.npc_house.interacts.any(func(it): return it.id == "bed"), "you wake up at Kai's place now")
	Save.minute = 21 * 60.0
	Save.family.others = []
	game.life.ask_baby("kai")
	t.check(Save.family.others.any(func(o): return o.with == "kai"), "ask Kai for a baby together (fade to black)")
	game.life.move_out()
	# buying the house
	Save.wallet = 150000
	var n_items: int = Save.layouts.home.size()
	game.life.buy_house()
	t.check(Save.home_kind == "house" and game.home.kind == "house" and Save.wallet == 30000, "buy the house on the corner for ¥120,000")
	t.check(Save.layouts.home.size() + Save.furni_inv.size() >= n_items and NavReport.check(game.home, game.home.entry_point("door"), NavReport.points_for(game.home)).is_empty(), "your furniture moves with you and the house is walkable %s" % str(NavReport.check(game.home, game.home.entry_point("door"), NavReport.points_for(game.home))))
	game.hud.close_all()
	# ---- shop interiors, the clinic, and four more jobs
	Save.minute = 23 * 60.0
	game.travel_now("city", "market")
	game.enter_shop("market")
	t.check(game.loc == game.city, "shops are closed late at night")
	game.hud.close_all()
	Save.minute = 11 * 60.0
	Save.energy = 100.0
	game.enter_shop("florist")
	t.check(game.loc == game.shop_loc and game.shop_loc.shop == "florist" and game.shop_loc.keeper_node != null and String(game.shop_loc.keeper_node.get_meta("npc")) == "hana", "walk into Hana's Flowers: Hana is behind the counter at 11am")
	t.check(not game.city.people.hana.visible or game.loc != game.city, "…and not out on the street at the same time")
	game.leave_shop()
	game.enter_shop("clinic")
	t.check(game.loc == game.shop_loc and game.shop_loc.keeper_node != null, "the clinic, with Dr. Mori")
	Save.wallet = 50000
	var kc: int = Save.family.kids.size()
	game.life.adopt("toddler")
	t.check(Save.family.kids.size() == kc + 1 and Life.kid_stage(Save.family.kids.back()) == "toddler" and Save.family.kids.back().get("adopted", false), "adopt a toddler")
	Save.partner = "yuki"
	game.life.fertility_visit()
	t.check(Life.fertile() and Save.wallet == 37000, "a fertility visit (a baby is very likely for a week)")
	Save.partner = ""
	game.life.checkup()
	var mg2: Minigames = game.hud.minigames
	var w35 := Save.wallet
	game.life.start_job("tailoring")
	mg2._state.pick = mg2._state.want.duplicate()
	mg2._tl_submit()
	t.check(int(mg2._state.made) == 1, "sew an outfit exactly to order")
	mg2._finish()
	game.life.start_job("gems")
	var cell: Dictionary = mg2._state.cells[0]
	cell.t = 1.0
	mg2._gem_click(cell)
	t.check(int(mg2._state.polished) == 1, "polish a sparkling gem")
	mg2._finish()
	game.life.start_job("assembly")
	mg2._state.show = -1
	for step_i in mg2._state.seq.duplicate(): mg2._asm_press(step_i)
	t.check(int(mg2._state.built) == 1, "repeat the assembly steps")
	mg2._finish()
	game.life.start_job("nursery")
	mg2._state.babies[0].cry = 1.0
	mg2._soothe(mg2._state.babies[0])
	t.check(int(mg2._state.soothed) == 1, "rock a crying baby back to sleep")
	mg2._finish()
	t.check(Save.wallet > w35 + 600, "four more jobs pay (%s)" % G.yen(Save.wallet - w35))
	game.leave_shop()
	game.hud.close_all()
	# ---- sleep & time
	game.hud.close_all()
	Save.minute = 600.0
	Save.energy = 50.0
	game.sim(10.0)
	t.check(Save.minute >= 609.0 and Save.energy < 50.0, "time passes one game minute per second and energy drains")
	var d1 := Save.day
	game.life.sleep()
	t.check(Save.day == d1 + 1 and Save.energy == 100.0 and Save.minute == 420.0 and game.loc == game.home, "sleeping ends the day: 7am, full energy, at home")
	# ---- cheats
	var w2 := Save.wallet
	t.check(game.life.cheat("KaChing") != "Unknown code" and Save.wallet == w2 + 10000, "cheat kaching: +¥10,000")
	game.life.cheat("cookbook")
	t.check(Save.found_count() == G.RECIPES.size(), "cheat cookbook: every recipe found")
	t.check(game.life.cheat("nope") == "Unknown code" and Save.cheats_used, "unknown codes are rejected")
	# ---- save round trip
	Save.save()
	var snap := Save.wallet
	Save.wallet = 1
	Save.load_game()
	t.check(Save.wallet == snap and Save.r("hana").ex and Save.family.kids.size() >= 2, "the save file round-trips the new life")
	Save.reset()
	game.queue_free()
