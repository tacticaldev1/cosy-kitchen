## Little jobs and festival games, each a short timed panel: the takoyaki stall, shelving books
## at Ren's, arranging bouquets at Hana's, and goldfish scooping. They pay wages (or prizes),
## take a slice of the day and some energy.
class_name Minigames
extends Node

var hud: Hud
var game: Game
var active := ""
var t_left := 0.0
var _w: Control
var _panel_v: VBoxContainer
var _timer_lbl: Label
var _score_lbl: Label
var _state := {}
var _on_done: Callable

func is_running() -> bool:
	return active != ""

func _open(title: String, sub: String, secs: float, width := 820.0) -> VBoxContainer:
	var pr := hud._panel(title, sub, width)
	var v: VBoxContainer = pr[1]
	var top := UI.hbox(16)
	_timer_lbl = UI.label("", 26, UI.SAKURA_D, UI.font_display)
	top.add_child(_timer_lbl)
	_score_lbl = UI.label("", 22, UI.PLUM, UI.font_xbold)
	_score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_score_lbl)
	v.add_child(top)
	_w = hud._modal(pr[0], true, false)
	(pr[2] as Button).pressed.connect(func(): _finish())
	t_left = secs
	_panel_v = v
	return v

func _process(dt: float) -> void:
	if active == "": return
	t_left -= dt
	if _timer_lbl: _timer_lbl.text = "⏱ %d" % maxi(0, ceili(t_left))
	match active:
		"takoyaki": _tako_tick(dt)
		"goldfish": _fish_tick(dt)
		"gems": _gems_tick(dt)
		"assembly": _asm_tick(dt)
		"nursery": _nursery_tick(dt)
	if t_left <= 0.0: _finish()

## Ends the game, pays out and passes time.
func _finish() -> void:
	if active == "": return
	var what := active
	active = ""
	var pay: int = _state.get("pay", 0)
	var minutes: float = _state.get("minutes", 60.0)
	hud.close_modal(_w)
	Save.wallet += pay
	game.life.skip_time(minutes)
	game.life.use_energy(_state.get("energy", 8.0))
	if _state.has("npc") and pay > 0: Save.add_hearts(_state.npc, 0.3)
	if what == "goldfish" and int(_state.get("caught", 0)) > 0: Save.furni_inv["goldfish"] = int(Save.furni_inv.get("goldfish", 0)) + 1
	Save.flags["job_" + what] = Save.day
	Save.save()
	Sfx.play("coin" if pay > 0 else "pop")
	var msg: String = _state.get("result", "")
	if msg == "": msg = "Shift over! You earned %s." % G.yen(pay) if pay > 0 else "That didn't go so well…"
	hud.say([["", msg]], _on_done)
	_on_done = Callable()

func _btn_style(b: Button, col: Color, radius := 18) -> void:
	for s in ["normal", "hover", "pressed", "disabled"]:
		var sb := UI.box(col if s != "hover" else col.lightened(0.08), radius, 3, 4, Vector4(4, 4, 4, 4))
		b.add_theme_stylebox_override(s, sb)

# ================================================================ takoyaki stall
func takoyaki(done := Callable()) -> void:
	_on_done = done
	active = "takoyaki"
	var v := _open("Takoyaki stall", "Click a hole to pour batter. Click again when it's golden to flip it into the box. Fill each customer's order!", 75.0)
	_state = {"pay": 0, "minutes": 120.0, "energy": 10.0, "holes": [], "tray": 0, "orders": [], "served": 0}
	var orders := UI.hbox(10)
	v.add_child(orders)
	_state.orders_box = orders
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	v.add_child(cc)
	for i in 12:
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 96)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 18)
		var hole := {"b": b, "t": -1.0}
		b.pressed.connect(func(): _tako_click(hole))
		grid.add_child(b)
		_state.holes.append(hole)
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var serve := UI.button("Serve the box", "", func(): _tako_serve(), 24)
	row.add_child(serve)
	v.add_child(row)
	for k in 3: _tako_new_order()
	_tako_tick(0.0)

