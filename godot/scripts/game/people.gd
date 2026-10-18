## The people of Hoshizora Town: who they are, what they like, what they say, plus the gift
## catalogue. Pure data and small helpers; Life drives the relationships.
class_name People
extends RefCounted

## Dateable townsfolk. spot = where they hang out in town (a city mark).
const NPCS := {
	"hana": {"name": "Hana", "job": "the florist", "shop": "florist", "spot": "hana", "fav": "Matcha Latte",
		"look": {"skin": "FFE6D6", "hair": "2E3A5A", "shirt": "B7E3A0", "pants": "FFC2D6", "style": "buns", "acc": "flower"},
		"loves": ["roses", "art_book"], "likes": ["tulips", "sweets", "necklace", "tea_set"],
		"bio": "Runs the flower shop. Knows the meaning of every flower and hums while she works."},
	"ren": {"name": "Ren", "job": "the bookseller", "shop": "bookshop", "spot": "ren", "fav": "Shoyu Ramen",
		"look": {"skin": "F2CDB0", "hair": "3A2A2A", "shirt": "A9C8FF", "pants": "3B4A7A", "style": "short", "acc": "glasses"},
		"loves": ["poetry", "tea_set"], "likes": ["novel", "manga", "sweets", "bracelet"],
		"bio": "Quiet, kind and always reading. Writes poems he never shows anyone."},
	"kai": {"name": "Kai", "job": "the market grocer", "shop": "market", "spot": "kai", "fav": "Katsu Curry",
		"look": {"skin": "E8B896", "hair": "8A4A2A", "shirt": "FFB86A", "pants": "5A4A70", "style": "spiky", "acc": ""},
		"loves": ["sunflower", "manga"], "likes": ["sweets", "bracelet", "novel"],
		"bio": "Wakes at four to pick the freshest vegetables. Laughs louder than anyone in town."},
	"yuki": {"name": "Yuki", "job": "a painter", "shop": "", "spot": "yuki", "fav": "Fluffy Pancakes",
		"look": {"skin": "FFE2D2", "hair": "F2F2F8", "shirt": "C3A6FF", "pants": "BDEBDD", "style": "long", "acc": "beret"},
		"loves": ["art_book", "bouquet"], "likes": ["tulips", "poetry", "necklace", "sweets"],
		"bio": "Paints the cherry trees in the park every day, in every weather."},
}

## Shopkeepers you buy from (not dateable).
const KEEPERS := {
	"homestore": {"name": "Mr. Tanaka", "look": {"skin": "F2CDB0", "hair": "C8C8D8", "shirt": "E8A04A", "pants": "3B4A7A", "style": "short", "acc": "glasses"}},
	"boutique": {"name": "Mimi", "look": {"skin": "FFEADF", "hair": "F2B8C8", "shirt": "8B7BC9", "pants": "2E2A3A", "style": "twin", "acc": "bow"}},
	"jeweler": {"name": "Mrs. Kobayashi", "look": {"skin": "FFE2D2", "hair": "6A4AC8", "shirt": "6A8AD8", "pants": "2E2A3A", "style": "bob", "acc": "glasses"}},
	"jiro": {"name": "Grandpa Jiro", "look": {"skin": "E8B896", "hair": "F2F2F8", "shirt": "8A6A4A", "pants": "5A4A70", "style": "short", "acc": "beret"}},
}

## gift id: [name, price, sold at, colour]
const GIFTS := {
	"tulips": ["Tulips", 600, "florist", "FF9EBB"],
	"sunflower": ["Sunflower", 500, "florist", "FFD24A"],
	"roses": ["Red roses", 1500, "florist", "E8404A"],
	"bouquet": ["Big bouquet", 2600, "florist", "C3A6FF"],
	"novel": ["Mystery novel", 900, "bookshop", "6A8AD8"],
	"poetry": ["Poetry book", 700, "bookshop", "BDEBDD"],
	"manga": ["Manga volume", 500, "bookshop", "FF7EA6"],
	"art_book": ["Art book", 1800, "bookshop", "FFB86A"],
	"sweets": ["Box of sweets", 400, "market", "FFC2D6"],
	"tea_set": ["Tea set", 1200, "market", "7FD3B8"],
	"bracelet": ["Bracelet", 4000, "jeweler", "A9C8FF"],
	"necklace": ["Necklace", 6000, "jeweler", "FFD24A"],
}
const RING_PRICE := 30000

static func gift_name(id: String) -> String:
	return GIFTS[id][0] if GIFTS.has(id) else id

static func npc_name(id: String) -> String:
	if NPCS.has(id): return NPCS[id].name
	if KEEPERS.has(id): return KEEPERS[id].name
	return id.capitalize()

static func look_of(id: String) -> Dictionary:
	if NPCS.has(id): return NPCS[id].look
	if KEEPERS.has(id): return KEEPERS[id].look
	return {}

## How much a gift means to someone: 2 loved, 1 liked, 0.5 otherwise.
static func gift_value(npc: String, gift: String) -> float:
	var d: Dictionary = NPCS[npc]
	if d.loves.has(gift): return 2.0
	if d.likes.has(gift): return 1.0
	return 0.5

static func gift_reaction(npc: String, gift: String) -> String:
	var v := gift_value(npc, gift)
	var g := gift_name(gift).to_lower()
	if v >= 2.0:
		return {"hana": "A %s? Oh! This is exactly what I hoped for. Thank you, really." % g, "ren": "...You remembered. I'll treasure this %s." % g,
			"kai": "NO WAY! A %s! You're the best, you know that?" % g, "yuki": "Oh, this %s makes my heart do a little twirl." % g}[npc]
	if v >= 1.0:
		return {"hana": "How sweet of you! I love it.", "ren": "Thank you. That's very thoughtful.", "kai": "Ha, nice one! Thanks, chef!", "yuki": "For me? That's lovely, thank you."}[npc]
	return {"hana": "Oh, thank you! That's kind.", "ren": "Ah. Thank you.", "kai": "Huh, thanks! I'll find a use for it.", "yuki": "Thank you. I'll think of you when I see it."}[npc]

