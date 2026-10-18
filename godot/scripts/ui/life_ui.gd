## The life-sim side of the HUD: the status card (place, clock, energy), the interaction
## prompt, the dish in your hands, edit mode, dialogue with portraits, the town's shops,
## the journal, the newspaper, the character creator, fades and the cheat console.
class_name LifeUI
extends Node

var hud: Hud
var game: Game
var status: PanelContainer
var place_lbl: Label
var time_lbl: Label
var weather_ic: TextureRect
var energy_bar: Control
var prompt: PanelContainer
var prompt_lbl: Label
var carry: PanelContainer
var carry_icon: TextureRect
var carry_lbl: Label
var edit_panel: PanelContainer
var edit_list: HBoxContainer
var edit_hint: Label
var fader: ColorRect
# dialogue
var dlg: Control
var dlg_wrap: Control
var dlg_portrait: TextureRect
var dlg_name: Label
var dlg_text: RichTextLabel
var dlg_opts: VBoxContainer
var dlg_more: Label
var _lines: Array = []
var _done: Callable = Callable()
var _typing_t := 0.0
var _text_input: LineEdit

func build() -> void:
	_build_status()
	_build_prompt()
	_build_carry()
	_build_edit()
	_build_dialogue()
	fader = ColorRect.new()
	fader.color = Color("2A1E36")
	fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fader.modulate.a = 0.0
	hud.add_child(fader)
	fader.z_index = 100

# ================================================================ status card
func _build_status() -> void:
	status = PanelContainer.new()
	status.position = Vector2(24, 14)
	status.add_theme_stylebox_override("panel", UI.box(Color(1, 0.99, 0.965, 0.94), 24, 3, 5, Vector4(18, 10, 20, 10)))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root.add_child(status)
	var h := UI.hbox(14)
	status.add_child(h)
	weather_ic = UI.tex(UI.icon("sun", 64), Vector2(58, 58))
	h.add_child(weather_ic)
	var v := UI.vbox(0)
	h.add_child(v)
	place_lbl = UI.label("Hoshizora Town", 26, UI.PLUM, UI.font_display)
	v.add_child(place_lbl)
	time_lbl = UI.label("Day 1 · 7:00 am", 19, UI.MUTED, UI.font_xbold)
	v.add_child(time_lbl)
	var eh := UI.hbox(4)
	eh.add_child(UI.tex(UI.icon("bolt", 22), Vector2(20, 20)))
	energy_bar = UI.bar(1.0, Color("5CC98E"), 150.0, 12.0)
	energy_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	eh.add_child(energy_bar)
	v.add_child(eh)

func _build_prompt() -> void:
	prompt = PanelContainer.new()
	prompt.theme_type_variation = "Dark"
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root.add_child(prompt)
	prompt_lbl = UI.label("", 24, UI.CREAM, UI.font_xbold)
	prompt.add_child(prompt_lbl)
	prompt.visible = false

func _build_carry() -> void:
	carry = PanelContainer.new()
	carry.add_theme_stylebox_override("panel", UI.box(Color("FFF6EA"), 26, 3, 7, Vector4(14, 8, 16, 8)))
	hud.root.add_child(carry)
	var h := UI.hbox(10)
	carry.add_child(h)
	carry_icon = UI.tex(null, Vector2(72, 72))
	h.add_child(carry_icon)
	var v := UI.vbox(2)
	h.add_child(v)
	carry_lbl = UI.label("", 20, UI.PLUM, UI.font_xbold)
	v.add_child(carry_lbl)
	var row := UI.hbox(8)
	v.add_child(row)
	row.add_child(UI.button("Eat it (Q)", "Mint", func(): game.eat_carried(), 18))
	row.add_child(UI.button("Bin", "Ghost", func(): game.bin_carried(), 18))
	carry.visible = false

func carry_changed() -> void:
	carry.visible = game.carrying.size() > 0
	if carry.visible:
		var cf: Dictionary = game.carrying
		var c: Customer = game.shop.order_for(cf.rid) if cf.rid >= 0 else null
		carry_icon.texture = Photo.recipe(cf.rid, 128) if cf.rid >= 0 else Photo.food(cf.foods[0], 128)
		var nm: String = G.RECIPES[cf.rid].n if cf.rid >= 0 else String(cf.get("name", "Your creation"))
		carry_lbl.text = ("%s for %s: walk over and press E" % [nm, c.cname]) if c else "%s in your hands" % nm

# ================================================================ per frame
func update(dt: float) -> void:
	var h := Save.hour()
	place_lbl.text = game.loc.title if game.loc else ""
	var ev: String = Save.flags.get("event", "")
	time_lbl.text = "Day %d · %s%s%s" % [Save.day, Save.time_text(), "  ·  café open" if game.shop.open else "", ("  ·  " + People.EVENTS[ev][0]) if People.EVENTS.has(ev) else ""]
	var night := h >= 19.5 or h < 6.0
	var ic := "moon" if night else ("rain" if Save.weather == "rain" else "sun")
	if weather_ic.get_meta("ic", "") != ic:
		weather_ic.set_meta("ic", ic)
		weather_ic.texture = UI.icon(ic, 64)
	var e := Save.energy / 100.0
	UI.set_bar(energy_bar, e, Color("5CC98E") if e > 0.5 else Color("FFC93C") if e > 0.2 else Color("FF6A6A"))
	status.visible = game.open_key == "" and not game.edit.active
	# interaction prompt
	var f: Dictionary = game.focus
	var show := f.size() > 0 and not hud.modal_open() and game.open_key == "" and not game.cutscene
	prompt.visible = show
	if show:
		var t := "E  ·  " + String(f.label) + ("      Tab ⇄ next" if f.get("more", false) else "")
		if prompt_lbl.text != t:
			prompt_lbl.text = t
			prompt.reset_size()
		prompt.position = Vector2((hud.root.size.x - prompt.size.x) * 0.5, hud.root.size.y - (300.0 if carry.visible else 190.0))
	if carry.visible:
		carry.position = Vector2((hud.root.size.x - carry.size.x) * 0.5, hud.root.size.y - 160.0)
		carry.visible = game.open_key == ""
	elif game.carrying.size() and game.open_key == "":
		carry.visible = true
	if _typing_t > 0.0 and dlg_text:
		_typing_t = maxf(0.0, _typing_t - dt)
		dlg_text.visible_ratio = 1.0 - _typing_t / maxf(0.01, dlg_text.get_meta("dur", 1.0))
		dlg_more.visible = _typing_t <= 0.0 and dlg_opts.get_child_count() == 0 and not _text_input
	if dlg_wrap.visible:
		dlg.reset_size()
		dlg.position = Vector2((hud.root.size.x - dlg.size.x) * 0.5, hud.root.size.y - dlg.size.y - 22.0)
	if dlg_more and dlg_more.visible:
		dlg_more.position.y = 150 + sin(game.clock * 6.0) * 4.0

