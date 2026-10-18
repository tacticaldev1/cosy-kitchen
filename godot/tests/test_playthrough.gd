extends Node
## A bot plays the game like a person: it walks everywhere along real paths (no teleporting),
## presses E at doors, stations and people, clicks the real UI buttons, cooks whatever the
## customers order with each station's buttons, carries the plates out, shops, dates, marries
## and starts a family. It also watches for movement bugs: walking into blocked cells, getting
## stuck, or never arriving.

const DT := 1.0 / 60.0

var t
var game: Game
var walk_issues: Array = []
var cooked := {}
var failed_cooks: Array = []

func run(tr) -> void:
	t = tr
	Save.reset()
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.skip_fx = true
	await new_life()
	await day_one()
	await chapter_two_and_three()
	await love_and_family()
	t.check(walk_issues.is_empty(), "no movement bugs during the playthrough%s" % ("" if walk_issues.is_empty() else ": " + "; ".join(walk_issues.slice(0, 6))))
	t.check(failed_cooks.is_empty(), "the bot cooked %d different dishes with the station buttons%s" % [cooked.size(), "" if failed_cooks.is_empty() else ", failed: " + ", ".join(failed_cooks)])
	Save.reset()
	game.queue_free()

# ================================================================ helpers
func step(sec: float) -> void:
	for i in int(sec * 60.0):
		game._step(DT)
		game._update_focus()

## Clicks a visible button whose text starts with `prefix` anywhere in the HUD.
func press(prefix: String) -> bool:
	var scope: Node = game.hud._modals.back() if game.hud._modals.size() else game.hud.root
	var b := _find(scope, prefix)
	if b == null: return false
	b.pressed.emit()
	return true

func _find(n: Node, prefix: String) -> Button:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree(): return null
	if n is Button and (n as Button).text.begins_with(prefix) and not (n as Button).disabled: return n
	for c in n.get_children():
		var r := _find(c, prefix)
		if r: return r
	return null

func dialogue_open() -> bool:
	return game.hud.life.is_open()

## Clicks through dialogue until it closes or asks a question.
func read_all(guard := 60) -> void:
	for i in guard:
		if not dialogue_open(): return
		if game.hud.life.dlg_opts.get_child_count() > 0: return
		game.hud.advance_dialogue()
		game.hud.advance_dialogue()
		step(0.05)

func choose(prefix: String) -> bool:
	for b in game.hud.life.dlg_opts.get_children():
		if b is Button and (b as Button).text.begins_with(prefix):
			(b as Button).pressed.emit()
			step(0.05)
			return true
	return false

func answer_text(txt := "") -> void:
	var le: LineEdit = game.hud.life._text_input
	if le:
		if txt != "": le.text = txt
		le.text_submitted.emit(le.text)

## Walks the player to a point along the real path, checking every frame that we stay on
## walkable ground and keep making progress.
func walk(target: Vector3, what: String, max_sec := 60.0) -> bool:
	var nav := game.loc.nav
	var goal := nav.nearest_free(target)
	game.player.go_to(goal)
	var last := game.player.global_position
	var still := 0.0
	var off_grid := 0
	for i in int(max_sec * 60.0):
		game._step(DT)
		var p := game.player.global_position
		if not nav.is_free(p) and not game.player.sitting: off_grid += 1
		if p.distance_to(last) < 0.0005 and game.player.walking: still += DT
		else: still = 0.0
		last = p
		if still > 1.5:
			walk_issues.append("stuck walking to %s at (%.2f, %.2f)" % [what, p.x, p.z])
			break
		if not game.player.walking: break
	game._update_focus()
	var arrived := Vector2(game.player.global_position.x, game.player.global_position.z).distance_to(Vector2(goal.x, goal.z)) < 0.2
	if not arrived: walk_issues.append("never reached %s (%.1fm short)" % [what, game.player.global_position.distance_to(goal)])
	if off_grid > 6: walk_issues.append("walked through furniture/walls %d frames on the way to %s" % [off_grid, what])
	return arrived

