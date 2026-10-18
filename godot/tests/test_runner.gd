extends Node
## Headless test suite: `tools/gd.sh test`. Exits with code 1 if anything fails.

var failed := 0
var passed := 0

func check(ok: bool, msg: String) -> void:
	if ok:
		passed += 1
		print("PASS  ", msg)
	else:
		failed += 1
		printerr("FAIL  ", msg)

func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	test_recipes()
	test_steps_and_specs()
	if has_method("test_art"): call("test_art")
	if ResourceLoader.exists("res://tests/test_gameplay.gd"):
		var gp: Node = load("res://tests/test_gameplay.gd").new()
		add_child(gp)
		await gp.run(self)
	if ResourceLoader.exists("res://tests/test_playthrough.gd") and not OS.get_cmdline_user_args().has("--quick"):
		var pt: Node = load("res://tests/test_playthrough.gd").new()
		add_child(pt)
		await pt.run(self)
	print("\n%d passed, %d failed (%d ms)" % [passed, failed, Time.get_ticks_msec() - t0])
	get_tree().quit(1 if failed else 0)

func test_art() -> void:
	var empty: Array = []
	var verts := 0
	for k in G.ING_KEYS:
		var m := FoodArt.ingredient_mesh(k)
		if m.get_surface_count() == 0: empty.append(k)
		var p := FoodArt.piece_mesh(k)
		if p.get_surface_count() == 0: empty.append(k + " piece")
	check(empty.is_empty(), "all 59 ingredients and pieces build%s" % ("" if empty.is_empty() else ": " + ", ".join(empty)))
	empty.clear()
	for r in G.RECIPES:
		var m := FoodArt.spec_mesh(G.recipe_spec(r))
		if m.get_surface_count() == 0: empty.append(r.n)
		else: verts += m.surface_get_array_len(0)
	check(empty.is_empty(), "all 100 dishes build (avg %d verts)%s" % [verts / 100, "" if empty.is_empty() else ": " + ", ".join(empty)])
	var unb: Array = []
	for r in G.RECIPES:
		var mb := MB.new()
		DishArt.build(mb, G.recipe_spec(r))
		if mb.unbalanced or mb.stack_depth(): unb.append("%s(%d/%d)" % [r.n, mb.unbalanced, mb.stack_depth()])
	check(unb.is_empty(), "dish builders balance push/pop%s" % ("" if unb.is_empty() else ": " + ", ".join(unb)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var procs := ["chop", "mix", "blend", "roll", "boil", "fry", "bake", "zap", "freeze"]
	var bad := 0
	for i in 200:
		var foods: Array = []
		for j in rng.randi_range(1, 4):
			foods.append(G.new_food(G.ING_KEYS[rng.randi() % G.ING_KEYS.size()]))
		var f: Dictionary = G.merge_foods(foods, procs[rng.randi() % procs.size()], rng.randf() * 1.6)
		if rng.randf() < 0.4:
			f = G.merge_foods([f], procs[rng.randi() % procs.size()], rng.randf() * 1.6)
		var m := FoodArt.spec_mesh(G.food_spec(f))
		if m.get_surface_count() == 0: bad += 1
	check(bad == 0, "200 random generic foods all build a mesh (%d empty)" % bad)

func comps_for(r: Dictionary) -> Array:
	var out: Array = []
	for g in r.groups:
		for ing in g.ings:
			out.append({"ing": ing, "tags": g.tags.map(func(t): return "boil" if t == "hot" else "mix" if t == "stir" else t)})
	return out

func test_recipes() -> void:
	check(G.RECIPES.size() == 100, "100 recipes parsed (%d)" % G.RECIPES.size())
	check(G.ING.size() == 59, "59 ingredients (%d)" % G.ING.size())
	var bad: Array = []
	for r in G.RECIPES:
		var d: Dictionary = G.detect(comps_for(r))
		if not (d.has("match") and d.match.r.id == r.id):
			bad.append(r.n + (" -> " + d.match.r.n if d.has("match") else ""))
	check(bad.is_empty(), "every recipe detects as itself%s" % ("" if bad.is_empty() else ": " + ", ".join(bad)))
	# near miss: pancakes without frying
	var d2: Dictionary = G.detect([{"ing": "egg", "tags": ["mix"]}, {"ing": "flour", "tags": ["mix"]}, {"ing": "milk", "tags": ["mix"]}])
	check(d2.has("near") and d2.near.r.n == "Fluffy Pancakes", "unfried batter is a near miss for pancakes")
	check(G.missing_text(d2.near).begins_with("fry"), "near-miss hint says to fry (%s)" % G.missing_text(d2.near))
	var unpriced := G.RECIPES.filter(func(r): return not G.MENU_PRICE.has(r.n))
	check(unpriced.is_empty(), "every recipe has a menu price")

func test_steps_and_specs() -> void:
	var ok := true
	for r in G.RECIPES:
		var steps: Array = G.build_steps(r)
		if steps.size() < 2 or steps[0].check.type != "have" or steps[steps.size() - 1].check.type != "plate":
			ok = false
			printerr("  bad steps for ", r.n)
	check(ok, "steps build for every recipe")
	var p: Array = G.build_steps(G.RECIPES[0])
	check(p[1].text == "Mix the egg, flour and milk in the bowl." and p[2].text == "Fry the batter in the pan.", "pancake steps read naturally (%s / %s)" % [p[1].text, p[2].text])
	var arts := {}
	for r in G.RECIPES:
		var sp: Dictionary = G.recipe_spec(r)
		arts[sp.art] = true
	check(arts.size() == 19, "recipe specs cover %d art types" % arts.size())
	# generic specs for every process on random combos
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var procs := ["chop", "mix", "blend", "roll", "boil", "fry", "bake", "zap", "freeze"]
	var n := 0
	for i in 300:
		var foods: Array = []
		for j in rng.randi_range(1, 4):
			foods.append(G.new_food(G.ING_KEYS[rng.randi() % G.ING_KEYS.size()]))
		var f: Dictionary = G.merge_foods(foods, procs[rng.randi() % procs.size()], rng.randf() * 1.6)
		var sp: Dictionary = G.food_spec(f)
		if sp.has("art"): n += 1
		G.invent_name([f])
	check(n == 300, "300 random cooked foods all get a look")
	var pan: Dictionary = G.merge_foods([G.new_food("egg"), G.new_food("flour"), G.new_food("milk")], "mix")
	check(G.food_spec(pan).art == "bowl" and G.food_spec(pan).style == "batter", "mixed egg+flour+milk looks like batter")
	G.apply_proc(pan, "fry", 0.8)
	check(pan.recipe >= 0 and G.RECIPES[pan.recipe].n == "Fluffy Pancakes" and pan.q == "perfect", "frying batter at 0.8 makes perfect pancakes")
	check(G.yen(1234567) == "¥1,234,567" and G.yen(-50) == "−¥50", "yen formatting")