# ================================================================ fades
func fade(mid: Callable, done := Callable()) -> void:
	if game.instant or game.skip_fx:
		mid.call()
		if done.is_valid(): done.call()
		return
	fader.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := fader.create_tween()
	tw.tween_property(fader, "modulate:a", 1.0, 0.35)
	tw.tween_callback(mid)
	tw.tween_interval(0.25)
	tw.tween_property(fader, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func():
		fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if done.is_valid(): done.call())

## The tasteful fade for the family scene: the lights go down, little hearts float up, and
## the screen goes softly dark.
func heart_fade(then: Callable) -> void:
	if game.instant or game.skip_fx:
		then.call()
		return
	fader.mouse_filter = Control.MOUSE_FILTER_STOP
	var hearts: Array = []
	var tw := fader.create_tween()
	tw.tween_property(fader, "modulate:a", 0.55, 1.2)
	tw.tween_callback(func():
		for i in 14:
			var t := UI.tex(UI.icon("heart", 64), Vector2(48, 48))
			t.size = Vector2(48, 48)
			t.position = Vector2(randf_range(0.3, 0.7) * hud.root.size.x, hud.root.size.y * 0.75)
			t.modulate.a = 0.0
			t.z_index = 101
			hud.add_child(t)
			hearts.append(t)
			var ht := t.create_tween()
			ht.tween_interval(i * 0.15)
			ht.tween_property(t, "modulate:a", 0.9, 0.3)
			ht.parallel().tween_property(t, "position:y", hud.root.size.y * randf_range(0.2, 0.4), 2.6).set_trans(Tween.TRANS_SINE)
			ht.tween_property(t, "modulate:a", 0.0, 0.6))
	tw.tween_interval(2.6)
	tw.tween_property(fader, "modulate:a", 1.0, 1.0)
	tw.tween_interval(1.2)
	tw.tween_callback(func():
		for t in hearts: if is_instance_valid(t): t.queue_free()
		then.call())
	tw.tween_interval(0.3)
	tw.tween_property(fader, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func(): fader.mouse_filter = Control.MOUSE_FILTER_IGNORE)

# ================================================================ dialogue
func _build_dialogue() -> void:
	dlg_wrap = Control.new()
	dlg_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	dlg_wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	dlg_wrap.visible = false
	dlg_wrap.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: advance())
	hud.root.add_child(dlg_wrap)
	dlg = PanelContainer.new()
	dlg.add_theme_stylebox_override("panel", UI.box(Color("FFFDF6"), 30, 4, 10, Vector4(26, 18, 30, 18)))
	dlg.custom_minimum_size = Vector2(1180, 210)
	dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg_wrap.add_child(dlg)
	var h := UI.hbox(22)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg.add_child(h)
	dlg_portrait = UI.tex(null, Vector2(180, 180))
	h.add_child(dlg_portrait)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	dlg_name = UI.label("", 30, UI.SAKURA_D, UI.font_display)
	v.add_child(dlg_name)
	dlg_text = UI.rich("", 26)
	dlg_text.custom_minimum_size = Vector2(620, 0)
	v.add_child(dlg_text)
	dlg_opts = UI.vbox(8)
	dlg_opts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(dlg_opts)
	dlg_more = UI.label("▼", 24, UI.SAKURA, UI.font_xbold)
	dlg_more.position = Vector2(1130, 150)
	dlg.add_child(dlg_more)
	dlg_more.top_level = false

func _speaker(s: String) -> Array:
	var id := s
	if s == "partner": id = Save.partner
	if s == "Grandpa Jiro": id = "jiro"
	if People.NPCS.has(id) or People.KEEPERS.has(id):
		return [People.npc_name(id), portrait(id)]
	if s == "me": return [Save.player_name, portrait("me")]
	return [s, null]

func portrait(id: String) -> Texture2D:
	var look: Dictionary = Save.player_look if id == "me" else People.look_of(id)
	var key := "portrait:%s:%s" % [id, str(look.hash())]
	return Photo.request(key, func() -> Node3D:
		var c := Chibi.new()
		c.build(look, "adult")
		c.feel("happy", 99.0)
		return c, 256, {"focus": 0.7, "zoom": 0.46, "elev": 8.0})

func _open_dlg() -> void:
	if not dlg_wrap.visible:
		dlg_wrap.visible = true
		hud._modals.append(dlg_wrap)
		UI.pop_in(dlg, 0.94)

func _close_dlg() -> void:
	dlg_wrap.visible = false
	hud._modals.erase(dlg_wrap)
	_clear_opts()
	_text_input = null

## Removes the old answer buttons right away (not at the end of the frame), so a quick
## second click can never hit a stale option from the previous question.
func _clear_opts() -> void:
	for c in dlg_opts.get_children():
		dlg_opts.remove_child(c)
		c.queue_free()

func is_open() -> bool:
	return dlg_wrap.visible

## Shows lines of dialogue one after another: [[speaker, text], …]; then calls done.
func say(lines: Array, done := Callable()) -> void:
	if game.instant:
		if done.is_valid(): done.call()
		return
	if dlg_wrap.visible and (_lines.size() or _typing_t > 0.0 or dlg_opts.get_child_count()):
		# queue behind what's showing
		_lines.append_array(lines)
		if done.is_valid():
			var prev := _done
			_done = func():
				if prev.is_valid(): prev.call()
				done.call()
		return
	_lines = lines.duplicate()
	_done = done
	_open_dlg()
	_next()