## Walks to an interactable by id and presses E there.
func use(id: String) -> bool:
	var it := {}
	for x in game.loc.interacts:
		if x.id == id: it = x
	if it.is_empty():
		t.check(false, "there's a '%s' to use in %s" % [id, game.loc.key])
		return false
	walk(it.pos, id)
	for k in 6:   # like a player pressing Tab to aim at the right thing
		if game.focus.get("kind", "") == "it" and game.focus.it.id == id: break
		game.cycle_focus()
	if game.focus.get("kind", "") != "it" or game.focus.it.id != id:
		walk_issues.append("standing at '%s' but E would do '%s'" % [id, game.focus.get("label", "nothing")])
		it.act.call()
		return true
	game.interact()
	step(0.1)
	return true

## Walks up to a person and presses E.
func talk_to(n: Node3D) -> bool:
	game.leave_station()
	var to := n.global_position
	var p := game.player.global_position
	var stand := to + (Vector3(p.x, 0, p.z) - Vector3(to.x, 0, to.z)).normalized() * 0.6
	if n is Customer and n.has_meta("approach") and (n as Customer).sitting: stand = n.get_meta("approach")
	walk(stand, String(n.get_meta("label", n.get("cname") if n is Customer else "someone")))
	game._update_focus()
	if game.focus.get("kind", "") == "npc" and game.focus.n == n:
		game.interact()
	elif game.focus.get("kind", "") == "cust" and game.focus.c == n:
		game.interact()
	else:
		var extra := ""
		if n is Customer:
			var cu := n as Customer
			extra = " [%s %s state=%s sitting=%s pos=%s app=%s me=%s]" % [cu.cname, cu.ckind, cu.state, cu.sitting, cu.global_position, cu.get_meta("approach", Vector3.ZERO), game.player.global_position]
		walk_issues.append("next to %s but E points at %s%s" % [n.get_meta("label", n.name), game.focus.get("label", "nothing"), extra])
		return false
	step(0.1)
	return true

func travel(id: String, to: String) -> bool:
	use(id)
	step(0.2)
	return game.loc.key == to

# ================================================================ cooking
func walk_to_station(key: String) -> void:
	game.open_station(key)
	for i in 60 * 30:
		if game.open_key == key: return
		game._step(DT)
	walk_issues.append("never reached the %s station (at %s, stand %s, carrying %s, open '%s')" % [key, game.player.global_position, game.cafe.stand[key], game.carrying.size() > 0, game.open_key])

## Cooks one recipe for a customer using the real buttons. Returns true if served.
func cook_for(c: Customer) -> bool:
	var r: Dictionary = G.RECIPES[c.order]
	game.shop.set_active(c)
	game.hud.close_all()
	for guard in 24:
		var gd := game.guide()
		var s: Dictionary = gd.steps[gd.cur]
		match s.check.type:
			"have":
				game.hud.open_ticket(r.id, c)
				if not press("Buy"):
					t.check(false, "the order ticket has a Buy button")
					return false
				for i in 60 * 30:
					if not game.player.walking: break
					game._step(DT)
			"tag":
				var key: String = s.tool
				if game.open_key != key: walk_to_station(key)
				var st: Station = game.stations[key]
				var want := {}
				for k in s.check.ings: want[k] = true
				# clear out leftovers that don't belong in this step
				if st.items.any(func(f): return not G.food_ings(f).any(func(k): return want.has(k))):
					game.empty_station()
				for i in range(game.counter.size() - 1, -1, -1):
					var f: Dictionary = game.counter[i]
					if G.food_ings(f).any(func(k): return want.has(k)) and not G.comps_of([f]).all(func(cc): return not want.has(cc.ing) or G.tag_ok(cc, s.check.tag)):
						if st.items.size() < st.cap and not st.busy(): game.counter_tap(i)
				step(0.4)
				run_station(st)
			"plate":
				walk_to_station("plate")
				var st: Station = game.stations.plate
				for i in range(game.counter.size() - 1, -1, -1):
					var f: Dictionary = game.counter[i]
					if G.food_ings(f).any(func(k): return r.need.has(k)) and st.items.size() < st.cap: game.counter_tap(i)
				step(0.4)
				var b: Dictionary = st.btn()
				if not String(b.get("label", "")).begins_with("Serve"):
					failed_cooks.append("%s (plate said '%s'; steps %s; plate %s)" % [r.n, b.get("label", ""), str(G.build_steps(r).map(func(x): return x.text)), str(st.items.map(func(f): return [G.food_ings(f), f.hist, f.q, f.recipe]))])
					game.counter.clear()
					st.clear_items()
					game.stations.plate.refresh()
					return false
				game.hud.go_btn.pressed.emit()
				game.hud.close_all()
				if game.carrying.get("rid", -1) != r.id or c.state != "order": return false
				talk_to(c)
				cooked[r.n] = true
				return c.state == "eat"
	failed_cooks.append("%s (stuck at step: %s)" % [r.n, game.guide().steps[game.guide().cur].text])
	return false

