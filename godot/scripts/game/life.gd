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
	if not cheat_on("tireless"): Save.energy = maxf(0.0, Save.energy - dt * 0.012)
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
		_check_affair()
	_tick_delivery(dt)

func hour() -> float:
	return Save.hour()

func is_night() -> bool:
	return Save.minute >= 20 * 60 or Save.minute < 6 * 60

func _check_affair() -> void:
	var aff: Dictionary = Save.flags.get("affair", {})
	var on: bool = aff.size() > 0 and not aff.get("seen", false) and Save.partner != "" and Save.hour() >= 12.0 and Save.hour() < 18.0
	if game.loc == game.city: game.city.affair_scene(on)
	if on and game.loc == game.city and not game.hud.modal_open():
		var n: Chibi = game.city.people.get(Save.partner)
		if n and n.visible and n.global_position.distance_to(game.player.global_position) < 7.0:
			spot_affair()

func use_energy(x: float) -> void:
	if cheat_on("tireless"): return
	Save.energy = clampf(Save.energy - x, 0.0, 100.0)
	if Save.energy < 15.0 and not game.has_meta("low_e"):
		game.set_meta("low_e", true)
		game.toast("You're getting tired. Eat a staff meal or head home to sleep")

func eat(x: float) -> void:
	Save.energy = clampf(Save.energy + x, 0.0, 100.0)
	if Save.energy > 20.0 and game.has_meta("low_e"): game.remove_meta("low_e")

func walk_speed() -> float:
	return (2.0 if Save.energy > 15.0 else 1.4) * (1.8 if cheat_on("speedy") else 1.0)

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
		go_to_bed_place(), func():
		game.cutscene = false
		morning())

## Where you sleep: your own home, or your sweetheart's place if you've moved in together.
func go_to_bed_place() -> void:
	var lw: String = Save.flags.get("live_with", "")
	if lw != "" and not Save.married:
		game.npc_house.set_host(lw)
		game.travel_now("npchome", "bed")
	else:
		game.travel_now("home", "bed")

func new_day(fainted := false) -> void:
	Save.day += 1
	Save.minute = DAY_START + (90.0 if fainted else 0.0)
	Save.energy = 55.0 if fainted else 100.0
	Save.flags.slept = true
	Save.flags["news"] = drama_day()
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
			lines.append(["", "The baby is due in %d day%s. Little socks are piling up by the door." % [due - Save.day, "" if due - Save.day == 1 else "s"]])
	# a baby from a fling
	var others: Array = fam.get("others", [])
	for o in others.duplicate():
		if Save.day >= int(o.due):
			others.erase(o)
			game.after(1.0, func(): surprise_baby(o))
			break
	# word gets around: your spouse hears at breakfast
	if Save.married and Save.flags.has("gossip"):
		var gs: Dictionary = Save.flags.gossip
		game.after(1.4, func(): caught(String(gs.lover), String(gs.what)))
	if Save.flags.get("sneaked", false):
		Save.flags.erase("sneaked")
		lines.append(["", "The Hoshizora Times: \"Mysterious intruder spotted in town. Neighbours lock their doors.\""])
	for k in fam.kids:
		var age: int = Save.day - int(k.born)
		if age == 4: lines.append(["", "%s took their first wobbly steps today!" % k.name])
		if age == 10: lines.append(["", "%s is growing up so fast! They want to help in the kitchen now." % k.name])
	if Save.weather == "rain": lines.append(["", "Rain patters on the window. A perfect day for soup at the café."])
	var news: Array = Save.flags.get("news", [])
	Save.flags.erase("news")
	lines = news + lines
	if lines.size(): game.hud.say(lines, drama_scenes)
	else: drama_scenes()
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
	# your partner heard something…
	if Save.partner == id and Save.flags.has("gossip"):
		var gs: Dictionary = Save.flags.gossip
		caught(String(gs.lover), String(gs.what))
		return
	# a friend heard what you said behind their back
	if String(d.get("heard_from", "")) != "":
		var who: String = d.heard_from
		d.erase("heard_from")
		Save.add_hearts(id, -1.5)
		game.npc_react(id, "yuck")
		game.hud.say([[id, "%s told me what you said about me. I thought we were friends." % People.npc_name(who)]])
		Save.save()
		return
	var opts: Array = []
	opts.append(["Chat", func(): chat(id)])
	if Save.hearts(id) >= 3.0 and int(d.get("flirted", -1)) != Save.day: opts.append(["Flirt ♥", func(): flirt(id)])
	if Save.gifts.size(): opts.append(["Give a gift", func(): game.hud.pick_gift(id)])
	if Save.partner == "" and Save.hearts(id) >= 4.0 and int(d.get("dated", -1)) != Save.day:
		opts.append(["Ask on a date (¥1,500)", func(): date(id)])
	elif Save.partner == id and int(d.get("dated", -1)) != Save.day and not is_night():
		opts.append(["Go on a date (¥1,500)", func(): date(id)])
	elif Save.partner != "" and Save.hearts(id) >= 4.0 and int(d.get("dated", -1)) != Save.day and not is_night():
		opts.append(["Secret date ♥ (¥1,500)", func(): date(id)])
	if game.loc is NpcHomeLocation and (game.loc as NpcHomeLocation).host == id and Save.minute >= 20 * 60.0 and Save.hearts(id) >= 7.0 and (is_lover(id) or Save.partner == id):
		opts.append(["Stay the night ♥", func(): stay_night(id)])
	var lw: String = Save.flags.get("live_with", "")
	if (is_lover(id) or (Save.partner == id and not Save.married)) and Save.hearts(id) >= 7.0 and lw != id:
		opts.append(["Ask to move in together ♥", func(): move_in(id)])
	if lw == id and not Save.married: opts.append(["Move back to your own place", func(): move_out()])
	if game.loc is NpcHomeLocation and (game.loc as NpcHomeLocation).host == id and Save.minute >= 20 * 60.0 and Save.hearts(id) >= 8.0 and (is_lover(id) or Save.partner == id):
		opts.append(["Ask for a baby together ♥", func(): ask_baby(id)])
	if Save.hearts(id) >= 2.0: opts.append(["Gossip about someone…", func(): gossip_menu(id)])
	if Save.partner == id and not Save.married: opts.append(["Break up", func(): confirm_break_up()])
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
	if cheating_with(id): return "your secret ♥"
	if is_lover(id): return "sweetheart"
	if Save.r(id).get("ex", false): return "your ex"
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
	var v := People.gift_value(id, gift) * (2.0 if Save.flags.get("event", "") == "hearts" else 1.0)
	Save.add_hearts(id, v)
	flag("gift")
	game.hud.say([[id, People.gift_reaction(id, gift)]])
	game.npc_react(id, "wow" if v >= 2.0 else "happy")
	game.hearts_fx(id)
	Save.save()