## What someone says when you chat, by how close you are.
static func chat_line(npc: String, h: float, partner: bool, married: bool, rng: RandomNumberGenerator) -> String:
	var tiers: Dictionary = LINES[npc]
	var pool: Array
	if married: pool = tiers.married
	elif partner: pool = tiers.partner
	elif h >= 6.0: pool = tiers.close
	elif h >= 3.0: pool = tiers.friend
	else: pool = tiers.stranger
	return pool[rng.randi() % pool.size()]

const LINES := {
	"hana": {
		"stranger": ["Oh, you're the new owner of the café? Welcome to Hoshizora!", "These are camellias. They mean 'longing'. Not that I'm longing for anything!", "If you ever need flowers for your tables, you know where to find me."],
		"friend": ["I walked past the café this morning. It smelled like heaven.", "Do you want to know a secret? I talk to the flowers. They grow better.", "You always look so busy. Remember to stop and smell the roses. Literally!"],
		"close": ["I saved the prettiest tulip for you today. Don't tell the others.", "When I can't sleep, I think about your matcha lattes. Is that weird?", "I feel like I can tell you anything. That's rare, you know."],
		"partner": ["Every flower in my shop is jealous of you.", "I pressed one of the roses from our first date. It's in my diary.", "Come by after closing? I'll make us tea."],
		"married": ["Good morning, my love. I put fresh flowers by the bed.", "Our home smells like flowers and pancakes. I love it.", "I'm so happy I said yes."],
	},
	"ren": {
		"stranger": ["...Oh. Hello. Are you looking for a book?", "The café's new chef? I read about you in the paper.", "This one? It's about a lighthouse keeper. It's quiet. I like quiet."],
		"friend": ["I found a cookbook from 1962. I thought of you.", "Your ramen is better than the one in this novel. And the novel won awards.", "I don't talk much. But I like talking to you."],
		"close": ["I wrote a poem. It's... not about anyone. Maybe it is.", "When you laugh, I forget what page I was on.", "Will you sit with me a while? The shop can wait."],
		"partner": ["I've started writing our story. Chapter one is the day we met.", "You're my favourite thing to read.", "I bought two copies of this book so we can read together."],
		"married": ["I made coffee. Badly. Sorry. I love you.", "Our home is my favourite library.", "Every day with you is a good chapter."],
	},
	"kai": {
		"stranger": ["Hey hey! You're the café chef? These daikon are the best in the prefecture!", "Up since four! The early bird gets the crispiest cabbage!", "Need ingredients? My market's cheaper than delivery, I promise!"],
		"friend": ["Your katsu curry? I dream about it. Real dreams.", "I saved you the reddest tomatoes. Market secret!", "Wanna arm wrestle? No? Next time!"],
		"close": ["Honestly? Mornings are better now that you stop by.", "My grandma says I talk about you too much. She's right.", "You make this whole town feel warmer, you know?"],
		"partner": ["I told the whole market about us. Sorry. Not sorry!", "I grew a heart-shaped potato. It's for you.", "Let's get takoyaki at the festival together!"],
		"married": ["Morning, sunshine! Breakfast is on me today.", "I still can't believe you married a guy who sells cabbages.", "Our family is the best thing I ever grew."],
	},
	"yuki": {
		"stranger": ["Hello. The light through the cherry trees is perfect today.", "I paint the same tree every day. It's never the same tree.", "Your café's window glows at night. I've painted it twice."],
		"friend": ["Can I paint you someday? You have a very warm colour.", "Rainy days are my favourite. Everything shines.", "I tried your pancakes. I painted them afterwards."],
		"close": ["I keep painting a figure by the café window. I think it's you.", "When you're around, my colours come out softer.", "Sit with me? We don't have to talk."],
		"partner": ["I finished the painting of us. I'm hanging it in the gallery. And in my heart.", "Let's watch the sunset from the fountain.", "You're my favourite colour."],
		"married": ["Our kitchen is my favourite gallery.", "I painted the baby's room with little stars.", "Good morning. You're still my favourite colour."],
	},
}

## Date conversation: a question with three answers; the best answer gives extra hearts.
const DATES := {
	"hana": [["Which flower do you think suits me?", ["A cherry blossom, gentle and bright.", "Hmm, a cactus?", "All of them. You make every flower look better."], 2],
		["If you could live anywhere, where would you live?", ["Right here, in Hoshizora.", "A big city!", "Wherever you are."], 2]],
	"ren": [["What's the last book that made you cry?", ["I don't really read...", "The one about the lighthouse. You lent it to me.", "A cookbook. The soufflé chapter."], 1],
		["Do you believe in fate?", ["Not really.", "I believe in good timing. And good noodles.", "I think I do, now."], 2]],
	"kai": [["Be honest. Tomato: fruit or vegetable?", ["Fruit, scientifically!", "Vegetable, in my kitchen!", "It's whatever makes you smile."], 2],
		["What should we do next weekend?", ["Sleep in.", "The summer festival! Takoyaki and fireworks!", "Work at the café."], 1]],
	"yuki": [["What colour is today?", ["Grey, it's cloudy.", "Peach. Like the evening sky.", "Whatever colour your paintbrush says."], 1],
		["Would you sit for a portrait?", ["Only if you paint my good side.", "Only if you're in it with me.", "I'm too busy, sorry."], 1]],
}
