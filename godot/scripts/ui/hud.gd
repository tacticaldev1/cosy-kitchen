## The heads-up display: top bar, order tickets, station toolbar, counter shelf, hint and
## action buttons, flying food icons, toasts, and the modal panels.
class_name Hud
extends CanvasLayer

var game: Game
var root: Control
var top_right: HBoxContainer
var coins_lbl: Label
var day_lbl: Label
var level_lbl: Label
var level_bar: ProgressBar
var book_lbl: Label
var ticket_box: PanelContainer
var ticket_title: Label
var ticket_label: Label
var ticket_body: RichTextLabel
var ticket_bar: ProgressBar
var ticket_dots: HBoxContainer
var ticket_icon: TextureRect
var ticket_btn: Button
var orders_row: HBoxContainer
var toolbar: GridContainer
var tool_btns := {}
var hint_lbl: RichTextLabel
var meter: Control
var meter_fill: Panel
var meter_zone: Panel
var go_btn: Button
var back_btn: Button
var slots: Array = []
var slot_icons: Array = []
var slot_badges: Array = []
var next_chip: Button
var toast_box: PanelContainer
var toast_lbl: Label
var toast_t := 0.0
var fly_layer: Control
var fridge: Control
var _modals: Array = []
var _book: BookPanel
var _cache := {}
var _fridge_cat := "fruit"

func _ready() -> void:
	layer = 5
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	add_child(root)
	_build_top()
	_build_ticket()
	_build_toolbar()
	_build_footer()
	_build_counter()
	fly_layer = Control.new()
	fly_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fly_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fly_layer)
	_build_toast()
	Save.changed.connect(_sync_top)
	game.shop.changed.connect(_sync_orders)
	_sync_top()
	_sync_orders()
	counter_changed()
	station_changed()

## 3D viewport coordinates -> HUD canvas coordinates.
func to_canvas(p: Vector2) -> Vector2:
	return p

# ================================================================ top bar
func _pill(icon_name: String, text: String, cb: Callable = Callable()) -> Array:
	var b := Button.new()
	b.theme_type_variation = "Ghost"
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.icon = UI.icon(icon_name, 34)
	b.text = text
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_constant_override("h_separation", 8)
	if cb.is_valid():
		b.pressed.connect(cb)
		b.pressed.connect(func(): Sfx.play("click"))
	else:
		b.mouse_default_cursor_shape = Control.CURSOR_ARROW
	return [b, b]

func _build_top() -> void:
	var title := UI.vbox(-6)
	title.position = Vector2(28, 14)
	root.add_child(title)
	var t := UI.title("Cosy Kitchen", 40)
	t.add_theme_color_override("font_shadow_color", Color("FF7EA6"))
	t.add_theme_constant_override("shadow_offset_y", 3)
	t.add_theme_constant_override("shadow_offset_x", 0)
	t.add_theme_color_override("font_outline_color", Color.WHITE)
	t.add_theme_constant_override("outline_size", 10)
	title.add_child(t)
	var sub := UI.label("ほっこりキッチン", 17, UI.SAKURA_D, UI.font_xbold)
	sub.add_theme_color_override("font_outline_color", Color.WHITE)
	sub.add_theme_constant_override("outline_size", 6)
	title.add_child(sub)
	top_right = UI.hbox(10)
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.position = Vector2(-20, 16)
	top_right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.add_child(top_right)
	var day := _pill("clock", "Day 1", func(): game.shop.toggle())
	day_lbl = null
	top_right.add_child(day[0])
	_cache.day_btn = day[0]
	var lv := Button.new()
	lv.theme_type_variation = "Ghost"
	lv.focus_mode = Control.FOCUS_NONE
	lv.icon = UI.icon("star", 34)
	lv.add_theme_font_size_override("font_size", 24)
	lv.tooltip_text = "Café level: earn stars by serving customers"
	top_right.add_child(lv)
	_cache.lv_btn = lv
	var coins := _pill("coin", "¥0")
	top_right.add_child(coins[0])
	_cache.coin_btn = coins[0]
	var book := _pill("book", "0/100", func(): open_book())
	top_right.add_child(book[0])
	_cache.book_btn = book[0]
	var deco := _pill("plant", "", func(): open_decor())
	deco[0].tooltip_text = "Decorate the café"
	top_right.add_child(deco[0])
	var upd := UI.button("Update!", "Gold", func(): Updater.update_now(), 22)
	upd.visible = false
	upd.tooltip_text = "A new version of Cosy Kitchen is ready"
	top_right.add_child(upd)
	_cache.upd_btn = upd
	Updater.status_changed.connect(_sync_update)
	var gear := _pill("gear", "", func(): open_settings())
	gear[0].tooltip_text = "Settings"
	top_right.add_child(gear[0])

func _sync_update() -> void:
	var b: Button = _cache.get("upd_btn")
	if b == null: return
	match Updater.state:
		"available":
			b.visible = true
			b.disabled = false
			b.text = "Update to v%s" % Updater.latest
		"downloading":
			b.visible = true
			b.disabled = true
			b.text = "Downloading… %d%%" % int(Updater.progress * 100.0)
		_:
			b.visible = false
	if Updater.state == "available" and not _cache.get("upd_toasted", false):
		_cache.upd_toasted = true
		toast("A new version (v%s) is ready. Tap Update in the top bar!" % Updater.latest)

func _sync_top() -> void:
	if not _cache.has("coin_btn"): return
	(_cache.coin_btn as Button).text = G.yen(Save.wallet)
	(_cache.coin_btn as Button).add_theme_color_override("font_color", Color("C2415E") if Save.wallet < 0 else UI.PLUM)
	(_cache.book_btn as Button).text = "%d/%d" % [Save.found_count(), G.RECIPES.size()]
	var lp := Save.level_progress()
	(_cache.lv_btn as Button).text = "Lv %d  %d/%d" % [Save.level(), lp.x, lp.y]
	_sync_day()

func _sync_day() -> void:
	var b: Button = _cache.day_btn
	if game.shop.open:
		var h := 11.0 + game.shop.day_t * 10.0
		var hh := int(h)
		var mm := int((h - hh) * 60.0) / 15 * 15
		b.text = "Day %d · %d:%02d%s · Close" % [Save.day, hh if hh <= 12 else hh - 12, mm, "am" if hh < 12 else "pm"]
	else:
		b.text = "Day %d · Open shop" % Save.day