## Choose where to go on a date (what's open depends on the time and your purse).
func date(id: String) -> void:
	var h := Save.hour()
	var knows: bool = Save.hearts(id) >= 6.0 or Save.r(id).get("known", false)
	var opts: Array = []
	for t in People.DATE_TYPES:
		var dt: Dictionary = People.DATE_TYPES[t]
		if h < float(dt.from) or h > float(dt.to) - 1.5: continue
		if dt.get("festival", false) and not CityLocation.festival_now() and Save.flags.get("event", "") != "festival": continue
		if Save.wallet < int(dt.cost): continue
		var tt: String = t
		var tag := "  ♥" if knows and People.DATE_LIKES[id].has(t) else ""
		opts.append(["%s · %s%s" % [dt.name, "free" if int(dt.cost) == 0 else G.yen(dt.cost), tag], func(): go_date(id, tt)])
	if opts.is_empty():
		game.hud.say([[id, "Hmm, nothing's open that we can afford right now. Another time?"]])
		return
	opts.append(["Maybe another time", func(): pass])
	game.hud.ask(id, "Ooh, a date? Where should we go?", opts)

var _date_state := {}

func go_date(id: String, t: String) -> void:
	var dt: Dictionary = People.DATE_TYPES[t]
	var d := Save.r(id)
	d.dated = Save.day
	Save.wallet -= int(dt.cost)
	var pool: Array = People.DATES[id].duplicate()
	var first: Array = pool[int(d.dates) % pool.size()]
	pool.erase(first)
	pool.append_array(People.QUESTIONS)
	var second: Array = pool[rng.randi() % pool.size()]
	_date_state = {"id": id, "type": t, "qs": [first, second], "i": 0, "score": 0.0}
	game.start_date(id, t, func():
		game.hud.say([["", dt.line]], func(): _ask_date_q()))

func _ask_date_q() -> void:
	var st := _date_state
	if st.is_empty(): return
	var q: Array = st.qs[st.i]
	var id: String = st.id
	game.hud.ask(id, q[0], [[q[1][0], func(): _date_answer(id, 0, q)], [q[1][1], func(): _date_answer(id, 1, q)], [q[1][2], func(): _date_answer(id, 2, q)]])

func _date_answer(id: String, i: int, q: Array) -> void:
	if _date_state.is_empty() or _date_state.id != id:
		_date_state = {"id": id, "type": "icecream", "qs": [q], "i": 0, "score": 0.0}
	var best: bool = i == int(q[2])
	var worst: bool = q.size() > 3 and i == int(q[3])
	_date_state.score += 0.55 if best else (-0.4 if worst else 0.15)
	_date_state.i += 1
	game.npc_react(id, "wow" if best else "yuck" if worst else "happy")
	var line := "Hehe. That's the best answer I've ever heard." if best else ("…Oh. Okay then." if worst else "Ha, I like that about you.")
	game.hud.say([[id, line]], func():
		if not _date_state.is_empty() and _date_state.i < _date_state.qs.size(): _ask_date_q()
		else: _finish_date(id))

func _finish_date(id: String) -> void:
	var st := _date_state
	_date_state = {}
	if st.is_empty(): return
	var t: String = st.type
	var gain: float = 0.7 + float(st.score)
	if People.DATE_LIKES[id].has(t): gain += 0.6
	if People.DATE_DISLIKES[id].has(t): gain -= 0.5
	if Save.flags.get("event", "") == "hearts": gain *= 2.0
	gain = maxf(gain, -0.5)
	var d := Save.r(id)
	d.dates = int(d.dates) + 1
	d.romance = true
	Save.add_hearts(id, gain)
	if Save.partner != "" and Save.partner != id: _risk(id, 0.3, "on a date with")
	skip_time(120.0)
	Save.save()
	if gain > 0.0: game.hearts_fx(id)
	var verdict := ("What a lovely date. (♥ +%.1f)" % gain) if gain >= 1.0 else ("A nice time. (♥ +%.1f)" % gain) if gain > 0.0 else "That… didn't go great. (♥ %.1f)" % gain
	if People.DATE_LIKES[id].has(t): verdict += "  %s loved this kind of date!" % People.npc_name(id)
	elif People.DATE_DISLIKES[id].has(t): verdict += "  %s wasn't really into it." % People.npc_name(id)
	game.hud.say([["", verdict]], func(): game.end_date())

