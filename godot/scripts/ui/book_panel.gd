## The recipe book: search, filter by type / tool / made-it, and a detail page with a
## spinning 3D dish, ingredients, auto-written steps and a "Cook this" button.
class_name BookPanel
extends PanelContainer

var hud: Hud
var on_close: Callable
var cat := "all"
var tools := {}
var stat := "all"
var query := ""
var _list: VBoxContainer
var _detail: VBoxContainer
var _grid: GridContainer
var _count: Label
var _search: LineEdit
var _cats: HFlowContainer
var _tools: HFlowContainer
var _stats: HFlowContainer

func _ready() -> void:
	custom_minimum_size = Vector2(1500, 900)
	var v := UI.vbox(10)
	add_child(v)
	var head := UI.hbox(12)
	v.add_child(head)
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.title("Recipe Book", 40))
	tv.add_child(UI.label("%d of %d discovered" % [Save.found_count(), G.RECIPES.size()], 20, UI.MUTED, UI.font_xbold))
	head.add_child(tv)
	head.add_child(UI.button("✕", "Ghost", func(): on_close.call(), 24))
	_list = UI.vbox(8)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_list)
	_detail = UI.vbox(10)
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.visible = false
	v.add_child(_detail)
	_search = LineEdit.new()
	_search.placeholder_text = "Search recipes or ingredients"
	_search.custom_minimum_size = Vector2(0, 52)
	_search.add_theme_font_size_override("font_size", 22)
	_search.text_changed.connect(func(t):
		query = t
		_render())
	_list.add_child(_search)
	var filters := UI.hbox(24)
	_list.add_child(filters)
	_cats = HFlowContainer.new()
	_cats.add_theme_constant_override("h_separation", 6)
	_cats.add_theme_constant_override("v_separation", 6)
	_cats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(_cats)
	_stats = HFlowContainer.new()
	_stats.add_theme_constant_override("h_separation", 6)
	filters.add_child(_stats)
	_tools = HFlowContainer.new()
	_tools.add_theme_constant_override("h_separation", 6)
	_tools.add_theme_constant_override("v_separation", 6)
	_list.add_child(_tools)
	_count = UI.label("", 18, UI.MUTED, UI.font_xbold)
	_list.add_child(_count)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list.add_child(sc)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(_grid)
	_filters()
	_render()

func _filters() -> void:
	for c in _cats.get_children(): c.queue_free()
	for c in _tools.get_children(): c.queue_free()
	for c in _stats.get_children(): c.queue_free()
	_cats.add_child(UI.chip("All", cat == "all", func(): cat = "all"; _refresh()))
	for c in G.RCATS:
		var k: String = c[0]
		_cats.add_child(UI.chip(c[1], cat == k, func(): cat = "all" if cat == k else k; _refresh()))
	for k in G.TOOL_NAMES:
		var kk: String = k
		_tools.add_child(UI.chip(G.TOOL_NAMES[k], tools.has(k), func():
			if tools.has(kk): tools.erase(kk)
			else: tools[kk] = true
			_refresh()))
	for s in [["all", "Every recipe"], ["found", "Made it"], ["new", "Not yet"]]:
		var k: String = s[0]
		_stats.add_child(UI.chip(s[1], stat == k, func(): stat = k; _refresh()))

func _refresh() -> void:
	Sfx.play("click")
	_filters()
	_render()

func _match(r: Dictionary) -> bool:
	if cat != "all" and r.cat != cat: return false
	for t in tools:
		if not (r.tools.has(t) or (t == "pot" and r.tools.has("micro"))): return false
	if stat != "all" and (stat == "found") != Save.is_found(r.id): return false
	for w in query.to_lower().split(" ", false):
		if not r.search.contains(w): return false
	return true