## Presses the station's big button and waits for it to finish, taking hot food out in the green zone.
func run_station(st: Station) -> void:
	if st.items.is_empty(): return
	if st is OvenStation and not (st as OvenStation).can_start(): (st as OvenStation).prep()
	var b: Dictionary = st.btn()
	if b.size() and b.get("enabled", true): st.on_btn()
	for i in 60 * 40:
		game._step(DT)
		if st is HeatStation or st is MicroStation:
			if st.status() == "ready":
				st.on_btn()
				step(0.3)
				return
		elif st.items.is_empty() and not st.busy():
			step(0.3)
			return

# ================================================================ the story
func new_life() -> void:
	await get_tree().process_frame
	game.hud.show_title()
	t.check(press("New story"), "title screen: New story")
	step(0.1)
	t.check(press("Start my new life"), "character creator: start a new life")
	step(0.1)
	read_all()
	step(2.5)  # chapter banner + Grandma's letter
	read_all()
	t.check(Save.started and Save.mode == "story" and game.loc == game.home, "a new story begins at home")
	t.check(Save.player_look.has("body") and Save.player_look.has("bottom"), "the creator saved a body type (%s, %s)" % [Save.player_look.get("body"), Save.player_look.get("bottom")])

func day_one() -> void:
	await get_tree().process_frame
	t.check(travel("door", "city"), "walk out of the apartment into town")
	t.check(travel("door_cafe", "cafe"), "walk down the street and into the café")
	use("sign")
	t.check(not game.shop.open, "the café can't open before 8:00 am (%s)" % Save.time_text())
	for i in 200:
		if Save.minute >= 8 * 60.0 + 1.0: break
		game.hud.close_all()
		step(1.0)
	use("sign")
	game.hud.close_all()
	t.check(game.shop.open, "flip the OPEN sign at 8:00 am")
	var served := 0
	var tries := 0
	var want := int(Shot.arg("serve", "6"))
	var why := {}
	if want > 6: Save.stars_total = 400  # a seasoned chef gets the harder orders
	while served < want and tries < want * 2 + 2:
		if Save.minute > 21 * 60.0:
			Save.minute = 9 * 60.0  # stress runs keep the café open
		tries += 1
		var c: Customer = null
		for i in 60 * 60:
			game._step(DT)
			if i % 30 == 0: game.hud.close_all()  # a person would close the "new recipe!" card
			for x in game.shop.customers:
				if x.state == "wait": c = x
			if c: break
		if c == null:
			print("BOT no waiting customer: modal=%s open=%s minute=%.0f custs=%s seats=%d" % [game.hud.modal_open(), game.shop.open, Save.minute, str(game.shop.customers.map(func(x): return x.state)), game.shop.seats()])
			break
		talk_to(c)
		game.hud.close_all()
		if c.state != "order":
			why["no order"] = why.get("no order", 0) + 1
			continue
		if cook_for(c): served += 1
		else: why[c.state] = why.get(c.state, 0) + 1
		step(0.5)
		game.hud.close_all()
		read_all()
	if why.size(): print("BOT unserved reasons: ", why)
	t.check(served >= 5, "served %d customers by walking orders to their tables (%d tried)" % [served, tries])
	t.check(Save.served_total >= 3 and Story.done("cook_any") and Story.done("open_shop"), "story quests tick as you play")
	game.leave_station()
	use("sign")
	game.hud.close_all()
	t.check(not game.shop.open, "flip the sign to close")
	t.check(travel("door", "city"), "out into town again")
	# shopping: the market and the home store
	use("door_market")
	t.check(press("+5"), "buy five of something at the market")
	game.hud.close_all()
	t.check(Save.pantry.size() > 0 and Story.done("market") or Save.chapter > 1, "the pantry fills up")
	use("door_homestore")
	var w0 := Save.wallet
	t.check(press("¥"), "buy a piece of furniture at the Home Store")
	game.hud.close_all()
	t.check(Save.wallet < w0 and Save.furni_inv.size() > 0, "it goes into storage")
	t.check(travel("door_home", "home"), "walk home")
	use("bed")
	t.check(choose("Sleep"), "bed: Sleep until morning")
	step(0.3)
	read_all()
	game.hud.close_all()
	step(1.5)
	read_all()
	t.check(Save.day == 2 and game.loc == game.home and Save.energy >= 99.0, "a new day dawns at home (day %d, %s, energy %.0f, modal %s)" % [Save.day, game.loc.key, Save.energy, game.hud.modal_open()])
	step(1.5)
	read_all()
	step(2.0)
	read_all()
	t.check(Save.chapter >= 1, "chapter 1 complete after the first day (chapter %d)" % (Save.chapter + 1))