# ---------------------------------------------------------------- town drama
## Runs every new day: townsfolk fall in love with each other, have babies, break up; your
## partner's eye might wander; two of your sweethearts might find out about each other.
func drama_day() -> Array:
	var news: Array = []
	var couples: Array = Save.flags.get("couples", [])
	var taken := func(k: String) -> bool: return couples.any(func(c): return c[0] == k or c[1] == k)
	var singles: Array = People.NPCS.keys().filter(func(k): return k != Save.partner and not taken.call(k))
	# two townsfolk fall for each other
	if singles.size() >= 2 and rng.randf() < (1.0 if cheat_on("matchmaker") else 0.07):
		singles.shuffle()
		var a: String = singles[0]
		var b: String = singles[1]
		couples.append([a, b, Save.day])
		news.append(["", "Town gossip: %s and %s were seen holding hands by the fountain!" % [People.npc_name(a), People.npc_name(b)]])
		for x in [a, b]:
			if is_lover(x):
				Save.r(x).romance = false
				news.append(["", "Your heart sinks. %s moved on without telling you." % People.npc_name(x)])
	# couples: a baby on the way, or a break-up
	var babies: Array = Save.flags.get("npc_babies", [])
	for c in couples.duplicate():
		var expecting := babies.any(func(nb): return nb.parents.has(c[0]))
		if not expecting and Save.day - int(c[2]) >= 4 and rng.randf() < 0.15:
			babies.append({"parents": [c[0], c[1]], "due": Save.day + 5})
			news.append(["", "Big news: %s and %s are expecting a baby!" % [People.npc_name(c[0]), People.npc_name(c[1])]])
		elif not expecting and Save.day - int(c[2]) >= 2 and rng.randf() < 0.04:
			couples.erase(c)
			news.append(["", "Oh no, %s and %s broke up. The whole market is talking about it." % [People.npc_name(c[0]), People.npc_name(c[1])]])
	var kids: Array = Save.flags.get("npc_kids", [])
	for nb in babies.duplicate():
		if Save.day >= int(nb.due):
			babies.erase(nb)
			var lk := Chibi.random_look(rng)
			lk.hair = People.look_of(nb.parents[rng.randi() % 2]).get("hair", lk.hair)
			var nm: String = ["Kiko", "Taro", "Nami", "Shun", "Yua", "Ken"][rng.randi() % 6]
			kids.append({"parents": nb.parents, "name": nm, "born": Save.day, "look": lk})
			news.append(["", "%s and %s welcomed baby %s! The town sends tiny socks." % [People.npc_name(nb.parents[0]), People.npc_name(nb.parents[1]), nm]])
	Save.flags["couples"] = couples
	Save.flags["npc_babies"] = babies
	Save.flags["npc_kids"] = kids
	# your partner's wandering eye (more likely if you've been neglecting them)
	var aff: Dictionary = Save.flags.get("affair", {})
	if Save.partner != "" and aff.is_empty() and not cheat_on("loyal"):
		var p := 0.12 if Save.hearts(Save.partner) < 5.0 else 0.02
		if cheat_on("drama"): p = 1.0
		if rng.randf() < p:
			var others: Array = People.NPCS.keys().filter(func(k): return k != Save.partner)
			aff = {"with": others[rng.randi() % others.size()], "day": Save.day, "seen": false, "baby": false}
			Save.flags["affair"] = aff
			news.append(["", "%s came home late again, humming a song you don't know…" % People.npc_name(Save.partner) if Save.married else "%s has been strangely busy lately. Too busy to text back." % People.npc_name(Save.partner)])
	elif aff.size() and Save.partner != "" and not aff.baby and Save.day - int(aff.day) >= 3 and rng.randf() < (1.0 if cheat_on("drama") else 0.2):
		aff.baby = true
		Save.flags["affair_baby_reveal"] = true
	# two of your sweethearts find out about each other
	var lovers: Array = People.NPCS.keys().filter(func(k): return is_lover(k) and k != Save.partner)
	if lovers.size() >= 2 and not cheat_on("nogossip") and rng.randf() < (1.0 if cheat_on("drama") else 0.15):
		Save.flags["triangle"] = [lovers[0], lovers[1]]
	# an ex who misses you
	for k in People.NPCS:
		if Save.r(k).get("ex", false) and Save.hearts(k) >= 4.0 and rng.randf() < 0.06:
			news.append(["", "A letter from %s: \"I still think about us sometimes.\"" % People.npc_name(k)])
	# special days (and the summer festival every week)
	var ev := ""
	if Save.day % 7 == 0:
		ev = "festival"
		news.append(["", "Tonight is the Hoshizora Summer Festival! Food stalls, games and fireworks on Main Street from 4pm."])
	elif rng.randf() < 0.3:
		var keys: Array = People.EVENTS.keys()
		ev = keys[rng.randi() % keys.size()]
		news.append(["", "Today is %s! %s" % [People.EVENTS[ev][0], People.EVENTS[ev][1]]])
	Save.flags["event"] = ev
	return news

## Morning drama scenes that need a choice.
func drama_scenes() -> void:
	if Save.flags.get("triangle", []).size() == 2:
		var tr: Array = Save.flags.triangle
		Save.flags.erase("triangle")
		var a: String = tr[0]
		var b: String = tr[1]
		Save.add_hearts(a, -1.5)
		Save.add_hearts(b, -1.5)
		game.hud.say([["", "Knock knock. You open the door to find %s and %s on your doorstep. At the same time." % [People.npc_name(a), People.npc_name(b)]],
			[a, "So it's true. You've been seeing both of us."], [b, "You need to choose. Right now."]], func():
			game.hud.ask("", "Who do you choose?", [
				["Choose %s" % People.npc_name(a), func(): _choose_lover(a, b)],
				["Choose %s" % People.npc_name(b), func(): _choose_lover(b, a)],
				["I'm sorry. I'll let you both go.", func():
					for x in [a, b]:
						Save.r(x).romance = false
						Save.add_hearts(x, -1.0)
					game.hud.say([["", "They leave together, talking about you in low voices. Ouch."]])]]))
		return
	if Save.flags.get("affair_baby_reveal", false) and Save.partner != "":
		Save.flags.erase("affair_baby_reveal")
		var pid := Save.partner
		var other: String = Save.flags.get("affair", {}).get("with", "")
		if other == "": return
		game.hud.say([[pid, "Please sit down. I have to tell you something… I've been seeing %s. And there's going to be a baby." % People.npc_name(other)]], func():
			game.hud.ask(pid, "Can you ever forgive me?", [
				["We'll raise the baby together.", func():
					Save.flags.erase("affair")
					var others: Array = Save.family.get("others", [])
					others.append({"with": pid, "due": Save.day + 5, "other": other})
					Save.family.others = others
					Save.add_hearts(pid, 1.0)
					game.hud.say([[pid, "…Thank you. I don't deserve you."]])],
				["I need some time.", func():
					Save.add_hearts(pid, -1.0)
					game.hud.say([[pid, "I understand. I'll wait."]])],
				["It's over.", func():
					Save.flags.erase("affair")
					break_up(true)]]))

func _choose_lover(keep: String, lose: String) -> void:
	Save.r(lose).romance = false
	Save.add_hearts(lose, -2.5)
	Save.add_hearts(keep, 1.0)
	game.hud.say([[keep, "…Okay. Just me from now on, right?"], [lose, "Fine. I hope you're happy."]])
	Save.save()

## Seeing your partner with someone else in town.
func spot_affair() -> void:
	var aff: Dictionary = Save.flags.get("affair", {})
	if aff.is_empty() or Save.partner == "": return
	aff.seen = true
	var pid := Save.partner
	var other: String = aff.with
	game.hud.say([["", "Wait… is that %s by the fountain? Holding hands with %s?!" % [People.npc_name(pid), People.npc_name(other)]]], func():
		game.hud.ask("", "What do you do?", [
			["Confront them", func():
				game.hud.say([[pid, "It… it's not what it looks like. …Okay, it is. I'm so sorry."], [other, "I should go."]], func():
					game.hud.ask(pid, "Please. Say something.", [
						["I forgive you. Just stop.", func():
							Save.flags.erase("affair")
							Save.add_hearts(pid, 1.5)
							Save.add_hearts(other, -1.0)
							game.city.affair_scene(false)
							game.hud.say([[pid, "Never again. I promise."]])],
						["We're done.", func():
							Save.flags.erase("affair")
							game.city.affair_scene(false)
							break_up(true)]]))],
			["Walk away quietly", func():
				game.hud.say([["", "You turn around before they see you. Your chest feels tight all afternoon."]])]]))

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
			Save.flags.erase("live_with")
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
			Save.family.expecting_with = Save.partner
			game.cutscene = false
			new_day()
			game.travel_now("home", "bed")
			game.hud.say([["", "The next morning…"], ["", "A few weeks later, the doctor smiles: you're expecting a baby! ♥ (due in 3 days)"]], func(): morning())))

