## The serving plate on the pass. Shows the finished dish when the food makes a recipe.
class_name PlateStation
extends Station

var combo: Node3D
var combo_key := ""
var sparkle: CPUParticles3D
var bell: Node3D

func _init() -> void:
	super("plate", "Plate", 6)  # some dishes (tacos, burgers…) bring five things together
	item_scale = 1.15

func attach(mo: Node3D) -> void:
	super(mo)
	bell = mo.get_node("Bell")
	sparkle = Fx.sparkles()
	sparkle.position = Vector3(0, 0.08, 0)
	mo.add_child(sparkle)

func slot(i: int, n: int) -> Vector3:
	if n == 1: return Vector3.ZERO
	if n == 2: return [Vector3(-0.08, 0, 0), Vector3(0.08, 0, 0)][i]
	if n > 4: return Vector3(-0.1 + (i % 3) * 0.1, 0, -0.05 + (i / 3) * 0.11)
	return [Vector3(-0.08, 0, -0.05), Vector3(0.08, 0, -0.05), Vector3(-0.08, 0, 0.07), Vector3(0.08, 0, 0.07)][i % 4]

func live() -> Dictionary:
	return G.detect(G.comps_of(items)) if items.size() else {}

func hint() -> String:
	if items.is_empty():
		return "Put the finished dish here, then pick it up and carry it out" if game.shop.orders().size() else "Put finished food here, then <b>Pick up</b> the plate"
	var d := live()
	if d.has("match"):
		var r: Dictionary = d.match.r
		var o = game.shop.order_for(r.id)
		if o: return "<b>%s</b> for %s! Pick it up and carry it over while it's hot" % [r.n, o.cname]
		if game.shop.open and game.shop.orders().size(): return "That's %s, but nobody ordered it. Enjoy it as a staff meal" % r.n
		return "Looks like <b>%s</b>! Ready to serve" % r.n
	if d.has("near"):
		return "Almost <b>%s</b>: %s" % [d.near.r.n, G.missing_text(d.near)]
	return "A new creation? Serve it and see!"

func btn() -> Dictionary:
	if items.is_empty(): return {}
	var d := live()
	var o = game.shop.order_for(d.match.r.id) if d.has("match") else null
	var lab = "Serve " + o.cname if o else ("Staff meal" if game.shop.open and game.shop.orders().size() else "Pick up")
	return {"label": lab, "enabled": true, "ready": o != null or (not game.shop.open and d.has("match"))}

func on_btn() -> void: game.serve()
func auto() -> void:
	if items.size(): game.serve()

func refresh(delay := 0.0) -> void:
	super(delay)
	var d := live()
	var show_combo := d.has("match") and items.size() > 1
	var k := ""
	if show_combo:
		var sp := G.recipe_spec(d.match.r, items)
		k = G.spec_key(sp)
		if k != combo_key:
			if combo: combo.queue_free()
			combo = FoodArt.spec_node(sp)
			combo.scale = Vector3.ONE * 0.01
			contents.add_child(combo)
			combo.create_tween().tween_property(combo, "scale", Vector3.ONE * 1.25, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			Sfx.play("sparkle")
	elif combo:
		combo.queue_free()
		combo = null
	combo_key = k
	for n in _nodes.values():
		n.visible = not show_combo
	sparkle.emitting = d.has("match")

func ring_bell() -> void:
	if not bell: return
	var tw := bell.create_tween()
	tw.tween_property(bell, "scale", Vector3(1.15, 0.8, 1.15), 0.05)
	tw.tween_property(bell, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Sfx.play("bell")
