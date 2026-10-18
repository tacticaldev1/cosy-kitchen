## G: the game's data and rules. Ingredients, the 100 recipes, prices, recipe detection,
## auto-written steps, and how any food should look (its "spec"). A faithful port of the
## web version (src/02, src/04, src/06) so both games agree on every recipe.
extends Node

# ------------------------------------------------------------------ ingredients
# key: [name, category, shape, colour, light colour, mix colour?, mix weight?]
const ING_DEF := {
	"apple": ["Apple", "fruit", "round", "F2545B", "FFE7C2"], "banana": ["Banana", "fruit", "banana", "FFE070", "FFF6D6", "FFF0B0"],
	"strawberry": ["Strawberry", "fruit", "straw", "F0475E", "FFD5DD", "FF7A92"], "blueberry": ["Blueberry", "fruit", "cluster", "5B6CD6", "A9B5FF", "7C5CC9"],
	"orange": ["Orange", "fruit", "round", "FF9F2E", "FFE3B0"], "lemon": ["Lemon", "fruit", "lemon", "FFE24A", "FFF8C8", "FFF19A", 0.6],
	"mango": ["Mango", "fruit", "mango", "FFB53B", "FFE08A"], "pineapple": ["Pineapple", "fruit", "pine", "FFC93C", "FFF0A8", "FFE27A"],
	"watermelon": ["Watermelon", "fruit", "melon", "FF5C77", "FFC2CC"], "avocado": ["Avocado", "fruit", "avo", "7DB54A", "E2F09A", "B8DC7A"],
	"cherry": ["Cherry", "fruit", "cherry", "E0233F", "FF8095"],
	"tomato": ["Tomato", "veg", "round", "F24B3B", "FFB3A8"], "lettuce": ["Lettuce", "veg", "leafy", "8ED16B", "D9F5C2"],
	"cucumber": ["Cucumber", "veg", "long", "4E9E57", "D2EFB6"], "carrot": ["Carrot", "veg", "carrot", "FF8A2B", "FFC48A"],
	"potato": ["Potato", "veg", "potato", "D9A86C", "FFF0C8", "F6E2B0"], "onion": ["Onion", "veg", "onion", "B97ACB", "F3E2F7", "F2E6EE", 0.5],
	"mushroom": ["Mushroom", "veg", "mushroom", "C98F65", "FFF1E2"], "pepper": ["Pepper", "veg", "pepper", "F44E3F", "FFB09E"],
	"corn": ["Corn", "veg", "corn", "FFD24A", "FFF0A0"], "broccoli": ["Broccoli", "veg", "broccoli", "4E9E57", "9BD27E"],
	"spinach": ["Spinach", "veg", "leafy", "3F8A4A", "9BD27E"], "pumpkin": ["Pumpkin", "veg", "pumpkin", "FF9A3C", "FFD199"],
	"cabbage": ["Cabbage", "veg", "cabbage", "BFE6A0", "EFFAE2"],
	"egg": ["Egg", "protein", "egg", "FFF4E2", "FFC93C", "FFD45A"], "chicken": ["Chicken", "protein", "drum", "FFD2B8", "FFEDE2"],
	"beef": ["Beef", "protein", "steak", "D9475A", "FFC2C8", "9A4A3A"], "sausage": ["Sausage", "protein", "sausage", "D9654A", "FFB59E"],
	"bacon": ["Bacon", "protein", "bacon", "E8677A", "FFE0E3"], "salmon": ["Salmon", "protein", "fillet", "F4895A", "FFE3D2"],
	"tuna": ["Tuna", "protein", "fillet", "D63B4E", "F57C8C"], "shrimp": ["Shrimp", "protein", "shrimp", "FF9C7A", "FFE3D8"],
	"crab": ["Crab stick", "protein", "strip", "E9523F", "FFF1EA"], "tofu": ["Tofu", "protein", "block", "FFF8E8", "FFFFFF"],
	"milk": ["Milk", "dairy", "carton", "FFFFFF", "8EC5F0", "FFFDF8"], "cheese": ["Cheese", "dairy", "wedge", "FFD54A", "FFF0A0"],
	"butter": ["Butter", "dairy", "stick", "FFE58A", "FFF6C8", "FFE58A", 0.3], "yogurt": ["Yogurt", "dairy", "tub", "FFF5F8", "FF9EBB", "FFF8FA"],
	"cream": ["Cream", "dairy", "carton", "FFFFFF", "FFB3CF", "FFFBF6"],
	"flour": ["Flour", "grain", "bag", "F7F1E6", "E8C9A0", "FBF3E4"], "bread": ["Bread", "grain", "bread", "E8B26A", "FFF0D2"],
	"rice": ["Rice", "grain", "sack", "FFFFFF", "9FD3C0", "FFFFFF"], "pasta": ["Pasta", "grain", "pasta", "F7D27A", "FFF0C0"],
	"noodles": ["Noodles", "grain", "noodle", "F6E0A0", "FFF6D8"], "oats": ["Oats", "grain", "bag", "E8D2A6", "C8A878", "E8D6B0"],
	"tortilla": ["Tortilla", "grain", "tortilla", "F2D49B", "FFF0D0"], "nori": ["Nori", "grain", "sheet", "1F2C25", "3F5E4C", "1F2C25", 0.2],
	"sugar": ["Sugar", "pantry", "bag", "FFFFFF", "FFB7CF", "FFFFFF", 0.2], "honey": ["Honey", "pantry", "jar", "F6B73C", "FFE29A", "F6C25A", 0.35],
	"chocolate": ["Chocolate", "pantry", "bar", "6B3A26", "A0674A"], "matcha": ["Matcha", "pantry", "tin", "8CC152", "D7F0B8", "9BCB5E"],
	"coffee": ["Coffee", "pantry", "tin", "6B4430", "C79A7A", "7A4A30"], "soy": ["Soy sauce", "pantry", "bottle", "4A2618", "F06A4A", "6A3A22", 0.25],
	"curry": ["Curry roux", "pantry", "box", "C8812E", "FFD27A", "B8732A"], "ice": ["Ice", "pantry", "cube", "DFF4FF", "FFFFFF", "EAF6FF", 0.2],
	"kernels": ["Popcorn", "pantry", "kernel", "FFD24A", "FFFBEA"], "redbean": ["Red bean", "pantry", "jar", "7A2E3A", "E8A0A8"],
	"syrup": ["Syrup", "pantry", "bottle", "B4642A", "E8A05A", "B4642A", 0.3], "sprinkles": ["Sprinkles", "pantry", "sprink", "FF7EA6", "7FD3F7", "FFD0E0", 0.1],
}
const CATS := [["fruit", "Fruit"], ["veg", "Veg"], ["protein", "Protein"], ["dairy", "Dairy"], ["grain", "Grains"], ["pantry", "Pantry"]]