func _next() -> void:
	_clear_opts()
	if _lines.is_empty():
		_close_dlg()
		var cb := _done
		_done = Callable()
		if cb.is_valid(): cb.call()
		return
	var l: Array = _lines.pop_front()
	_show_line(String(l[0]), String(l[1]))

func _show_line(speaker: String, text: String) -> void:
	var sp := _speaker(speaker)
	dlg_name.text = sp[0]
	dlg_name.visible = sp[0] != ""
	dlg_portrait.texture = sp[1]
	dlg_portrait.visible = sp[1] != null
	dlg_text.text = text if sp[0] != "" else "[i]%s[/i]" % text
	var dur := clampf(text.length() * 0.022, 0.2, 2.2)
	dlg_text.set_meta("dur", dur)
	dlg_text.visible_ratio = 0.0
	_typing_t = dur
	dlg_more.visible = false
	Sfx.play("pop", 0.4, 1.4)

func advance() -> void:
	if not dlg_wrap.visible: return
	if _typing_t > 0.0:
		_typing_t = 0.0
		dlg_text.visible_ratio = 1.0
		return
	if dlg_opts.get_child_count() > 0 or _text_input: return
	_next()

## A question with choices: opts = [[label, Callable], …].
func ask(speaker: String, text: String, opts: Array) -> void:
	if game.instant: return
	_lines.clear()
	_done = Callable()
	_open_dlg()
	_show_line(speaker, text)
	_typing_t = 0.0
	dlg_text.visible_ratio = 1.0
	for o in opts:
		var cb: Callable = o[1]
		var b := UI.button(o[0], "Ghost" if o[0] in ["Bye!", "Not yet", "Leave"] else "", func():
			_close_dlg()
			cb.call(), 22)
		b.custom_minimum_size = Vector2(320, 52)
		dlg_opts.add_child(b)

func ask_text(question: String, default: String, cb: Callable) -> void:
	if game.instant:
		cb.call(default)
		return
	_lines.clear()
	_done = Callable()
	_open_dlg()
	_show_line("", question)
	_typing_t = 0.0
	dlg_text.visible_ratio = 1.0
	_text_input = LineEdit.new()
	_text_input.text = default
	_text_input.max_length = 14
	_text_input.custom_minimum_size = Vector2(300, 56)
	_text_input.add_theme_font_size_override("font_size", 26)
	_text_input.select_all_on_focus = true
	dlg_opts.add_child(_text_input)
	var ok := func():
		var t := _text_input.text.strip_edges()
		if t == "": t = default
		_close_dlg()
		cb.call(t)
	_text_input.text_submitted.connect(func(_t): ok.call())
	dlg_opts.add_child(UI.button("OK", "", ok, 24))
	_text_input.grab_focus.call_deferred()

func typing() -> bool:
	var f := hud.get_viewport().gui_get_focus_owner()
	return f is LineEdit

# ================================================================ shops
func open_shop(id: String) -> void:
	match id:
		"market": _shop_market()
		"homestore": _shop_home()
		"boutique": open_boutique(false)
		"florist", "bookshop", "jeweler": _shop_gifts(id)

func _shop_header(id: String, greet: String, v: VBoxContainer) -> void:
	var keeper: String = {"market": "kai", "florist": "hana", "bookshop": "ren", "homestore": "homestore", "boutique": "boutique", "jeweler": "jeweler"}.get(id, "")
	if keeper == "": return
	var h := UI.hbox(14)
	h.add_child(UI.tex(portrait(keeper), Vector2(84, 84)))
	var l := UI.label("%s: \"%s\"" % [People.npc_name(keeper), greet], 21, UI.MUTED, UI.font_xbold, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 600
	h.add_child(l)
	h.add_child(_wallet_lbl())
	v.add_child(h)

func _wallet_lbl() -> Label:
	var l := UI.label(G.yen(Save.wallet), 26, UI.PLUM, UI.font_display)
	l.set_meta("wallet", true)
	var cb := func(): l.text = G.yen(Save.wallet)
	Save.changed.connect(cb)
	l.tree_exiting.connect(func(): Save.changed.disconnect(cb))
	return l

func _buy(price: int) -> bool:
	if Save.wallet < price:
		hud.toast("Not enough yen! Serve more customers at the café")
		Sfx.play("sad" if Sfx.has("sad") else "tick")
		return false
	Save.wallet -= price
	Sfx.play("coin")
	Save.save()
	return true

static func market_price(k: String) -> int:
	var sale := 0.5 if Save.flags.get("event", "") == "sale" else 1.0
	return maxi(10, int(round(G.ING_COST.get(k, 0) * 0.6 * sale / 10.0)) * 10)

var _market_cat := "fruit"
func _shop_market() -> void:
	var pr := hud._panel("Kai's Market", "Fresh ingredients for your pantry at 40% off delivery prices", 1100)
	var v: VBoxContainer = pr[1]
	_shop_header("market", "Everything picked this morning! Your café fridge uses pantry stock first, for free.", v)
	var cats := HFlowContainer.new()
	cats.add_theme_constant_override("h_separation", 6)
	v.add_child(cats)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var mh := {}
	var fill := func():
		for c in grid.get_children(): c.queue_free()
		for k in G.ING_KEYS:
			if G.ING[k].cat != _market_cat: continue
			var kk: String = k
			var card := PanelContainer.new()
			card.theme_type_variation = "Card"
			var cv := UI.vbox(2)
			card.add_child(cv)
			cv.add_child(UI.tex(Photo.ingredient(k, 128), Vector2(80, 80)))
			var nl := UI.label(G.ING[k].n, 17, UI.PLUM, UI.font_xbold)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.custom_minimum_size.x = 130
			nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			cv.add_child(nl)
			var have := UI.label("In pantry: %d" % int(Save.pantry.get(k, 0)), 15, UI.MUTED, UI.font_xbold)
			have.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(have)
			var row := UI.hbox(4)
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			for n in [1, 5]:
				var nn: int = n
				row.add_child(UI.button("+%d %s" % [n, G.yen(market_price(k) * n)], "Ghost" if n == 1 else "Mint", func():
					if _buy(market_price(kk) * nn):
						Save.pantry[kk] = int(Save.pantry.get(kk, 0)) + nn
						have.text = "In pantry: %d" % Save.pantry[kk]
						game.life.flag("market")
						Save.save(), 14))
			cv.add_child(row)
			grid.add_child(card)
	for c in G.CATS:
		var ck: String = c[0]
		cats.add_child(UI.chip(c[1], ck == _market_cat, func():
			_market_cat = ck
			for b in cats.get_children(): b.button_pressed = b.text == c[1]
			fill.call()))
	fill.call()
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1040, 470)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(grid)
	v.add_child(sc)
	var gifts := UI.hbox(10)
	gifts.add_child(UI.label("Gifts:", 20, UI.PLUM, UI.font_xbold))
	for g in ["sweets", "tea_set"]: gifts.add_child(_gift_btn(g))
	v.add_child(gifts)
	mh.w = hud._modal(pr[0])
	(pr[2] as Button).pressed.connect(func(): hud.close_modal(mh.w))