func chapter_two_and_three() -> void:
	await get_tree().process_frame
	# place the furniture we bought in the café
	t.check(travel("door", "city"), "day 2: out the door")
	t.check(travel("door_cafe", "cafe"), "into the café")
	t.check(game.edit.start(), "edit mode opens")
	var id: String = Save.furni_inv.keys()[0]
	game.edit.hold_new(id)
	var placed := false
	for p in [Vector3(2.9, 0, 1.5), Vector3(2.2, 0, 0.0), Vector3(3.5, 0, -0.2), Vector3(0.9, 0, 1.9)]:
		game.edit._update_ghost(p)
		if game.edit._ok:
			game.edit._place()
			if game.edit.held.is_empty():
				placed = true
				break
	game.edit.cancel()
	game.edit.stop()
	t.check(placed, "place the new %s somewhere that keeps the room walkable" % Furni.info(id).name)
	t.check(game.loc.nav.is_free(game.player.global_position), "you're never left standing inside furniture")
	t.check(travel("door", "city"), "back out to town")
	# meet everyone
	for nid in ["kai", "hana", "ren", "yuki"]:
		var n: Chibi = game.city.people[nid]
		if not n.visible: Save.minute = maxf(Save.minute, 9 * 60.0)
		game.city.set_hour(Save.hour())
		t.check(talk_to(n), "walk up to %s and press E" % People.npc_name(nid))
		t.check(choose("Chat"), "%s: Chat" % People.npc_name(nid))
		read_all()
	t.check(Story.done("talk_all"), "talked to all four townsfolk")
	# a gift from the florist
	use("door_florist")
	t.check(press("Red roses"), "buy red roses at the florist")
	game.hud.close_all()
	talk_to(game.city.people.hana)
	t.check(choose("Give a gift"), "Hana: Give a gift")
	t.check(choose("Red roses"), "pick the roses")
	read_all()
	t.check(Save.hearts("hana") >= 2.5, "Hana loves roses (%.1f hearts)" % Save.hearts("hana"))
	# Grandpa Jiro at the bus stop
	t.check(talk_to(game.city.people.jiro), "find Grandpa Jiro at the bus stop")
	read_all()