func birth() -> void:
	var parent: String = Save.family.get("expecting_with", Save.partner)
	var look := _kid_look(parent)
	var girl: bool = look.body == "f"
	var names: Array = ["Hina", "Mio", "Sakura", "Yui", "Aoi", "Momo"] if girl else ["Sora", "Haru", "Riku", "Ren", "Taichi", "Kota"]
	game.hud.say([["", "Today's the day! After a long, long night at Hoshizora Clinic…"], ["", "It's a %s! A healthy, beautiful baby %s. ♥" % ["girl" if girl else "boy", "girl" if girl else "boy"]]], func():
		game.hud.ask_text("What will you name your baby %s?" % ("girl" if girl else "boy"), names[rng.randi() % names.size()], func(nm: String):
			Save.family.kids.append({"name": nm, "born": Save.day, "look": look, "parent": parent})
			Save.family.expecting = -1
			flag("baby")
			Save.save()
			Sfx.play("yay")
			game.home.refresh_family()
			var crib := Story._home_has("crib")
			game.hud.say([[parent if parent != "" else "", "Welcome to the world, little %s." % nm], ["", "You're a parent now!" + ("" if crib else " Don't forget to put a crib in the apartment.")]])))

func _kid_look(parent := "") -> Dictionary:
	var a: Dictionary = Save.player_look
	var b: Dictionary = People.look_of(parent if parent != "" else Save.partner)
	var lk := Chibi.random_look(rng)
	lk.skin = a.get("skin", "FFE2D2") if rng.randf() < 0.5 else b.get("skin", "FFE2D2")
	lk.hair = a.get("hair", "4B2E5A") if rng.randf() < 0.5 else b.get("hair", "4B2E5A")
	return lk

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
		opts.append(["Ask for a divorce", func(): confirm_break_up()])
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

# ---------------------------------------------------------------- romance, secrets and drama
## Townsfolk are at home from 9pm until 7am (your spouse lives with you instead).
static func npc_home(id: String) -> bool:
	var h := Save.hour()
	return not (Save.married and Save.partner == id) and (h >= 21.0 or h < 7.0)

static func npc_asleep(id: String) -> bool:
	var h := Save.hour()
	return npc_home(id) and (h >= 23.0 or h < 6.5)

func is_lover(id: String) -> bool:
	return bool(Save.r(id).get("romance", false))

## Seeing someone behind your partner's back.
func cheating_with(id: String) -> bool:
	return Save.partner != "" and Save.partner != id and is_lover(id)

func flirt(id: String) -> void:
	var d := Save.r(id)
	d.flirted = Save.day
	var h := Save.hearts(id)
	var ok := h >= 3.0 and rng.randf() < 0.6 + h * 0.06
	if ok:
		Save.add_hearts(id, 0.7 if Save.partner != id else 0.4)
		if Save.hearts(id) >= 5.0: d.romance = true
		game.hearts_fx(id)
		game.npc_react(id, "wow")
	else:
		game.npc_react(id, "focus")
	var yes := {"hana": ["*giggles* You're such a charmer.", "Stop it, you'll make me blush… don't stop."], "ren": ["…You can't just say things like that. (He's smiling.)", "I'll be thinking about that all day."],
		"kai": ["Whoa, smooth! Say it again!", "Ha! You trying to make my heart race? It's working."], "yuki": ["Oh… you're blushing too, you know.", "That's the nicest colour anyone's ever called me."]}
	var no := {"hana": "Hehe, let's just be friends for now, okay?", "ren": "…Um. I should get back to my books.", "kai": "Ha, nice try, chef!", "yuki": "That's sweet, but my heart's on my canvas today."}
	var line: String = yes[id][rng.randi() % 2] if ok else no[id]
	game.hud.say([[id, line]])
	if ok and Save.partner != "" and Save.partner != id: _risk(id, 0.18, "flirting with")
	Save.save()

## Gossip with someone about a mutual friend: they like you a little more… unless it gets back.
func gossip_menu(id: String) -> void:
	var opts: Array = []
	for k in People.NPCS:
		if k == id: continue
		var kk: String = k
		opts.append([People.npc_name(k), func(): gossip(id, kk)])
	opts.append(["Never mind", func(): pass])
	game.hud.ask(id, "Ooh, gossip? Who about?", opts)

func gossip(listener: String, target: String) -> void:
	var d := Save.r(listener)
	if int(d.get("gossiped", -1)) == Save.day:
		game.hud.say([[listener, "We already gossiped today! My ears need a rest."]])
		return
	d.gossiped = Save.day
	Save.add_hearts(listener, 0.4)
	var tn := People.npc_name(target)
	var juicy := ["%s still sleeps with a night-light, you know." % tn, "Between us? %s burnt toast three times last week." % tn,
		"I heard %s practises speeches to the mirror." % tn, "%s has a secret stash of sweets behind the counter." % tn]
	if rng.randf() < 0.45 and not cheat_on("nogossip"): Save.r(target).heard_from = listener
	game.hud.say([["me", juicy[rng.randi() % juicy.size()]], [listener, "No way! Hehe, my lips are sealed."]])
	Save.save()

## The chance your partner hears about it. Right in front of them, they find out immediately.
func _risk(lover: String, p: float, what: String) -> void:
	if cheat_on("nogossip") or Save.partner == "" or Save.partner == lover: return
	var pn := game.npc_node(Save.partner)
	var seen := pn != null and pn.visible and pn.global_position.distance_to(game.player.global_position) < 10.0
	if seen:
		game.after(0.6, func(): caught(lover, what))
	elif rng.randf() < p:
		Save.flags["gossip"] = {"lover": lover, "what": what, "day": Save.day}