# ================================================================ ticket (current order / guide)
func _build_ticket() -> void:
	ticket_box = PanelContainer.new()
	ticket_box.theme_type_variation = "Ticket"
	ticket_box.position = Vector2(28, 98)
	ticket_box.custom_minimum_size = Vector2(430, 0)
	ticket_box.rotation = -0.012
	ticket_box.mouse_filter = Control.MOUSE_FILTER_STOP
	ticket_box.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: _ticket_click())
	root.add_child(ticket_box)
	var h := UI.hbox(14)
	ticket_box.add_child(h)
	ticket_icon = UI.tex(null, Vector2(96, 96))
	h.add_child(ticket_icon)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := UI.hbox(6)
	v.add_child(top)
	ticket_label = UI.label("", 16, Color("9C7FA3"), UI.font_xbold)
	ticket_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(ticket_label)
	ticket_dots = UI.hbox(4)
	top.add_child(ticket_dots)
	ticket_title = UI.label("", 26, UI.PLUM, UI.font_display)
	ticket_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ticket_title.custom_minimum_size.x = 290
	v.add_child(ticket_title)
	ticket_body = UI.rich("", 19)
	ticket_body.custom_minimum_size = Vector2(300, 0)
	v.add_child(ticket_body)
	ticket_bar = ProgressBar.new()
	ticket_bar.custom_minimum_size = Vector2(0, 10)
	ticket_bar.show_percentage = false
	ticket_bar.max_value = 1.0
	ticket_bar.add_theme_stylebox_override("background", UI.box(Color(UI.PLUM, 0.12), 6, 0, 0, Vector4.ZERO))
	v.add_child(ticket_bar)
	orders_row = UI.hbox(8)
	orders_row.position = Vector2(30, 0)
	root.add_child(orders_row)
	var tape := ColorRect.new()
	tape.color = Color(1.0, 0.49, 0.65, 0.7)
	tape.size = Vector2(76, 24)
	tape.position = Vector2(205, 86)
	tape.rotation = -0.03
	tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tape)

func _ticket_click() -> void:
	Sfx.play("click")
	var a := game.shop.active_cust()
	if a:
		open_ticket(a.order, a)
	elif not game.shop.open and Save.pinned < 0:
		game.shop.toggle()
	elif Save.pinned >= 0:
		open_ticket(Save.pinned, null)
	else:
		var w := game.shop.waiting()
		if w.size(): game.shop.take_order(w[0])

func _sync_ticket() -> void:
	var a := game.shop.active_cust()
	var gd := game.guide()
	var dot_key := str(gd.get("id", -1)) + str(gd.get("done", []))
	var rebuild_dots: bool = _cache.get("dots", "") != dot_key
	if rebuild_dots:
		_cache.dots = dot_key
		for c in ticket_dots.get_children(): c.queue_free()
	ticket_bar.visible = false
	if a:
		var r: Dictionary = G.RECIPES[a.order]
		var others := game.shop.orders().size() - 1
		ticket_label.text = "ORDER · %s · %s%s" % [a.cname.to_upper(), G.yen(r.price * (2 if a.kind == "critic" else 1)), "   +%d MORE" % others if others > 0 else ""]
		ticket_title.text = r.n
		ticket_icon.texture = Photo.recipe(r.id, 192)
		ticket_body.text = ("%d/%d: %s" % [gd.cur + 1, gd.steps.size(), gd.steps[gd.cur].text]) if gd.size() else ""
		ticket_bar.visible = true
		var f := clampf(a.patience / a.pmax, 0.0, 1.0)
		ticket_bar.value = f
		ticket_bar.add_theme_stylebox_override("fill", UI.box(Color("5CC98E") if f > 0.5 else Color("FFC93C") if f > 0.25 else Color("FF6A6A"), 6, 0, 0, Vector4.ZERO))
		_dots(gd)
	elif game.shop.open:
		var w := game.shop.waiting()
		ticket_label.text = "DAY %d · SHOP OPEN · %s TAKEN" % [Save.day, G.yen(game.shop.stats.get("sales", 0) + game.shop.stats.get("tips", 0))]
		ticket_icon.texture = Customer.wait_texture() if w.size() else UI.icon("sign", 96)
		if w.size():
			ticket_title.text = "%s is ready to order" % w[0].cname
			ticket_body.text = "Tap them (or this ticket) to take the order."
		elif gd.size():
			ticket_title.text = G.RECIPES[Save.pinned].n
			ticket_body.text = "%d/%d: %s" % [gd.cur + 1, gd.steps.size(), gd.steps[gd.cur].text]
			ticket_icon.texture = Photo.recipe(Save.pinned, 192)
			_dots(gd)
		else:
			ticket_title.text = "Waiting for customers…"
			ticket_body.text = "[color=#7D6283]Cook something while you wait, or check the recipe book.[/color]"
			if game.shop.special >= 0:
				ticket_body.text = "[color=#7D6283]Today's special: [b]%s[/b] (+50%% tip)[/color]" % G.RECIPES[game.shop.special].n
	elif gd.size():
		var r: Dictionary = G.RECIPES[Save.pinned]
		ticket_label.text = "GUIDE · STEP %d OF %d" % [gd.cur + 1, gd.steps.size()]
		ticket_title.text = r.n
		ticket_icon.texture = Photo.recipe(r.id, 192)
		ticket_body.text = gd.steps[gd.cur].text
		_dots(gd)
	else:
		ticket_label.text = "DAY %d · SHOP CLOSED" % Save.day
		ticket_title.text = "Free cooking"
		ticket_icon.texture = UI.icon("sign", 96)
		ticket_body.text = "[color=#7D6283]Tap here (or the Day button) to open the shop and serve customers.[/color]"

func _dots(gd: Dictionary) -> void:
	if ticket_dots.get_child_count() > 0 and not ticket_dots.get_child(0).is_queued_for_deletion(): return
	for i in gd.steps.size():
		var d := Panel.new()
		d.custom_minimum_size = Vector2(12, 12)
		d.add_theme_stylebox_override("panel", UI.box(Color("2E8A68") if gd.done[i] else Color(UI.PLUM, 0.22), 6, 0, 0, Vector4.ZERO))
		ticket_dots.add_child(d)

func _sync_orders() -> void:
	for c in orders_row.get_children(): c.queue_free()
	var a := game.shop.active_cust()
	for c in game.shop.customers:
		if c.state != "order" and c.state != "wait": continue
		if a and c == a: continue
		var b := Button.new()
		b.theme_type_variation = "Ghost"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 64)
		b.icon = Photo.recipe(c.order, 96) if c.state == "order" else Customer.wait_texture()
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 48)
		b.text = c.cname
		b.add_theme_font_size_override("font_size", 19)
		b.tooltip_text = ("%s ordered %s" % [c.cname, G.RECIPES[c.order].n]) if c.state == "order" else "%s is ready to order" % c.cname
		var cc: Customer = c
		b.pressed.connect(func(): Sfx.play("click"); game.customer_tap(cc))
		orders_row.add_child(b)
	_sync_top()

