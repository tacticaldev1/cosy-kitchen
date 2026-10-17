## UI helpers: the pastel theme (chunky plum-outlined buttons like the web version),
## SVG icons and small builders used by the HUD and panels.
class_name UI
extends RefCounted

const PLUM := Color("3B2340")
const SAKURA := Color("FF7EA6")
const SAKURA_D := Color("D9527E")
const CREAM := Color("FFF8EE")
const PAPER := Color("FFFDF6")
const MUTED := Color("7D6283")
const MINT := Color("BDEBDD")
const OK := Color("2E8A68")

static var font_display: Font
static var font_body: Font
static var font_xbold: Font
static var _theme: Theme
static var _icons := {}

static func fonts() -> void:
	if font_display: return
	font_display = load("res://assets/fonts/MochiyPopOne-Regular.ttf")
	font_body = load("res://assets/fonts/MPLUSRounded1c-Bold.ttf")
	font_xbold = load("res://assets/fonts/MPLUSRounded1c-ExtraBold.ttf")

static func box(bg: Color, radius := 22, border := 3, bottom := 3, pad := Vector4(16, 10, 16, 10)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = PLUM
	s.set_border_width_all(border)
	s.border_width_bottom = bottom
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad.x
	s.content_margin_top = pad.y
	s.content_margin_right = pad.z
	s.content_margin_bottom = pad.w
	s.anti_aliasing = true
	s.corner_detail = 10
	return s

static func theme() -> Theme:
	if _theme: return _theme
	fonts()
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = 24
	# buttons
	for v in [["Button", Color("FF9EBB"), Color("FFB3CA")], ["Ghost", Color("FFF8EE"), Color("FFFFFF")], ["Mint", Color("BDEBDD"), Color("D6F5EA")], ["SkyBtn", Color("CFEFFF"), Color("E4F6FF")], ["Gold", Color("FFE27A"), Color("FFEC9E")]]:
		var tn: String = v[0]
		if tn != "Button":
			t.set_type_variation(tn, "Button")
		t.set_stylebox("normal", tn, box(v[1], 28, 3, 7, Vector4(22, 10, 22, 12)))
		t.set_stylebox("hover", tn, box(v[2], 28, 3, 7, Vector4(22, 10, 22, 12)))
		t.set_stylebox("pressed", tn, box(v[1].darkened(0.06), 28, 3, 3, Vector4(22, 14, 22, 8)))
		t.set_stylebox("disabled", tn, box(Color(v[1], 0.5), 28, 3, 7, Vector4(22, 10, 22, 12)))
		t.set_stylebox("focus", tn, StyleBoxEmpty.new())
		t.set_color("font_color", tn, PLUM)
		t.set_color("font_hover_color", tn, PLUM)
		t.set_color("font_pressed_color", tn, PLUM)
		t.set_color("font_focus_color", tn, PLUM)
		t.set_color("font_disabled_color", tn, Color(PLUM, 0.5))
		t.set_font("font", tn, font_xbold)
		t.set_font_size("font_size", tn, 26)
	# chips
	t.set_type_variation("Chip", "Button")
	t.set_stylebox("normal", "Chip", box(Color.WHITE, 20, 3, 3, Vector4(14, 4, 14, 6)))
	t.set_stylebox("hover", "Chip", box(Color("FFF2E8"), 20, 3, 3, Vector4(14, 4, 14, 6)))
	t.set_stylebox("pressed", "Chip", box(PLUM, 20, 3, 3, Vector4(14, 4, 14, 6)))
	t.set_stylebox("hover_pressed", "Chip", box(PLUM.lightened(0.15), 20, 3, 3, Vector4(14, 4, 14, 6)))
	t.set_stylebox("focus", "Chip", StyleBoxEmpty.new())
	t.set_color("font_color", "Chip", PLUM)
	t.set_color("font_pressed_color", "Chip", CREAM)
	t.set_color("font_hover_pressed_color", "Chip", CREAM)
	t.set_color("font_hover_color", "Chip", PLUM)
	t.set_font("font", "Chip", font_xbold)
	t.set_font_size("font_size", "Chip", 19)
	# panels
	t.set_stylebox("panel", "PanelContainer", box(PAPER, 30, 4, 10, Vector4(26, 22, 26, 24)))
	t.set_type_variation("Card", "PanelContainer")
	t.set_stylebox("panel", "Card", box(Color.WHITE, 20, 3, 5, Vector4(10, 10, 10, 10)))
	t.set_type_variation("Ticket", "PanelContainer")
	t.set_stylebox("panel", "Ticket", box(Color("FFFDF6"), 14, 3, 6, Vector4(16, 12, 16, 12)))
	t.set_type_variation("Pill", "PanelContainer")
	t.set_stylebox("panel", "Pill", box(Color("FFF8EE"), 30, 3, 6, Vector4(16, 6, 18, 8)))
	t.set_type_variation("Dark", "PanelContainer")
	var dk := box(Color(PLUM, 0.92), 30, 0, 0, Vector4(22, 10, 22, 12))
	t.set_stylebox("panel", "Dark", dk)
	# labels
	t.set_color("font_color", "Label", PLUM)
	t.set_type_variation("Title", "Label")
	t.set_font("font", "Title", font_display)
	t.set_font_size("font_size", "Title", 40)
	t.set_type_variation("Small", "Label")
	t.set_font_size("font_size", "Small", 19)
	t.set_color("font_color", "Small", MUTED)
	t.set_color("default_color", "RichTextLabel", PLUM)
	t.set_font("normal_font", "RichTextLabel", font_body)
	t.set_font("bold_font", "RichTextLabel", font_xbold)
	t.set_font_size("normal_font_size", "RichTextLabel", 24)
	t.set_font_size("bold_font_size", "RichTextLabel", 24)
	# line edit
	t.set_stylebox("normal", "LineEdit", box(Color.WHITE, 26, 3, 3, Vector4(18, 8, 18, 8)))
	t.set_stylebox("focus", "LineEdit", box(Color.WHITE, 26, 3, 3, Vector4(18, 8, 18, 8)))
	t.set_color("font_color", "LineEdit", PLUM)
	t.set_color("font_placeholder_color", "LineEdit", Color(PLUM, 0.45))
	t.set_color("caret_color", "LineEdit", SAKURA_D)
	# sliders
	var track := box(Color(PLUM, 0.15), 10, 0, 0, Vector4(0, 6, 0, 6))
	t.set_stylebox("slider", "HSlider", track)
	var fill := box(SAKURA, 10, 0, 0, Vector4(0, 6, 0, 6))
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", icon("knob", 34))
	t.set_icon("grabber_highlight", "HSlider", icon("knob", 34))
	# scrollbars: slim and soft
	var sb := box(Color(PLUM, 0.12), 8, 0, 0, Vector4(4, 4, 4, 4))
	var gr := box(Color(PLUM, 0.4), 8, 0, 0, Vector4(4, 4, 4, 4))
	t.set_stylebox("scroll", "VScrollBar", sb)
	t.set_stylebox("grabber", "VScrollBar", gr)
	t.set_stylebox("grabber_highlight", "VScrollBar", gr)
	t.set_stylebox("grabber_pressed", "VScrollBar", gr)
	# check button
	t.set_icon("checked", "CheckButton", icon("toggle_on", 64))
	t.set_icon("unchecked", "CheckButton", icon("toggle_off", 64))
	t.set_color("font_color", "CheckButton", PLUM)
	t.set_color("font_hover_color", "CheckButton", PLUM)
	t.set_color("font_pressed_color", "CheckButton", PLUM)
	t.set_color("font_hover_pressed_color", "CheckButton", PLUM)
	t.set_color("font_focus_color", "CheckButton", PLUM)
	t.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())
	_theme = t
	return t