func _tako_new_order() -> void:
	var names := ["Mina", "Taro", "Kiko", "Haru", "Emi", "Sota", "Rin", "Ken"]
	_state.orders.append({"name": names[randi() % names.size()], "n": [4, 6, 6, 8][randi() % 4]})
	_tako_orders_ui()

func _tako_orders_ui() -> void:
	var box: HBoxContainer = _state.orders_box
	for c in box.get_children(): c.queue_free()
	for i in _state.orders.size():
		var o: Dictionary = _state.orders[i]
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UI.box(Color("FFE3EC") if i == 0 else Color.WHITE, 16, 2, 2, Vector4(12, 6, 12, 6)))
		p.add_child(UI.label("%s wants %d" % [o.name, o.n], 19, UI.PLUM, UI.font_xbold))
		box.add_child(p)

func _tako_click(h: Dictionary) -> void:
	var t: float = h.t
	if t < 0.0:
		h.t = 0.0
		Sfx.play("plunk", 0.6)
	elif t < 3.5:
		Sfx.play("tick", 0.4)
	elif t <= 6.5:
		h.t = -1.0
		_state.tray += 1
		Sfx.play("pop", 0.8, 1.3)
	else:
		h.t = -1.0
		Sfx.play("sigh" if Sfx.has("sigh") else "pop", 0.4)
	_tako_tick(0.0)

func _tako_serve() -> void:
	if _state.orders.is_empty(): return
	var o: Dictionary = _state.orders[0]
	if _state.tray < o.n:
		hud.toast("You need %d in the box (you have %d)" % [o.n, _state.tray])
		return
	_state.tray -= o.n
	_state.pay += o.n * 120 + 100
	_state.served += 1
	_state.orders.pop_front()
	Sfx.play("coin")
	_tako_new_order()
	_tako_tick(0.0)

func _tako_tick(dt: float) -> void:
	for h in _state.holes:
		var b: Button = h.b
		if h.t >= 0.0: h.t += dt
		var t: float = h.t
		var col := Color("4A4458")
		var txt := ""
		if t >= 0.0 and t < 3.5:
			col = Color("FFF1C9").lerp(Color("F2C77A"), t / 3.5)
			txt = "…"
		elif t >= 3.5 and t <= 6.5:
			col = Color("E8A04A")
			txt = "FLIP!"
		elif t > 6.5:
			col = Color("4B2E2A")
			txt = "burnt"
		_btn_style(b, col, 48)
		b.text = txt
		b.add_theme_color_override("font_color", Color.WHITE if t > 6.5 or t < 0.0 else UI.PLUM)
	if _score_lbl: _score_lbl.text = "In the box: %d   ·   Served: %d   ·   Earned: %s" % [_state.tray, _state.served, G.yen(_state.pay)]

# ================================================================ shelving books at Ren's
func books(done := Callable()) -> void:
	_on_done = done
	active = "books"
	var v := _open("Shelving at Ren's Books", "Click the books in order, 1 to 8. Mistakes cost time!", 50.0)
	_state = {"pay": 0, "minutes": 90.0, "energy": 6.0, "next": 1, "rounds": 0, "npc": "ren"}
	var row := UI.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	_state.row = row
	_books_round()

func _books_round() -> void:
	var row: HBoxContainer = _state.row
	for c in row.get_children(): c.queue_free()
	_state.next = 1
	var nums := [1, 2, 3, 4, 5, 6, 7, 8]
	nums.shuffle()
	var cols := ["6A8AD8", "E8504A", "7FD3B8", "FFB86A", "C3A6FF", "FF9EBB", "8ED16B", "FFD24A"]
	for n in nums:
		var b := Button.new()
		b.custom_minimum_size = Vector2(70, 200 - (n % 3) * 18)
		b.size_flags_vertical = Control.SIZE_SHRINK_END
		b.focus_mode = Control.FOCUS_NONE
		b.text = str(n)
		b.add_theme_font_size_override("font_size", 28)
		_btn_style(b, Color(cols[n - 1]), 8)
		var nn: int = n
		b.pressed.connect(func():
			if nn == _state.next:
				_state.next += 1
				b.disabled = true
				b.modulate.a = 0.35
				Sfx.play("pop", 0.6, 0.8 + nn * 0.08)
				if _state.next > 8:
					_state.rounds += 1
					_state.pay += 350
					Sfx.play("chime")
					_books_round()
			else:
				t_left -= 3.0
				Sfx.play("tick", 0.6))
		row.add_child(b)
	_score_lbl.text = "Shelves done: %d   ·   Earned: %s" % [_state.rounds, G.yen(_state.pay)]