## Your partner confronts you.
func caught(lover: String, what: String) -> void:
	var pid := Save.partner
	if pid == "": return
	Save.flags.erase("gossip")
	var d := Save.r(pid)
	d.cheated = int(d.get("cheated", 0)) + 1
	game.npc_react(pid, "yuck")
	for k in People.NPCS:
		if k != pid and k != lover: Save.add_hearts(k, -0.3)   # the whole town talks
	Save.reputation = clampf(Save.reputation - 0.1, 0.0, 5.0)
	var lines := {"hana": "I heard you were %s %s. Tell me it isn't true…", "ren": "People are saying you were %s %s. I… need to hear it from you.",
		"kai": "Everybody at the market says you were %s %s! Is it true?!", "yuki": "Someone saw you %s %s. My heart feels grey."}
	var line: String = lines[pid] % [what, People.npc_name(lover)]
	game.hud.say([[pid, line]], func():
		game.hud.ask(pid, "Well?", [
			["I'm so sorry. It won't happen again.", func(): _after_caught(pid, lover, -3.0, true)],
			["It meant nothing!", func(): _after_caught(pid, lover, -4.0, false)],
			["Maybe we should split up.", func(): break_up(true)]]))
	Save.save()

func _after_caught(pid: String, lover: String, loss: float, sorry: bool) -> void:
	var times := int(Save.r(pid).get("cheated", 1))
	Save.add_hearts(pid, loss - 1.5 * (times - 1))
	Save.r(lover).romance = false
	if not sorry: Save.add_hearts(lover, -1.5)
	if Save.hearts(pid) < 2.0 or times >= 3:
		game.hud.say([[pid, "I can't keep doing this. I'm sorry… we're over."]], func(): break_up(false))
	else:
		game.hud.say([[pid, "…Okay. I'll try to trust you again. Don't make me regret it."]])
	Save.save()

func confirm_break_up() -> void:
	var pid := Save.partner
	game.hud.ask("", "Really end things with %s?%s" % [People.npc_name(pid), " (This means a divorce.)" if Save.married else ""],
		[["Yes, it's over", func(): break_up(true)], ["No, I love them", func(): pass]])

## Breaking up (or a divorce). Your ex moves out; the kids stay with you.
func break_up(you_ended_it: bool) -> void:
	var pid := Save.partner
	if pid == "": return
	var was_married := Save.married
	Save.partner = ""
	Save.married = false
	Save.has_ring = false
	Save.flags.erase("gossip")
	Save.flags.erase("wedding")
	var d := Save.r(pid)
	d.romance = false
	d.ex = true
	Save.add_hearts(pid, -4.0 if you_ended_it else -2.0)
	game.home.refresh_family()
	Sfx.play("sigh" if Sfx.has("sigh") else "pop")
	var bye := ("The divorce papers are signed. %s packs a bag and moves out. The apartment feels very quiet." if was_married else "You and %s go your separate ways.") % People.npc_name(pid)
	game.hud.say([["", bye]])
	Save.save()

## A night at your sweetheart's place. Tasteful: the lights go down and the screen fades to black.
func stay_night(id: String) -> void:
	game.hud.say([[id, "Stay… I don't want tonight to end."]], func():
		game.cutscene = true
		game.family_scene(func():
			if game.shop.open: game.shop.close_day(true)
			new_day()
			game.cutscene = false
			var d := Save.r(id)
			d.nights = int(d.get("nights", 0)) + 1
			d.romance = true
			Save.add_hearts(id, 1.0)
			var pending: Array = Save.family.get("others", [])
			if Save.family.kids.size() + pending.size() < MAX_KIDS and not pending.any(func(o): return o.with == id) and (rng.randf() < 0.35 or cheat_on("fertile")):
				pending.append({"with": id, "due": Save.day + 5})
				Save.family.others = pending
			game.player.global_position = game.loc.nav.nearest_free(Vector3(-1.2, 0, 1.2))
			if game.loc is NpcHomeLocation: (game.loc as NpcHomeLocation).set_hour(Save.hour())
			if Save.partner != "" and Save.partner != id: _risk(id, 0.5, "spending the night with")
			game.hud.say([["", "The next morning…"], [id, "Good morning, sleepyhead. I made tea."]], func(): morning())))

## Someone you had a fling with turns up with your baby.
func surprise_baby(o: Dictionary) -> void:
	var id: String = o.with
	if o.has("other"):
		var lk := _kid_look(String(o.other))
		var gl: bool = lk.body == "f"
		game.hud.say([["", "%s comes home from Hoshizora Clinic with a tiny baby %s: %s and %s's baby." % [People.npc_name(id), "girl" if gl else "boy", People.npc_name(id), People.npc_name(o.other)]]], func():
			game.hud.ask_text("What will you call the baby?", ["Hina", "Mio"][rng.randi() % 2] if gl else ["Sora", "Riku"][rng.randi() % 2], func(nm: String):
				Save.family.kids.append({"name": nm, "born": Save.day, "look": lk, "parent": id, "other": o.other})
				game.home.refresh_family()
				Save.save()
				game.hud.say([["", "Whatever happened before, %s is part of your family now." % nm]])))
		return
	var look := _kid_look(id)
	var girl: bool = look.body == "f"
	var kind := "girl" if girl else "boy"
	var names: Array = ["Hina", "Mio", "Sakura", "Yui"] if girl else ["Sora", "Haru", "Riku", "Kota"]
	game.hud.say([["", "There's a knock at the door. It's %s, holding a tiny bundle." % People.npc_name(id)],
		[id, "I didn't know how to tell you… This is our baby %s. I want them to know you." % kind]], func():
		game.hud.ask_text("What will you name your baby %s?" % kind, names[rng.randi() % names.size()], func(nm: String):
			Save.family.kids.append({"name": nm, "born": Save.day, "look": look, "parent": id})
			Save.add_hearts(id, 1.0)
			game.home.refresh_family()
			Save.save()
			if Save.partner != "" and Save.partner != id:
				game.hud.say([["", "%s comes to live with you. %s looks at the baby… and knows." % [nm, People.npc_name(Save.partner)]]], func(): caught(id, "having a baby with"))
			else:
				game.hud.say([["", "%s comes to live with you. You're a parent!" % nm]])))

# ---------------------------------------------------------------- living together, babies
func move_in(id: String) -> void:
	var other := Save.partner
	if other != "" and other != id:
		game.hud.ask("", "Moving in with %s means leaving %s%s. Are you sure?" % [People.npc_name(id), People.npc_name(other), " (a divorce)" if Save.married else ""], [
			["Yes. I'm moving in with %s." % People.npc_name(id), func():
				break_up(true)
				_do_move_in(id)],
			["No, never mind", func(): pass]])
		return
	_do_move_in(id)