func _render() -> void:
	for c in _grid.get_children(): c.queue_free()
	var list: Array = G.RECIPES.filter(_match)
	_count.text = "Showing %d recipe%s" % [list.size(), "" if list.size() == 1 else "s"] if list.size() else "No recipes match. Try fewer filters or another word."
	for r in list:
		var b := Button.new()
		b.theme_type_variation = "Ghost"
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.custom_minimum_size = Vector2(278, 112)
		var h := UI.hbox(10)
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 8; h.offset_right = -8
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(h)
		var t := UI.tex(Photo.recipe(r.id, 192), Vector2(92, 92))
		if not Save.is_found(r.id): t.modulate = Color(0.75, 0.72, 0.8, 0.75)
		h.add_child(t)
		var iv := UI.vbox(0)
		iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		iv.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(iv)
		var n := UI.label(r.n, 19, UI.PLUM, UI.font_xbold, true)
		n.custom_minimum_size.x = 150
		iv.add_child(n)
		iv.add_child(UI.label(G.yen(r.price) + " · " + " ".join(r.tools.map(func(k): return G.TOOL_NAMES[k])), 14, UI.MUTED, UI.font_xbold, true))
		if Save.is_found(r.id):
			var stamp := PanelContainer.new()
			stamp.add_theme_stylebox_override("panel", UI.box(UI.SAKURA, 12, 2, 2, Vector4(8, 0, 8, 2)))
			stamp.add_child(UI.label("Made", 14, UI.PLUM, UI.font_xbold))
			stamp.position = Vector2(210, -10)
			b.add_child(stamp)
		var rid: int = r.id
		b.pressed.connect(func(): Sfx.play("pop"); show_detail(rid))
		_grid.add_child(b)

func show_detail(rid: int) -> void:
	var r: Dictionary = G.RECIPES[rid]
	_list.visible = false
	_detail.visible = true
	for c in _detail.get_children(): c.queue_free()
	var back := UI.chip("‹ All recipes", false, func():
		Sfx.play("click")
		_detail.visible = false
		_list.visible = true
		_render())
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_detail.add_child(back)
	var top := UI.hbox(26)
	_detail.add_child(top)
	var tt := Turntable.new()
	tt.custom_minimum_size = Vector2(440, 380)
	tt.spec = G.recipe_spec(r)
	top.add_child(tt)
	var info := UI.vbox(10)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	info.add_child(UI.title(r.n, 46))
	info.add_child(UI.label(r.desc, 24, UI.MUTED, UI.font_xbold, true))
	info.add_child(UI.label("Menu price %s · ingredients %s" % [G.yen(r.price), G.yen(r.cost)], 22, UI.SAKURA_D, UI.font_xbold))
	var tags := HFlowContainer.new()
	tags.add_theme_constant_override("h_separation", 6)
	var tag_list: Array = []
	for c in G.RCATS:
		if c[0] == r.cat: tag_list.append(c[1])
	for k in r.tools: tag_list.append(G.TOOL_NAMES[k])
	tag_list.append("Made it ×%d" % int(Save.found.get(str(rid), 0)) if Save.is_found(rid) else "Not made yet")
	for t in tag_list:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UI.box(UI.MINT, 14, 2, 2, Vector4(10, 2, 10, 3)))
		p.add_child(UI.label(t, 17, UI.PLUM, UI.font_xbold))
		tags.add_child(p)
	info.add_child(tags)
	info.add_child(UI.label("INGREDIENTS", 18, UI.MUTED, UI.font_xbold))
	var ings := HFlowContainer.new()
	ings.add_theme_constant_override("h_separation", 8)
	ings.add_theme_constant_override("v_separation", 8)
	for k in r.need: ings.add_child(hud.ing_chip(k))
	for k in r.opt:
		var c := hud.ing_chip(k, false, "optional")
		c.modulate.a = 0.75
		ings.add_child(c)
	info.add_child(ings)
	_detail.add_child(UI.label("HOW TO MAKE IT", 18, UI.MUTED, UI.font_xbold))
	var steps := G.build_steps(r)
	var pinned := Save.pinned == rid
	var i := 1
	for s in steps:
		var done := pinned and hud.game.step_done(s)
		_detail.add_child(UI.rich(("[color=#2E8A68][s]%d. %s[/s][/color]" if done else "%d. %s") % [i, s.text], 24))
		i += 1
	var opt := G.optional_text(r)
	if opt != "": _detail.add_child(UI.label(opt + " Faded ingredients are optional.", 19, UI.MUTED, UI.font_xbold))
	var row := UI.hbox(12)
	_detail.add_child(row)
	var have := hud.game.on_hand()
	var cost := 0
	for k in r.need:
		if not have.has(k): cost += G.ING_COST.get(k, 0)
	row.add_child(UI.button("Cook this · buy %s" % G.yen(cost if cost else r.cost), "", func():
		on_close.call()
		hud.game.buy_for(r, null)))
	if pinned:
		row.add_child(UI.button("Stop guide", "Ghost", func():
			Save.pinned = -1
			Save.save()
			show_detail(rid)))