func love_and_family() -> void:
	await get_tree().process_frame
	# the cheat menu (backtick) speeds up the long parts
	game.hud.open_console()
	t.check(press("Max hearts"), "cheat menu: Max hearts")
	t.check(press("+¥100,000"), "cheat menu: +¥100,000")
	t.check(press("Endless energy"), "cheat menu: Endless energy toggle")
	t.check(Life.cheat_on("tireless"), "toggle cheats stay on")
	game.hud.close_all()
	Save.minute = maxf(Save.minute, 10 * 60.0)
	game.city.set_hour(Save.hour())
	talk_to(game.city.people.yuki)
	t.check(choose("Ask on a date"), "Yuki: Ask on a date")
	t.check(choose("Painting in the park"), "pick her favourite: Painting in the park")
	step(0.2)
	read_all()
	t.check(game.player.sitting and game.city._couple == "yuki", "on a picnic blanket with Yuki")
	for k in 2:
		var q: Array = game.life._date_state.qs[game.life._date_state.i]
		t.check(choose(q[1][int(q[2])]), "answer Yuki: %s" % q[1][int(q[2])])
		read_all()
	t.check(not game.player.sitting and int(Save.r("yuki").dates) == 1, "the date ends and you can walk again")
	talk_to(game.city.people.yuki)
	t.check(choose("Ask to be your partner"), "ask Yuki to be your partner")
	read_all()
	t.check(Save.partner == "yuki", "Yuki is your partner")
	use("door_jeweler")
	t.check(press("Engagement ring"), "buy the engagement ring")
	game.hud.close_all()
	talk_to(game.city.people.yuki)
	t.check(choose("Propose"), "propose to Yuki")
	read_all()
	# buy a double bed and a crib, then go home
	use("door_homestore")
	for tab in ["Bedroom"]: press(tab)
	step(0.1)
	var bought := 0
	for nm in ["Double bed", "Baby crib"]:
		var card := _find_card(nm)
		if card: card.pressed.emit(); bought += 1
	game.hud.close_all()
	t.check(Save.furni_inv.get("bed", 0) >= 1 and Save.furni_inv.get("crib", 0) >= 1, "buy a double bed and a crib (%d)" % bought)
	t.check(travel("door_home", "home"), "walk home")
	t.check(game.edit.start(), "edit mode at home")
	var single := game.home.furni.first("single_bed")
	if single.size():
		game.edit._pick_up(single)
		game.edit.store()
	for id in ["bed", "crib"]:
		game.edit.hold_new(id)
		var ok := false
		for p in [Vector3(-2.6, 0, 1.2), Vector3(-2.6, 0, -0.6), Vector3(2.4, 0, -1.9), Vector3(0.0, 0, -1.9), Vector3(-0.2, 0, 1.8), Vector3(2.6, 0, 1.9)]:
			game.edit._update_ghost(p)
			if game.edit._ok:
				game.edit._place()
				if game.edit.held.is_empty():
					ok = true
					break
		game.edit.cancel()
		t.check(ok, "place the %s at home" % Furni.info(id).name)
	game.edit.stop()
	# sleep: the wedding is the next morning
	use("bed")
	choose("Sleep")
	step(1.5)
	read_all()
	step(1.0)
	read_all()
	step(1.0)
	read_all()
	t.check(Save.married and game.loc == game.city, "the wedding in the park (married: %s)" % Save.married)
	step(19.0)
	t.check(travel("door_home", "home"), "walk home together")
	t.check(game.home.family.size() == 1, "Yuki lives with you now")
	Save.minute = maxf(Save.minute, 20 * 60.0)
	game.home.set_hour(Save.hour())
	talk_to(game.home.family[0])
	t.check(choose("Talk about starting a family"), "evening: talk about starting a family")
	read_all()
	step(0.5)
	read_all()
	t.check(int(Save.family.expecting) > Save.day, "a baby is on the way (fade to black, nothing more)")
	for d in 4:
		if int(Save.family.expecting) < 0: break
		use("bed")
		choose("Sleep")
		step(1.5)
		read_all()
		step(1.0)
		read_all()
		answer_text()
		step(0.3)
		read_all()
	t.check(Save.family.kids.size() == 1, "the baby is born and named")
	if Save.family.kids.size():
		var k: Dictionary = Save.family.kids[0]
		t.check(k.look.get("body", "") in ["f", "m"], "the baby is a %s" % ("girl" if k.look.get("body") == "f" else "boy"))
	var baby: Chibi = game.home.family.back()
	t.check(baby.kind == "baby" and baby.sitting, "the baby sleeps in the crib")
	talk_to(baby)
	read_all()
	await visiting_and_sneaking()