func _do_move_in(id: String) -> void:
	Save.partner = id
	Save.flags["live_with"] = id
	Save.flags.erase("affair")
	var d := Save.r(id)
	d.romance = true
	d.erase("ex")
	Save.add_hearts(id, 1.0)
	Sfx.play("yay")
	game.hearts_fx(id)
	game.hud.say([[id, {"hana": "Really?! I'll clear a drawer for you. Two drawers!", "ren": "…I already made space on the bookshelf. Just in case.", "kai": "YES! Bring your knives, my kitchen needs a real chef!", "yuki": "My little house just became our little house."}[id]],
		["", "You move in with %s. You'll sleep at their cottage now (your own place is still yours)." % People.npc_name(id)]])
	Save.save()

func move_out() -> void:
	var id: String = Save.flags.get("live_with", "")
	Save.flags.erase("live_with")
	Save.add_hearts(id, -1.0)
	game.hud.say([[id, "Oh… okay. I'll miss you snoring."]])
	Save.save()

## Asking your sweetheart for a baby. Tasteful: the lights go down and the screen fades to black.
func ask_baby(id: String) -> void:
	var pending: Array = Save.family.get("others", [])
	if pending.any(func(o): return o.with == id):
		game.hud.say([[id, "Silly, we're already expecting! Just a few more days."]])
		return
	if Save.family.kids.size() + pending.size() >= MAX_KIDS:
		game.hud.say([[id, "Our home is full of little ones already. Let's love the ones we have."]])
		return
	if Save.hearts(id) < 8.5 and rng.randf() < 0.35:
		game.hud.say([[id, "I… I love you. But I'm not ready for that yet. Ask me again someday?"]])
		return
	game.hud.say([[id, "A baby… with you? Yes. I'd love that."]], func():
		game.cutscene = true
		game.family_scene(func():
			if game.shop.open: game.shop.close_day(true)
			new_day()
			game.cutscene = false
			pending.append({"with": id, "due": Save.day + 5})
			Save.family.others = pending
			Save.add_hearts(id, 1.0)
			if Save.partner != "" and Save.partner != id: _risk(id, 0.5, "spending the night with")
			game.player.global_position = game.loc.nav.nearest_free(Vector3(-1.2, 0, 1.2))
			game.hud.say([["", "The next morning…"], ["", "A few weeks later, %s tells you the news: a baby is on the way! ♥ (due in 5 days)" % People.npc_name(id)]], func(): morning())))
	Save.save()

# ---------------------------------------------------------------- jobs and the festival
func job_done_today(job: String) -> bool:
	return int(Save.flags.get("job_" + job, -1)) == Save.day

func job_open() -> bool:
	return Save.hour() >= 9.0 and Save.hour() < 18.0

func start_job(job: String) -> void:
	if job_done_today(job):
		game.hud.say([["", "You've already worked that shift today. Come back tomorrow!"]])
		return
	if not job_open():
		game.hud.say([["", "Shifts run from 9am to 6pm."]])
		return
	if Save.energy < 10.0:
		game.hud.say([["", "You're too tired to work. Eat something or get some sleep first."]])
		return
	game.hud.close_all()
	match job:
		"books": game.hud.minigames.books()
		"bouquets": game.hud.minigames.bouquets()
		"delivery": start_delivery()

func festival_job() -> void:
	if int(Save.flags.get("job_takoyaki", -1)) == Save.day:
		game.hud.say([["", "You've already run the stall tonight. Go enjoy the festival!"]])
		return
	game.hud.say([["", "The stall keeper hands you a headband and a pick. \"The takoyaki pan is all yours tonight!\""]], func(): game.hud.minigames.takoyaki())

func festival_game() -> void:
	if Save.wallet < 300:
		game.hud.say([["", "You need ¥300 for a paper scoop."]])
		return
	Save.wallet -= 300
	game.hud.minigames.goldfish()

func festival_snack() -> void:
	if Save.wallet < 300: return
	Save.wallet -= 300
	eat(15.0)
	Sfx.play("nom")
	game.toast("Fluffy pink cotton candy! +15 energy")

func festival_mask() -> void:
	if Save.wallet < 800:
		game.toast("A fox mask costs ¥800")
		return
	Save.wallet -= 800
	Save.player_look.acc = "fox"
	game.rebuild_player()
	Sfx.play("yay")
	game.toast("You wear a fox mask on the side of your head. Very festival.")
	Save.save()

## Delivery runs for Kai's market: carry a crate to a door across town before time runs out.
var delivery := {}
const DELIVERY_SPOTS := ["door_cafe", "door_homestore", "door_boutique", "door_florist", "door_jeweler", "door_bookshop", "house_hana", "house_ren", "house_yuki", "door_home"]

func start_delivery() -> void:
	var spots: Array = DELIVERY_SPOTS.duplicate()
	spots.shuffle()
	delivery = {"queue": spots.slice(0, 3), "t": 0.0, "pay": 0, "done": 0}
	var crate := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.28, 0.2, 0.22)
	crate.mesh = bm
	crate.material_override = Toon.solid(Color("C8864E"), 1.0)
	game.player.carry(crate)
	crate.scale = Vector3.ONE
	_next_delivery()

func _next_delivery() -> void:
	game.city.interacts = game.city.interacts.filter(func(it): return it.id != "delivery")
	if delivery.queue.is_empty():
		_end_delivery()
		return
	var target: String = delivery.queue[0]
	var pos := Vector3.ZERO
	var nm := ""
	for it in game.city.interacts:
		if it.id == target:
			pos = it.pos
			nm = String(it.label).replace("Shop at ", "").replace("Enter the café", "the café").replace("Sakura Apartments", "the apartments")
	delivery.t = 80.0
	delivery.target = target
	game.city.add_interact("delivery", pos, 1.0, "Deliver the crate", func(): deliver_crate())
	game.city.interacts.back().prio = 0.6
	game.city.interacts.back().h = 2.0
	game.city.set_delivery_mark(pos)
	game.toast("Deliver the crate to %s! (%ds)" % [nm, int(delivery.t)])

func deliver_crate() -> void:
	if delivery.is_empty(): return
	var bonus := int(maxf(0.0, delivery.t) * 6.0)
	delivery.pay += 350 + bonus
	delivery.done += 1
	delivery.queue.pop_front()
	Sfx.play("coin")
	game.toast("Delivered! +%s" % G.yen(350 + bonus))
	_next_delivery()