func _gift_btn(g: String) -> Button:
	var d: Array = People.GIFTS[g]
	var b := UI.button("%s  %s" % [d[0], G.yen(d[1])], "Ghost", Callable(), 18)
	b.icon = UI.icon("gift", 32)
	b.modulate = Color(1, 1, 1).lerp(Color(d[3]), 0.12)
	b.pressed.connect(func():
		if _buy(d[1]):
			Save.gifts[g] = int(Save.gifts.get(g, 0)) + 1
			Save.save()
			hud.toast("Bought %s (you have %d). Give it to someone special!" % [d[0], Save.gifts[g]]))
	return b

func _shop_gifts(id: String) -> void:
	var titles := {"florist": ["Hana's Flowers", "Bouquets, blooms and potted plants", "Every flower has a meaning. Roses say what words can't!"],
		"bookshop": ["Ren's Books", "Novels, poetry, manga and cookbooks", "...Welcome. The cookbooks are on the left. They're good."],
		"jeweler": ["Kobayashi Jewels", "Sparkly gifts and engagement rings", "Looking for something special, dear? Something… for a proposal, perhaps?"]}
	var t: Array = titles[id]
	var pr := hud._panel(t[0], t[1], 940)
	var v: VBoxContainer = pr[1]
	_shop_header(id, t[2], v)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	for g in People.GIFTS:
		if People.GIFTS[g][2] == id: flow.add_child(_gift_btn(g))
	v.add_child(flow)
	var mh := {}
	if id == "jeweler":
		var ring := UI.button("Engagement ring  %s" % G.yen(People.RING_PRICE), "Gold", Callable(), 24)
		ring.disabled = Save.has_ring or Save.married
		if Save.has_ring: ring.text = "You have the ring ♥"
		ring.pressed.connect(func():
			if Save.partner == "":
				hud.toast("You'll want a partner before you buy a ring!")
				return
			if _buy(People.RING_PRICE):
				Save.has_ring = true
				Save.save()
				ring.disabled = true
				ring.text = "You have the ring ♥"
				hud.toast("A ring! Talk to %s when the moment feels right…" % People.npc_name(Save.partner)))
		v.add_child(ring)
	if id == "florist":
		var pl := UI.button("Potted plant (furniture)  %s" % G.yen(900), "Mint", func():
			if _buy(900):
				Save.furni_inv["plant"] = int(Save.furni_inv.get("plant", 0)) + 1
				Save.save()
				hud.toast("A potted plant is in your storage. Place it in Edit mode"), 20)
		v.add_child(pl)
	if id == "bookshop":
		var prices := [5000, 9000, 15000]
		if Save.cookbooks < 3:
			var cb := UI.button("Plating cookbook vol. %d  %s  (+5%% tips forever)" % [Save.cookbooks + 1, G.yen(prices[Save.cookbooks])], "Gold", Callable(), 20)
			cb.pressed.connect(func():
				if _buy(prices[Save.cookbooks]):
					Save.cookbooks += 1
					Save.save()
					hud.toast("You study the cookbook all evening. Your plating looks even prettier!")
					hud.close_modal(mh.w)
					_shop_gifts("bookshop"))
			v.add_child(cb)
		else:
			v.add_child(UI.label("You've read every plating cookbook. Ren is impressed.", 19, UI.MUTED, UI.font_xbold))
	v.add_child(UI.label("Your gifts: " + (", ".join(Save.gifts.keys().map(func(k): return "%s ×%d" % [People.gift_name(k), Save.gifts[k]])) if Save.gifts.size() else "none yet"), 18, UI.MUTED, UI.font_xbold, true))
	mh.w = hud._modal(pr[0])
	(pr[2] as Button).pressed.connect(func(): hud.close_modal(mh.w))

var _home_tab := "Tables"
func _shop_home() -> void:
	var pr := hud._panel("Home Store", "Furniture for your café and your home · bought items go to storage (Edit mode)", 1120)
	var v: VBoxContainer = pr[1]
	_shop_header("homestore", "Ah, a customer! Everything here is handmade in Hoshizora.", v)
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 6)
	v.add_child(tabs)
	var body := UI.vbox(8)
	body.custom_minimum_size.x = 1040
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1060, 500)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(body)
	v.add_child(sc)
	var mh := {}
	var cats := ["Tables", "Seating", "Bedroom", "Decor", "Living", "Walls & floors"]
	var fill := func():
		for c in body.get_children(): c.queue_free()
		if _home_tab == "Walls & floors":
			_themes(body)
			return
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		body.add_child(grid)
		for id in Furni.CATALOG:
			var f := Furni.info(id)
			if f.cat != _home_tab: continue
			var fid: String = id
			var card := PanelContainer.new()
			card.theme_type_variation = "Card"
			card.custom_minimum_size = Vector2(515, 0)
			var h := UI.hbox(12)
			card.add_child(h)
			h.add_child(UI.tex(Photo.request("furni:" + id, func() -> Node3D: return Furni.node(fid), 160), Vector2(110, 110)))
			var iv := UI.vbox(2)
			iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(iv)
			iv.add_child(UI.label(f.name, 22, UI.PLUM, UI.font_display))
			iv.add_child(UI.label(f.desc, 16, UI.MUTED, UI.font_xbold, true))
			var where: String = {"both": "Café or home", "cafe": "Café only", "home": "Home only"}[f.where]
			var owned := int(Save.furni_inv.get(id, 0))
			var tag := UI.label("%s · %s" % [where, ("%d in storage" % owned) if owned else "not owned"], 15, UI.SAKURA_D, UI.font_xbold)
			iv.add_child(tag)
			var b := UI.button(G.yen(f.price), "Gold", Callable(), 20)
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			b.pressed.connect(func():
				if _buy(f.price):
					Save.furni_inv[fid] = int(Save.furni_inv.get(fid, 0)) + 1
					Save.save()
					game.life.flag("buy_furni")
					tag.text = "%s · %d in storage" % [where, Save.furni_inv[fid]]
					hud.toast("%s is in storage. Open Edit mode in your %s to place it" % [f.name, "café or home" if f.where == "both" else f.where]))
			h.add_child(b)
			grid.add_child(card)
	for c in cats:
		var cc: String = c
		tabs.add_child(UI.chip(c, c == _home_tab, func():
			_home_tab = cc
			for b in tabs.get_children(): b.button_pressed = b.text == cc
			fill.call()))
	fill.call()
	mh.w = hud._modal(pr[0])
	(pr[2] as Button).pressed.connect(func(): hud.close_modal(mh.w))