# ================================================================ bouquets at Hana's
const FLOWERS := [["Rose", "E8404A"], ["Tulip", "FF9EBB"], ["Sunflower", "FFD24A"], ["Daisy", "FFFFFF"], ["Lavender", "C3A6FF"]]

func bouquets(done := Callable()) -> void:
	_on_done = done
	active = "bouquets"
	var v := _open("Helping at Hana's Flowers", "Make each bouquet exactly as the customer asks, then wrap it.", 60.0)
	_state = {"pay": 0, "minutes": 90.0, "energy": 6.0, "made": 0, "pick": {}, "npc": "hana"}
	var req := UI.label("", 24, UI.PLUM, UI.font_display, true)
	v.add_child(req)
	_state.req_lbl = req
	var cur := UI.label("", 20, UI.MUTED, UI.font_xbold)
	v.add_child(cur)
	_state.cur_lbl = cur
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for f in FLOWERS:
		var fname: String = f[0]
		var b := UI.button(fname, "", func():
			_state.pick[fname] = int(_state.pick.get(fname, 0)) + 1
			Sfx.play("pop", 0.5, 1.2)
			_bq_ui(), 20)
		_btn_style(b, Color(f[1]), 20)
		b.custom_minimum_size = Vector2(130, 80)
		row.add_child(b)
	v.add_child(row)
	var row2 := UI.hbox(12)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_child(UI.button("Wrap it ♥", "", func(): _bq_submit(), 22))
	row2.add_child(UI.button("Start over", "Ghost", func():
		_state.pick = {}
		_bq_ui(), 20))
	v.add_child(row2)
	_bq_new()

func _bq_new() -> void:
	var want := {}
	for k in 3 + randi() % 2:
		var f: String = FLOWERS[randi() % FLOWERS.size()][0]
		want[f] = int(want.get(f, 0)) + 1
	_state.want = want
	_state.pick = {}
	_bq_ui()

func _bq_text(d: Dictionary) -> String:
	if d.is_empty(): return "nothing yet"
	return ", ".join(d.keys().map(func(k): return "%d %s" % [d[k], k.to_lower() + ("s" if d[k] > 1 else "")]))

func _bq_ui() -> void:
	_state.req_lbl.text = "Customer wants: " + _bq_text(_state.want)
	_state.cur_lbl.text = "Your bouquet: " + _bq_text(_state.pick)
	_score_lbl.text = "Bouquets: %d   ·   Earned: %s" % [_state.made, G.yen(_state.pay)]

func _bq_submit() -> void:
	if _same(_state.pick, _state.want):
		_state.made += 1
		_state.pay += 300
		Sfx.play("chime")
	else:
		t_left -= 4.0
		hud.toast("That's not what they asked for!")
		Sfx.play("tick")
		_state.pick = {}
		_bq_ui()
		return
	_bq_new()

