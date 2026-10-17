extends Node
## Plays the game through its real stations and shop, headless (like tests/smoke.mjs).

func run(t) -> void:
	var game: Game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.hud.hide_title()
	var w0: int = Save.wallet
	# 1. open the shop, a customer comes in and orders pancakes
	game.shop.toggle()
	game.shop.spawn()
	game.sim(12.0)
	var c: Customer = game.shop.customers[0]
	t.check(c.state == "wait", "a customer walks in and sits down (%s)" % c.state)
	game.shop.take_order(c)
	game.hud.close_all()
	var pancakes: Dictionary = G.RECIPES.filter(func(r): return r.n == "Fluffy Pancakes")[0]
	c.order = pancakes.id
	game.shop.set_active(c)
	game.buy_for(pancakes, c)
	t.check(game.stations.bowl.items.size() == 3, "Buy all puts egg, flour and milk into the bowl (%d)" % game.stations.bowl.items.size())
	t.check(game.open_key == "bowl", "camera moves to the bowl")
	# 2. stir with real circular pointer gestures
	var bowl: BowlStation = game.stations.bowl
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
	t.check(game.next_hint().get("tool", "") == "pan", "the guide points to the Pan next")
	# 3. fry: counter -> pan, start, cook into the perfect zone, take out
	game.open_station("pan")
	game.counter_tap(0)
	var pan: PanStation = game.stations.pan
	t.check(pan.items.size() == 1, "tapping the counter moves the batter into the pan")
	pan.on_btn()
	t.check(pan.run, "the pan heats up")
	game.sim(5.0)
	t.check(pan.status() == "ready", "after 5s the pan says ready (%s, cook %.2f)" % [pan.status(), pan.cook])
	pan.on_btn()
	var f: Dictionary = game.counter[0]
	t.check(f.recipe == pancakes.id and f.q == "perfect", "perfect Fluffy Pancakes come out (%s, %s)" % [f.recipe, f.q])
	# 4. plate and serve
	game.open_station("plate")
	game.counter_tap(0)
	var b: Dictionary = game.stations.plate.btn()
	t.check(b.get("label", "").begins_with("Serve "), "the plate offers to serve the customer (%s)" % b.get("label", ""))
	game.serve()
	t.check(c.state == "eat", "the customer receives the order")
	game.sim(2.0)
	t.check(Save.wallet - w0 > 900, "the customer paid (net %s after ingredients)" % G.yen(Save.wallet - w0))
	game.sim(8.0)
	t.check(not game.shop.customers.has(c) or c.state == "leave", "the customer leaves happy")
	# 5. chop with a swipe, roll sushi, blend, freeze, micro popcorn, oven cookies
	game.open_station("board")
	var board: BoardStation = game.stations.board
	board.add_item(G.new_food("tomato"))
	var tp := game.screen_pos(board.world_slot(0, 1) + Vector3(0, 0.03, 0))
	for i in 3:
		board.pointer_down(tp)
		board.pointer_up(tp)
	t.check(board.items.is_empty() and game.counter.back().hist.has("chop"), "three taps chop a tomato")
	var micro: MicroStation = game.stations.micro
	game.open_station("micro")
	micro.add_item(G.new_food("kernels"))
	micro.press(4); micro.press(10)
	t.check(micro.buf == "50", "keypad types 0:50 (%s)" % micro.buf)
	micro.press(11)
	t.check(micro.run, "▶ starts the microwave")
	game.sim(7.0)
	var pop: Dictionary = game.counter.back()
	t.check(pop.recipe >= 0 and G.RECIPES[pop.recipe].n == "Popcorn", "the microwave pops Popcorn")
	var oven: OvenStation = game.stations.oven
	game.open_station("oven")
	for k in ["flour", "butter", "sugar", "chocolate"]: oven.add_item(G.new_food(k))
	oven.on_btn()
	t.check(oven.run, "the oven bakes")
	game.sim(7.0)
	oven.on_btn()
	t.check(game.counter.back().recipe < 0, "unmixed cookie ingredients bake into an invention, not cookies (%s)" % G.invent_name([game.counter.back()]))
	# 6. counter limit and bin
	game.counter.clear()
	for i in 10: game.add_ingredient("egg")
	t.check(game.counter.size() + game.current().items.size() >= 8, "fridge fills station then counter")
	game.open_station("bin")
	var n0 := game.counter.size()
	game.counter_tap(0)
	t.check(game.counter.size() == n0 - 1, "tapping the counter with the bin open throws food away")
	# 7. day summary
	game.shop.close_day()
	t.check(game.hud.modal_open(), "closing the shop shows the day summary")
	game.hud.close_all()
	Save.reset()
	game.queue_free()
