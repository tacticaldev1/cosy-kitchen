## Life outside the kitchen: the clock and energy, sleeping and new days, weather, friendship,
## dating, marriage, a growing family, the story chapters and cheat codes.
class_name Life
extends Node

const MIN_PER_SEC := 1.0          # one real second is one game minute
const DAY_START := 420.0          # 7:00
const PASS_OUT := 1560.0          # 2:00 the next morning
const MAX_KIDS := 4

var game: Game
var rng := RandomNumberGenerator.new()
var _hour_shown := -1
var _check_t := 0.0

func _init() -> void:
	rng.randomize()

# ---------------------------------------------------------------- clock & energy
func tick(dt: float) -> void:
	if game.paused() or game.cutscene: return
	Save.minute += dt * MIN_PER_SEC
	Save.energy = maxf(0.0, Save.energy - dt * 0.012)
	var h := int(Save.minute / 15.0)
	if h != _hour_shown:
		_hour_shown = h
		if game.loc: game.loc.set_hour(Save.hour())
	if Save.minute >= PASS_OUT:
		pass_out()
		return
	_check_t -= dt
	if _check_t <= 0.0:
		_check_t = 1.0
		check_story()

func hour() -> float:
	return Save.hour()

func is_night() -> bool:
	return Save.minute >= 20 * 60 or Save.minute < 6 * 60

func use_energy(x: float) -> void:
	Save.energy = clampf(Save.energy - x, 0.0, 100.0)
	if Save.energy < 15.0 and not game.has_meta("low_e"):
		game.set_meta("low_e", true)
		game.toast("You're getting tired. Eat a staff meal or head home to sleep")

func eat(x: float) -> void:
	Save.energy = clampf(Save.energy + x, 0.0, 100.0)
	if Save.energy > 20.0 and game.has_meta("low_e"): game.remove_meta("low_e")

func walk_speed() -> float:
	return 2.0 if Save.energy > 15.0 else 1.4

func skip_time(minutes: float) -> void:
	Save.minute = minf(Save.minute + minutes, PASS_OUT - 1.0)
	if game.loc: game.loc.set_hour(Save.hour())

# ---------------------------------------------------------------- sleeping & mornings
func pass_out() -> void:
	game.toast("You fell asleep on your feet… a kind neighbour walks you home")
	Save.energy = 55.0
	sleep(true)

## Sleep in your bed: the day ends, the shop closes, and the morning brings news.
func sleep(fainted := false) -> void:
	if game.shop.open: game.shop.close_day(true)
	game.leave_station()
	game.drop_carry()
	game.cutscene = true
	game.hud.fade(func():
		new_day(fainted)
		game.travel_now("home", "bed"), func():
		game.cutscene = false
		morning())

func new_day(fainted := false) -> void:
	Save.day += 1
	Save.minute = DAY_START + (90.0 if fainted else 0.0)
	Save.energy = 55.0 if fainted else 100.0
	Save.flags.slept = true
	var roll := rng.randf()
	Save.weather = "rain" if roll < 0.3 else "cloud" if roll < 0.45 else "sun"
	Sfx.set_ambience(Save.weather == "rain" and Save.settings.get("rain", true))
	for k in Save.rel:
		var d: Dictionary = Save.rel[k]
		# a little drift if you ignore someone (never below 0, never for your spouse)
		if k != Save.partner and int(d.get("talked", -1)) < Save.day - 4: d.hearts = maxf(0.0, float(d.hearts) - 0.2)
	Save.save()