# ---------------------------------------------------------------- icons (SVG)
const SVG := {
	"book": "<svg viewBox='0 0 32 32'><path d='M4 7c4-2 8-2 12 1 4-3 8-3 12-1v19c-4-2-8-2-12 1-4-3-8-3-12-1z' fill='#FF9EBB' stroke='#3B2340' stroke-width='2.6' stroke-linejoin='round'/><path d='M16 8v19' stroke='#3B2340' stroke-width='2.6'/></svg>",
	"coin": "<svg viewBox='0 0 32 32'><circle cx='16' cy='16' r='12' fill='#FFD24A' stroke='#3B2340' stroke-width='2.6'/><circle cx='16' cy='16' r='7.5' fill='none' stroke='#E8A800' stroke-width='2'/><path d='M12 11l4 5 4-5M16 16v6M13 18h6' fill='none' stroke='#B8800A' stroke-width='2.2' stroke-linecap='round'/></svg>",
	"star": "<svg viewBox='0 0 32 32'><path d='M16 3l3.9 8 8.8 1.2-6.4 6.1 1.6 8.7L16 22.8 8.1 27l1.6-8.7-6.4-6.1 8.8-1.2z' fill='#FFD24A' stroke='#3B2340' stroke-width='2.6' stroke-linejoin='round'/></svg>",
	"star_off": "<svg viewBox='0 0 32 32'><path d='M16 3l3.9 8 8.8 1.2-6.4 6.1 1.6 8.7L16 22.8 8.1 27l1.6-8.7-6.4-6.1 8.8-1.2z' fill='#EADBD0' stroke='#3B2340' stroke-opacity='0.4' stroke-width='2.6' stroke-linejoin='round'/></svg>",
	"gear": "<svg viewBox='0 0 32 32'><path d='M16 4l2.4 3.3 4-1 .9 4 3.8 1.6-1.6 3.8 1.6 3.8-3.8 1.6-.9 4-4-1L16 28l-2.4-3.3-4 1-.9-4-3.8-1.6 1.6-3.8-1.6-3.8 3.8-1.6.9-4 4 1z' fill='#C3A6FF' stroke='#3B2340' stroke-width='2.4' stroke-linejoin='round'/><circle cx='16' cy='16' r='4.5' fill='#FFF8EE' stroke='#3B2340' stroke-width='2.4'/></svg>",
	"plant": "<svg viewBox='0 0 32 32'><path d='M9 19h14l-2 9H11z' fill='#E8826A' stroke='#3B2340' stroke-width='2.4' stroke-linejoin='round'/><path d='M16 19c0-6-6-8-9-7 0 4 4 7 9 7zM16 19c0-7 5-10 9-9 0 5-4 9-9 9z' fill='#8ED16B' stroke='#3B2340' stroke-width='2.4' stroke-linejoin='round'/></svg>",
	"house": "<svg viewBox='0 0 32 32'><path d='M5 15L16 5l11 10v12H5z' fill='#FFE3EC' stroke='#3B2340' stroke-width='2.6' stroke-linejoin='round'/><path d='M13 27v-7h6v7' fill='#FF9EBB' stroke='#3B2340' stroke-width='2.4' stroke-linejoin='round'/></svg>",
	"fridge": "<svg viewBox='0 0 32 32'><rect x='8' y='3' width='16' height='26' rx='4' fill='#BFE6FF' stroke='#3B2340' stroke-width='2.6'/><path d='M8 13h16M11 7v3M11 16v5' stroke='#3B2340' stroke-width='2.6' stroke-linecap='round'/></svg>",
	"clock": "<svg viewBox='0 0 32 32'><circle cx='16' cy='16' r='12' fill='#FFF8EE' stroke='#3B2340' stroke-width='2.6'/><path d='M16 9v7l5 3' stroke='#FF7EA6' stroke-width='3' stroke-linecap='round' fill='none'/></svg>",
	"music": "<svg viewBox='0 0 32 32'><path d='M12 23V8l13-3v15' fill='none' stroke='#3B2340' stroke-width='2.6' stroke-linejoin='round'/><circle cx='9' cy='23' r='4' fill='#FF9EBB' stroke='#3B2340' stroke-width='2.4'/><circle cx='22' cy='20' r='4' fill='#FF9EBB' stroke='#3B2340' stroke-width='2.4'/></svg>",
	"heart": "<svg viewBox='0 0 32 32'><path d='M16 27C6 20 3 15 3 10.5 3 6.6 6 4 9.5 4c2.9 0 5 1.8 6.5 4.2C17.5 5.8 19.6 4 22.5 4 26 4 29 6.6 29 10.5 29 15 26 20 16 27z' fill='#FF7EA6' stroke='#3B2340' stroke-width='2.4' stroke-linejoin='round'/></svg>",
	"knob": "<svg viewBox='0 0 34 34'><circle cx='17' cy='17' r='13' fill='#FFF8EE' stroke='#3B2340' stroke-width='3.5'/><circle cx='17' cy='17' r='5' fill='#FF7EA6'/></svg>",
	"toggle_on": "<svg viewBox='0 0 64 36'><rect x='2' y='4' width='60' height='28' rx='14' fill='#FF9EBB' stroke='#3B2340' stroke-width='3'/><circle cx='45' cy='18' r='10' fill='#FFF8EE' stroke='#3B2340' stroke-width='3'/></svg>",
	"toggle_off": "<svg viewBox='0 0 64 36'><rect x='2' y='4' width='60' height='28' rx='14' fill='#E8DDE6' stroke='#3B2340' stroke-width='3'/><circle cx='19' cy='18' r='10' fill='#FFF8EE' stroke='#3B2340' stroke-width='3'/></svg>",
	"check": "<svg viewBox='0 0 32 32'><circle cx='16' cy='16' r='12' fill='#9FE6C6' stroke='#3B2340' stroke-width='2.6'/><path d='M10 16l4 4 8-9' fill='none' stroke='#3B2340' stroke-width='3' stroke-linecap='round' stroke-linejoin='round'/></svg>",
	"rain": "<svg viewBox='0 0 32 32'><path d='M8 18a6 6 0 0 1 2-11.5A8 8 0 0 1 25 9a5 5 0 0 1-1 9.5z' fill='#CFEFFF' stroke='#3B2340' stroke-width='2.4' stroke-linejoin='round'/><path d='M11 22l-2 4M17 22l-2 4M23 22l-2 4' stroke='#7FA8E0' stroke-width='2.6' stroke-linecap='round'/></svg>",
	"sign": "<svg viewBox='0 0 32 32'><path d='M10 4l6 5 6-5' fill='none' stroke='#6A3E20' stroke-width='2.2'/><rect x='4' y='9' width='24' height='18' rx='4' fill='#FFE3EC' stroke='#3B2340' stroke-width='2.6'/></svg>",
}