# Ingredient cost is one portion at a Japanese supermarket (yen).
const ING_COST := {"apple": 150, "banana": 40, "strawberry": 120, "blueberry": 150, "orange": 60, "lemon": 100, "mango": 250, "pineapple": 150, "watermelon": 150, "avocado": 180, "cherry": 150,
	"tomato": 80, "lettuce": 60, "cucumber": 50, "carrot": 40, "potato": 40, "onion": 30, "mushroom": 100, "pepper": 60, "corn": 120, "broccoli": 150, "spinach": 80, "pumpkin": 150, "cabbage": 60,
	"egg": 25, "chicken": 250, "beef": 300, "sausage": 80, "bacon": 120, "salmon": 180, "tuna": 200, "shrimp": 150, "crab": 60, "tofu": 60,
	"milk": 40, "cheese": 80, "butter": 40, "yogurt": 60, "cream": 120, "flour": 20, "bread": 40, "rice": 50, "pasta": 40, "noodles": 60, "oats": 30, "tortilla": 50, "nori": 20,
	"sugar": 5, "honey": 40, "chocolate": 100, "matcha": 80, "coffee": 50, "soy": 5, "curry": 60, "ice": 5, "kernels": 30, "redbean": 80, "syrup": 40, "sprinkles": 20}

const MENU_PRICE := {"Fluffy Pancakes": 1100, "Chocolate Pancakes": 1200, "Blueberry Pancakes": 1200, "Banana Pancakes": 1150, "Strawberry Pancakes": 1300, "Crêpes": 750, "Sunny Fried Egg": 250, "Scrambled Eggs": 450, "Cheese Omelette": 700, "Veggie Omelette": 750, "Toast": 250, "Egg on Toast": 450, "French Toast": 850, "Avocado Toast": 900, "Porridge": 500, "Yogurt Parfait": 650, "Bacon & Eggs": 800, "Full Breakfast": 1400,
	"Strawberry Smoothie": 600, "Banana Smoothie": 550, "Berry Blast": 650, "Mango Lassi": 600, "Tropical Smoothie": 700, "Green Smoothie": 650, "Chocolate Milkshake": 650, "Strawberry Milkshake": 650, "Lemonade": 450, "Orange Juice": 450, "Watermelon Juice": 500, "Hot Chocolate": 500, "Matcha Latte": 550, "Iced Matcha": 580, "Café Latte": 480, "Honey Lemon Tea": 450,
	"Salmon Maki": 600, "Tuna Maki": 650, "Cucumber Maki": 350, "California Roll": 800, "Futomaki": 900, "Onigiri": 200, "Salmon Onigiri": 320, "Salmon Nigiri": 380, "Tuna Nigiri": 420, "Tamagoyaki": 450, "Shoyu Ramen": 900, "Chicken Ramen": 980, "Yakisoba": 750, "Japanese Curry": 850, "Katsu Curry": 1100, "Oyakodon": 850, "Okonomiyaki": 950, "Gyoza": 550, "Mochi": 400, "Dorayaki": 300, "Shrimp Tempura": 1100, "Honey Toast": 950,
	"Spaghetti Pomodoro": 1000, "Mac & Cheese": 900, "Carbonara": 1200, "Margherita Pizza": 1400, "Pepperoni Pizza": 1500, "Hamburger": 1000, "Cheeseburger": 1100, "Hot Dog": 600, "Roast Chicken": 1600, "Fish & Chips": 1300, "Fried Rice": 750, "Veggie Stir-fry": 800, "Tacos": 900, "Grilled Cheese": 700,
	"Tomato Soup": 550, "Pumpkin Soup": 600, "Corn Soup": 500, "Mushroom Soup": 600, "Chicken Noodle Soup": 750, "Beef Stew": 1200,
	"Garden Salad": 600, "Fruit Salad": 650, "Popcorn": 300, "Butter Popcorn": 350, "Caramel Popcorn": 400, "Fries": 400, "Guacamole": 700, "Corn on the Cob": 350, "Cheesy Nachos": 750,
	"Chocolate Chip Cookies": 400, "Sugar Cookies": 350, "Vanilla Cupcakes": 450, "Chocolate Cupcakes": 500, "Strawberry Shortcake": 650, "Chocolate Cake": 600, "Carrot Cake": 600, "Apple Pie": 650, "Banana Bread": 450, "Brownies": 450, "Strawberry Ice Cream": 450, "Matcha Ice Cream": 480, "Mango Sorbet": 450, "Purin": 350, "Rainbow Popsicle": 450}