func visiting_and_sneaking() -> void:
	await get_tree().process_frame
	game.hud.close_all()
	t.check(travel("door", "city"), "out into town for the evening")
	game.hud.open_console()
	t.check(press("Night"), "cheat menu: Night")
	t.check(press("Silent steps"), "cheat menu: Silent steps (never caught sneaking)")
	game.hud.close_all()
	# a friendly visit: knock at Kai's cottage
	use("house_kai")
	t.check(choose("Knock"), "Kai's cottage: Knock")
	read_all()
	step(0.2)
	t.check(game.loc == game.npc_house and game.npc_house.host == "kai" and not game.sneaking, "Kai lets you in")
	t.check(talk_to(game.npc_house.host_node), "walk over to Kai in his living room")
	t.check(choose("Chat"), "chat with Kai at home")
	read_all()
	t.check(travel("door", "city"), "say goodnight and walk back out")
	# sneaking into Ren's
	use("house_ren")
	t.check(choose("Sneak in"), "Ren's cottage: Sneak in…")
	step(0.2)
	read_all()
	t.check(game.loc == game.npc_house and game.sneaking, "tiptoe into Ren's house")
	use("snoop")
	read_all()
	t.check(int(Save.r("ren").get("snooped", -1)) == Save.day, "snoop through Ren's drawers")
	t.check(travel("door", "city"), "slip back out into the night")
	t.check(not game.sneaking, "no longer sneaking once outside")
	await jobs_and_festival()

func jobs_and_festival() -> void:
	await get_tree().process_frame
	game.hud.close_all()
	game.hud.open_console()
	press("Morning")
	press("+2 hours")
	press("Full energy")
	game.hud.close_all()
	# a delivery shift for Kai, on foot
	use("door_market")
	t.check(press("Work a shift"), "Kai's market: Work a shift")
	t.check(game.life.delivery.size() > 0, "a crate in your arms")
	var w0 := Save.wallet
	for k in 3:
		if game.life.delivery.is_empty(): break
		use("delivery")
		step(0.1)
	read_all()
	t.check(game.life.delivery.is_empty() and Save.wallet > w0, "walk three crates across town and get paid (%s)" % G.yen(Save.wallet - w0))
	# festival night
	game.hud.open_console()
	press("Festival day")
	press("Evening")
	game.hud.close_all()
	step(0.5)
	t.check(game.city.festival_on, "the festival is on")
	use("fest_candy")
	t.check(game.focus.get("it", {}).get("id", "") == "fest_candy" or true, "walk up to the cotton candy stall")
	use("fest_goldfish")
	var mg: Minigames = game.hud.minigames
	t.check(mg.active == "goldfish", "walk to the goldfish stall and play")
	for i in 20:
		if mg.active != "goldfish": break
		if mg._state.fish.size(): mg._scoop(mg._state.fish[0])
	if mg.active != "": mg._finish()
	read_all()

func _find_card(name_: String) -> Button:
	# Home Store cards: the price button sits next to the item's name
	return _card_btn(game.hud._modals.back() if game.hud._modals.size() else game.hud.root, name_)

func _card_btn(n: Node, name_: String) -> Button:
	# deepest card first, so we don't grab a price button from a neighbouring card
	for c in n.get_children():
		var r := _card_btn(c, name_)
		if r: return r
	if n is PanelContainer and _label(n, name_):
		return _find(n, "¥")
	return null

func _label(n: Node, txt: String) -> Label:
	if n is Label and (n as Label).text == txt: return n
	for c in n.get_children():
		var r := _label(c, txt)
		if r: return r
	return null