static func icon(name: String, size := 48) -> Texture2D:
	var key := "%s@%d" % [name, size]
	if _icons.has(key): return _icons[key]
	var src: String = SVG.get(name, SVG.star)
	var vb := Vector2(32, 32)
	var m := RegEx.create_from_string("viewBox='0 0 (\\d+) (\\d+)'").search(src)
	if m: vb = Vector2(float(m.get_string(1)), float(m.get_string(2)))
	src = src.replace("<svg ", "<svg width='%d' height='%d' xmlns='http://www.w3.org/2000/svg' " % [vb.x, vb.y])
	var img := Image.new()
	img.load_svg_from_string(src, float(size) / vb.y)
	var tex := ImageTexture.create_from_image(img)
	_icons[key] = tex
	return tex

# ---------------------------------------------------------------- builders
static func label(text: String, size := 24, col := PLUM, font: Font = null, wrap := false) -> Label:
	fonts()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if font: l.add_theme_font_override("font", font)
	if wrap: l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func title(text: String, size := 40) -> Label:
	fonts()
	return label(text, size, PLUM, font_display)

static func button(text: String, variant := "", cb: Callable = Callable(), size := 26) -> Button:
	var b := Button.new()
	b.text = text
	if variant != "": b.theme_type_variation = variant
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if cb.is_valid(): b.pressed.connect(cb)
	b.pressed.connect(func(): Sfx.play("click"))
	return b

static func chip(text: String, pressed: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = "Chip"
	b.toggle_mode = true
	b.button_pressed = pressed
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(cb)
	return b

static func tex(t: Texture2D, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = t
	r.custom_minimum_size = size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func hbox(sep := 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func vbox(sep := 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func rich(text: String, size := 24) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = text
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func stars(n: int, size := 40) -> HBoxContainer:
	var h := hbox(2)
	for i in 3:
		h.add_child(tex(icon("star" if i < n else "star_off", size), Vector2(size, size)))
	return h

static func pop_in(c: Control, from := 0.85) -> void:
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2.ONE * from
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, 0.18)