func morning() -> void:
	var lines: Array = []
	_hour_shown = -1
	# the morning paper: critic reviews from yesterday
	var unread: Array = Save.reviews.filter(func(r): return not r.get("read", false))
	if unread.size():
		game.hud.open_newspaper(unread)
		for r in unread: r.read = true
	# wedding day
	if Save.flags.get("wedding", false) and not Save.married:
		Save.flags.erase("wedding")
		game.after(0.6, wedding)
		return
	# family
	var fam: Dictionary = Save.family
	if int(fam.get("expecting", -1)) >= 0:
		var due := int(fam.expecting)
		if Save.day >= due:
			game.after(0.8, birth)
		else:
			lines.append(["", "%s rests a hand on the bump and smiles. The baby is due in %d day%s." % [partner_name(), due - Save.day, "" if due - Save.day == 1 else "s"]])
	for k in fam.kids:
		var age: int = Save.day - int(k.born)
		if age == 4: lines.append(["", "%s took their first wobbly steps today!" % k.name])
		if age == 10: lines.append(["", "%s is growing up so fast! They want to help in the kitchen now." % k.name])
	if Save.weather == "rain": lines.append(["", "Rain patters on the window. A perfect day for soup at the café."])
	if lines.size(): game.hud.say(lines)
	check_story()
	Save.save()

# ---------------------------------------------------------------- story
func check_story() -> void:
	if not Story.active() or game.hud.modal_open() or game.cutscene: return
	if not Save.flags.get("intro_%d" % Save.chapter, false):
		Save.flags["intro_%d" % Save.chapter] = true
		Save.save()
		var ch := Story.chapter()
		game.hud.chapter_banner(Save.chapter + 1, ch.title)
		game.after(1.6, func(): game.hud.say(ch.intro))
		return
	if Story.complete():
		var ch := Story.chapter()
		Save.wallet += int(ch.reward)
		Save.chapter += 1
		Save.save()
		Sfx.play("yay")
		game.hud.say([["", "Chapter complete: %s! Grandma's envelope had %s inside." % [ch.title, G.yen(ch.reward)]]])
		if Save.chapter >= Story.CHAPTERS.size():
			game.after(0.5, func(): game.hud.say(Story.ENDING))

func flag(f: String) -> void:
	if not Save.flags.get(f, false):
		Save.flags[f] = true
		Save.save()

# ---------------------------------------------------------------- people
func partner_name() -> String:
	return People.npc_name(Save.partner) if Save.partner != "" else "Your partner"

## Opens the conversation menu for a townsperson.
func talk(id: String) -> void:
	if not People.NPCS.has(id):
		_talk_keeper(id)
		return
	var d := Save.r(id)
	var nm := People.npc_name(id)
	var opts: Array = []
	opts.append(["Chat", func(): chat(id)])
	if Save.gifts.size(): opts.append(["Give a gift", func(): game.hud.pick_gift(id)])
	if Save.partner == "" and Save.hearts(id) >= 4.0 and int(d.get("dated", -1)) != Save.day:
		opts.append(["Ask on a date (¥1,500)", func(): date(id)])
	elif Save.partner == id and int(d.get("dated", -1)) != Save.day and not is_night():
		opts.append(["Go on a date (¥1,500)", func(): date(id)])
	if Save.partner == "" and Save.hearts(id) >= 6.0 and int(d.dates) >= 1:
		opts.append(["Ask to be your partner ♥", func(): ask_partner(id)])
	if Save.partner == id and not Save.married and not Save.flags.get("wedding", false) and Save.has_ring:
		opts.append(["Propose with the ring ♥", func(): propose(id)])
	opts.append(["Bye!", func(): pass])
	var hi: String = ["Oh, hello there!", "Hi! Nice weather, huh?", "Hey, chef!", "Oh! It's you. Hi."][rng.randi() % 4] if Save.hearts(id) < 6.0 else ["You came to see me? ♥", "There you are! I was hoping you'd stop by.", "Hi, you."][rng.randi() % 3]
	game.hud.ask(id, "(%s) %s" % [_status(id), hi], opts)

func _status(id: String) -> String:
	if Save.married and Save.partner == id: return "your spouse"
	if Save.partner == id: return "your partner"
	var h := Save.hearts(id)
	return "stranger" if h < 1.0 else "acquaintance" if h < 3.0 else "friend" if h < 6.0 else "close friend"

func chat(id: String) -> void:
	var d := Save.r(id)
	var first := int(d.get("talked", -1)) != Save.day
	d.talked = Save.day
	d.talks = int(d.get("talks", 0)) + 1
	if first: Save.add_hearts(id, 0.5)
	var line := People.chat_line(id, Save.hearts(id), Save.partner == id, Save.married and Save.partner == id, rng)
	game.hud.say([[id, line]])
	game.npc_react(id, "happy")
	if first: game.hearts_fx(id)
	Save.save()