func _end_delivery(cancelled := false) -> void:
	if delivery.is_empty(): return
	var pay: int = delivery.pay
	var done: int = delivery.done
	delivery = {}
	game.city.interacts = game.city.interacts.filter(func(it): return it.id != "delivery")
	game.city.set_delivery_mark(null)
	var c := game.player.drop()
	if c: c.queue_free()
	Save.wallet += pay
	Save.flags["job_delivery"] = Save.day
	use_energy(8.0)
	if done > 0: Save.add_hearts("kai", 0.3)
	Save.save()
	game.hud.say([["kai", ("Shift's over! %d deliveries, %s earned. You're fast!" % [done, G.yen(pay)]) if not cancelled else "Hey, where'd you go with my crate? I'll pay for what you delivered: %s." % G.yen(pay)]])

func _tick_delivery(dt: float) -> void:
	if delivery.is_empty(): return
	if game.loc != game.city:
		_end_delivery(true)
		return
	delivery.t -= dt
	if delivery.t <= 0.0:
		game.toast("Too slow! That customer gave up on their crate.")
		delivery.queue.pop_front()
		_next_delivery()

# ---------------------------------------------------------------- your own house
func house_door() -> void:
	if Save.home_kind == "house":
		game.travel("home", "door")
		return
	var price := HomeLocation.HOUSE_PRICE
	game.hud.say([["", "A two-room house with a fireplace, a big kitchen and a bedroom of its own. The sign says %s." % G.yen(price)]], func():
		if Save.wallet < price:
			game.hud.say([["", "You have %s. Keep saving! (The café is a great place to earn.)" % G.yen(Save.wallet)]])
			return
		game.hud.ask("", "Buy the house for %s?" % G.yen(price), [
			["Buy it and move in!", func(): buy_house()],
			["Not yet", func(): pass]]))

func buy_house() -> void:
	Save.wallet -= HomeLocation.HOUSE_PRICE
	game.home.move_to("house")
	game.city.update_forsale()
	flag("house")
	Sfx.play("yay")
	game.hud.say([["", "The keys are yours! Your furniture is moved over (anything that didn't fit is in storage)."]], func(): game.travel("home", "door"))
	Save.save()

# ---------------------------------------------------------------- other people's houses
func visit_house(id: String) -> void:
	var nm := People.npc_name(id)
	if Save.married and Save.partner == id:
		game.hud.say([["", "%s lives with you now. This cottage is empty." % nm]])
		return
	var opts: Array = []
	var text := ""
	if not npc_home(id):
		text = "%s's house. Nobody's home right now." % nm
	elif npc_asleep(id):
		text = "%s's house. The lights are off… they must be asleep." % nm
	else:
		text = "%s's house. You can hear humming inside." % nm
		opts.append(["Knock", func(): knock(id)])
	opts.append(["Sneak in…", func(): sneak(id)])
	opts.append(["Leave", func(): pass])
	game.hud.ask("", text, opts)

func knock(id: String) -> void:
	if Save.hearts(id) >= 3.0 or is_lover(id) or Save.partner == id:
		game.hud.say([[id, "Oh! Come in, come in!"]], func(): game.enter_house(id, false))
	else:
		game.hud.say([[id, "Um… it's a bit late. See you around town tomorrow?"]])

func sneak(id: String) -> void:
	var chance := 0.0
	if not cheat_on("sneaky"):
		chance = 0.6 if npc_home(id) and not npc_asleep(id) else 0.2 if npc_asleep(id) else 0.08
	game.enter_house(id, true)
	if rng.randf() < chance:
		game.after(0.8, func(): caught_sneaking(id))
	else:
		game.toast("You slip inside without a sound…")

func snoop(id: String) -> void:
	if not game.sneaking and npc_home(id) and not npc_asleep(id):
		Save.add_hearts(id, -0.5)
		game.npc_react(id, "yuck")
		game.hud.say([[id, "Um… are you going through my things?!"]])
		return
	var d := Save.r(id)
	if int(d.get("snooped", -1)) == Save.day:
		game.toast("You've already looked everywhere today")
		return
	d.snooped = Save.day
	var chance := 0.0 if cheat_on("sneaky") else (0.3 if npc_home(id) and not npc_asleep(id) else 0.15 if npc_asleep(id) else 0.05)
	if rng.randf() < chance:
		caught_sneaking(id)
		return
	var nm := People.npc_name(id)
	var roll := rng.randf()
	var line := ""
	if roll < 0.35:
		d.known = true
		line = "You find a wish list in a drawer: %s would love %s." % [nm, " and ".join(People.NPCS[id].loves.map(People.gift_name))]
	elif roll < 0.6:
		var entry := ("I think I'm falling for %s…" % Save.player_name) if Save.hearts(id) >= 5.0 else "Busy day. The café chef seems nice."
		line = "You peek at %s's diary: \"%s\"" % [nm, entry]
	elif roll < 0.8:
		var y := 200 + rng.randi() % 600
		Save.wallet += y
		line = "There's %s in a jar marked 'rainy day'. You pocket it… sneaky." % G.yen(y)
	else:
		line = "Just socks. So many socks."
	game.hud.say([["", line]])
	Save.save()

func caught_sneaking(id: String) -> void:
	Save.add_hearts(id, -3.0)
	for k in People.NPCS:
		if k != id: Save.add_hearts(k, -0.3)
	Save.reputation = clampf(Save.reputation - 0.15, 0.0, 5.0)
	Save.flags["sneaked"] = true
	game.npc_react(id, "yuck")
	var lines := {"hana": "Eek! What are you doing in my house?! Get out!", "ren": "…Why are you in my house. Please leave. Now.",
		"kai": "HEY! Who's there?! …You?! Out, out, OUT!", "yuki": "You… came in without asking? I need you to go."}
	game.hud.say([[id, lines[id]], ["", "Word of this will be all over town by morning."]], func(): game.leave_house())
	Save.save()

