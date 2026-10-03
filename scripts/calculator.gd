extends Control

@onready var display: PanelContainer = $Center/Body/Margin/VBox/Display
@onready var display_expr: TextureRect = $Center/Body/Margin/VBox/Display/DisplayVBox/DisplayExpr
@onready var display_main: TextureRect = $Center/Body/Margin/VBox/Display/DisplayVBox/DisplayMain
@onready var grid: GridContainer = $Center/Body/Margin/VBox/Grid
@onready var body: PanelContainer = $Center/Body
@onready var margin: MarginContainer = $Center/Body/Margin
@onready var vbox: VBoxContainer = $Center/Body/Margin/VBox
@onready var bg: ColorRect = $Background
@onready var popup: Label = $Popup

var _entry: String = "0"
var _accum: float = 0.0
var _pending_op: String = ""
var _fresh_entry: bool = true
var _last_meme_key: String = ""
var _show_a := ""
var _show_op := ""
var _show_b := ""
var _show_valid := false

var fx: MemeEffects
var raid: SixSevenRaid
var printer: PrinterShow
var dfont: DoodleFont
var _disp_token := 0

const BTN_ORDER := ["C", "⌫", "%", "÷", "7", "8", "9", "×", "4", "5", "6", "-", "1", "2", "3", "+", "±", "0", ".", "="]

const EASTER_EGGS := {
	"21": "9 + 10 = 21?",
	"67": "SIX SEVEN!",
}


func _ready() -> void:
	_apply_25d_styles()
	get_tree().root.size_changed.connect(_on_window_size_changed)
	_fit_layout()
	call_deferred("_fit_layout")
	fx = MemeEffects.new()
	add_child(fx)
	fx.setup(self, body, display, bg, popup)
	raid = SixSevenRaid.new()
	add_child(raid)
	raid.setup(self, bg)
	printer = PrinterShow.new()
	add_child(printer)
	printer.setup(self, body, bg, fx)
	dfont = DoodleFont.new()
	add_child(dfont)
	dfont.setup(self)
	dfont.setup_display(self)
	for btn in grid.get_children():
		if btn is Button:
			(btn as Button).pressed.connect(_on_button.bind((btn as Button).text))
	_update_display()
	await _apply_doodle_text()
	if "--demo21" in OS.get_cmdline_user_args():
		_demo_21()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_fit_layout")


func _on_window_size_changed() -> void:
	call_deferred("_fit_layout")


func _fit_layout() -> void:
	if not is_instance_valid(body) or not is_instance_valid(grid):
		return
	if not is_inside_tree():
		return
	var vp: Vector2 = size
	if vp.x < 10.0 or vp.y < 10.0:
		vp = get_viewport().get_visible_rect().size
	if vp.x < 10.0 or vp.y < 10.0:
		return
	var narrow: bool = vp.x < 600.0
	var short: bool = vp.y < 500.0
	var tiny_h: bool = vp.y < 320.0
	const CARD_ASPECT := 0.62
	var max_w: float = vp.x * 0.92
	var max_h: float = vp.y * 0.90
	var target_w: float
	var target_h: float
	if max_w / maxf(max_h, 1.0) > CARD_ASPECT:
		target_h = max_h
		target_w = target_h * CARD_ASPECT
	else:
		target_w = max_w
		target_h = target_w / CARD_ASPECT
		if target_h > max_h:
			target_h = max_h
			target_w = target_h * CARD_ASPECT
	target_w = maxf(target_w, 240.0)
	target_h = maxf(target_h, 320.0)
	body.custom_minimum_size = Vector2(target_w, target_h)
	var m: int = 8 if tiny_h else (12 if (narrow or short) else 20)
	margin.add_theme_constant_override("margin_left", m)
	margin.add_theme_constant_override("margin_right", m)
	margin.add_theme_constant_override("margin_top", m)
	margin.add_theme_constant_override("margin_bottom", m)
	vbox.add_theme_constant_override("separation", 8 if tiny_h else (10 if (narrow or short) else 14))
	var gsep: int = 6 if tiny_h else (8 if (narrow or short) else 12)
	grid.add_theme_constant_override("h_separation", gsep)
	grid.add_theme_constant_override("v_separation", gsep)
	var disp_h: float = clampf(target_h * 0.20, 64.0, 320.0)
	display.custom_minimum_size = Vector2(0, disp_h)
	var btn_min: float = 26.0 if tiny_h else (32.0 if short else 44.0)
	for btn in grid.get_children():
		if btn is Button:
			(btn as Button).custom_minimum_size = Vector2(40.0, btn_min)
	var ps: int = int(clampf(target_w * 0.16, 28.0, 160.0))
	popup.add_theme_font_size_override("font_size", ps)