# ================================================================ toolbar
func _build_toolbar() -> void:
	toolbar = GridContainer.new()
	toolbar.columns = 2
	toolbar.add_theme_constant_override("h_separation", 8)
	toolbar.add_theme_constant_override("v_separation", 8)
	toolbar.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	toolbar.position = Vector2(26, -250)
	root.add_child(toolbar)
	var keys := ["cafe", "fridge"] + Game.ORDER
	for k in keys:
		var b := Button.new()
		b.theme_type_variation = "SkyBtn" if k == "fridge" else "Ghost"
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.custom_minimum_size = Vector2(96, 92)
		b.toggle_mode = false
		var v := UI.vbox(-2)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(v)
		var ic: Texture2D
		if k == "cafe": ic = UI.icon("house", 96)
		elif k == "fridge": ic = Photo.request("tool:fridge", func() -> Node3D: return Appl.fridge(), 128)
		else: ic = Photo.request("tool:" + k, _tool_builder(k), 128)
		var tr := UI.tex(ic, Vector2(56, 56))
		tr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(tr)
		var l := UI.label(Game.LABEL[k], 16, UI.PLUM, UI.font_xbold)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		var badge := Label.new()
		badge.add_theme_font_size_override("font_size", 16)
		badge.add_theme_color_override("font_color", Color.WHITE)
		badge.add_theme_font_override("font", UI.font_xbold)
		var bs := UI.box(UI.PLUM, 14, 0, 0, Vector4(8, 0, 8, 2))
		badge.add_theme_stylebox_override("normal", bs)
		badge.position = Vector2(66, -8)
		badge.visible = false
		b.add_child(badge)
		b.pressed.connect(func():
			Sfx.play("click")
			if k == "cafe": game.set_overview()
			elif k == "fridge": open_fridge()
			else: game.open_station(k))
		toolbar.add_child(b)
		tool_btns[k] = {"b": b, "badge": badge, "bs": bs, "cls": "", "pulse": 0.0}

func _tool_builder(k: String) -> Callable:
	return func() -> Node3D:
		var n: Node3D
		match k:
			"board": n = Appl.board()
			"bowl": n = Appl.bowl()
			"blender": n = Appl.blender()
			"mat": n = Appl.mat()
			"pot": n = Appl.pot()
			"pan": n = Appl.pan()
			"oven": n = Appl.oven()
			"micro": n = Appl.micro()
			"freezer": n = Appl.freezer()
			"plate": n = Appl.pass_plate()
			"bin": n = Appl.bin()
		return n

func station_changed() -> void:
	for k in tool_btns:
		var on: bool = (k == "cafe" and game.open_key == "") or k == game.open_key
		var b: Button = tool_btns[k].b
		b.theme_type_variation = "Button" if on else ("SkyBtn" if k == "fridge" else "Ghost")
	_cache.erase("hint")
	_cache.erase("btn")

func _sync_toolbar(dt: float) -> void:
	var nh := game.next_hint()
	for k in Game.ORDER:
		var st: Station = game.stations[k]
		var t: Dictionary = tool_btns[k]
		var cls := st.status()
		var n := st.items.size()
		var lab := "✓" if cls == "ready" else "!" if cls == "burning" else "●" if cls != "" else (str(n) if n else "")
		var badge: Label = t.badge
		if badge.text != lab:
			badge.text = lab
			badge.visible = lab != ""
		if t.cls != cls:
			t.cls = cls
			t.bs.bg_color = Color("FF9A3C") if cls == "cooking" else Color("2E8A68") if cls == "ready" else Color("E5484D") if cls == "burning" else UI.PLUM
		badge.modulate.a = (0.55 + 0.45 * sin(game.clock * (14.0 if cls == "burning" else 6.0))) if cls == "ready" or cls == "burning" else 1.0
		var b: Button = t.b
		var nx: bool = nh.get("tool", "") == k
		b.scale = Vector2.ONE * (1.0 + (0.05 * (0.5 + 0.5 * sin(game.clock * 5.0)) if nx else 0.0))
		b.pivot_offset = b.size * 0.5

# ================================================================ footer: hint, meter, buttons
func _build_footer() -> void:
	var hint_panel := PanelContainer.new()
	hint_panel.theme_type_variation = "Pill"
	hint_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint_panel.position = Vector2(236, -146)
	hint_panel.custom_minimum_size = Vector2(462, 124)
	hint_panel.size = Vector2(462, 124)
	hint_panel.add_theme_stylebox_override("panel", UI.box(Color(1, 0.99, 0.965, 0.95), 26, 3, 6, Vector4(20, 12, 20, 12)))
	root.add_child(hint_panel)
	var v := UI.vbox(8)
	hint_panel.add_child(v)
	hint_lbl = UI.rich("", 22)
	hint_lbl.custom_minimum_size = Vector2(420, 0)
	v.add_child(hint_lbl)
	meter = Control.new()
	meter.custom_minimum_size = Vector2(420, 16)
	v.add_child(meter)
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", UI.box(Color(UI.PLUM, 0.12), 9, 0, 0, Vector4.ZERO))
	meter.add_child(bg)
	meter_zone = Panel.new()
	meter_zone.add_theme_stylebox_override("panel", UI.box(Color(0.31, 0.75, 0.59, 0.5), 3, 0, 0, Vector4.ZERO))
	meter.add_child(meter_zone)
	meter_fill = Panel.new()
	meter_fill.add_theme_stylebox_override("panel", UI.box(UI.SAKURA, 9, 0, 0, Vector4.ZERO))
	meter.add_child(meter_fill)
	var btns := UI.hbox(12)
	btns.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btns.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	btns.position = Vector2(-30, -120)
	root.add_child(btns)
	back_btn = UI.button("Empty", "Ghost", func(): game.empty_station(), 26)
	back_btn.custom_minimum_size = Vector2(0, 76)
	btns.add_child(back_btn)
	go_btn = UI.button("Go", "", func():
		var st := game.current()
		if st:
			var b := st.btn()
			if b.size() and b.get("enabled", true): st.on_btn(), 30)
	go_btn.custom_minimum_size = Vector2(190, 84)
	btns.add_child(go_btn)
	next_chip = UI.button("Next ›", "Mint", func():
		var nh := game.next_hint()
		if nh.get("act", "") == "ticket": open_ticket(Save.pinned, game.shop.active_cust())
		elif nh.has("tool"): game.open_station(nh.tool), 24)
	next_chip.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	next_chip.position = Vector2(-100, -200)
	next_chip.visible = false
	root.add_child(next_chip)

