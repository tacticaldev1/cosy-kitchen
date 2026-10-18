## Story mode: chapters of quests, from inheriting Grandma's little café to running the most
## loved restaurant in Hoshizora Town and raising a family. Quests are checked against the save.
class_name Story
extends RefCounted

const CHAPTERS := [
	{"title": "Grandma's Café", "intro": [
		["Grandma Sachi (a letter)", "My dear, the café is yours now. I'm off to the seaside to grow tomatoes and nap in the sun."],
		["Grandma Sachi (a letter)", "The kitchen knows what you're making, so just play with your food! The town will love you. Love, Grandma ♥"]],
		"quests": [["visit_cafe", "Walk to the café (out the door, then along the street)"], ["cook_any", "Cook anything at a station"], ["open_shop", "Flip the OPEN sign by the café door"],
			["served:3", "Serve 3 customers"], ["slept", "Go home and sleep in your bed"]], "reward": 2000},
	{"title": "Finding Your Feet", "intro": [["Grandpa Jiro", "So you're Sachi's grandchild! I've eaten at that café for forty years. Make the old place proud."],
		["Grandpa Jiro", "Kai's market sells ingredients cheaper than delivery, and Mr. Tanaka at the Home Store has furniture. A café needs tables!"]],
		"quests": [["market", "Stock your pantry at Kai's market"], ["buy_furni", "Buy a piece of furniture at the Home Store"], ["placed", "Place furniture with Edit mode"],
			["served:12", "Serve 12 customers in total"], ["recipes:10", "Discover 10 recipes"]], "reward": 4000},
	{"title": "New Friends", "intro": [["Grandpa Jiro", "A café is only as warm as the people in it. Go and say hello to the town!"]],
		"quests": [["talk_all", "Chat with Hana, Ren, Kai and Yuki"], ["gift", "Give someone a gift"], ["hearts:3", "Reach 3 hearts with someone"]], "reward": 5000},
	{"title": "The Critic", "intro": [["The Hoshizora Times", "Rumour has it Critic Kuroda, the sharpest tongue in the prefecture, is planning a visit to a certain little café…"],
		["Grandpa Jiro", "Kuroda only cares about three things: perfect cooking, speed, and ambition. Cook something hard and cook it well."]],
		"quests": [["rep:2.5", "Raise the café rating to 2.5 stars"], ["critic4", "Earn a 4-star review from a critic"], ["diff4", "Serve a 4-hat recipe"]], "reward": 8000},
	{"title": "Butterflies", "intro": [["Grandpa Jiro", "You've been smiling at someone in town a lot lately. Don't think I haven't noticed!"]],
		"quests": [["hearts:5", "Reach 5 hearts with someone special"], ["date", "Go on a date"], ["partner", "Ask someone to be your partner"]], "reward": 6000},
	{"title": "Wedding Bells", "intro": [["Grandpa Jiro", "Mrs. Kobayashi at the jeweler's has a ring in the window that's been waiting for the right person."]],
		"quests": [["hearts:8", "Reach 8 hearts with your partner"], ["ring", "Buy an engagement ring"], ["married", "Propose and get married"]], "reward": 10000},
	{"title": "A Growing Family", "intro": [["Grandpa Jiro", "A wedding in the park! Sachi would have cried. Now, your home will need more room…"]],
		"quests": [["bed", "Put a double bed in your home"], ["crib", "Put a baby crib in your home"], ["baby", "Welcome a baby into the family"]], "reward": 12000},
	{"title": "Grandma's Legacy", "intro": [["Grandma Sachi (a letter)", "I hear the whole town talks about your café. And a baby! I'm coming to visit with tomatoes."]],
		"quests": [["rep:4.5", "Reach a 4.5-star café rating"], ["recipes:50", "Discover 50 recipes"], ["served:150", "Serve 150 customers"]], "reward": 30000},
]

const ENDING := [["Grandma Sachi", "I sat at the window seat and watched you cook. You laughed with the customers, just like I used to."],
	["Grandma Sachi", "This café was always about love. You filled it with more than I ever did. I'm so proud of you."],
	["", "The story is complete! Hoshizora Town carries on. Keep cooking, decorating and loving as long as you like."]]

static func active() -> bool:
	return Save.mode == "story" and Save.chapter >= 0 and Save.chapter < CHAPTERS.size()

static func chapter() -> Dictionary:
	return CHAPTERS[Save.chapter] if active() else {}

static func max_hearts() -> float:
	var m := 0.0
	for k in People.NPCS: m = maxf(m, Save.hearts(k))
	return m

static func done(q: String) -> bool:
	var p := q.split(":")
	var n := float(p[1]) if p.size() > 1 else 0.0
	match p[0]:
		"served": return Save.served_total >= int(n)
		"recipes": return Save.found_count() >= int(n)
		"rep": return Save.reputation >= n - 0.001
		"hearts":
			if Save.partner != "": return Save.hearts(Save.partner) >= n
			return max_hearts() >= n
		"talk_all":
			for k in People.NPCS:
				if int(Save.r(k).get("talks", 0)) < 1: return false
			return true
		"date": return People.NPCS.keys().any(func(k): return int(Save.r(k).dates) > 0)
		"partner": return Save.partner != ""
		"married": return Save.married
		"ring": return Save.has_ring or Save.married
		"baby": return Save.family.kids.size() > 0
		"bed": return _home_has("bed")
		"crib": return _home_has("crib")
	return Save.flags.get(p[0], false)

static func _home_has(id: String) -> bool:
	for it in Save.layouts.get("home", []):
		if it.id == id: return true
	return false

static func progress() -> Array:
	var out: Array = []
	for q in chapter().get("quests", []):
		out.append([q[1], done(q[0])])
	return out

static func complete() -> bool:
	var ch := chapter()
	if ch.is_empty(): return false
	for q in ch.quests:
		if not done(q[0]): return false
	return true