func _themes(body: VBoxContainer) -> void:
	for place in ["cafe", "home"]:
		var pk: String = place
		body.add_child(UI.label("Your %s (¥1,500 each)" % ("café" if place == "cafe" else "home"), 22, UI.PLUM, UI.font_display))
		for kind in ["wall", "floor"]:
			var kk: String = kind
			var row := HFlowContainer.new()
			row.add_theme_constant_override("h_separation", 6)
			row.add_theme_constant_override("v_separation", 6)
			row.add_child(UI.label("Walls:" if kind == "wall" else "Floor:", 18, UI.MUTED, UI.font_xbold))
			var opts: Dictionary = Furni.WALLS if kind == "wall" else Furni.FLOORS
			for nm in opts:
				var n: String = nm
				var cur: String = Save.themes.get(place, {}).get(kind, "")
				var b := UI.button(nm, "Mint" if cur == nm else "Ghost", Callable(), 17)
				var col: Color = Color(opts[nm]) if kind == "wall" else Color(opts[nm][0])
				b.icon = _swatch(col)
				b.pressed.connect(func():
					if _buy(1500):
						if not Save.themes.has(pk): Save.themes[pk] = {}
						Save.themes[pk][kk] = n
						Save.save()
						game.locs[pk].apply_theme()
						hud.toast("Repainted! It looks lovely")
						for c in row.get_children(): if c is Button: c.theme_type_variation = "Mint" if c.text == n else "Ghost")
				row.add_child(b)
			body.add_child(row)

static func _swatch(c: Color) -> Texture2D:
	var img := Image.create(28, 28, false, Image.FORMAT_RGBA8)
	img.fill(c)
	for i in 28:
		for j in [0, 1, 26, 27]:
			img.set_pixel(i, j, Color("3B2340"))
			img.set_pixel(j, i, Color("3B2340"))
	return ImageTexture.create_from_image(img)

# ================================================================ character look (creator, boutique, wardrobe)
func _look_editor(look: Dictionary, v: VBoxContainer, on_change: Callable, skin := true) -> void:
	if not look.has("body"): look.body = Chibi.body_of(look)
	if not look.has("bottom"): look.bottom = "pants"
	var rows := [["body", "Body", ["f", "m"]], ["style", "Hair", Chibi.STYLES], ["hair", "Hair colour", Chibi.HAIRS], ["shirt", "Top", Chibi.SHIRTS],
		["bottom", "Bottoms", Chibi.BOTTOMS], ["pants", "Bottoms colour", Chibi.PANTS], ["acc", "Accessory", ["", "bow", "flower", "beret", "glasses"]]]
	if skin: rows.insert(1, ["skin", "Skin", Chibi.SKINS])
	var names := {"f": "Feminine", "m": "Masculine", "pants": "Trousers", "shorts": "Shorts", "skirt": "Skirt", "dress": "Dress", "": "None"}
	for r in rows:
		var field: String = r[0]
		var h := HFlowContainer.new()
		h.add_theme_constant_override("h_separation", 5)
		h.add_theme_constant_override("v_separation", 5)
		var l := UI.label(r[1], 18, UI.PLUM, UI.font_xbold)
		l.custom_minimum_size.x = 150
		h.add_child(l)
		for o in r[2]:
			var val: String = o.to_html(false) if o is Color else String(o)
			var b: Button
			if o is Color:
				b = Button.new()
				b.icon = _swatch(o)
				b.theme_type_variation = "Ghost"
				b.focus_mode = Control.FOCUS_NONE
				b.custom_minimum_size = Vector2(44, 44)
			else:
				b = UI.button(names.get(val, val.capitalize()), "Ghost", Callable(), 16)
			b.toggle_mode = true
			b.button_pressed = String(look.get(field, "")).to_lower() == val.to_lower()
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			b.pressed.connect(func():
				look[field] = val
				for c in h.get_children(): if c is Button: c.button_pressed = c == b
				Sfx.play("click")
				on_change.call())
			h.add_child(b)
		v.add_child(h)

## A little live 3D preview of a chibi that slowly turns.
func chibi_preview(look: Dictionary, size := Vector2(300, 380)) -> Array:
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.custom_minimum_size = size
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	cont.add_child(vp)
	var cam := Camera3D.new()
	cam.fov = 28
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, 0.75, 2.2), Vector3(0, 0.4, 0))
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-40, -30, 0)
	l.light_energy = 0.8
	vp.add_child(l)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.8, 0.95)
	env.ambient_light_energy = 0.7
	we.environment = env
	vp.add_child(we)
	var pivot := Node3D.new()
	vp.add_child(pivot)
	var holder := {"c": null}
	var rebuild := func():
		if holder.c: holder.c.queue_free()
		var c := Chibi.new()
		pivot.add_child(c)
		c.build(look, "adult")
		c.feel("happy", 999.0)
		holder.c = c
	rebuild.call()
	var tw := pivot.create_tween().set_loops()
	tw.tween_property(pivot, "rotation:y", TAU, 9.0).from(0.0)
	return [cont, rebuild]