func _sync_footer() -> void:
	var st := game.current()
	var h := ""
	if st == null:
		h = "Pick a station on the left, or click one in the café. Tap customers to take orders!"
		if game.shop.waiting().size(): h = "<b>%s</b> is waiting to order. Click them!" % game.shop.waiting()[0].cname
	else:
		h = st.hint()
	h = h.replace("<b>", "[b][color=#D9527E]").replace("</b>", "[/color][/b]").replace("<em>", "[b][color=#D9527E]").replace("</em>", "[/color][/b]")
	if _cache.get("hint", "") != h:
		_cache.hint = h
		hint_lbl.text = h
	var m: Dictionary = st.meter() if st else {}
	meter.visible = not m.is_empty()
	if m.size():
		var w := meter.size.x
		meter_fill.position = Vector2.ZERO
		meter_fill.size = Vector2(maxf(18.0, w * float(m.v)), meter.size.y)
		meter_zone.visible = m.has("zone")
		if m.has("zone"):
			var z: Vector2 = m.zone
			meter_zone.position = Vector2(w * z.x, 0)
			meter_zone.size = Vector2(w * (z.y - z.x), meter.size.y)
	var b: Dictionary = st.btn() if st else {}
	go_btn.visible = b.size() > 0
	if b.size():
		go_btn.text = b.label
		go_btn.disabled = not b.get("enabled", true)
		var rd: bool = b.get("ready", false)
		go_btn.modulate = Color(1, 1, 1) if not rd else Color(1, 1, 1).lerp(Color(1.15, 1.05, 1.1), 0.5 + 0.5 * sin(game.clock * 6.0))
		go_btn.scale = Vector2.ONE * (1.0 + (0.035 * (0.5 + 0.5 * sin(game.clock * 6.0)) if rd else 0.0))
		go_btn.pivot_offset = go_btn.size * 0.5
	back_btn.visible = st != null and st.items.size() > 0 and not st.busy() and st.key != "bin"
	var nh := game.next_hint()
	next_chip.visible = nh.size() > 0 and not modal_open()
	if nh.size():
		next_chip.text = nh.label + "  ›"
		next_chip.position.y = -222 + sin(game.clock * 3.5) * 5.0
		next_chip.position.x = 1080 - next_chip.size.x * 0.5

# ================================================================ counter shelf
func _build_counter() -> void:
	var shelf := PanelContainer.new()
	shelf.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	shelf.add_theme_stylebox_override("panel", UI.box(Color("FFF6EA"), 28, 3, 9, Vector4(14, 12, 14, 12)))
	shelf.position = Vector2(712, -146)
	shelf.custom_minimum_size = Vector2(736, 124)
	root.add_child(shelf)
	var h := UI.hbox(8)
	shelf.add_child(h)
	var tag := UI.label("COUNTER", 14, UI.PLUM, UI.font_xbold)
	var tagp := PanelContainer.new()
	tagp.add_theme_stylebox_override("panel", UI.box(Color("FFE3EC"), 10, 2, 2, Vector4(10, 2, 10, 2)))
	tagp.add_child(tag)
	root.add_child(tagp)
	tagp.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	tagp.position = Vector2(740, -164)
	for i in Game.COUNTER_CAP:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(80, 92)
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var empty := StyleBoxFlat.new()
		empty.bg_color = Color(1, 1, 1, 0.5)
		empty.set_corner_radius_all(46)
		empty.border_color = Color(UI.PLUM, 0.2)
		empty.set_border_width_all(2)
		slot.add_theme_stylebox_override("normal", empty)
		slot.add_theme_stylebox_override("hover", empty)
		slot.add_theme_stylebox_override("pressed", empty)
		slot.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var ic := UI.tex(null, Vector2(88, 88))
		ic.set_anchors_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = 2; ic.offset_top = 0; ic.offset_right = -2; ic.offset_bottom = -4
		slot.add_child(ic)
		var badge := UI.tex(UI.icon("star", 28), Vector2(28, 28))
		badge.position = Vector2(64, -6)
		badge.visible = false
		slot.add_child(badge)
		var idx := i
		slot.pressed.connect(func(): game.counter_tap(idx))
		slot.mouse_entered.connect(func(): _counter_hover(idx))
		h.add_child(slot)
		slots.append(slot)
		slot_icons.append(ic)
		slot_badges.append(badge)

func _counter_hover(i: int) -> void:
	if i < game.counter.size():
		var f: Dictionary = game.counter[i]
		var name: String = G.RECIPES[f.recipe].n if f.recipe >= 0 else G.invent_name([f])
		slots[i].tooltip_text = name + (" (burnt)" if f.q == "burnt" else " (perfect!)" if f.q == "perfect" else "")

func counter_changed() -> void:
	for i in Game.COUNTER_CAP:
		var ic: TextureRect = slot_icons[i]
		var badge: TextureRect = slot_badges[i]
		if i < game.counter.size():
			var f: Dictionary = game.counter[i]
			if not f.has("_fly") or f._fly <= game.clock:
				ic.texture = Photo.food(f, 160)
				ic.visible = true
			badge.visible = f.recipe >= 0 or f.q == "perfect"
			badge.texture = UI.icon("star", 28)
			var full := StyleBoxFlat.new()
			full.bg_color = Color("FFE3EE") if f.recipe >= 0 else Color("EEF0FB")
			full.set_corner_radius_all(46)
			full.border_color = Color("D9527E") if f.recipe >= 0 else Color(UI.PLUM, 0.4)
			full.set_border_width_all(3)
			for s in ["normal", "hover", "pressed"]: slots[i].add_theme_stylebox_override(s, full)
		else:
			ic.texture = null
			badge.visible = false
			var empty := StyleBoxFlat.new()
			empty.bg_color = Color(1, 1, 1, 0.5)
			empty.set_corner_radius_all(46)
			empty.border_color = Color(UI.PLUM, 0.2)
			empty.set_border_width_all(2)
			for s in ["normal", "hover", "pressed"]: slots[i].add_theme_stylebox_override(s, empty)

func slot_center(i: int) -> Vector2:
	var s: Control = slots[clampi(i, 0, slots.size() - 1)]
	return s.global_position + s.size * 0.5

