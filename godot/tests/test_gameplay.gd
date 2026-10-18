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
	game.sim(5.0)
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
	game.sim(7.0)
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
	game.life.date("hana")
	t.check(game.loc == game.city and game.city._couple == "hana" and game.player.sitting, "a date: sitting on the park bench together")
	game.life._date_answer("hana", 2, People.DATES.hana[0])
	t.check(int(Save.r("hana").dates) == 1 and Save.hearts("hana") >= 6.0 and not game.player.sitting, "the best answer on a date: +1.5 hearts (%.1f)" % Save.hearts("hana"))
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
	game.life.date("ren")
	game.life._date_answer("ren", 1, People.DATES.ren[0])
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
	t.check(Save.family.kids.size() == dr_kids0 + 1 and Save.family.kids.back().get("parent", "") == "kai", "days later Kai arrives with your baby")
	game.life.cheat("fertile")
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
	t.check(Save.wallet == snap and Save.r("hana").ex and Save.family.kids.size() == 2, "the save file round-trips the new life")
	Save.reset()
	game.queue_free()