func _demo_21() -> void:
	await get_tree().create_timer(1.0).timeout
	for k in ["9", "+", "1", "0", "="]:
		_on_button(k)
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(6.5).timeout
	var img1 := get_viewport().get_texture().get_image()
	img1.save_png("user://demo_wait.png")
	printer.reveal()
	await get_tree().create_timer(2.0).timeout
	var img2 := get_viewport().get_texture().get_image()
	img2.save_png("user://demo_after.png")
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		var k: InputEventKey = event
		match k.keycode:
			KEY_0, KEY_KP_0: _on_button("0")
			KEY_1, KEY_KP_1: _on_button("1")
			KEY_2, KEY_KP_2: _on_button("2")
			KEY_3, KEY_KP_3: _on_button("3")
			KEY_4, KEY_KP_4: _on_button("4")
			KEY_5, KEY_KP_5: _on_button("5")
			KEY_6, KEY_KP_6: _on_button("6")
			KEY_7, KEY_KP_7: _on_button("7")
			KEY_8, KEY_KP_8: _on_button("8")
			KEY_9, KEY_KP_9: _on_button("9")
			KEY_PERIOD, KEY_KP_PERIOD, KEY_COMMA: _on_button(".")
			KEY_PLUS, KEY_KP_ADD: _on_button("+")
			KEY_MINUS, KEY_KP_SUBTRACT: _on_button("-")
			KEY_ASTERISK, KEY_KP_MULTIPLY: _on_button("×")
			KEY_SLASH, KEY_KP_DIVIDE: _on_button("÷")
			KEY_ENTER, KEY_KP_ENTER, KEY_EQUAL: _on_button("=")
			KEY_BACKSPACE: _on_button("⌫")
			KEY_DELETE: _on_button("C")
			KEY_ESCAPE: _on_button("C")
			KEY_C: _on_button("C")
			KEY_P: _on_button("±")
			KEY_R: _on_button("%")
		get_viewport().set_input_as_handled()



func _on_button(label: String) -> void:
	if printer and printer.is_busy():
		return
	match label:
		"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
			_input_digit(label)
		".":
			_input_dot()
		"+", "-", "×", "÷":
			_set_operator(label)
		"=":
			_equals()
		"C":
			_clear_all()
		"⌫":
			_backspace()
		"±":
			_toggle_sign()
		"%":
			_percent()
	_update_display()


func _input_digit(d: String) -> void:
	_show_valid = false
	if _fresh_entry or _entry == "0" or _entry == "Error":
		_entry = d
		_fresh_entry = false
	elif _entry.replace("-", "").replace(".", "").length() < 12:
		_entry += d


func _input_dot() -> void:
	_show_valid = false
	if _fresh_entry or _entry == "Error":
		_entry = "0."
		_fresh_entry = false
	elif "." not in _entry:
		_entry += "."


func _set_operator(op: String) -> void:
	if _entry == "Error":
		return
	_show_valid = false
	if not _fresh_entry and _pending_op != "":
		_accum = _calc(_accum, _pending_op, float(_entry))
		_entry = _format(_accum)
	_pending_op = op
	_accum = float(_entry)
	_fresh_entry = true


func _equals() -> void:
	if _pending_op == "" or _fresh_entry or _entry == "Error":
		return
	if _pending_op == "+" and _format(_accum) == "9" and _format(float(_entry)) == "10":
		_show_a = "9"
		_show_op = "+"
		_show_b = "10"
		_show_valid = true
		_entry = "21"
		_pending_op = ""
		_fresh_entry = true
		return
	_show_a = _format(_accum)
	_show_op = _pending_op
	_show_b = _format(float(_entry))
	_show_valid = true
	var result: float = _calc(_accum, _pending_op, float(_entry))
	_entry = _format(result)
	_pending_op = ""
	_fresh_entry = true


func _clear_all() -> void:
	_entry = "0"
	_accum = 0.0
	_pending_op = ""
	_fresh_entry = true
	_last_meme_key = ""
	_show_valid = false


func _backspace() -> void:
	if _fresh_entry or _entry == "Error":
		return
	_entry = _entry.substr(0, _entry.length() - 1)
	if _entry == "" or _entry == "-":
		_entry = "0"
		_fresh_entry = true


func _toggle_sign() -> void:
	if _entry == "0" or _entry == "Error":
		return
	if _entry.begins_with("-"):
		_entry = _entry.substr(1)
	else:
		_entry = "-" + _entry


func _percent() -> void:
	if _entry == "Error":
		return
	_entry = _format(float(_entry) / 100.0)