# ------------------------------------------------------------------ recipes
# Name|category|art.style|groups|optional|description
# Groups are "ing,ing:tag,tag;ing:tag". Every ingredient in a group needs all of that group's tags.
# "hot" = any heat (boil, fry, bake, zap). "stir" = mix or blend.
const RECIPE_SRC := """Fluffy Pancakes|breakfast|stack|egg,flour,milk:mix,fry|sugar,butter,syrup,strawberry,blueberry,honey|Golden, wobbly and stacked sky high.
Chocolate Pancakes|breakfast|stack.choc|egg,flour,milk,chocolate:mix,fry|syrup,strawberry,banana,cream|Cocoa-dark pancakes for sweet mornings.
Blueberry Pancakes|breakfast|stack|egg,flour,milk,blueberry:mix,fry|syrup,butter|Little purple berries in every bite.
Banana Pancakes|breakfast|stack|egg,flour,milk,banana:mix,fry|honey,syrup|Soft, sweet and extra fluffy.
Strawberry Pancakes|breakfast|stack|egg,flour,milk:mix,fry;strawberry:chop|cream,syrup|A pancake stack crowned with fresh strawberries.
Crêpes|breakfast|stack.crepe|egg,flour,milk,butter:mix,fry|strawberry,banana,chocolate,cream|Thin, buttery and folded into triangles.
Sunny Fried Egg|breakfast|egg|egg:fry|bread|One perfect yolk, sunny side up.
Scrambled Eggs|breakfast|egg.scramble|egg,milk:mix,fry|butter,cheese|Soft fluffy clouds of egg.
Cheese Omelette|breakfast|egg.omelette|egg,cheese:mix,fry|milk,mushroom|Folded over a gooey cheesy middle.
Veggie Omelette|breakfast|egg.omelette|egg:mix,fry;pepper,onion:chop,mix,fry|cheese,mushroom,tomato|Packed with crunchy pepper and onion.
Toast|breakfast|toast|bread:bake|butter,honey|Warm, crunchy and golden.
Egg on Toast|breakfast|toast.egg|bread:bake;egg:fry||A fried egg on a golden slice.
French Toast|breakfast|toast.french|bread,egg,milk:mix,fry|syrup,strawberry,sugar|Eggy bread fried until golden.
Avocado Toast|breakfast|toast.avo|bread:bake;avocado:chop|egg,tomato,lemon|Smashed avocado on crunchy toast.
Porridge|breakfast|bowl.porridge|oats,milk:boil|honey,banana,blueberry,strawberry|A warm hug in a bowl.
Yogurt Parfait|breakfast|glass.parfait|yogurt,oats:mix;strawberry:chop|honey,blueberry|Layers of yogurt, oats and berries.
Bacon & Eggs|breakfast|egg.bacon|egg,bacon:fry|bread|The sizzling classic.
Full Breakfast|breakfast|plate.breakfast|egg,bacon,sausage:fry;bread:bake|tomato,mushroom|Everything you need to start the day.
Strawberry Smoothie|drinks|glass|strawberry,milk:blend|yogurt,ice,honey,banana|Pink, creamy and dreamy.
Banana Smoothie|drinks|glass|banana,milk:blend|honey,ice|Mellow, sweet and smooth.
Berry Blast|drinks|glass|strawberry,blueberry,yogurt:blend|honey,ice,milk|A purple pop of berries.
Mango Lassi|drinks|glass|mango,yogurt:blend|honey,milk|Sunny mango and cool yogurt.
Tropical Smoothie|drinks|glass|mango,pineapple,banana:blend|ice,yogurt,milk|An island holiday in a glass.
Green Smoothie|drinks|glass|spinach,banana,apple:blend|honey,yogurt|Surprisingly sweet and very green.
Chocolate Milkshake|drinks|glass.shake|chocolate,milk,ice:blend|cream,banana|Thick, cold and chocolatey.
Strawberry Milkshake|drinks|glass.shake|strawberry,milk,ice:blend|cream,sugar|Pink with a cherry on top.
Lemonade|drinks|glass.ice|lemon,sugar,ice:mix|strawberry|Sour, sweet and fresh.
Orange Juice|drinks|glass|orange:blend|ice|Squeezed sunshine.
Watermelon Juice|drinks|glass|watermelon:blend|ice,lemon|Summer in a cup.
Hot Chocolate|drinks|mug|chocolate,milk:hot|cream,sugar|Cosy cocoa for rainy nights.
Matcha Latte|drinks|mug|matcha,milk:hot|honey,sugar|Earthy green tea with steamed milk.
Iced Matcha|drinks|glass.ice|matcha,milk,ice:mix|honey|Green, creamy and chilled.
Café Latte|drinks|mug|coffee,milk:hot|sugar,cream|Coffee with a milky heart.
Honey Lemon Tea|drinks|mug|lemon,honey:boil||Soothing, sweet and tangy.
Salmon Maki|japanese|maki|rice:boil,roll,chop;nori:roll,chop;salmon:roll,chop|avocado,cucumber|Rice, nori and salmon rolled and sliced.
Tuna Maki|japanese|maki|rice:boil,roll,chop;nori:roll,chop;tuna:roll,chop|cucumber|Ruby-red tuna in a neat little roll.
Cucumber Maki|japanese|maki|rice:boil,roll,chop;nori:roll,chop;cucumber:roll,chop||Crunchy, fresh and simple.
California Roll|japanese|maki|rice:boil,roll,chop;nori:roll,chop;crab,avocado,cucumber:roll,chop||Crab, avocado and cucumber in one roll.
Futomaki|japanese|maki|rice:boil,roll,chop;nori:roll,chop;egg:fry,roll,chop;crab,cucumber:roll,chop||A big, colourful festival roll.
Onigiri|japanese|onigiri|rice:boil;nori:||A smiling rice ball wrapped in nori.
Salmon Onigiri|japanese|onigiri|rice:boil;nori:;salmon:fry||A rice ball with flaky salmon inside.
Salmon Nigiri|japanese|onigiri.nigiri|rice:boil;salmon:chop||Silky salmon on a pillow of rice.
Tuna Nigiri|japanese|onigiri.nigiri|rice:boil;tuna:chop||Classic tuna on rice.
Tamagoyaki|japanese|egg.tamago|egg,sugar,soy:mix,fry,roll||Sweet rolled omelette, sliced into spirals.
Shoyu Ramen|japanese|bowl.ramen|noodles,soy,egg:boil|spinach,mushroom,corn|Slurpy noodles in soy broth.
Chicken Ramen|japanese|bowl.ramen|noodles,soy,chicken:boil|egg,corn,spinach|Hearty chicken noodle comfort.
Yakisoba|japanese|pile.noodle|noodles,carrot,pepper,soy:fry|cabbage,beef|Sizzling stir-fried noodles.
Japanese Curry|japanese|bowl.curry|rice:boil;curry,potato,carrot,onion:boil|beef,chicken|Mild, thick curry beside fluffy rice.
Katsu Curry|japanese|bowl.curry|rice:boil;curry,potato,carrot:boil;chicken,flour,egg:fry||Crispy chicken cutlet with curry.
Oyakodon|japanese|bowl.don|rice:boil;chicken,egg,onion:boil|soy|Chicken and egg simmered over rice.
Okonomiyaki|japanese|stack.okonomi|flour,egg,cabbage:mix,fry|bacon,soy|A savoury cabbage pancake with a sauce zig-zag.
Gyoza|japanese|pile.dumpling|flour,beef,cabbage:mix,fry|soy,onion|Pan-fried dumplings with crispy bottoms.
Mochi|japanese|scoop.mochi|rice,sugar:boil,mix|matcha,strawberry|Squishy, chewy rice cakes.
Dorayaki|japanese|stack.dorayaki|flour,egg,honey:mix,fry;redbean:||Two fluffy pancakes hugging sweet red bean.
Shrimp Tempura|japanese|pile.tempura|shrimp,flour,egg:fry|soy|Light, crunchy battered shrimp.
Honey Toast|japanese|toast.honey|bread:bake;honey,butter:|cream|A tall toast tower dripping with honey.
Spaghetti Pomodoro|mains|bowl.pasta|pasta:boil;tomato,onion:fry|cheese|Pasta in a bright tomato sauce.
Mac & Cheese|mains|bowl.mac|pasta:boil;cheese,milk:hot|butter|Creamy, cheesy, cosy.
Carbonara|mains|bowl.pasta|pasta:boil;egg,cheese,bacon:fry||Silky egg and crispy bacon pasta.
Margherita Pizza|mains|pizza|flour:mix,bake;tomato,cheese:bake||Tomato, cheese and a golden crust.
Pepperoni Pizza|mains|pizza|flour:mix,bake;tomato,cheese,sausage:bake||Little sausage coins on a cheesy pizza.
Hamburger|mains|burger|beef:fry;bread:;lettuce:|tomato,onion|A juicy patty in a soft bun.
Cheeseburger|mains|burger|beef:fry;bread:;cheese:|lettuce,tomato|A burger with a melty cheese hat.
Hot Dog|mains|hotdog|sausage:fry;bread:|onion|A sausage tucked in a bun.
Roast Chicken|mains|plate.roast|chicken:bake|potato,carrot|Golden, crackly and juicy.
Fish & Chips|mains|plate.fish|salmon,flour:fry;potato:chop,fry|lemon|Crunchy battered fish with chips.
Fried Rice|mains|pile.rice|rice:boil,fry;egg,carrot:fry|soy,pepper|Egg-fried rice with bright veg.
Veggie Stir-fry|mains|pile|broccoli,pepper,carrot:chop,fry;soy:|tofu,mushroom|Crunchy veg tossed in a hot pan.
Tacos|mains|taco|tortilla:;beef:fry;lettuce,tomato,cheese:||Crunchy shells piled with fillings.
Grilled Cheese|mains|toast.grilled|bread,cheese,butter:fry|tomato|Golden bread with a cheesy stretch.
Tomato Soup|soups|bowl.smooth|tomato,onion:boil,blend|cream,bread|Velvety and bright red.
Pumpkin Soup|soups|bowl.smooth|pumpkin,milk:boil,blend|cream|Autumn in a bowl.
Corn Soup|soups|bowl.smooth|corn,milk:boil,blend|butter|Sweet, golden and creamy.
Mushroom Soup|soups|bowl.smooth|mushroom,milk,butter:boil,blend||Earthy and silky smooth.
Chicken Noodle Soup|soups|bowl.ramen|chicken,noodles,carrot:boil|onion|The get-well-soon classic.
Beef Stew|soups|bowl|beef,potato,carrot:boil|onion|Slow, rich and chunky.
Garden Salad|snacks|salad|lettuce,tomato,cucumber:chop,mix|carrot,pepper|Crisp, crunchy and fresh.
Fruit Salad|snacks|salad.fruit|apple,banana,strawberry:chop,mix|blueberry,orange,honey|A rainbow of fruit.
Popcorn|snacks|pile.popcorn|kernels:zap||Pop, pop, pop!
Butter Popcorn|snacks|pile.popcorn|kernels:zap;butter:||Buttery movie-night popcorn.
Caramel Popcorn|snacks|pile.popcorn|kernels:zap;sugar,butter:hot||Sticky, sweet and crunchy.
Fries|snacks|pile.fries|potato:chop,fry||Crispy golden sticks.
Guacamole|snacks|bowl.guac|avocado,tomato,onion,lemon:chop,mix|tortilla|Chunky avocado dip.
Corn on the Cob|snacks|plate.corn|corn:boil;butter:||Sweet corn dripping with butter.
Cheesy Nachos|snacks|pile.nachos|tortilla:chop,bake;cheese:|tomato,avocado|Crunchy chips under melty cheese.
Chocolate Chip Cookies|desserts|cookie.choc|flour,butter,sugar,chocolate:mix,bake||Chewy middles, crispy edges.
Sugar Cookies|desserts|cookie|flour,butter,sugar:mix,bake|sprinkles|Simple, sweet and sprinkle-ready.
Vanilla Cupcakes|desserts|cupcake|flour,egg,sugar,butter:mix,bake|cream,sprinkles,strawberry|Fluffy little cakes with pink frosting.
Chocolate Cupcakes|desserts|cupcake|flour,egg,sugar,butter,chocolate,milk:mix,bake|cream,cherry|Rich cocoa cupcakes.
Strawberry Shortcake|desserts|cake.short|flour,egg,sugar:mix,bake;cream:;strawberry:chop||Sponge, cream and strawberries.
Chocolate Cake|desserts|cake.choc|flour,egg,sugar,chocolate,milk:mix,bake|cream|A dark, glossy slice.
Carrot Cake|desserts|cake.carrot|flour,egg,sugar,carrot:mix,bake|cream|Soft sponge with creamy frosting.
Apple Pie|desserts|cake.pie|flour,butter:mix,bake;apple:chop,bake;sugar:|cream|Lattice crust over sweet apples.
Banana Bread|desserts|cake.loaf|flour,egg,banana,sugar:mix,bake|chocolate|A cosy loaf for sharing.
Brownies|desserts|cake.brownie|chocolate,butter,egg,sugar,flour:mix,bake||Fudgy squares with a crackly top.
Strawberry Ice Cream|desserts|scoop|strawberry,milk,cream,sugar:stir,freeze||Pink scoops in a cup.
Matcha Ice Cream|desserts|scoop|matcha,milk,cream,sugar:stir,freeze|redbean|Cool, creamy green tea.
Mango Sorbet|desserts|scoop|mango,sugar:blend,freeze|lemon|Icy and bursting with mango.
Purin|desserts|scoop.purin|egg,milk,sugar:mix,bake|cream,cherry|Wobbly custard pudding with caramel.
Rainbow Popsicle|desserts|scoop.pop|strawberry,orange,blueberry:blend,freeze||A stripy frozen treat."""