func give(id: String, gift: String) -> void:
	var d := Save.r(id)
	if int(d.get("gifted", -1)) == Save.day:
		game.hud.say([[id, "You already gave me something today! You'll spoil me."]])
		return
	Save.gifts[gift] = int(Save.gifts.get(gift, 0)) - 1
	if Save.gifts[gift] <= 0: Save.gifts.erase(gift)
	d.gifted = Save.day
	var v := People.gift_value(id, gift)
	Save.add_hearts(id, v)
	flag("gift")
	game.hud.say([[id, People.gift_reaction(id, gift)]])
	game.npc_react(id, "wow" if v >= 2.0 else "happy")
	game.hearts_fx(id)
	Save.save()

func date(id: String) -> void:
	if Save.wallet < 1500:
		game.hud.say([[id, "Let's go when you've saved up a little. I'm not going anywhere!"]])
		return
	if Save.minute > 22 * 60:
		game.hud.say([[id, "It's a bit late tonight. Ask me tomorrow?"]])
		return
	var d := Save.r(id)
	d.dated = Save.day
	Save.wallet -= 1500
	var q: Array = People.DATES[id][int(d.dates) % People.DATES[id].size()]
	game.start_date(id, func():
		game.hud.say([["", "You share warm taiyaki on a bench by the fountain while the evening lights come on."], [id, q[0]]], func():
			game.hud.ask(id, q[0], [[q[1][0], func(): _date_answer(id, 0, q)], [q[1][1], func(): _date_answer(id, 1, q)], [q[1][2], func(): _date_answer(id, 2, q)]])))

func _date_answer(id: String, i: int, q: Array) -> void:
	var d := Save.r(id)
	d.dates = int(d.dates) + 1
	var best: bool = i == int(q[2])
	Save.add_hearts(id, 1.5 if best else 0.8)
	skip_time(120.0)
	Save.save()
	game.hearts_fx(id)
	game.npc_react(id, "wow" if best else "happy")
	game.hud.say([[id, ("Hehe. That's the best answer I've ever heard." if best else "Ha, I like that about you.")], ["", "What a lovely evening. (♥ +%s)" % ("1.5" if best else "0.8")]], func(): game.end_date())

func ask_partner(id: String) -> void:
	Save.partner = id
	Save.save()
	game.hearts_fx(id)
	game.npc_react(id, "wow")
	Sfx.play("yay")
	game.hud.say([["", "You take a deep breath and ask %s to be your partner." % People.npc_name(id)],
		[id, {"hana": "Yes! A thousand times yes. I've been hoping you'd ask!", "ren": "...I was going to ask you. Today. I even wrote it down. Yes.",
			"kai": "YES! Wait, was I supposed to play it cool? Too late. YES!", "yuki": "Yes. You've been in all my paintings for weeks."}[id]]])

func propose(id: String) -> void:
	game.hud.say([["", "You kneel and open the little box. The ring catches the light."], [id, {"hana": "Oh… oh my. Yes! Yes! Let's get married in the park, under the cherry trees!",
		"ren": "I… have no words. That's a first. Yes. Yes, please.", "kai": "Are you serious?! YES! I'm telling EVERYONE!", "yuki": "Yes. Let's marry under the cherry tree I always paint."}[id]],
		["", "The wedding will be tomorrow morning in the park. Sleep well!"]])
	Save.has_ring = false
	Save.flags.wedding = true
	Save.add_hearts(id, 1.0)
	Sfx.play("yay")
	game.hearts_fx(id)
	Save.save()