# ---------------------------------------------------------------- cheats
## Every cheat: code -> [label, category, description, toggle?]. Toggles stay on until switched off.
const CHEATS := {
	"kaching": ["+¥10,000", "Money", "A little pocket money", false],
	"motherlode": ["+¥100,000", "Money", "A lot of pocket money", false],
	"millionaire": ["+¥1,000,000", "Money", "Never worry about money again", false],
	"cookbook": ["Every recipe", "Cooking", "Stamp all 100 recipes in your book", false],
	"pantrypower": ["Full pantry", "Cooking", "20 of every ingredient in your pantry", false],
	"freefood": ["Free ingredients", "Cooking", "The fridge never charges you", true],
	"chefmaster": ["Max chef level", "Cooking", "Jump to chef level 10", false],
	"fivestars": ["5-star café", "Café", "Top café rating", false],
	"rushhour": ["Rush hour", "Café", "Three customers walk in now (café open)", false],
	"criticnow": ["Critic visit", "Café", "A food critic walks in now (café open)", false],
	"zen": ["Patient customers", "Café", "Customers never get tired of waiting", true],
	"nap": ["Full energy", "You", "Feel fully rested", false],
	"tireless": ["Endless energy", "You", "Never get tired", true],
	"speedy": ["Speedy shoes", "You", "Walk much faster", true],
	"timeskip": ["+2 hours", "Time", "Skip ahead two hours", false],
	"morning": ["Morning", "Time", "Jump to 8:00 am", false],
	"evening": ["Evening", "Time", "Jump to 6:00 pm", false],
	"night": ["Night", "Time", "Jump to 9:00 pm", false],
	"sunnyday": ["Sunny", "Time", "Sunny weather", false],
	"rainyday": ["Rainy", "Time", "Rainy weather", false],
	"lovebirds": ["Max hearts", "Love", "Everyone in town adores you", false],
	"giftbag": ["Gift bag", "Love", "One of every gift", false],
	"shinyring": ["Engagement ring", "Love", "A ring for a proposal", false],
	"quickwedding": ["Instant wedding", "Love", "Marry your partner right now", false],
	"storkdelivery": ["Baby now", "Love", "A baby arrives (if married)", false],
	"growup": ["Kids grow up", "Love", "Your kids age by a week", false],
	"sneaky": ["Silent steps", "Love", "Never get caught sneaking or snooping", true],
	"nogossip": ["Tight lips", "Love", "Nobody ever gossips about your secrets", true],
	"forgiveme": ["Forgiven", "Love", "Your partner forgives everything", false],
	"fertile": ["Baby fever", "Love", "Every night together brings a baby", true],
	"loyal": ["Loyal partner", "Love", "Your partner never strays", true],
	"drama": ["Soap opera", "Love", "Maximum drama every morning", true],
	"matchmaker": ["Matchmaker", "Love", "Townsfolk fall for each other", true],
	"festival": ["Festival day", "Time", "Today becomes the Sakura Festival", false],
	"freedecor": ["All furniture", "Stuff", "One of every furniture item in storage", false],
	"nextchapter": ["Next chapter", "Stuff", "Skip to the next story chapter", false],
}

static func cheat_on(code: String) -> bool:
	return bool(Save.flags.get("cheat_" + code, false))

func cheat(code: String) -> String:
	code = code.strip_edges().to_lower().replace(" ", "")
	if not CHEATS.has(code): return "Unknown code"
	var msg := ""
	if CHEATS[code][3]:
		var on := not cheat_on(code)
		Save.flags["cheat_" + code] = on
		msg = "%s %s" % [CHEATS[code][0], "ON" if on else "OFF"]
	else:
		match code:
			"kaching": Save.wallet += 10000; msg = "Ka-ching! +¥10,000"
			"motherlode": Save.wallet += 100000; msg = "Motherlode! +¥100,000"
			"millionaire": Save.wallet += 1000000; msg = "You're a millionaire!"
			"cookbook":
				for r in G.RECIPES:
					if not Save.is_found(r.id): Save.mark_found(r.id)
				msg = "Every recipe is in your book"
			"pantrypower":
				for k in G.ING_KEYS: Save.pantry[k] = maxi(20, int(Save.pantry.get(k, 0)))
				msg = "Your pantry is overflowing"
			"chefmaster": Save.stars_total = maxi(Save.stars_total, 600); msg = "Chef level 10!"
			"fivestars": Save.reputation = 5.0; msg = "Your café is now rated 5 stars"
			"rushhour", "criticnow":
				if not game.shop.open: return "Open the café first"
				if code == "criticnow": game.shop.force_critic = true
				for i in (3 if code == "rushhour" else 1): game.shop.spawn()
				msg = "Here they come!"
			"nap": Save.energy = 100.0; msg = "Fully rested!"
			"timeskip": skip_time(120.0); msg = "Two hours later…"
			"morning": Save.minute = 8 * 60.0; msg = "Good morning!"
			"evening": Save.minute = maxf(Save.minute, 18 * 60.0); msg = "The evening lights come on"
			"night": Save.minute = maxf(Save.minute, 21 * 60.0); msg = "A starry night"
			"sunnyday": Save.weather = "sun"; msg = "The sun comes out"
			"festival": Save.flags["event"] = "festival"; msg = "Lanterns go up all over town!"
			"rainyday": Save.weather = "rain"; msg = "Pitter patter…"
			"lovebirds":
				for k in People.NPCS: Save.add_hearts(k, 10.0)
				msg = "Everyone adores you"
			"giftbag":
				for g in People.GIFTS: Save.gifts[g] = int(Save.gifts.get(g, 0)) + 1
				msg = "One of every gift is in your bag"
			"shinyring": Save.has_ring = true; msg = "A sparkly ring is in your pocket"
			"quickwedding":
				if Save.partner == "": return "You need a partner first"
				if Save.married: return "You're already married!"
				Save.married = true
				Save.wedding_day = Save.day
				Save.has_ring = false
				Save.flags.erase("wedding")
				game.home.refresh_family()
				msg = "Just married! ♥"
			"storkdelivery":
				if not Save.married: return "You need to be married first"
				Save.family.expecting = Save.day
				game.after(0.3, birth)
				msg = "The stork is on its way!"
			"forgiveme":
				if Save.partner == "": return "You don't have a partner"
				Save.flags.erase("gossip")
				Save.r(Save.partner).cheated = 0
				Save.add_hearts(Save.partner, 10.0)
				msg = "All is forgiven ♥"
			"growup":
				if Save.family.kids.is_empty(): return "No kids yet"
				for k in Save.family.kids: k.born = int(k.born) - 7
				game.home.refresh_family()
				msg = "Look how they've grown!"
			"freedecor":
				for id in Furni.CATALOG: Save.furni_inv[id] = int(Save.furni_inv.get(id, 0)) + 1
				msg = "One of everything is in your storage (Edit mode)"
			"nextchapter":
				if not Story.active(): return "No story chapter is active"
				Save.chapter += 1
				msg = "Skipped to the next chapter"
	Save.cheats_used = true
	Sfx.set_ambience(Save.weather == "rain" and Save.settings.get("rain", true))
	if game.loc: game.loc.set_hour(Save.hour())
	Sfx.play("sparkle")
	Save.save()
	return msg