func open_creator(mode: String) -> void:
	var look := Chibi.random_look()
	look.acc = ""
	var pr := hud._panel("Who are you?", ("Story mode: inherit Grandma's café and build a life in Hoshizora" if mode == "story" else "Freeplay: ¥20,000, no story, everything open"), 1180)
	var v: VBoxContainer = pr[1]
	var h := UI.hbox(20)
	v.add_child(h)
	var prev := chibi_preview(look)
	h.add_child(prev[0])
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	var nrow := UI.hbox(10)
	nrow.add_child(UI.label("Name", 20, UI.PLUM, UI.font_xbold))
	var name_in := LineEdit.new()
	name_in.text = ["Mochi", "Sakura", "Kiku", "Nori", "Yuzu", "Ume"][randi() % 6]
	name_in.max_length = 14
	name_in.custom_minimum_size = Vector2(300, 50)
	name_in.add_theme_font_size_override("font_size", 24)
	nrow.add_child(name_in)
	nrow.add_child(UI.button("Surprise me", "Ghost", func():
		var r := Chibi.random_look()
		for k in r: look[k] = r[k]
		hud.close_top()
		open_creator(mode), 18))
	right.add_child(nrow)
	_look_editor(look, right, prev[1])
	var mh := {}
	var start := UI.button("Start my new life ♥", "", func():
		var nm := name_in.text.strip_edges()
		Save.new_game(mode, nm if nm != "" else "Chef", look)
		hud.close_all()
		game.counter.clear()
		game.rebuild_player()
		game.home.reload()
		game.cafe.furni.load_layout()
		game.cafe.apply_theme()
		game.travel_now("home", "start")
		hud.counter_changed()
		Sfx.play("chime")
		if mode == "freeplay":
			say([["", "Welcome to Hoshizora Town, %s! Your café is just down the street. Everything is open: cook, decorate, make friends, fall in love." % Save.player_name],
				["", "Tips: WASD or click to walk · E to interact · J for your journal · ` (backtick) opens the cheat console."]])
		else:
			say([["", "Your train pulls into Hoshizora Town on a sunny spring morning. Grandma's old apartment smells of tea and tatami."],
				["", "Tips: WASD or click to walk · E to interact · J for your journal."]], func(): game.life.check_story()), 28)
	start.custom_minimum_size = Vector2(0, 70)
	v.add_child(start)
	mh.w = hud._modal(pr[0], true, false)
	(pr[2] as Button).pressed.connect(func(): hud.close_modal(mh.w))

func open_boutique(free: bool) -> void:
	var look: Dictionary = Save.player_look.duplicate()
	var pr := hud._panel("Your wardrobe" if free else "Mimi's Boutique", "Try on a new look" + ("" if free else " · ¥1,200 for a makeover"), 1100)
	var v: VBoxContainer = pr[1]
	if not free: _shop_header("boutique", "Ooh, you'd look adorable in lilac! Try everything on, sweetie.", v)
	var h := UI.hbox(20)
	v.add_child(h)
	var prev := chibi_preview(look, Vector2(280, 340))
	h.add_child(prev[0])
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	_look_editor(look, right, prev[1], false)
	var mh := {}
	v.add_child(UI.button("Wear this" if free else "Buy the makeover · ¥1,200", "", func():
		if not free and not _buy(1200): return
		Save.player_look = look
		Save.save()
		game.rebuild_player()
		hud.close_modal(mh.w)
		hud.toast("Looking good!")
		Sfx.play("yay"), 24))
	mh.w = hud._modal(pr[0])
	(pr[2] as Button).pressed.connect(func(): hud.close_modal(mh.w))

# ================================================================ gifts, journal, newspaper, console
func pick_gift(npc: String) -> void:
	var opts: Array = []
	for g in Save.gifts:
		var gg: String = g
		opts.append(["%s (×%d)" % [People.gift_name(g), Save.gifts[g]], func(): game.life.give(npc, gg)])
	opts.append(["Never mind", func(): pass])
	ask(npc, "What will you give?", opts)

func open_journal() -> void:
	var pr := hud._panel("Journal", "%s's notebook · Day %d" % [Save.player_name, Save.day], 1000)
	var v: VBoxContainer = pr[1]
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 6)
	v.add_child(tabs)
	var body := UI.vbox(10)
	body.custom_minimum_size.x = 920
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(940, 520)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(body)
	v.add_child(sc)
	var show := func(tab: String):
		for c in body.get_children(): c.queue_free()
		for b in tabs.get_children(): b.button_pressed = b.text == tab
		match tab:
			"Story": _journal_story(body)
			"People": _journal_people(body)
			"Café": _journal_cafe(body)
			"Family": _journal_family(body)
	for t in ["Story", "People", "Café", "Family"]:
		var tt: String = t
		tabs.add_child(UI.chip(t, false, func(): show.call(tt)))
	show.call("Story")
	var mh := {}
	mh.w = hud._modal(pr[0])
	(pr[2] as Button).pressed.connect(func(): hud.close_modal(mh.w))

func _journal_story(body: VBoxContainer) -> void:
	if Save.mode == "freeplay":
		body.add_child(UI.label("Freeplay", 30, UI.PLUM, UI.font_display))
		body.add_child(UI.label("No story, no rules. Cook, decorate, make friends, fall in love and raise a family at your own pace.", 21, UI.MUTED, UI.font_xbold, true))
	elif not Story.active():
		body.add_child(UI.label("The story is complete ♥", 30, UI.PLUM, UI.font_display))
		body.add_child(UI.label("Grandma is proud of you. Hoshizora Town carries on as long as you like.", 21, UI.MUTED, UI.font_xbold, true))
	else:
		var ch := Story.chapter()
		body.add_child(UI.label("Chapter %d of %d" % [Save.chapter + 1, Story.CHAPTERS.size()], 18, UI.SAKURA_D, UI.font_xbold))
		body.add_child(UI.label(ch.title, 34, UI.PLUM, UI.font_display))
		for q in Story.progress():
			var h := UI.hbox(10)
			h.add_child(UI.tex(UI.icon("check" if q[1] else "star_off", 32), Vector2(30, 30)))
			var rt := UI.rich(("[color=#2E8A68][s]%s[/s][/color]" if q[1] else "%s") % q[0], 22)
			rt.custom_minimum_size.x = 820
			h.add_child(rt)
			body.add_child(h)
		body.add_child(UI.label("Reward: %s from Grandma" % G.yen(ch.reward), 19, UI.MUTED, UI.font_xbold))
	body.add_child(UI.label("Controls", 22, UI.PLUM, UI.font_display))
	body.add_child(UI.label("WASD / arrows or click: walk · E / Space: interact · J: journal · B: recipe book · F: fridge (café) · Q: eat what you're carrying · Esc: back / settings · `: cheat console", 18, UI.MUTED, UI.font_xbold, true))