const RCATS := [["breakfast", "Breakfast"], ["drinks", "Drinks"], ["japanese", "Japanese"], ["mains", "Mains"], ["soups", "Soups"], ["snacks", "Snacks"], ["desserts", "Desserts"]]
const TOOLMAP := {"chop": "board", "mix": "bowl", "blend": "blender", "roll": "mat", "boil": "pot", "fry": "pan", "bake": "oven", "zap": "micro", "freeze": "freezer", "hot": "pot", "stir": "bowl"}
const TOOL_NAMES := {"board": "Knife", "bowl": "Bowl", "blender": "Blender", "mat": "Bamboo mat", "pot": "Pot", "pan": "Pan", "oven": "Oven", "micro": "Microwave", "freezer": "Freezer"}
const VERB := {"chop": ["Chop", "on the board"], "mix": ["Mix", "in the bowl"], "blend": ["Blend", "in the blender"], "roll": ["Roll", "on the bamboo mat"], "boil": ["Boil", "in the pot"], "fry": ["Fry", "in the pan"], "bake": ["Bake", "in the oven"], "zap": ["Microwave", "in the microwave"], "freeze": ["Freeze", "in the freezer"], "hot": ["Heat", "in the pot or microwave"], "stir": ["Mix", "in the bowl or blender"]}
const HEAT := ["boil", "fry", "bake", "zap"]
const QRANK := {"perfect": 0, "ok": 1, "under": 2, "burnt": 3}

var ING := {}
var ING_KEYS: Array[String] = []
var RECIPES: Array = []
var LEAFY := {"lettuce": true, "spinach": true, "cabbage": true}
var FRUIT := {}
var PROTEIN := {}
var LIQUID := {"milk": true, "cream": true, "yogurt": true, "coffee": true, "matcha": true, "chocolate": true, "honey": true, "lemon": true, "soy": true, "syrup": true}
var FLAVOUR := {"sugar": true, "soy": true, "ice": true, "butter": true, "honey": true, "syrup": true, "flour": true, "milk": true, "cream": true, "nori": true, "rice": true}

var _uid := 1

func _init() -> void:
	for k in ING_DEF:
		var d: Array = ING_DEF[k]
		var it := {"key": k, "n": d[0], "cat": d[1], "sh": d[2], "c": Color(d[3]), "c2": Color(d[4]),
			"mix": Color(d[5]) if d.size() > 5 else Color(d[3]), "w": float(d[6]) if d.size() > 6 else 1.0}
		ING[k] = it
		ING_KEYS.append(k)
		if it.cat == "fruit": FRUIT[k] = true
		if it.cat == "protein": PROTEIN[k] = true
	var i := 0
	for line in RECIPE_SRC.split("\n"):
		var p := line.split("|")
		var groups: Array = []
		for gs in p[3].split(";"):
			var ab := gs.split(":")
			var ings: Array = []
			for x in ab[0].split(","):
				if x != "": ings.append(x)
			var tags: Array = []
			if ab.size() > 1:
				for x in ab[1].split(","):
					if x != "": tags.append(x)
			groups.append({"ings": ings, "tags": tags})
		var need: Array = []
		for g in groups:
			for k in g.ings:
				if not need.has(k): need.append(k)
		var opt: Array = []
		for x in p[4].split(","):
			if x != "": opt.append(x)
		var tools: Array = []
		var weight := 0
		for g in groups:
			weight += g.ings.size() * (2 + g.tags.size())
			for t in g.tags:
				var tool: String = TOOLMAP[t]
				if not tools.has(tool): tools.append(tool)
		var r := {"id": i, "n": p[0], "cat": p[1], "art": p[2], "groups": groups, "need": need, "opt": opt, "desc": p[5], "tools": tools, "weight": weight}
		var search: String = p[0] + " " + " ".join(need.map(ing_name)) + " " + " ".join(opt.map(ing_name)) + " " + p[5]
		r.search = search.to_lower()
		r.price = MENU_PRICE.get(p[0], 500)
		var cost := 0
		for k in need: cost += ING_COST.get(k, 0)
		r.cost = cost
		for k in need + opt:
			if not ING.has(k): push_warning("unknown ingredient %s in %s" % [k, p[0]])
		if not MENU_PRICE.has(p[0]): push_warning("no price for " + p[0])
		RECIPES.append(r)
		i += 1
	_rate_difficulty()