## food icon flies from a 3D-projected point to its counter slot
func fly_to_counter(f: Dictionary, from: Vector2, idx: int) -> void:
	f["_fly"] = game.clock + 0.5
	slot_icons[idx].visible = false
	var t := UI.tex(Photo.food(f, 160), Vector2(110, 110))
	t.size = Vector2(110, 110)
	t.position = to_canvas(from) - t.size * 0.5
	fly_layer.add_child(t)
	var to := slot_center(idx) - Vector2(46, 46)
	var tw := t.create_tween()
	tw.tween_method(func(k: float):
		var e := 1.0 - pow(1.0 - k, 3.0)
		t.position = (to_canvas(from) - Vector2(55, 55)).lerp(to, e) - Vector2(0, sin(k * PI) * 120.0)
		t.scale = Vector2.ONE * lerpf(1.0, 0.84, e), 0.0, 1.0, 0.5)
	tw.tween_callback(func():
		t.queue_free()
		f.erase("_fly")
		Sfx.play("plunk", 0.6, 1.3)
		counter_changed())

func fly_from_slot(f: Dictionary, idx: int, to: Vector2) -> void:
	var t := UI.tex(Photo.food(f, 160), Vector2(92, 92))
	t.size = Vector2(92, 92)
	var from := slot_center(idx) - Vector2(46, 46)
	t.position = from
	fly_layer.add_child(t)
	var tw := t.create_tween()
	tw.tween_method(func(k: float):
		var e := 1.0 - pow(1.0 - k, 3.0)
		t.position = from.lerp(to_canvas(to) - Vector2(46, 46), e) - Vector2(0, sin(k * PI) * 90.0)
		t.modulate.a = 1.0 - maxf(0.0, k - 0.7) / 0.3, 0.0, 1.0, 0.32)
	tw.tween_callback(t.queue_free)

# ================================================================ toast & banner
func _build_toast() -> void:
	toast_box = PanelContainer.new()
	toast_box.theme_type_variation = "Dark"
	toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_box)
	toast_lbl = UI.label("", 24, UI.CREAM, UI.font_xbold)
	toast_box.add_child(toast_lbl)
	toast_box.modulate.a = 0.0

func toast(msg: String) -> void:
	toast_lbl.text = msg
	toast_box.reset_size()
	toast_t = 2.2

func show_banner(big: String, small: String) -> void:
	var v := UI.vbox(0)
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.title(big, 96)
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 22)
	l.add_theme_color_override("font_shadow_color", UI.SAKURA)
	l.add_theme_constant_override("shadow_offset_y", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var s := UI.label(small, 28, UI.SAKURA_D, UI.font_xbold)
	s.add_theme_color_override("font_outline_color", Color.WHITE)
	s.add_theme_constant_override("outline_size", 10)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	root.add_child(v)
	var ms := v.get_combined_minimum_size()
	v.position = Vector2((root.size.x - ms.x) * 0.5, root.size.y * 0.3)
	v.modulate.a = 0.0
	var tw := v.create_tween()
	tw.tween_property(v, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(v, "position:y", root.size.y * 0.27, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.4)
	tw.tween_property(v, "modulate:a", 0.0, 0.5)
	tw.tween_callback(v.queue_free)

# ================================================================ per-frame
func _process(dt: float) -> void:
	_sync_footer()
	_sync_toolbar(dt)
	_sync_ticket()
	if toast_t > 0.0:
		toast_t -= dt
		toast_box.modulate.a = clampf(toast_t * 4.0, 0.0, 1.0) if toast_t < 0.25 else minf(1.0, toast_box.modulate.a + dt * 8.0)
		toast_box.position = Vector2((root.size.x - toast_box.size.x) * 0.5, 104 + (1.0 - toast_box.modulate.a) * -8.0)
	else:
		toast_box.modulate.a = 0.0
	orders_row.position = Vector2(ticket_box.position.x + ticket_box.size.x + 14, ticket_box.position.y + 6)
	if game.shop.open and int(game.clock * 2.0) != _cache.get("dt", -1):
		_cache.dt = int(game.clock * 2.0)
		_sync_day()

# ================================================================ modal panels
func modal_open() -> bool:
	return not _modals.is_empty()

func _modal(panel: Control, dim := true, close_on_dim := true) -> Control:
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.23, 0.137, 0.25, 0.42 if dim else 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(bg)
	if close_on_dim:
		bg.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: close_modal(wrap))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(center)
	center.add_child(panel)
	root.add_child(wrap)
	_modals.append(wrap)
	UI.pop_in.call_deferred(panel)
	return wrap

func close_modal(w: Control) -> void:
	if w == null or not is_instance_valid(w): return
	_modals.erase(w)
	w.queue_free()
	Sfx.play("pop", 0.6, 0.8)

func close_top() -> void:
	if fridge and fridge.visible:
		close_fridge()
		return
	if _modals.size(): close_modal(_modals.back())

func close_all() -> void:
	for w in _modals.duplicate(): close_modal(w)

func _panel(title: String, sub := "", width := 900.0) -> Array:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(width, 0)
	var v := UI.vbox(14)
	p.add_child(v)
	var head := UI.hbox(12)
	v.add_child(head)
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tv)
	tv.add_child(UI.title(title, 38))
	if sub != "":
		var s := UI.label(sub, 20, UI.MUTED, UI.font_xbold)
		tv.add_child(s)
	var x := UI.button("✕", "Ghost", Callable(), 24)
	x.custom_minimum_size = Vector2(56, 56)
	head.add_child(x)
	return [p, v, x]

