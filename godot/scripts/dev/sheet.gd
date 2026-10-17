extends Control
## Contact sheets for art review: `-- --sheet=ingredients|pieces|dishes [--page=0]`.

func _ready() -> void:
	var mode := Shot.arg("sheet", "ingredients")
	var page := int(Shot.arg("page", "0"))
	var bg := ColorRect.new()
	bg.color = Color("FFF4EC")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var grid := GridContainer.new()
	grid.columns = 10 if mode != "dishes" else 10
	grid.position = Vector2(20, 14)
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 2)
	add_child(grid)
	var items: Array = []
	var only := Shot.arg("only", "").split(",", false)
	if mode == "dishes":
		var src: Array = G.RECIPES.slice(page * 50, page * 50 + 50) if only.is_empty() else G.RECIPES.filter(func(r): return only.has(r.n))
		for r in src:
			items.append([r.n, Photo.recipe(r.id, 200)])
	elif mode == "pieces":
		for k in G.ING_KEYS:
			items.append([G.ING[k].n, Photo.request("piece:" + k, func() -> Node3D:
				var n := Node3D.new()
				for i in 3:
					var mi := FoodArt.mesh_node(FoodArt.piece_mesh(k))
					mi.position = Vector3((i - 1) * 0.03, 0, (i % 2) * 0.012)
					mi.rotation.y = i * 1.3
					n.add_child(mi)
				return n, 200)])
	else:
		for k in G.ING_KEYS:
			items.append([G.ING[k].n, Photo.ingredient(k, 200)])
	var font := load("res://assets/fonts/MPLUSRounded1c-Bold.ttf")
	var tile := 186 if mode != "dishes" else 186
	for it in items:
		var v := VBoxContainer.new()
		v.custom_minimum_size = Vector2(tile, 0)
		v.add_theme_constant_override("separation", -10)
		var tr := TextureRect.new()
		tr.texture = it[1]
		tr.custom_minimum_size = Vector2(tile, tile - 26 if mode == "dishes" else tile - 30)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(tr)
		var l := Label.new()
		l.text = it[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", font)
		l.add_theme_font_size_override("font_size", 16)
		l.add_theme_color_override("font_color", Color("3B2340"))
		v.add_child(l)
		grid.add_child(v)
	await Photo.flush()
	await get_tree().process_frame
	Shot.maybe_capture(get_tree(), 3)