## Recipe difficulty 1..5 chef hats: how many steps, tools and ingredients a dish takes,
## ranked across the whole menu so each rating is roughly a fifth of the recipes.
func _rate_difficulty() -> void:
	var scored: Array = []
	for r in RECIPES:
		scored.append([build_steps(r).size() * 3.0 + r.tools.size() * 1.5 + r.need.size() * 0.8 + r.weight * 0.05, r])
	scored.sort_custom(func(a, b): return a[0] < b[0])
	for k in scored.size():
		scored[k][1].diff = 1 + mini(4, k * 5 / scored.size())

func difficulty(r: Dictionary) -> int:
	return int(r.get("diff", 1))

## Tip multiplier for harder dishes (and what critics expect).
func diff_bonus(r: Dictionary) -> float:
	return [0.0, 0.0, 0.08, 0.16, 0.26, 0.4][difficulty(r)]

func hats(n: int) -> String:
	return "♛".repeat(n)

# ------------------------------------------------------------------ small helpers
func ing_name(k) -> String:
	return ING[k].n if ING.has(k) else str(k)

func list_names(keys: Array) -> String:
	var n: Array = keys.map(func(k): return ing_name(k).to_lower())
	if n.size() < 2: return "".join(n)
	return ", ".join(n.slice(0, -1)) + " and " + n[n.size() - 1]

func join_names(parts: Array) -> String:
	if parts.size() < 2: return "".join(parts)
	return ", ".join(parts.slice(0, -1)) + " and " + parts[parts.size() - 1]

func yen(n: float) -> String:
	var v := absi(roundi(n))
	var s := str(v)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("−¥" if n < 0 else "¥") + s + out

static func lighten(c: Color, t: float) -> Color: return c.lerp(Color.WHITE, clampf(t, 0, 1))
static func darken(c: Color, t: float) -> Color: return c.lerp(Color("2A1608"), clampf(t, 0, 1))
static func mix_c(list: Array) -> Color:
	var s := Vector3.ZERO
	var w := 0.0
	for e in list:
		var c: Color = e[0]
		s += Vector3(c.r, c.g, c.b) * float(e[1])
		w += float(e[1])
	if w <= 0.0: return Color("F2E6D8")
	s /= w
	return Color(s.x, s.y, s.z)

# ------------------------------------------------------------------ food model
## Food: {uid, comps: [{ing, tags: []}], hist: [], cook, q, recipe, hot}
func new_food(ing: String) -> Dictionary:
	_uid += 1
	return {"uid": _uid, "comps": [{"ing": ing, "tags": []}], "hist": [], "cook": 0.0, "q": "", "recipe": -1, "hot": 0.0}

func cook_q(level: float) -> String:
	if level < 0.45: return "under"
	if level > 1.18: return "burnt"
	if level >= 0.62 and level <= 1.0: return "perfect"
	return "ok"

func worst_q(a: String, b: String) -> String:
	if a == "": return b
	if b == "": return a
	return a if QRANK[a] >= QRANK[b] else b

## now = game clock in seconds (for steam/hot timers)
func apply_proc(food: Dictionary, proc: String, cook := 0.0, now := 0.0) -> Dictionary:
	for c in food.comps:
		if not c.tags.has(proc): c.tags.append(proc)
	food.hist.append(proc)
	if HEAT.has(proc):
		food.cook = cook
		food.q = worst_q(food.q, cook_q(cook))
		food.hot = now + 8.0
	food.recipe = -1
	tag_recipe(food)
	return food

func merge_foods(foods: Array, proc: String, cook := 0.0, now := 0.0) -> Dictionary:
	_uid += 1
	var f := {"uid": _uid, "comps": [], "hist": [], "cook": 0.0, "q": "", "recipe": -1, "hot": 0.0}
	for x in foods:
		for c in x.comps:
			f.comps.append({"ing": c.ing, "tags": c.tags.duplicate()})
		for h in x.hist:
			if not f.hist.has(h): f.hist.append(h)
		f.q = worst_q(f.q, x.q)
	return apply_proc(f, proc, cook, now)

func comps_of(foods: Array) -> Array:
	var out: Array = []
	for f in foods: out.append_array(f.comps)
	return out

func food_ings(food: Dictionary) -> Array:
	var out: Array = []
	for c in food.comps:
		if not out.has(c.ing): out.append(c.ing)
	return out

# ------------------------------------------------------------------ detection
func tag_ok(c: Dictionary, t: String) -> bool:
	if t == "hot":
		for x in c.tags:
			if HEAT.has(x): return true
		return false
	if t == "stir": return c.tags.has("mix") or c.tags.has("blend")
	return c.tags.has(t)

func eval_recipe(r: Dictionary, comps: Array) -> Dictionary:
	var pairs := 0
	var ok := 0
	var full := true
	var missing: Array = []
	for g in r.groups:
		for ing in g.ings:
			var mine: Array = comps.filter(func(c): return c.ing == ing)
			pairs += 1 + g.tags.size()
			if mine.size(): ok += 1
			else:
				full = false
				missing.append({"ing": ing, "tag": ""})
			for t in g.tags:
				if mine.any(func(c): return tag_ok(c, t)): ok += 1
				elif mine.size(): missing.append({"ing": ing, "tag": t})
			if mine.size() and not mine.any(func(c): return g.tags.all(func(t): return tag_ok(c, t))):
				full = false
	var all := {}
	for k in r.need + r.opt: all[k] = true
	var extras: Array = []
	for c in comps:
		if not all.has(c.ing) and not extras.has(c.ing): extras.append(c.ing)
	return {"r": r, "full": full, "cover": float(ok) / pairs, "missing": missing, "extras": extras}

## Returns {} (nothing), {match: eval} or {near: eval}
func detect(comps: Array) -> Dictionary:
	if comps.is_empty(): return {}
	var evals: Array = RECIPES.map(func(r): return eval_recipe(r, comps))
	var full: Array = evals.filter(func(e): return e.full)
	if full.size():
		full.sort_custom(func(a, b):
			if a.r.weight != b.r.weight: return a.r.weight > b.r.weight
			return a.extras.size() < b.extras.size())
		return {"match": full[0]}
	var near: Array = evals.filter(func(e): return e.cover >= 0.55 and e.cover < 1.0 and e.missing.size() <= 3)
	if near.is_empty(): return {}
	near.sort_custom(func(a, b):
		if a.cover != b.cover: return a.cover > b.cover
		return a.r.weight > b.r.weight)
	return {"near": near[0]}