func wedding() -> void:
	game.start_wedding(func():
		game.hud.say([["Grandpa Jiro", "Friends! We're gathered under the cherry blossoms to celebrate %s and %s." % [Save.player_name, partner_name()]],
			[Save.partner, "I promise to love you on busy days, rainy days and burnt pancake days."],
			["", "You exchange rings as petals drift down. The whole town cheers!"],
			["Grandpa Jiro", "You may now… go and eat cake! Congratulations!"]], func():
			Save.married = true
			Save.wedding_day = Save.day
			Save.add_hearts(Save.partner, 1.0)
			Save.save()
			game.hud.say([["", "%s moves into your apartment. Your home just got a lot cosier. (Bigger furniture is at the Home Store!)" % partner_name()]])))

## At bedtime with your spouse. Tasteful: the lights go down and the screen fades to black.
func start_family() -> void:
	if Save.family.kids.size() >= MAX_KIDS:
		game.hud.say([[Save.partner, "Four little ones is plenty of love for one apartment, don't you think?"]])
		return
	game.hud.say([["", "You curl up with %s and talk about the future: little shoes by the door, tiny hands helping in the kitchen…" % partner_name()],
		[Save.partner, "I'd love to start a family with you."]], func():
		game.cutscene = true
		game.family_scene(func():
			Save.family.expecting = Save.day + 4
			game.cutscene = false
			new_day()
			game.travel_now("home", "bed")
			game.hud.say([["", "The next morning…"], ["", "A few weeks later, the doctor smiles: you're expecting a baby! ♥ (due in 3 days)"]], func(): morning())))

func birth() -> void:
	game.hud.say([["", "Today's the day! After a long, long night at Hoshizora Clinic…"], ["", "A healthy, beautiful baby is born. ♥"]], func():
		game.hud.ask_text("What will you name your baby?", ["Sora", "Hina", "Haru", "Mio", "Riku", "Aoi"][rng.randi() % 6], func(nm: String):
			var look := _kid_look()
			Save.family.kids.append({"name": nm, "born": Save.day, "look": look})
			Save.family.expecting = -1
			flag("baby")
			Save.save()
			Sfx.play("yay")
			game.home.refresh_family()
			var crib := Story._home_has("crib")
			game.hud.say([[Save.partner, "Welcome to the world, little %s." % nm], ["", "You're a parent now!" + ("" if crib else " Don't forget to put a crib in the apartment.")]])))

func _kid_look() -> Dictionary:
	var a: Dictionary = Save.player_look
	var b: Dictionary = People.look_of(Save.partner)
	return {"skin": a.get("skin", "FFE2D2") if rng.randf() < 0.5 else b.get("skin", "FFE2D2"), "hair": a.get("hair", "4B2E5A") if rng.randf() < 0.5 else b.get("hair", "4B2E5A"),
		"shirt": Chibi.SHIRTS[rng.randi() % Chibi.SHIRTS.size()].to_html(false), "pants": Chibi.PANTS[rng.randi() % Chibi.PANTS.size()].to_html(false),
		"style": Chibi.STYLES[rng.randi() % Chibi.STYLES.size()], "acc": ""}

static func kid_stage(k: Dictionary) -> String:
	var age: int = Save.day - int(k.born)
	return "baby" if age < 4 else "toddler" if age < 10 else "child"

func talk_family(id: String) -> void:
	if id == "partner":
		var opts: Array = [["Chat", func(): chat(Save.partner)], ["Hug", func():
			game.hearts_fx(Save.partner)
			game.npc_react("partner", "happy")
			if int(Save.r(Save.partner).get("hugged", -1)) != Save.day:
				Save.r(Save.partner).hugged = Save.day
				Save.add_hearts(Save.partner, 0.3)
			game.hud.say([[Save.partner, "Mmm. Best part of my day."]])]]
		if Save.married and int(Save.family.expecting) < 0 and Save.minute >= 19 * 60:
			if Story._home_has("bed"):
				opts.append(["Talk about starting a family ♥", start_family])
			else:
				opts.append(["Talk about starting a family ♥", func(): game.hud.say([[Save.partner, "We'd need a proper double bed first, love. The single bed is cosy, but…"]])])
		if Save.gifts.size(): opts.append(["Give a gift", func(): game.hud.pick_gift(Save.partner)])
		opts.append(["Bye!", func(): pass])
		game.hud.ask(Save.partner, "%s  ·  your %s" % [partner_name(), "spouse" if Save.married else "partner"], opts)
		return
	var i := int(id.split(":")[1])
	var k: Dictionary = Save.family.kids[i]
	var stage := kid_stage(k)
	var lines := {"baby": ["%s grabs your finger and giggles." % k.name, "%s is fast asleep, making tiny snoring sounds." % k.name, "%s blows a spit bubble. Adorable." % k.name],
		"toddler": ["%s: \"Hug! Hug! Pancake!\"" % k.name, "%s shows you a drawing of the café. It's mostly pink." % k.name, "%s wants a piggyback ride. You oblige." % k.name],
		"child": ["%s: \"When I grow up, I'm going to be a chef like you!\"" % k.name, "%s: \"Can we have katsu curry for dinner? Pleeease?\"" % k.name, "%s tells you all about their day at school." % k.name]}
	var pool: Array = lines[stage]
	game.hud.say([["", pool[rng.randi() % pool.size()]]])
	game.npc_react(id, "happy")
	Sfx.play("pop", 0.8, 1.3)