func _calc(a: float, op: String, b: float) -> float:
	match op:
		"+": return a + b
		"-": return a - b
		"×": return a * b
		"÷": return a / b if b != 0.0 else INF
	return b


func _format(v: float) -> String:
	if is_inf(v) or is_nan(v):
		return "Error"
	if absf(v) < 0.000000001:
		return "0"
	var s: String = "%.8f" % v
	while s.contains(".") and (s.ends_with("0")):
		s = s.substr(0, s.length() - 1)
	if s.ends_with("."):
		s = s.substr(0, s.length() - 1)
	return s


func _update_display() -> void:
	_disp_token += 1
	var t := _disp_token
	_render_expr_text(t, _typing_text())
	_render_main(t, _result_text())
	if _pending_op != "" and _fresh_entry:
		return
	_check_meme(t)


func _typing_text() -> String:
	if _show_valid:
		return "%s%s%s" % [_show_a, _show_op, _show_b]
	if _pending_op == "":
		return _entry
	if _fresh_entry:
		return "%s%s" % [_format(_accum), _pending_op]
	return "%s%s%s" % [_format(_accum), _pending_op, _entry]


func _result_text() -> String:
	return _entry if _show_valid else ""


func _render_main(t: int, text: String) -> void:
	var col := Color("#e8ecf2") if _entry != "Error" else Color("#ff6b6b")
	var tex: ImageTexture = await dfont.render_display(text, col)
	if t != _disp_token or tex == null:
		return
	display_main.texture = tex


func _render_expr_text(t: int, text: String) -> void:
	var tex: ImageTexture = await dfont.render_expr(text, Color("#9aa5b8"))
	if t != _disp_token or tex == null:
		return
	display_expr.texture = tex


func _apply_doodle_text() -> void:
	var groups := {
		"digit": ["7", "8", "9", "4", "5", "6", "1", "2", "3", "0", "."],
		"util": ["C", "⌫", "%", "±"],
		"op": ["÷", "×", "-", "+"],
		"equal": ["="],
	}
	var kids := grid.get_children()
	for kind in groups:
		var fs: int = DoodleFont.BTN_FONT_OP if (kind == "op" or kind == "equal") else DoodleFont.BTN_FONT
		var icons: Dictionary = await dfont.prerender(groups[kind], DoodleStyle.font_col(kind), fs, self)
		for i in BTN_ORDER.size():
			if icons.has(BTN_ORDER[i]) and i < kids.size() and kids[i] is Button:
				var b := kids[i] as Button
				b.expand_icon = true
				b.icon = icons[BTN_ORDER[i]]
				b.text = ""
	_update_display()


func _check_meme(_t: int) -> void:
	var meme: String = ""
	var key: String = ""
	if EASTER_EGGS.has(_entry):
		meme = EASTER_EGGS[_entry]
		key = _entry
	if meme == "":
		_last_meme_key = ""
		return
	var expr_text := _typing_text()
	if expr_text != "" and meme not in expr_text:
		expr_text += "  " + meme
	if key != _last_meme_key:
		_last_meme_key = key
		_epic_meme(key, meme)


func _epic_meme(key: String, text: String) -> void:
	if key == "21":
		if _show_valid and _show_a == "9" and _show_op == "+" and _show_b == "10":
			printer.play()
			return
		fx.punch_body()
		fx.flash_bg(key)
		fx.show_popup(text, key)
		fx.spawn_confetti()
		return
	if key != "67":
		return
	fx.punch_body()
	fx.flash_bg(key)
	fx.show_popup(text, key, SixSevenRaid.RAID_SECS - 1.2)
	raid.play()



func _apply_25d_styles() -> void:
	body.add_theme_stylebox_override("panel", DoodleStyle.body_style())
	var disp := DoodleStyle.display_style()
	display.add_theme_stylebox_override("panel", disp)

	for btn in grid.get_children():
		if btn is Button:
			_style_button(btn as Button)


func _style_button(b: Button) -> void:
	var t: String = b.text
	var kind: String = "digit"
	if t in ["C", "⌫", "%", "±"]:
		kind = "util"
	elif t in ["÷", "×", "-", "+", "="]:
		kind = "op"
	if t == "=":
		kind = "equal"

	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", DoodleStyle.btn(kind, "normal"))
	b.add_theme_stylebox_override("hover", DoodleStyle.btn(kind, "hover"))
	b.add_theme_stylebox_override("pressed", DoodleStyle.btn(kind, "pressed"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var font_col: Color = DoodleStyle.font_col(kind)
	b.add_theme_color_override("font_color", font_col)
	b.add_theme_color_override("font_hover_color", font_col)
	b.add_theme_color_override("font_pressed_color", font_col)
	b.add_theme_font_size_override("font_size", 24)