## A single food that already is a whole recipe gets that recipe's look.
func tag_recipe(food: Dictionary) -> void:
	var d := detect(food.comps)
	if d.has("match") and d.match.extras.size() <= 1:
		food.recipe = d.match.r.id

func product_name(t: String, ings: Array) -> String:
	var has := func(k): return ings.has(k)
	match t:
		"chop": return "pieces" if ings.size() > 1 else "chopped " + ing_name(ings[0]).to_lower()
		"mix":
			if has.call("flour") or has.call("egg"):
				return "dough" if has.call("flour") and not has.call("egg") and not has.call("milk") else "batter"
			return "mixture"
		"blend": return "blend"
		"stir": return "mixture"
		"roll": return "roll"
		"boil": return "cooked " + ing_name(ings[0]).to_lower() if ings.size() == 1 else "pot of food"
		"fry": return "fried " + ing_name(ings[0]).to_lower() if ings.size() == 1 else "fried mix"
		"bake": return "bake"
		"zap": return "popcorn" if ings.size() == 1 and ings[0] == "kernels" else "warm mix"
		"freeze": return "frozen mix"
		"hot": return "warm drink"
	return "food"

## Steps: [{text, check: {type: have|tag|plate, ings, tag}, tool}]
var _steps_cache := {}
func build_steps(r: Dictionary) -> Array:
	if _steps_cache.has(r.id): return _steps_cache[r.id]
	var steps: Array = [{"text": "Take %s from the fridge." % list_names(r.need), "check": {"type": "have", "ings": r.need}, "tool": "fridge"}]
	var order: Array = []
	for g in r.groups:
		for t in g.tags:
			if not order.has(t): order.append(t)
	var batches: Array = []
	for i in r.groups.size():
		batches.append({"ings": r.groups[i].ings.duplicate(), "gi": [i], "product": ""})
	for t in order:
		var gs: Array = []
		for i in r.groups.size():
			if r.groups[i].tags.has(t): gs.append(i)
		var bs: Array = batches.filter(func(b): return b.gi.any(func(i): return gs.has(i)))
		var all_first := gs.all(func(i): return r.groups[i].tags[0] == t)
		var targets := bs
		var labels: Array = bs.map(func(b): return "the " + (b.product if b.product != "" else list_names(b.ings)))
		if not all_first and bs.size() > 1:
			var merged := {"ings": [], "gi": [], "product": ""}
			for b in bs:
				merged.ings.append_array(b.ings)
				merged.gi.append_array(b.gi)
			var lab: String = "the " + join_names(bs.map(func(b): return b.product if b.product != "" else list_names(b.ings)))
			batches = batches.filter(func(b): return not bs.has(b))
			batches.append(merged)
			targets = [merged]
			labels = [lab]
		for k in targets.size():
			var b: Dictionary = targets[k]
			steps.append({"text": "%s %s %s." % [VERB[t][0], labels[k], VERB[t][1]], "check": {"type": "tag", "ings": b.ings.duplicate(), "tag": t}, "tool": TOOLMAP[t]})
			b.product = product_name(t, b.ings)
	var plain: Array = []
	for g in r.groups:
		if g.tags.is_empty(): plain.append_array(g.ings)
	steps.append({"text": ("Put it on the plate with the %s, then serve." % list_names(plain)) if plain.size() else "Put it on the plate and serve!", "check": {"type": "plate", "ings": r.need}, "tool": "plate"})
	_steps_cache[r.id] = steps
	return steps

func optional_text(r: Dictionary) -> String:
	return "Optional extras: %s." % list_names(r.opt) if r.opt.size() else ""

func missing_text(e: Dictionary) -> String:
	if e.missing.is_empty(): return ""
	var m: Dictionary = e.missing[0]
	if m.tag == "": return "add some " + ing_name(m.ing).to_lower()
	var v: Array = VERB[m.tag]
	var grp = null
	for g in e.r.groups:
		if g.ings.has(m.ing):
			grp = g
			break
	var idx: int = grp.tags.find(m.tag) if grp else -1
	var subj := ing_name(m.ing).to_lower()
	if grp and grp.ings.size() > 1:
		subj = product_name(grp.tags[idx - 1], grp.ings) if idx > 0 else list_names(grp.ings)
	return "%s the %s %s" % [v[0].to_lower(), subj, v[1]]

# ------------------------------------------------------------------ how food looks
func comp_color(c: Dictionary) -> Color:
	var col: Color = ING[c.ing].mix
	if c.tags.has("fry") or c.tags.has("bake"): col = col.lerp(Color("D08A3A"), 0.38)
	elif c.tags.has("boil"): col = lighten(col, 0.08)
	return col

func mix_of(comps: Array) -> Color:
	return mix_c(comps.map(func(c): return [comp_color(c), ING[c.ing].w]))

func set_of(keys: Array) -> Dictionary:
	var d := {}
	for k in keys: d[k] = true
	return d

