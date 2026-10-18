## The people of Hoshizora Town: who they are, what they like, what they say, plus the gift
## catalogue. Pure data and small helpers; Life drives the relationships.
class_name People
extends RefCounted

## Dateable townsfolk. spot = where they hang out in town (a city mark).
const NPCS := {
	"hana": {"name": "Hana", "job": "the florist", "shop": "florist", "spot": "hana", "fav": "Matcha Latte",
		"look": {"body": "f", "skin": "FFE6D6", "hair": "2E3A5A", "shirt": "B7E3A0", "pants": "FFC2D6", "style": "buns", "bottom": "skirt", "acc": "flower"},
		"loves": ["roses", "art_book"], "likes": ["tulips", "sweets", "necklace", "tea_set"],
		"bio": "Runs the flower shop. Knows the meaning of every flower and hums while she works."},
	"ren": {"name": "Ren", "job": "the bookseller", "shop": "bookshop", "spot": "ren", "fav": "Shoyu Ramen",
		"look": {"body": "m", "skin": "F2CDB0", "hair": "3A2A2A", "shirt": "A9C8FF", "pants": "3B4A7A", "style": "short", "bottom": "pants", "acc": "glasses"},
		"loves": ["poetry", "tea_set"], "likes": ["novel", "manga", "sweets", "bracelet"],
		"bio": "Quiet, kind and always reading. Writes poems he never shows anyone."},
	"kai": {"name": "Kai", "job": "the market grocer", "shop": "market", "spot": "kai", "fav": "Katsu Curry",
		"look": {"body": "m", "skin": "E8B896", "hair": "8A4A2A", "shirt": "FFB86A", "pants": "5A4A70", "style": "spiky", "bottom": "shorts", "acc": ""},
		"loves": ["sunflower", "manga"], "likes": ["sweets", "bracelet", "novel"],
		"bio": "Wakes at four to pick the freshest vegetables. Laughs louder than anyone in town."},
	"yuki": {"name": "Yuki", "job": "a painter", "shop": "", "spot": "yuki", "fav": "Fluffy Pancakes",
		"look": {"body": "f", "skin": "FFE2D2", "hair": "F2F2F8", "shirt": "C3A6FF", "pants": "BDEBDD", "style": "long", "bottom": "dress", "acc": "beret"},
		"loves": ["art_book", "bouquet"], "likes": ["tulips", "poetry", "necklace", "sweets"],
		"bio": "Paints the cherry trees in the park every day, in every weather."},
}