func _journal_people(body: VBoxContainer) -> void:
	for id in People.NPCS:
		var d: Dictionary = People.NPCS[id]
		var card := PanelContainer.new()
		card.theme_type_variation = "Card"
		var h := UI.hbox(14)
		card.add_child(h)
		h.add_child(UI.tex(portrait(id), Vector2(100, 100)))
		var iv := UI.vbox(2)
		iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(iv)
		var st: String = "your spouse ♥" if Save.married and Save.partner == id else "your partner ♥" if Save.partner == id else d.job
		if game.life.cheating_with(id): st = "your secret sweetheart ♥"
		elif game.life.is_lover(id): st = "your sweetheart ♥"
		elif Save.r(id).get("ex", false): st = "your ex · " + d.job
		iv.add_child(UI.label("%s · %s" % [d.name, st], 24, UI.PLUM, UI.font_display))
		iv.add_child(UI.hearts(Save.hearts(id), 26))
		iv.add_child(UI.label(d.bio, 17, UI.MUTED, UI.font_xbold, true))
		var known: bool = Save.hearts(id) >= 2.0 or Save.r(id).get("known", false)
		iv.add_child(UI.label("Loves: %s · Favourite dish: %s" % [", ".join(d.loves.map(People.gift_name)), d.fav] if known else "Get to know them better to learn what they love…", 16, UI.SAKURA_D, UI.font_xbold, true))
		body.add_child(card)

func _journal_cafe(body: VBoxContainer) -> void:
	var h := UI.hbox(12)
	h.add_child(UI.label("Café rating", 26, UI.PLUM, UI.font_display))
	h.add_child(UI.stars(int(round(Save.reputation)), 34, 5))
	h.add_child(UI.label("%.1f / 5" % Save.reputation, 24, UI.PLUM, UI.font_xbold))
	body.add_child(h)
	var lp := Save.level_progress()
	body.add_child(UI.label("Level %d (%d/%d stars to next) · %d customers served · best day %s · %d/%d recipes · %d plating cookbooks" % [lp.z, lp.x, lp.y, Save.served_total, G.yen(Save.best_day), Save.found_count(), G.RECIPES.size(), Save.cookbooks], 18, UI.MUTED, UI.font_xbold, true))
	body.add_child(UI.label("Reviews", 24, UI.PLUM, UI.font_display))
	if Save.reviews.is_empty():
		body.add_child(UI.label("No critic has visited yet. They come once the café has a bit of a reputation.", 18, UI.MUTED, UI.font_xbold, true))
	for i in range(Save.reviews.size() - 1, -1, -1):
		body.add_child(_review_card(Save.reviews[i]))