## Spec: {art, style, main: Color, tops: [Color], ings: {key: true}, pieces: [keys], ing, frost, cook, burnt, steam, hot}
func recipe_spec(r: Dictionary, foods = null) -> Dictionary:
	var present := {}
	if foods != null:
		for c in comps_of(foods): present[c.ing] = true
	else:
		for k in r.need: present[k] = true
		for k in r.opt.slice(0, 2): present[k] = true
	var parts: PackedStringArray = r.art.split(".")
	var art := parts[0]
	var style := parts[1] if parts.size() > 1 else ""
	var ings := set_of(r.need)
	for o in r.opt:
		if present.has(o): ings[o] = true
	var base: Dictionary = r.groups[0]
	for g in r.groups:
		if g.tags.size() > base.tags.size(): base = g
	var main := mix_c(base.ings.map(func(k): return [ING[k].mix, ING[k].w]))
	if base.tags.has("fry") or base.tags.has("bake"): main = main.lerp(Color("E0A050"), 0.45)
	var keys: Array = ings.keys()
	var tops: Array = keys.filter(func(k): return not base.ings.has(k) and not FLAVOUR.has(k)).map(func(k): return ING[k].c)
	var has := func(k): return ings.has(k)
	var protein := ""
	for k in keys:
		if PROTEIN.has(k):
			protein = k
			break
	var sp := {"art": art, "style": style, "main": main, "tops": tops, "ings": ings, "recipe": r.id}
	match art:
		"maki":
			sp.tops = keys.filter(func(k): return k != "rice" and k != "nori" and not FLAVOUR.has(k)).map(func(k): return ING[k].c)
		"onigiri":
			sp.main = ING[protein].c if protein != "" else Color("F4895A")
			sp.tops = [ING[protein].c] if protein != "" and style != "nigiri" else []
		"stack":
			sp.main = Color("7A4A33") if style == "choc" else Color("E8B26A") if style == "okonomi" else Color("E8A44A") if style == "dorayaki" else Color("F6D58A") if style == "crepe" else Color("EBB25A")
			sp.tops = keys.filter(func(k): return FRUIT.has(k) and not base.ings.has(k) or k == "blueberry").map(func(k): return ING[k].c)
		"toast":
			sp.main = Color("E2A55A")
			sp.tops = keys.filter(func(k): return FRUIT.has(k)).map(func(k): return ING[k].c)
		"glass", "mug":
			sp.main = lighten(mix_c(base.ings.map(func(k): return [ING[k].mix, ING[k].w])), 0.06)
			sp.tops = keys.filter(func(k): return FRUIT.has(k) and not base.ings.has(k)).map(func(k): return ING[k].c)
			if style == "parfait": sp.main = Color("FFF4F7")
		"bowl":
			match style:
				"curry": sp.main = Color("B8732A")
				"ramen": sp.main = Color("E0B070") if has.call("soy") else Color("F6E3B8")
				"porridge": sp.main = Color("EEDCB8")
				"pasta":
					sp.main = Color("F7D27A")
					sp.tops = [Color("E84A3A")] if has.call("tomato") else [Color("FFF0C0")]
				"mac": sp.main = Color("F7C24A")
				"don": sp.main = Color("FFD45A")
				"mash": sp.main = Color("FFF0C8")
				"guac": sp.main = Color("A8D46A")
				_: sp.main = lighten(main, 0.1)
			if style == "ramen" or style == "curry" or style == "":
				sp.tops = keys.filter(func(k): return not FLAVOUR.has(k) and k != "noodles" and k != "curry").map(func(k): return ING[k].c)
			sp.hot = true
		"salad":
			sp.tops = keys.filter(func(k): return not LEAFY.has(k) and not FLAVOUR.has(k)).map(func(k): return ING[k].c)
		"scoop":
			var fl: Array = keys.filter(func(k): return not ["sugar", "milk", "cream"].has(k)).map(func(k): return [ING[k].mix, 1.0])
			sp.main = lighten(mix_c(fl), 0.25)
			sp.tops = keys.filter(func(k): return FRUIT.has(k)).map(func(k): return ING[k].c)
			if has.call("matcha"): sp.main = Color("B8DC8A")
			if style == "mochi": sp.main = Color("CDE8A8") if has.call("matcha") else Color("FFC2D2") if has.call("strawberry") else Color("FFF0F4")
		"cookie":
			sp.main = Color("E8B26A")
		"cupcake":
			sp.main = Color("7A4A33") if has.call("chocolate") else Color("E8C07A") if has.call("banana") else Color("E9B45A")
			sp.frost = Color("8A5A3E") if has.call("chocolate") else Color("FFB3CF")
			sp.tops = keys.filter(func(k): return ["strawberry", "cherry", "blueberry"].has(k)).map(func(k): return ING[k].c)
			if r.art == "cupcake" and not has.call("sugar"): sp.style = "muffin"
		"cake":
			sp.main = Color("6B3A26") if style == "choc" else Color("E8A060") if style == "carrot" else Color("D9A060") if style == "loaf" else Color("5A2E1E") if style == "brownie" else Color("F6E0A8")
			sp.tops = [ING.apple.c2] if style == "pie" else [Color("F0475E")] if style == "short" else []
		"pizza":
			sp.tops = keys.filter(func(k): return not ["flour", "tomato", "cheese"].has(k) and not FLAVOUR.has(k)).map(func(k): return ING[k].c)
		"pile":
			match style:
				"fries": sp.main = Color("FFD24A")
				"noodle": sp.main = Color("C8955A")
				"rice": sp.main = Color("F6E7B8")
				"dumpling": sp.main = Color("D9954A")
				"tempura": sp.main = Color("F2C47A")
			sp.tops = keys.filter(func(k): return not FLAVOUR.has(k) and k != "noodles").map(func(k): return ING[k].c)
			if style == "popcorn" and has.call("sugar"): ings["caramel"] = true
			if style == "": sp.cook = 0.8
		"egg":
			sp.main = Color("FFD84A")
			sp.tops = keys.filter(func(k): return ING.has(k) and ING[k].cat == "veg").map(func(k): return ING[k].c)
		"plate":
			sp.main = Color("C8742E") if style == "roast" else Color("8A3A2A")
			sp.tops = keys.filter(func(k): return ING.has(k) and ING[k].cat == "veg").map(func(k): return ING[k].c)
	if foods != null:
		var q := ""
		for f in foods: q = worst_q(q, f.q)
		sp.burnt = q == "burnt"
	return sp

func food_spec(food: Dictionary, now := 0.0) -> Dictionary:
	if food.recipe >= 0:
		var sp := recipe_spec(RECIPES[food.recipe], [food])
		sp.steam = food.hot > now
		return sp
	return generic_spec(food.comps, food.hist, food, now)