# ---------------------------------------------------------------- order ticket
func open_ticket(rid: int, cust: Customer) -> void:
	var r: Dictionary = G.RECIPES[rid]
	var have := game.on_hand()
	var missing: Array = r.need.filter(func(k): return not have.has(k))
	var buy_list: Array = missing if missing.size() else r.need
	var cost := 0
	for k in buy_list: cost += G.ING_COST.get(k, 0)
	var pr := _panel(r.n, ("%s's order · pays %s" % [cust.cname, G.yen(r.price * (2 if cust.kind == "critic" else 1))]) if cust else "Menu price %s · ingredients %s" % [G.yen(r.price), G.yen(r.cost)], 940)
	var v: VBoxContainer = pr[1]
	var top := UI.hbox(18)
	v.add_child(top)
	var thumb := PanelContainer.new()
	thumb.theme_type_variation = "Card"
	thumb.add_child(UI.tex(Photo.recipe(rid, 256), Vector2(200, 200)))
	top.add_child(thumb)
	var info := UI.vbox(10)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	info.add_child(UI.label(r.desc, 22, UI.MUTED, UI.font_body, true))
	var ings := HFlowContainer.new()
	ings.add_theme_constant_override("h_separation", 8)
	ings.add_theme_constant_override("v_separation", 8)
	for k in r.need:
		ings.add_child(ing_chip(k, have.has(k), G.yen(G.ING_COST.get(k, 0)) if not have.has(k) else "✓"))
	info.add_child(ings)
	if cust and cust.kind == "regular":
		var hearts := int(Save.friends.get(cust.cname, 0))
		info.add_child(UI.label("%s ♥ %d/10  ·  favourite: %s" % [cust.cname, hearts, cust.get_meta("fav", "")], 20, UI.SAKURA_D, UI.font_xbold))
	if cust and cust.kind == "critic":
		info.add_child(UI.label("Critic: pays double, wants it cooked perfectly!", 20, UI.SAKURA_D, UI.font_xbold))
	var row := UI.hbox(12)
	v.add_child(row)
	var mh := {}
	var buy := UI.button(("Buy all · " if missing.size() else "Buy another set · ") + G.yen(cost), "", func():
		close_modal(mh.w)
		game.buy_for(r, cust), 26)
	row.add_child(buy)
	row.add_child(UI.button("Full recipe", "Ghost", func():
		close_modal(mh.w)
		open_book(rid), 24))
	if missing.size() and missing.size() < r.need.size():
		v.add_child(UI.label("You already have %d of %d, so this buys just the %d missing." % [r.need.size() - missing.size(), r.need.size(), missing.size()], 19, UI.MUTED))
	v.add_child(UI.label("STEPS", 18, UI.MUTED, UI.font_xbold))
	var steps := UI.vbox(4)
	var i := 1
	for s in G.build_steps(r):
		var done := game.step_done(s)
		steps.add_child(UI.rich(("[color=#2E8A68][s]%d. %s[/s][/color]" if done else "%d. %s") % [i, s.text], 21))
		i += 1
	v.add_child(steps)
	mh.w = _modal(pr[0])
	(pr[2] as Button).pressed.connect(func(): close_modal(mh.w))
	Sfx.play("note")

func ing_chip(k: String, got := false, extra := "") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(Color("E6FFF4") if got else Color.WHITE, 22, 3, 3, Vector4(4, 2, 14, 2)))
	var h := UI.hbox(6)
	p.add_child(h)
	h.add_child(UI.tex(Photo.ingredient(k, 96), Vector2(40, 40)))
	h.add_child(UI.label(G.ING[k].n, 20, UI.PLUM, UI.font_xbold))
	if extra != "":
		h.add_child(UI.label(extra, 17, UI.OK if got else UI.MUTED, UI.font_xbold))
	return p

# ---------------------------------------------------------------- fridge (side drawer, doesn't pause)
func open_fridge() -> void:
	if fridge == null:
		fridge = PanelContainer.new()
		fridge.add_theme_stylebox_override("panel", UI.box(Color("E8F6FF"), 30, 4, 10, Vector4(22, 18, 22, 18)))
		fridge.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		fridge.offset_left = -560
		fridge.offset_right = -20
		fridge.offset_top = 96
		fridge.offset_bottom = -160
		root.add_child(fridge)
	for c in fridge.get_children(): c.queue_free()
	var v := UI.vbox(10)
	fridge.add_child(v)
	var head := UI.hbox(10)
	v.add_child(head)
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.title("Fridge", 36))
	var st := game.current()
	tv.add_child(UI.label("Tap to add to the %s" % Game.LABEL[st.key] if st and st.key != "bin" and st.accepts() else "Tap to put it on the counter", 19, UI.MUTED, UI.font_xbold))
	head.add_child(tv)
	head.add_child(UI.button("✕", "Ghost", func(): close_fridge(), 24))
	var cats := HFlowContainer.new()
	cats.add_theme_constant_override("h_separation", 6)
	cats.add_theme_constant_override("v_separation", 6)
	for c in G.CATS:
		var ck: String = c[0]
		cats.add_child(UI.chip(c[1], ck == _fridge_cat, func():
			_fridge_cat = ck
			Sfx.play("click")
			open_fridge()))
	v.add_child(cats)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	for k in G.ING_KEYS:
		if G.ING[k].cat != _fridge_cat: continue
		var b := Button.new()
		b.theme_type_variation = "Ghost"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(112, 132)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var bv := UI.vbox(-4)
		bv.set_anchors_preset(Control.PRESET_FULL_RECT)
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bv)
		var tr := UI.tex(Photo.ingredient(k, 160), Vector2(80, 80))
		tr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bv.add_child(tr)
		var l := UI.label(G.ING[k].n, 17, UI.PLUM, UI.font_xbold)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		bv.add_child(l)
		var pl := UI.label(G.yen(G.ING_COST.get(k, 0)), 15, UI.MUTED, UI.font_xbold)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(pl)
		var kk: String = k
		b.pressed.connect(func():
			game.add_ingredient(kk)
			var tw := b.create_tween()
			b.pivot_offset = b.size * 0.5
			tw.tween_property(b, "scale", Vector2.ONE * 0.92, 0.05)
			tw.tween_property(b, "scale", Vector2.ONE, 0.12))
		grid.add_child(b)
	if not fridge.visible or fridge.get_meta("fresh", true):
		fridge.set_meta("fresh", false)
		fridge.visible = true
		Sfx.play("clunk")
		fridge.modulate.a = 0.0
		fridge.create_tween().tween_property(fridge, "modulate:a", 1.0, 0.15)

func close_fridge() -> void:
	if fridge:
		fridge.visible = false
		fridge.set_meta("fresh", true)

# ---------------------------------------------------------------- recipe book
func open_book(rid := -1) -> void:
	_book = BookPanel.new()
	_book.hud = self
	var w := _modal(_book, true, false)
	_book.on_close = func(): close_modal(w)
	if rid >= 0: _book.show_detail(rid)
	Sfx.play("fwip")