func _same(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size(): return false
	for k in a:
		if int(b.get(k, -1)) != int(a[k]): return false
	return true

# ================================================================ goldfish scooping (festival)
func goldfish(done := Callable()) -> void:
	_on_done = done
	active = "goldfish"
	var v := _open("Goldfish scooping", "Click a fish to scoop it before your paper scoop tears (3 misses)!", 30.0, 760.0)
	_state = {"pay": 0, "minutes": 20.0, "energy": 2.0, "caught": 0, "misses": 0, "fish": []}
	var pool := Panel.new()
	pool.custom_minimum_size = Vector2(700, 380)
	pool.add_theme_stylebox_override("panel", UI.box(Color("9BD8F0"), 40, 4, 4, Vector4.ZERO))
	pool.clip_contents = true
	v.add_child(pool)
	_state.pool = pool
	for i in 7:
		var f := Button.new()
		f.focus_mode = Control.FOCUS_NONE
		f.custom_minimum_size = Vector2(60, 34)
		f.size = Vector2(60, 34)
		_btn_style(f, Color("FF7E3A") if i % 3 else Color("FFFFFF"), 17)
		f.position = Vector2(randf_range(20, 600), randf_range(20, 320))
		var fish := {"b": f, "v": Vector2(randf_range(-160, 160), randf_range(-120, 120))}
		f.pressed.connect(func(): _scoop(fish))
		pool.add_child(f)
		_state.fish.append(fish)
	_fish_ui()

func _scoop(fish: Dictionary) -> void:
	if randf() < 0.65:
		_state.caught += 1
		fish.b.queue_free()
		_state.fish.erase(fish)
		Sfx.play("pop", 0.8, 1.4)
		if _state.fish.is_empty(): t_left = 0.0
	else:
		_state.misses += 1
		Sfx.play("tick")
		if _state.misses >= 3:
			hud.toast("Your paper scoop tore!")
			t_left = 0.0
	_fish_ui()

func _fish_tick(dt: float) -> void:
	for f in _state.fish:
		var b: Button = f.b
		if not is_instance_valid(b): continue
		var p: Vector2 = b.position + f.v * dt
		if p.x < 0 or p.x > 640: f.v.x *= -1
		if p.y < 0 or p.y > 346: f.v.y *= -1
		b.position = p.clamp(Vector2(0, 0), Vector2(640, 346))
		if randf() < dt * 0.8: f.v = f.v.rotated(randf_range(-1.2, 1.2))

func _fish_ui() -> void:
	_score_lbl.text = "Caught: %d   ·   Scoop: %s" % [_state.caught, "▮".repeat(3 - _state.misses) + "▯".repeat(_state.misses)]
	if _state.caught > 0:
		_state.result = "You caught %d goldfish! One comes home with you in a little bowl (it's in your storage)." % _state.caught
	else:
		_state.result = "Not a single fish… the stall keeper gives you a sympathy candy."

# ================================================================ tailoring at Mimi's
const CLOTH := [["Pink", "FF9EBB"], ["Sky", "A9C8FF"], ["Lemon", "FFD24A"], ["Mint", "B7E3A0"], ["Lilac", "C3A6FF"]]
const TRIMS := ["Bow", "Flower", "Beret", "Glasses"]

func tailoring(done := Callable()) -> void:
	_on_done = done
	active = "tailoring"
	var v := _open("Sewing at Mimi's Boutique", "Pick the top, the bottoms and the accessory each customer asks for, then sew it!", 60.0, 900.0)
	_state = {"pay": 0, "minutes": 90.0, "energy": 6.0, "made": 0, "pick": {}}
	var req := UI.label("", 24, UI.PLUM, UI.font_display, true)
	v.add_child(req)
	_state.req_lbl = req
	for part in ["Top", "Bottoms"]:
		var row := UI.hbox(8)
		row.add_child(UI.label(part, 20, UI.PLUM, UI.font_xbold))
		for c in CLOTH:
			var cn: String = c[0]
			var pp: String = part
			var b := UI.button(cn, "", func():
				_state.pick[pp] = cn
				Sfx.play("pop", 0.5, 1.2)
				_tl_ui(), 18)
			_btn_style(b, Color(c[1]), 16)
			b.custom_minimum_size = Vector2(120, 56)
			row.add_child(b)
		v.add_child(row)
	var arow := UI.hbox(8)
	arow.add_child(UI.label("Accessory", 20, UI.PLUM, UI.font_xbold))
	for a in TRIMS:
		var an: String = a
		arow.add_child(UI.button(a, "Ghost", func():
			_state.pick["Accessory"] = an
			Sfx.play("pop", 0.5, 1.2)
			_tl_ui(), 18))
	v.add_child(arow)
	var cur := UI.label("", 19, UI.MUTED, UI.font_xbold)
	v.add_child(cur)
	_state.cur_lbl = cur
	v.add_child(UI.button("Sew it! ✂", "", func(): _tl_submit(), 24))
	_tl_new()

func _tl_new() -> void:
	_state.want = {"Top": CLOTH[randi() % CLOTH.size()][0], "Bottoms": CLOTH[randi() % CLOTH.size()][0], "Accessory": TRIMS[randi() % TRIMS.size()]}
	_state.pick = {}
	_tl_ui()

func _tl_ui() -> void:
	var w: Dictionary = _state.want
	_state.req_lbl.text = "Customer wants: a %s top, %s bottoms and a %s" % [w.Top.to_lower(), w.Bottoms.to_lower(), w.Accessory.to_lower()]
	_state.cur_lbl.text = "On your table: " + (", ".join(_state.pick.keys().map(func(k): return "%s: %s" % [k, _state.pick[k]])) if _state.pick.size() else "nothing yet")
	_score_lbl.text = "Outfits: %d   ·   Earned: %s" % [_state.made, G.yen(_state.pay)]

func _tl_submit() -> void:
	if _same(_state.pick, _state.want):
		_state.made += 1
		_state.pay += 340
		Sfx.play("chime")
		_tl_new()
	else:
		t_left -= 4.0
		hud.toast("Not quite what they asked for!")
		Sfx.play("tick")

# ================================================================ polishing gems at Kobayashi's
func gems(done := Callable()) -> void:
	_on_done = done
	active = "gems"
	var v := _open("Polishing at Kobayashi Jewels", "Click each gem while it sparkles to polish it. Don't touch the dull ones!", 40.0, 760.0)
	_state = {"pay": 0, "minutes": 75.0, "energy": 6.0, "polished": 0, "cells": [], "next": 0.6}
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	v.add_child(cc)
	var gcols := ["E8404A", "6A8AD8", "8ED16B", "FFD24A", "C3A6FF", "7FD3F8"]
	for i in 12:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(100, 90)
		b.add_theme_font_size_override("font_size", 18)
		var cell := {"b": b, "t": 0.0, "col": Color(gcols[i % gcols.size()])}
		b.pressed.connect(func(): _gem_click(cell))
		grid.add_child(b)
		_state.cells.append(cell)
	_gems_tick(0.0)

func _gem_click(cell: Dictionary) -> void:
	if float(cell.t) > 0.0:
		cell.t = 0.0
		_state.polished += 1
		_state.pay += 95
		Sfx.play("sparkle", 0.6)
	else:
		t_left -= 1.5
		Sfx.play("tick", 0.5)
	_gems_tick(0.0)

func _gems_tick(dt: float) -> void:
	_state.next -= dt
	if _state.next <= 0.0:
		_state.next = randf_range(0.45, 0.9)
		var c: Dictionary = _state.cells[randi() % _state.cells.size()]
		c.t = 1.15
	for c in _state.cells:
		if float(c.t) > 0.0: c.t = maxf(0.0, float(c.t) - dt)
		var on: bool = float(c.t) > 0.0
		_btn_style(c.b, (c.col as Color).lightened(0.25) if on else (c.col as Color).darkened(0.45).lerp(Color("8A8A98"), 0.5), 30)
		c.b.text = "✦ ✦" if on else ""
	if _score_lbl: _score_lbl.text = "Polished: %d   ·   Earned: %s" % [_state.polished, G.yen(_state.pay)]

# ================================================================ furniture assembly at the Home Store
const TOOLS := [["Hammer", "E8A04A"], ["Screwdriver", "6A8AD8"], ["Wrench", "8ED16B"], ["Glue", "FF9EBB"], ["Saw", "C3A6FF"]]

func assembly(done := Callable()) -> void:
	_on_done = done
	active = "assembly"
	var v := _open("Assembling at the Home Store", "Watch Mr. Tanaka's steps, then repeat them in the same order!", 70.0, 860.0)
	_state = {"pay": 0, "minutes": 90.0, "energy": 7.0, "built": 0, "seq": [], "input": [], "show": -1, "show_t": 0.0, "btns": [], "len": 3}
	var info := UI.label("", 22, UI.SAKURA_D, UI.font_xbold)
	v.add_child(info)
	_state.info = info
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in TOOLS.size():
		var b := UI.button(TOOLS[i][0], "", Callable(), 20)
		b.custom_minimum_size = Vector2(150, 110)
		_btn_style(b, Color(TOOLS[i][1]), 18)
		var ii: int = i
		b.pressed.connect(func(): _asm_press(ii))
		row.add_child(b)
		_state.btns.append(b)
	v.add_child(row)
	_asm_round()

func _asm_round() -> void:
	_state.seq = []
	for k in int(_state.len): _state.seq.append(randi() % TOOLS.size())
	_state.input = []
	_state.show = 0
	_state.show_t = 0.7
	_state.info.text = "Watch… (%d steps)" % int(_state.len)

func _asm_press(i: int) -> void:
	if int(_state.show) >= 0: return
	_state.input.append(i)
	Sfx.play("pop", 0.6, 0.8 + i * 0.1)
	var k: int = _state.input.size() - 1
	if _state.seq[k] != i:
		t_left -= 3.0
		hud.toast("Oops! That wobbles. Watch again.")
		_asm_round()
		return
	if _state.input.size() == _state.seq.size():
		_state.built += 1
		_state.pay += 280 + 60 * int(_state.len)
		_state.len = mini(int(_state.len) + 1, 8)
		Sfx.play("chime")
		_asm_round()
	_score_lbl.text = "Built: %d   ·   Earned: %s" % [_state.built, G.yen(_state.pay)]

func _asm_tick(dt: float) -> void:
	var idx := int(_state.show)
	for i in _state.btns.size():
		(_state.btns[i] as Button).modulate = Color(1, 1, 1, 1.0 if idx < 0 or (idx < _state.seq.size() and _state.seq[idx] == i and float(_state.show_t) > 0.25) else 0.45)
	if idx < 0: return
	_state.show_t -= dt
	if _state.show_t <= 0.0:
		_state.show += 1
		_state.show_t = 0.7
		if int(_state.show) >= _state.seq.size():
			_state.show = -1
			_state.info.text = "Your turn! Repeat the %d steps." % _state.seq.size()
		else:
			Sfx.play("tick", 0.6, 0.8 + _state.seq[int(_state.show)] * 0.1)

# ================================================================ the nursery at the clinic
func nursery(done := Callable()) -> void:
	_on_done = done
	active = "nursery"
	var v := _open("Helping in the clinic nursery", "Babies start crying: click them to rock them back to sleep before their cry meter fills!", 45.0, 820.0)
	_state = {"pay": 0, "minutes": 90.0, "energy": 7.0, "soothed": 0, "missed": 0, "babies": [], "next": 1.0, "npc": ""}
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	v.add_child(cc)
	for i in 6:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(170, 110)
		b.add_theme_font_size_override("font_size", 22)
		var baby := {"b": b, "cry": -1.0}
		b.pressed.connect(func(): _soothe(baby))
		grid.add_child(b)
		_state.babies.append(baby)
	_nursery_tick(0.0)

func _soothe(baby: Dictionary) -> void:
	if float(baby.cry) >= 0.0:
		baby.cry = -1.0
		_state.soothed += 1
		_state.pay += 110
		Sfx.play("note", 0.5, 1.3)
	_nursery_tick(0.0)

func _nursery_tick(dt: float) -> void:
	_state.next -= dt
	if _state.next <= 0.0:
		_state.next = randf_range(0.7, 1.6)
		var quiet: Array = _state.babies.filter(func(b): return float(b.cry) < 0.0)
		if quiet.size(): quiet[randi() % quiet.size()].cry = 0.0
	for b in _state.babies:
		if float(b.cry) >= 0.0:
			b.cry += dt
			if float(b.cry) > 4.0:
				b.cry = -1.0
				_state.missed += 1
				Sfx.play("tick", 0.4)
		var c: float = b.cry
		_btn_style(b.b, Color("FFE2D2") if c < 0.0 else Color("FFE2D2").lerp(Color("FF8A8A"), c / 4.0), 40)
		b.b.text = "z z z" if c < 0.0 else "WAAH! " + "▮".repeat(int(c) + 1)
	if _score_lbl: _score_lbl.text = "Soothed: %d   ·   Woke the ward: %d   ·   Earned: %s" % [_state.soothed, _state.missed, G.yen(_state.pay)]