func generic_spec(comps: Array, hist: Array, food = null, now := 0.0) -> Dictionary:
	var ings := {}
	for c in comps: ings[c.ing] = true
	var keys: Array = ings.keys()
	var has := func(k): return ings.has(k)
	var last: String = hist[hist.size() - 1] if hist.size() else ""
	var some := func(st: Dictionary): return keys.any(func(k): return st.has(k))
	var col_keys: Array = keys.filter(func(k): return not FLAVOUR.has(k) or ings.size() == 1)
	var cols: Array = col_keys.map(func(k):
		for c in comps:
			if c.ing == k: return comp_color(c)
		return Color.WHITE)
	var sp := {"ings": ings, "main": mix_of(comps), "tops": cols,
		"burnt": food != null and food.get("q", "") == "burnt", "cook": food.get("cook", 0.0) if food != null else 0.0,
		"steam": food != null and food.get("hot", 0.0) > now}
	var only := func(list: Array): return keys.all(func(k): return list.has(k))
	var mk := func(extra: Dictionary) -> Dictionary:
		var d := sp.duplicate()
		d.merge(extra, true)
		return d
	if last == "":
		if comps.size() == 1: return mk.call({"art": "raw", "ing": comps[0].ing})
		return mk.call({"art": "chunks", "pieces": keys})
	var non_rn := func() -> Array: return keys.filter(func(k): return k != "rice" and k != "nori").map(func(k): return ING[k].c)
	match last:
		"chop":
			if hist.has("roll"): return mk.call({"art": "maki", "tops": non_rn.call()})
			return mk.call({"art": "chunks", "pieces": keys})
		"roll":
			if has.call("egg") and not has.call("rice"): return mk.call({"art": "egg", "style": "tamago"})
			return mk.call({"art": "log", "tops": non_rn.call()})
		"mix":
			if only.call(FRUIT.keys() + ["honey", "sugar"]): return mk.call({"art": "salad", "style": "fruit"})
			if some.call(LEAFY) and not has.call("flour") and not has.call("egg"): return mk.call({"art": "salad"})
			if has.call("ice"): return mk.call({"art": "glass", "style": "ice"})
			if has.call("yogurt") and has.call("oats"): return mk.call({"art": "glass", "style": "parfait"})
			return mk.call({"art": "bowl", "style": "batter", "tops": []})
		"blend":
			if hist.has("boil"): return mk.call({"art": "bowl", "style": "smooth"})
			return mk.call({"art": "glass", "style": "shake" if has.call("ice") and has.call("milk") else "", "tops": []})
		"freeze":
			if hist.has("blend") and not has.call("milk") and not has.call("cream") and not has.call("yogurt"):
				return mk.call({"art": "scoop", "style": "pop", "tops": cols})
			return mk.call({"art": "scoop", "main": lighten(sp.main, 0.2), "tops": []})
		"boil":
			if has.call("noodles"):
				var tc: Array = []
				for i in col_keys.size():
					if col_keys[i] != "noodles": tc.append(cols[i])
				return mk.call({"art": "bowl", "style": "ramen", "main": Color("E0B070") if has.call("soy") else Color("F6E3B8"), "tops": tc})
			if has.call("pasta"): return mk.call({"art": "bowl", "style": "pasta", "main": Color("F7D27A"), "tops": [Color("E84A3A")] if has.call("tomato") else [Color("FFF0C0")]})
			if has.call("curry"): return mk.call({"art": "bowl", "style": "curry", "main": Color("B8732A")})
			if has.call("oats"): return mk.call({"art": "bowl", "style": "porridge", "main": Color("EEDCB8")})
			if has.call("rice") and ings.size() <= 2: return mk.call({"art": "bowl", "style": "rice", "main": Color.WHITE})
			if only.call(LIQUID.keys() + ["sugar", "ice"]): return mk.call({"art": "mug"})
			return mk.call({"art": "bowl", "style": "", "main": lighten(sp.main, 0.15), "hot": true})
		"fry":
			if has.call("egg") and not has.call("flour") and not has.call("bread") and not has.call("rice") and not has.call("noodles") and not has.call("tortilla"):
				var st := ""
				if hist.has("mix"):
					st = "omelette" if has.call("cheese") or some.call(set_of(["pepper", "onion", "mushroom", "tomato"])) else "scramble"
				elif has.call("bacon"): st = "bacon"
				return mk.call({"art": "egg", "style": st, "tops": keys.filter(func(k): return ING[k].cat == "veg").map(func(k): return ING[k].c)})
			if has.call("flour") and (has.call("egg") or has.call("milk")) and hist.has("mix"):
				return mk.call({"art": "stack", "main": Color("7A4A33") if has.call("chocolate") else Color("EBB25A"), "tops": keys.filter(func(k): return FRUIT.has(k)).map(func(k): return ING[k].c)})
			if has.call("bread"): return mk.call({"art": "toast", "style": "grilled" if has.call("cheese") else "french" if has.call("egg") else "", "main": Color("D9954A")})
			if has.call("potato") and hist.has("chop"): return mk.call({"art": "pile", "style": "fries", "main": Color("FFD24A")})
			if has.call("noodles"): return mk.call({"art": "pile", "style": "noodle", "main": Color("C8955A")})
			if has.call("rice"): return mk.call({"art": "pile", "style": "rice", "main": Color("F6E7B8")})
			if has.call("tortilla"): return mk.call({"art": "taco", "style": "quesadilla"})
			if has.call("flour"): return mk.call({"art": "pile", "style": "tempura", "main": Color("F2C47A")})
			return mk.call({"art": "pile", "style": ""})
		"bake":
			if has.call("flour"):
				if has.call("sugar"):
					if has.call("egg"): return mk.call({"art": "cake" if has.call("milk") else "cupcake", "style": "", "main": sp.main.lerp(Color("E9A84C"), 0.5), "frost": Color("FFB3CF")})
					return mk.call({"art": "cookie", "style": "choc" if has.call("chocolate") else ""})
				if has.call("tomato") or has.call("cheese"): return mk.call({"art": "pizza", "tops": cols.slice(3)})
				return mk.call({"art": "cake", "style": "loaf", "main": Color("D9A060")})
			if has.call("bread"): return mk.call({"art": "toast", "main": Color("E2A55A"), "style": "cheese" if has.call("cheese") else ""})
			if has.call("tortilla"): return mk.call({"art": "pile", "style": "nachos"})
			if has.call("potato") and not hist.has("chop"): return mk.call({"art": "plate", "style": "potato"})
			if has.call("chicken") and ings.size() <= 2: return mk.call({"art": "plate", "style": "roast"})
			return mk.call({"art": "pile", "style": ""})
		"zap":
			if has.call("kernels"): return mk.call({"art": "pile", "style": "popcorn"})
			if only.call(LIQUID.keys() + ["sugar"]): return mk.call({"art": "mug"})
			var prev := generic_spec(comps, hist.slice(0, -1), food, now)
			prev.steam = true
			return prev
	return mk.call({"art": "chunks", "pieces": keys})

const NOUN := {"glass": "Smoothie", "mug": "Warm Drink", "bowl": "Soup", "salad": "Salad", "stack": "Pancakes", "egg": "Eggs", "toast": "Toast", "pile": "Bites", "cookie": "Cookies", "cake": "Cake", "cupcake": "Cupcakes", "scoop": "Ice Pop", "chunks": "Medley", "raw": "Snack", "log": "Roll", "maki": "Maki", "pizza": "Flatbread", "taco": "Wrap", "plate": "Plate"}
const ADJ := {"chop": "Chopped", "mix": "Mixed", "blend": "", "roll": "Rolled", "boil": "Simmered", "fry": "Crispy", "bake": "Baked", "zap": "Zapped", "freeze": "Frozen"}

func invent_name(foods: Array) -> String:
	var comps := comps_of(foods)
	var ings: Array = []
	for c in comps:
		if not ings.has(c.ing): ings.append(c.ing)
	var rank := func(k): return 0 if PROTEIN.has(k) else 1 if FRUIT.has(k) else 2 if ING[k].cat == "veg" else 5 if FLAVOUR.has(k) else 3
	var sorted := ings.duplicate()
	sorted.sort_custom(func(a, b): return rank.call(a) < rank.call(b))
	var mains: Array = sorted.slice(0, 2).map(ing_name)
	var f: Dictionary = foods[0]
	var sp := food_spec(f)
	var last: String = f.hist[f.hist.size() - 1] if f.hist.size() else ""
	if foods.size() == 1 and last == "" and comps.size() == 1: return "A Whole " + mains[0]
	var noun: String = "Batter" if sp.art == "bowl" and sp.get("style", "") == "batter" else "Rice Bowl" if sp.art == "bowl" and sp.get("style", "") == "rice" else NOUN.get(sp.art, "Surprise")
	var adj: String = ADJ.get(last, "")
	return ("%s%s %s" % [adj + " " if adj != "" else "", " & ".join(mains), noun]).strip_edges()

## Cache key for a spec: anything that changes the picture must be in here.
func spec_key(sp: Dictionary) -> String:
	var tops: Array = sp.get("tops", []).map(func(c): return c.to_html(false))
	var ik: Array = sp.get("ings", {}).keys()
	ik.sort()
	var fr = sp.get("frost", null)
	return "|".join([sp.get("art", ""), sp.get("style", ""), sp.get("main", Color.WHITE).to_html(false), ",".join(tops), ",".join(sp.get("pieces", [])), sp.get("ing", ""),
		"1" if sp.get("burnt", false) else "0", fr.to_html(false) if fr is Color else "", ",".join(ik), str(roundi(sp.get("cook", 0.0) * 10))])