## Shopkeepers you buy from (not dateable).
const KEEPERS := {
	"homestore": {"name": "Mr. Tanaka", "look": {"body": "m", "skin": "F2CDB0", "hair": "C8C8D8", "shirt": "E8A04A", "pants": "3B4A7A", "style": "short", "acc": "glasses"}},
	"boutique": {"name": "Mimi", "look": {"body": "f", "bottom": "skirt", "skin": "FFEADF", "hair": "F2B8C8", "shirt": "8B7BC9", "pants": "2E2A3A", "style": "twin", "acc": "bow"}},
	"jeweler": {"name": "Mrs. Kobayashi", "look": {"body": "f", "bottom": "dress", "skin": "FFE2D2", "hair": "6A4AC8", "shirt": "6A8AD8", "pants": "2E2A3A", "style": "bob", "acc": "glasses"}},
	"jiro": {"name": "Grandpa Jiro", "look": {"body": "m", "skin": "E8B896", "hair": "F2F2F8", "shirt": "8A6A4A", "pants": "5A4A70", "style": "short", "acc": "beret"}},
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

## Date questions: [question, [answers], best answer, worst answer (-1 = none)].
const DATES := {
	"hana": [["Which flower do you think suits me?", ["A cherry blossom, gentle and bright.", "Hmm, a cactus?", "All of them. You make every flower look better."], 2, 1],
		["If you could live anywhere, where would you live?", ["Right here, in Hoshizora.", "A big city!", "Wherever you are."], 2, 1],
		["Do you think I talk to my plants too much?", ["A little, yeah.", "They grow so well. They must love it.", "Plants can't hear you."], 1, 2],
		["What would you name a new rose?", ["The Hana.", "Rose #47.", "Sakura Sunrise."], 0, 1],
		["Rainy days: cosy or gloomy?", ["Gloomy, ugh.", "Cosy, with tea and you.", "I don't notice the weather."], 1, 0],
		["Would you ever open a flower café with me?", ["Flowers AND pancakes? Yes!", "Sounds like a lot of work.", "Only if I'm in charge."], 0, 1]],
	"ren": [["What's the last book that made you cry?", ["I don't really read...", "The one about the lighthouse. You lent it to me.", "A cookbook. The soufflé chapter."], 1, 0],
		["Do you believe in fate?", ["Not really.", "I believe in good timing. And good noodles.", "I think I do, now."], 2, 0],
		["Would you read my poems someday?", ["Every single one.", "If they're short.", "Poems are boring."], 0, 2],
		["Paper books or screens?", ["Paper. The smell!", "Screens, they're lighter.", "Audiobooks while cooking."], 0, 1],
		["What's your idea of a perfect quiet evening?", ["A party with friends!", "Rain, tea, two books and you.", "Working late."], 1, 2],
		["If you were a character in a novel, what genre?", ["Romance, obviously.", "A cosy mystery.", "Horror. Have you seen my kitchen?"], 1, 2]],
	"kai": [["Be honest. Tomato: fruit or vegetable?", ["Fruit, scientifically!", "Vegetable, in my kitchen!", "It's whatever makes you smile."], 2, -1],
		["What should we do next weekend?", ["Sleep in.", "The summer festival! Takoyaki and fireworks!", "Work at the café."], 1, 2],
		["Arm wrestle? Right now?", ["You're on!", "I'd rather not.", "Only if the loser buys dinner."], 2, 1],
		["Which veggie is the most underrated?", ["Daikon, obviously.", "Veggies are all the same.", "Lotus root. So crunchy!"], 2, 1],
		["Would you get up at four to pick cabbages with me?", ["Four?! Absolutely not.", "For you? I'll bring coffee.", "Only on weekends."], 1, 0],
		["What's my best quality?", ["Your laugh.", "Your muscles?", "Your cabbages."], 0, 2]],
	"yuki": [["What colour is today?", ["Grey, it's cloudy.", "Peach. Like the evening sky.", "Whatever colour your paintbrush says."], 1, 0],
		["Would you sit for a portrait?", ["Only if you paint my good side.", "Only if you're in it with me.", "I'm too busy, sorry."], 1, 2],
		["Sunrise or sunset?", ["Sunset, when the café lights come on.", "Neither, I'm asleep.", "Sunrise, with you."], 2, 1],
		["What would you paint, if you could?", ["Your smile.", "The cherry tree, like you.", "Nothing, I can't draw."], 0, 2],
		["Do you think quiet people are boring?", ["Quiet people notice everything.", "A little, sometimes.", "I love quiet with you."], 2, 1],
		["If we were a painting, which one?", ["A rainy café window.", "A busy city street.", "Two people under one umbrella."], 2, 1]],
}

## Questions anyone might ask on any date.
const QUESTIONS := [
	["What's your comfort food?", ["Fluffy pancakes, always.", "Instant noodles at 2am.", "Whatever you're having."], 2, -1],
	["Do you believe in love at first sight?", ["Should I walk past you again?", "No, love takes time.", "I've never thought about it."], 0, 2],
	["What's your biggest dream?", ["A café the whole town loves.", "To be rich.", "A family and a garden."], 2, 1],
	["Cats or dogs?", ["Cats. Mochi rules the café.", "Dogs, obviously.", "Both, in a big pile."], 2, -1],
	["What scares you the most?", ["Burnt rice.", "Losing the people I love.", "Spiders. Big ones."], 1, 0],
	["What do you notice first about someone?", ["Their smile.", "Their shoes.", "Their cooking."], 0, 1],
	["Summer festival or winter lights?", ["Summer fireworks!", "Winter lights and hot cocoa.", "Whichever one you're at."], 2, -1],
	["Would you rather fly or read minds?", ["Fly, over the cherry trees.", "Read minds… wait, can you?", "Neither, I like surprises."], 0, -1],
]

## Kinds of dates: where, when (hours), cost and which spot the scene uses.
const DATE_TYPES := {
	"icecream": {"name": "Ice cream by the fountain", "cost": 1500, "from": 9, "to": 20, "spot": "bench", "line": "You share soft-serve cones on a bench by the fountain while kids chase pigeons."},
	"picnic": {"name": "Picnic under the cherry trees", "cost": 2000, "from": 9, "to": 18, "spot": "picnic", "line": "You spread a gingham blanket under the cherry blossoms. Onigiri, strawberries and petals everywhere."},
	"painting": {"name": "Painting in the park", "cost": 1200, "from": 9, "to": 18, "spot": "picnic", "line": "You sit side by side with little canvases. Yours looks like a potato. Theirs is beautiful."},
	"books": {"name": "Browsing Ren's Books", "cost": 1000, "from": 9, "to": 20, "spot": "bookshop", "line": "You read the first lines of random books out loud to each other and try not to laugh too loudly."},
	"shopping": {"name": "Shopping spree at Mimi's", "cost": 3000, "from": 10, "to": 20, "spot": "boutique", "line": "Mimi makes you try on matching scarves. You buy them. Of course you buy them."},
	"market": {"name": "Food tasting at the market", "cost": 1500, "from": 8, "to": 19, "spot": "market", "line": "You taste every sample at the market: pickles, mochi, the spiciest radish in Japan."},
	"flowers": {"name": "Flower arranging at the florist", "cost": 1500, "from": 9, "to": 19, "spot": "florist", "line": "You make little bouquets for each other. Yours is mostly daisies and enthusiasm."},
	"dinner": {"name": "Candlelit dinner at your café", "cost": 2500, "from": 17, "to": 23, "spot": "cafe", "line": "You close the café early, light a candle and cook something special for two."},
	"movie": {"name": "Movie night at your place", "cost": 800, "from": 18, "to": 26, "spot": "home", "line": "A blanket, a bowl of popcorn, and a romance movie that makes you both cry."},
	"festival": {"name": "The summer festival together", "cost": 1000, "from": 17, "to": 24, "spot": "festival", "festival": true, "line": "You share takoyaki, win a goldfish, and stand together under the lanterns as the first fireworks bloom over the rooftops."},
	"stargazing": {"name": "Stargazing by the fountain", "cost": 0, "from": 20, "to": 26, "spot": "fountain", "line": "The town lights go out one by one. You count shooting stars and make secret wishes."},
}
const DATE_LIKES := {"hana": ["flowers", "picnic", "dinner", "festival"], "ren": ["books", "stargazing", "movie"], "kai": ["market", "dinner", "picnic", "festival"], "yuki": ["painting", "stargazing", "icecream", "festival"]}
const DATE_DISLIKES := {"hana": ["market"], "ren": ["shopping"], "kai": ["books"], "yuki": ["shopping"]}

## Things the town does on special days.
const EVENTS := {
	"festival": ["Summer Festival", "Food stalls, lanterns and fireworks on Main Street from 4pm! The café is busier and tips are 50% bigger."],
	"sale": ["Market Sale Day", "Kai's market has everything at half price today."],
	"critics": ["Critics' Week", "Food critics are touring the prefecture. Expect a visit!"],
	"sweet": ["Sweet Tooth Day", "Everyone's craving desserts and drinks today (bonus tips for them)."],
	"hearts": ["Heart Day", "Love is in the air: dates and gifts mean twice as much today."],
}