# ---------------------------------------------------------------- result card
func show_result(res: Dictionary) -> void:
	var r = res.get("r", null)
	var q: String = res.get("q", "")
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(620, 0)
	var v := UI.vbox(8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	var jp := UI.label(("おいしい！" if res.stars == 3 else "もぐもぐ") if r else "ふしぎ？", 22, UI.SAKURA_D, UI.font_xbold)
	jp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(jp)
	var sp: Dictionary
	if r: sp = G.recipe_spec(r, res.foods)
	elif res.foods.size() == 1: sp = G.food_spec(res.foods[0])
	else: sp = G.generic_spec(G.comps_of(res.foods), game._hist_of(res.foods), {"q": q})
	var tt := Turntable.new()
	tt.custom_minimum_size = Vector2(560, 380)
	tt.spec = sp
	v.add_child(tt)
	var h := UI.title(("You made %s!" % r.n) if r else res.name, 38)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.custom_minimum_size.x = 560
	v.add_child(h)
	var st := UI.stars(res.stars, 48)
	st.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(st)
	if r and res.get("is_new", false):
		var nb := PanelContainer.new()
		nb.add_theme_stylebox_override("panel", UI.box(Color("FFC6D9"), 20, 3, 3, Vector4(16, 4, 16, 6)))
		nb.add_child(UI.label("New recipe stamped in your book!", 21, UI.PLUM, UI.font_xbold))
		nb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(nb)
	var note := "A little bit burnt!" if q == "burnt" else "A tiny bit undercooked." if q == "under" else "Cooked perfectly." if q == "perfect" else ""
	var parts: Array = [note]
	if not r: parts.append("Your very own invention.")
	if res.get("near") != null and res.near is Dictionary and res.near.size(): parts.append("So close to %s: try to %s." % [res.near.r.n, G.missing_text(res.near)])
	if r and res.get("extras", []).size(): parts.append("With a twist of %s." % G.list_names(res.extras))
	var body := UI.label(" ".join(parts.filter(func(x): return x != "")), 21, UI.MUTED, UI.font_xbold, true)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.custom_minimum_size.x = 560
	v.add_child(body)
	var paid := UI.label(("%s paid %s. Thank you!" % [res.cust, G.yen(res.paid)]) if res.has("paid") else ("Staff meal. On the menu for %s." % G.yen(r.price)) if r else "Staff meal: a one-of-a-kind dish.", 21, UI.PLUM, UI.font_xbold)
	paid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(paid)
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var mh := {}
	row.add_child(UI.button("Keep cooking", "", func(): close_modal(mh.w)))
	if r or (res.get("near") is Dictionary and res.near.size()):
		var rid: int = r.id if r else res.near.r.id
		row.add_child(UI.button("See recipe", "Ghost", func():
			close_modal(mh.w)
			open_book(rid)))
	mh.w = _modal(p)
	if r: Sfx.play("stamp" if res.get("is_new", false) else "chime")
	else: Sfx.play("yay")
	if r and res.get("is_new", false): game.burst(game.camera.global_position + game.camera.global_transform.basis.z * -1.2, [Color("FFD24A"), Color("FF7EA6")], 24, 1.5)

# ---------------------------------------------------------------- day summary
func show_summary(s: Dictionary, day: int) -> void:
	var pr := _panel("Day %d is done" % day, "おつかれさま！ Great work today", 640)
	var v: VBoxContainer = pr[1]
	var avg: float = float(s.get("stars", 0)) / maxf(1.0, s.get("served", 0))
	var stw := UI.stars(int(round(avg)) if s.get("served", 0) else 0, 52)
	stw.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(stw)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	var profit: int = s.get("sales", 0) + s.get("tips", 0) - s.get("spend", 0)
	for row in [["Customers served", str(s.get("served", 0))], ["Walked out", str(s.get("walked", 0))], ["Sales", G.yen(s.get("sales", 0))], ["Tips", G.yen(s.get("tips", 0))],
			["Ingredients bought", G.yen(-s.get("spend", 0))], ["New recipes", str(s.get("new_recipes", 0))], ["Profit", G.yen(profit)], ["In your purse", G.yen(Save.wallet)]]:
		var a := UI.label(row[0], 24, UI.SAKURA_D if row[0] == "Profit" else UI.PLUM, UI.font_xbold)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(a)
		var b := UI.label(row[1], 24, UI.SAKURA_D if row[0] == "Profit" else UI.PLUM, UI.font_xbold)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(b)
	var lp := Save.level_progress()
	v.add_child(UI.label("Café level %d · %d/%d stars to the next level" % [Save.level(), lp.x, lp.y], 21, UI.MUTED, UI.font_xbold))
	var mh := {}
	var row2 := UI.hbox(12)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_child(UI.button("Keep cooking", "", func(): close_modal(mh.w)))
	row2.add_child(UI.button("Decorate", "Mint", func():
		close_modal(mh.w)
		open_decor()))
	v.add_child(row2)
	mh.w = _modal(pr[0])
	(pr[2] as Button).pressed.connect(func(): close_modal(mh.w))
	Sfx.play("chime")

# ---------------------------------------------------------------- decorations shop
const DECOR := [
	["lucky_cat", "Lucky cat", 2500, 1, "Maneki-neko waves in good fortune: +5% tips."],
	["flowers", "Flower vase", 1800, 1, "Fresh flowers on the bar: customers arrive a little sooner."],
	["fairy_lights", "Fairy lights", 3200, 2, "Twinkly lights along the wall. So cosy."],
	["big_plant", "Big plant", 2800, 2, "A leafy friend for the corner."],
	["record_player", "Record player", 4500, 3, "Lo-fi on vinyl: customers wait 25% longer."],
	["poster", "Hill poster", 1500, 1, "A sunny painting for the wall."],
	["lanterns", "Paper lanterns", 3800, 4, "Glowing lanterns for festival nights."],
	["cat_bed", "Café cat", 6000, 5, "A sleepy orange cat moves in. Zzz…"],
]

func open_decor() -> void:
	var pr := _panel("Decorate", "Spend your earnings to make the café even cosier · Café level %d" % Save.level(), 980)
	var v: VBoxContainer = pr[1]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	v.add_child(grid)
	var mh := {}
	for d in DECOR:
		var key: String = d[0]
		var card := PanelContainer.new()
		card.theme_type_variation = "Card"
		card.custom_minimum_size = Vector2(450, 0)
		var h := UI.hbox(12)
		card.add_child(h)
		var iv := UI.vbox(2)
		iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(iv)
		iv.add_child(UI.label(d[1], 26, UI.PLUM, UI.font_display))
		iv.add_child(UI.label(d[4], 18, UI.MUTED, UI.font_xbold, true))
		var owned := Save.decor.has(key)
		var b: Button
		if owned:
			var on: bool = Save.decor_on.get(key, true)
			b = UI.button("Shown" if on else "Hidden", "Mint" if on else "Ghost", func():
				Save.decor_on[key] = not Save.decor_on.get(key, true)
				Save.save()
				game.apply_decor()
				close_modal(mh.w)
				open_decor(), 20)
		elif Save.level() < d[3]:
			b = UI.button("Lv %d" % d[3], "Ghost", Callable(), 20)
			b.disabled = true
		else:
			b = UI.button(G.yen(d[2]), "Gold", func():
				if Save.wallet < d[2]:
					toast("Not enough yen yet. Serve more customers!")
					Sfx.play("sad")
					return
				Save.wallet -= d[2]
				Save.decor[key] = true
				Save.decor_on[key] = true
				Save.save()
				game.apply_decor()
				Sfx.play("yay")
				toast("%s added to the café!" % d[1])
				close_modal(mh.w)
				game.set_overview(), 22)
		b.custom_minimum_size = Vector2(150, 60)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
		grid.add_child(card)
	mh.w = _modal(pr[0])
	(pr[2] as Button).pressed.connect(func(): close_modal(mh.w))

# ---------------------------------------------------------------- settings
func open_settings() -> void:
	var pr := _panel("Settings", "Sound mixer and options", 720)
	var v: VBoxContainer = pr[1]
	for s in [["master", "Master volume"], ["sfx", "Cooking sounds (ASMR)"], ["amb", "Rain ambience"], ["music", "Lo-fi music"]]:
		var key: String = s[0]
		var row := UI.hbox(16)
		var l := UI.label(s[1], 22, UI.PLUM, UI.font_xbold)
		l.custom_minimum_size.x = 300
		row.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.01
		sl.value = Save.settings.get(key, 0.8)
		sl.custom_minimum_size = Vector2(320, 34)
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.value_changed.connect(func(x):
			Save.settings[key] = x
			Sfx.apply_volumes()
			if key == "sfx": Sfx.play("pop", 1.0))
		sl.drag_ended.connect(func(_c): Save.save())
		row.add_child(sl)
		v.add_child(row)
	for s in [["rain", "Rain outside the window"], ["fullscreen", "Full screen"], ["shake", "Camera wobble"]]:
		var key: String = s[0]
		var cb := CheckButton.new()
		cb.text = s[1]
		cb.add_theme_font_override("font", UI.font_xbold)
		cb.add_theme_font_size_override("font_size", 22)
		cb.button_pressed = Save.settings.get(key, false)
		cb.focus_mode = Control.FOCUS_NONE
		cb.toggled.connect(func(on):
			Save.settings[key] = on
			Save.save()
			Sfx.play("click")
			if key == "rain":
				game.cafe.set_rain(on)
				Sfx.set_ambience(on)
			elif key == "fullscreen":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
		v.add_child(cb)
	var vrow := UI.hbox(12)
	var vlab := UI.label("Version %s" % Updater.current, 21, UI.MUTED, UI.font_xbold)
	vlab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vrow.add_child(vlab)
	if OS.has_feature("web"):
		if Updater.repo != "":
			vrow.add_child(UI.button("Get the Windows version", "Mint", func(): OS.shell_open(Updater.releases_page()), 20))
	elif Updater.repo != "":
		var cu := UI.button("Check for updates", "Mint", Callable(), 20)
		cu.pressed.connect(func():
			cu.text = "Checking…"
			Updater.check()
			await Updater.status_changed
			while Updater.state == "checking": await Updater.status_changed
			cu.text = {"available": "Update to v%s!" % Updater.latest, "uptodate": "You're up to date ♥", "offline": "Couldn't reach GitHub"}.get(Updater.state, "Check for updates")
			if Updater.state == "available":
				cu.pressed.connect(func(): Updater.update_now(), CONNECT_ONE_SHOT))
		vrow.add_child(cu)
	v.add_child(vrow)
	v.add_child(UI.label("Keys: Space = do the station's action · 1-8 = counter · F = fridge · B = book · ←/→ = stations · Esc = café view", 18, UI.MUTED, UI.font_xbold, true))
	var row2 := UI.hbox(12)
	v.add_child(row2)
	var mh := {}
	var reset := UI.button("Reset progress…", "Ghost", Callable(), 20)
	reset.pressed.connect(func():
		if reset.get_meta("armed", false):
			Save.reset()
			toast("Progress reset. A fresh start!")
			close_modal(mh.w)
		else:
			reset.set_meta("armed", true)
			reset.text = "Tap again to erase everything")
	row2.add_child(reset)
	if not OS.has_feature("web"):
		row2.add_child(UI.button("Quit game", "Ghost", func(): get_tree().quit(), 20))
	mh.w = _modal(pr[0])
	(pr[2] as Button).pressed.connect(func(): close_modal(mh.w))

# ---------------------------------------------------------------- title screen
var _title: Control
func show_title() -> void:
	_title = Control.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.23, 0.137, 0.25, 0.25)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.add_child(c)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(760, 0)
	c.add_child(p)
	var v := UI.vbox(12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	var jp := UI.label("いらっしゃいませ", 24, UI.SAKURA_D, UI.font_xbold)
	jp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(jp)
	var t := UI.title("Cosy Kitchen", 84)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_shadow_color", UI.SAKURA)
	t.add_theme_constant_override("shadow_offset_y", 6)
	t.add_theme_constant_override("shadow_offset_x", 0)
	v.add_child(t)
	for line in ["Grab anything from the fridge, then chop, stir, blend, roll, boil, fry, bake or freeze it. The kitchen works out what you made.",
			"Flip the sign to open your little café, take orders and get paid. Decorate with your earnings and make friends with the regulars.",
			"%d of %d recipes discovered. Best with headphones." % [Save.found_count(), G.RECIPES.size()]]:
		var l := UI.label(line, 22, UI.MUTED, UI.font_xbold, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size.x = 680
		v.add_child(l)
	var row := UI.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UI.button("Start cooking" if Save.served_total == 0 and Save.found_count() == 0 else "Continue · Day %d" % Save.day, "", func():
		hide_title()
		Sfx.play("chime")
		toast("Tap the Fridge to grab ingredients, or open the shop!"), 30))
	row.add_child(UI.button("Recipe book", "Ghost", func():
		hide_title()
		open_book(), 26))
	row.add_child(UI.button("Settings", "Ghost", func(): open_settings(), 26))
	root.add_child(_title)
	_modals.append(_title)
	UI.pop_in(p)

func hide_title() -> void:
	if _title and is_instance_valid(_title):
		_modals.erase(_title)
		var tw := _title.create_tween()
		tw.tween_property(_title, "modulate:a", 0.0, 0.3)
		tw.tween_callback(_title.queue_free)
	_title = null