func _talk_keeper(id: String) -> void:
	match id:
		"jiro":
			var tips := ["Harder dishes earn bigger tips, and critics love ambition.", "Customers wait longer if you have a record player. Lo-fi calms the soul.",
				"The market sells ingredients cheaper than the fridge's delivery service.", "Kuroda the critic reads the newspaper reviews too, you know. Don't get cocky!",
				"Sleep when you're tired. A tired chef burns the rice.", "Flowers on the tables bring customers in a little sooner."]
			var line: String = tips[rng.randi() % tips.size()]
			if Story.active():
				for q in Story.progress():
					if not q[1]:
						line = "Your next goal: %s. " % q[0].to_lower() + line
						break
			game.hud.say([["jiro", line]])
		_:
			game.open_shop_ui(id)

# ---------------------------------------------------------------- cheats
const CHEATS := {
	"kaching": "+¥10,000", "motherlode": "+¥100,000", "cookbook": "Discover every recipe", "fivestars": "5-star café rating",
	"lovebirds": "Max hearts with everyone", "nap": "Full energy", "timeskip": "Skip 2 hours", "freedecor": "One of every furniture item",
	"storkdelivery": "A baby arrives (if married)", "sunnyday": "Sunny weather", "rainyday": "Rainy weather", "nextchapter": "Finish the story chapter",
}

func cheat(code: String) -> String:
	code = code.strip_edges().to_lower().replace(" ", "")
	var msg := ""
	match code:
		"kaching": Save.wallet += 10000; msg = "Ka-ching! +¥10,000"
		"motherlode": Save.wallet += 100000; msg = "Motherlode! +¥100,000"
		"cookbook":
			for r in G.RECIPES:
				if not Save.is_found(r.id): Save.mark_found(r.id)
			msg = "Every recipe is in your book"
		"fivestars": Save.reputation = 5.0; msg = "Your café is now rated 5 stars"
		"lovebirds":
			for k in People.NPCS: Save.add_hearts(k, 10.0)
			msg = "Everyone adores you"
		"nap": Save.energy = 100.0; msg = "Fully rested!"
		"timeskip": skip_time(120.0); msg = "Two hours later…"
		"freedecor":
			for id in Furni.CATALOG: Save.furni_inv[id] = int(Save.furni_inv.get(id, 0)) + 1
			msg = "One of everything is in your storage (Edit mode)"
		"storkdelivery":
			if not Save.married: return "You need to be married first"
			Save.family.expecting = Save.day
			game.after(0.3, birth)
			msg = "The stork is on its way!"
		"sunnyday": Save.weather = "sun"; msg = "The sun comes out"
		"rainyday": Save.weather = "rain"; msg = "Pitter patter…"
		"nextchapter":
			if not Story.active(): return "No story chapter is active"
			Save.chapter += 1
			msg = "Skipped to the next chapter"
		_:
			return "Unknown code"
	Save.cheats_used = true
	if game.loc: game.loc.set_hour(Save.hour())
	Sfx.play("sparkle")
	Save.save()
	return msg