func _review_card(r: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	var v := UI.vbox(4)
	card.add_child(v)
	var h := UI.hbox(10)
	h.add_child(UI.label("%s · %s" % [r.critic, r.get("paper", "")], 20, UI.PLUM, UI.font_xbold))
	h.add_child(UI.stars(int(r.stars), 24, 5))
	v.add_child(h)
	v.add_child(UI.label("Day %d · ordered %s" % [r.day, r.dish], 15, UI.MUTED, UI.font_xbold))
	v.add_child(UI.label("\"%s\"" % r.quote, 20, UI.PLUM, UI.font_body, true))
	return card

func _journal_family(body: VBoxContainer) -> void:
	if Save.partner == "":
		body.add_child(UI.label("Maybe one day someone special will share your life. Chat with the townsfolk, give gifts and ask them on dates.", 20, UI.MUTED, UI.font_xbold, true))
		for k in Save.family.kids:
			var par: String = k.get("parent", "")
			body.add_child(UI.label("%s · %s%s" % [k.name, Life.kid_stage(k), (" · with " + People.npc_name(par)) if par != "" else ""], 21, UI.PLUM, UI.font_xbold))
		return
	var h := UI.hbox(14)
	h.add_child(UI.tex(portrait(Save.partner), Vector2(110, 110)))
	var iv := UI.vbox(2)
	iv.add_child(UI.label("%s · your %s" % [People.npc_name(Save.partner), "spouse" if Save.married else "partner"], 26, UI.PLUM, UI.font_display))
	iv.add_child(UI.hearts(Save.hearts(Save.partner), 28))
	if Save.married: iv.add_child(UI.label("Married on day %d" % Save.wedding_day, 17, UI.MUTED, UI.font_xbold))
	if int(Save.family.expecting) >= 0: iv.add_child(UI.label("Expecting a baby in %d day(s) ♥" % maxi(0, int(Save.family.expecting) - Save.day), 18, UI.SAKURA_D, UI.font_xbold))
	h.add_child(iv)
	body.add_child(h)
	for k in Save.family.kids:
		var kh := UI.hbox(10)
		kh.add_child(UI.tex(UI.icon("baby", 48), Vector2(44, 44)))
		var par: String = k.get("parent", "")
		var with_txt := (" · with " + People.npc_name(par)) if par != "" else ""
		kh.add_child(UI.label("%s · %s · %d days old%s" % [k.name, Life.kid_stage(k), Save.day - int(k.born), with_txt], 21, UI.PLUM, UI.font_xbold))
		body.add_child(kh)
	if Save.married and Save.family.kids.is_empty() and int(Save.family.expecting) < 0:
		body.add_child(UI.label("Thinking about a family? With a double bed at home, talk to %s in the evening." % People.npc_name(Save.partner), 18, UI.MUTED, UI.font_xbold, true))

func open_newspaper(reviews: Array) -> void:
	var pr := hud._panel("The Hoshizora Times", "Morning edition · Day %d" % Save.day, 860)
	var v: VBoxContainer = pr[1]
	var head := UI.label("CRITIC VISITS LOCAL CAFÉ", 34, UI.PLUM, UI.font_display)
	v.add_child(head)
	for r in reviews: v.add_child(_review_card(r))
	var h := UI.hbox(10)
	h.add_child(UI.label("Café rating now:", 21, UI.MUTED, UI.font_xbold))
	h.add_child(UI.stars(int(round(Save.reputation)), 28, 5))
	h.add_child(UI.label("%.1f" % Save.reputation, 21, UI.PLUM, UI.font_xbold))
	v.add_child(h)
	var mh := {}
	v.add_child(UI.button("Fold the paper", "", func(): hud.close_modal(mh.w), 22))
	mh.w = hud._modal(pr[0])
	(pr[2] as Button).pressed.connect(func(): hud.close_modal(mh.w))
	Sfx.play("fwip" if Sfx.has("fwip") else "pop")

## The cheat menu: every cheat as a button (toggles light up), plus a box for typing codes.
func open_console() -> void:
	if hud.modal_open() and hud._modals.size() and hud._modals.back().has_meta("cheats"): return
	var pr := hud._panel("Cheat menu", "Shh… nobody will know. Tap a cheat, or type its code below.", 1180)
	var v: VBoxContainer = pr[1]
	var top := UI.hbox(10)
	var line := LineEdit.new()
	line.placeholder_text = "Type a code, e.g. kaching"
	line.custom_minimum_size = Vector2(420, 52)
	line.add_theme_font_size_override("font_size", 22)
	top.add_child(line)
	var out := UI.label("", 21, UI.SAKURA_D, UI.font_xbold)
	out.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(out)
	v.add_child(top)
	var body := UI.vbox(8)
	body.custom_minimum_size.x = 1120
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1140, 560)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(body)
	v.add_child(sc)
	var buttons := {}
	var refresh := func():
		for code in buttons:
			var b: Button = buttons[code]
			var on := Life.cheat_on(code)
			b.theme_type_variation = "Mint" if on else "Ghost"
			b.text = Life.CHEATS[code][0] + ("  ✓" if on else "")
	var run := func(code: String):
		var msg: String = game.life.cheat(code)
		out.text = msg
		hud.toast(msg)
		refresh.call()
	var cats := ["Money", "Cooking", "Café", "You", "Time", "Love", "Stuff"]
	for cat in cats:
		var row := UI.hbox(12)
		var cl := UI.label(cat, 22, UI.PLUM, UI.font_display)
		cl.custom_minimum_size.x = 110
		row.add_child(cl)
		var flow := HFlowContainer.new()
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		row.add_child(flow)
		for code in Life.CHEATS:
			var d: Array = Life.CHEATS[code]
			if d[1] != cat: continue
			var cc: String = code
			var b := UI.button(d[0], "Ghost", func(): run.call(cc), 18)
			b.tooltip_text = "%s  (code: %s)%s" % [d[2], code, "  · toggle" if d[3] else ""]
			b.custom_minimum_size = Vector2(150, 48)
			flow.add_child(b)
			buttons[code] = b
		body.add_child(row)
	refresh.call()
	line.text_submitted.connect(func(t):
		out.text = game.life.cheat(t)
		line.text = ""
		refresh.call())
	var mh := {}
	mh.w = hud._modal(pr[0])
	mh.w.set_meta("cheats", true)
	(pr[2] as Button).pressed.connect(func(): hud.close_modal(mh.w))

# ================================================================ edit mode panel
func _build_edit() -> void:
	edit_panel = PanelContainer.new()
	edit_panel.add_theme_stylebox_override("panel", UI.box(Color("FFF6EA"), 28, 3, 9, Vector4(16, 10, 16, 10)))
	edit_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	edit_panel.offset_left = 30
	edit_panel.offset_right = -30
	edit_panel.offset_top = -226
	edit_panel.offset_bottom = -20
	edit_panel.visible = false
	hud.root.add_child(edit_panel)
	var v := UI.vbox(6)
	edit_panel.add_child(v)
	var top := UI.hbox(10)
	v.add_child(top)
	var t := UI.label("Edit mode", 28, UI.PLUM, UI.font_display)
	top.add_child(t)
	edit_hint = UI.label("", 18, UI.MUTED, UI.font_xbold)
	edit_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(edit_hint)
	top.add_child(UI.button("Rotate (R)", "Ghost", func(): game.edit.rotate(), 18))
	top.add_child(UI.button("Store (X)", "Ghost", func(): game.edit.store(), 18))
	top.add_child(UI.button("Done", "", func(): game.edit.stop(), 20))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 136)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	edit_list = UI.hbox(8)
	sc.add_child(edit_list)

func edit_ui(on: bool) -> void:
	edit_panel.visible = on
	if on: edit_changed()
	hud.station_changed()

func edit_changed() -> void:
	if not edit_panel.visible: return
	var held: bool = game.edit.held.size() > 0
	edit_hint.text = ("Click to place · R or right-click to rotate · X to store · Esc to cancel" if held else "Click furniture to pick it up, or choose something from storage below")
	for c in edit_list.get_children(): c.queue_free()
	var where: String = game.loc.key if game.loc else "cafe"
	var any := false
	for id in Save.furni_inv:
		if not Furni.CATALOG.has(id) or int(Save.furni_inv[id]) <= 0 or not Furni.fits(id, where): continue
		any = true
		var fid: String = id
		var b := Button.new()
		b.theme_type_variation = "Ghost"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(130, 126)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var bv := UI.vbox(-2)
		bv.set_anchors_preset(Control.PRESET_FULL_RECT)
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bv)
		var tr := UI.tex(Photo.request("furni:" + id, func() -> Node3D: return Furni.node(fid), 160), Vector2(70, 70))
		tr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bv.add_child(tr)
		var l := UI.label("%s ×%d" % [Furni.info(id).name, Save.furni_inv[id]], 14, UI.PLUM, UI.font_xbold)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.custom_minimum_size.x = 112
		bv.add_child(l)
		b.pressed.connect(func():
			Sfx.play("click")
			game.edit.hold_new(fid)
			edit_changed())
		edit_list.add_child(b)
	if not any:
		edit_list.add_child(UI.label("Storage is empty. Buy furniture at the Home Store in town!", 19, UI.MUTED, UI.font_xbold))
