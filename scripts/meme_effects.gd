class_name MemeEffects
extends Node

const CONFETTI_COUNT := 8
const CONFETTI_W := 8.0
const CONFETTI_H := 12.0

var _main: Control
var _body: PanelContainer
var _display: Control
var _bg: ColorRect
var _popup: Label
var _popup_tween: Tween
var _confetti_tex: Array[Texture2D] = []


func setup(p_main: Control, p_body: PanelContainer, p_display: Control, p_bg: ColorRect, p_popup: Label) -> void:
	_main = p_main
	_body = p_body
	_display = p_display
	_bg = p_bg
	_popup = p_popup
	_confetti_tex.clear()
	for i in CONFETTI_COUNT:
		_confetti_tex.append(load("res://assets/confetti/c%d.png" % i) as Texture2D)


static func accent(key: String) -> Color:
	match key:
		"67":
			return Color("#2ed573")
	return Color("#ffe08a")


func play_generic(key: String, text: String) -> void:
	punch_body()
	flash_bg(key)
	show_popup(text, key)
	spawn_confetti()


func show_popup(text: String, key: String, hold: float = 0.7) -> void:
	_popup.text = text
	_popup.add_theme_color_override("font_color", accent(key))
	_popup.pivot_offset = _popup.size * 0.5
	if _popup_tween and _popup_tween.is_valid():
		_popup_tween.kill()
	_popup.scale = Vector2(0.5, 0.5)
	_popup.modulate.a = 1.0
	_popup_tween = create_tween()
	_popup_tween.tween_property(_popup, "scale", Vector2(1.1, 1.1), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(_popup, "scale", Vector2.ONE, 0.15)
	_popup_tween.tween_interval(hold)
	_popup_tween.tween_property(_popup, "modulate:a", 0.0, 0.4)
	_popup_tween.tween_property(_popup, "scale", Vector2(1.3, 1.3), 0.4)


func punch_body() -> void:
	_body.pivot_offset = _body.size * 0.5
	var tw := create_tween()
	tw.tween_property(_body, "scale", Vector2(1.07, 1.07), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_body, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var tw2 := create_tween()
	tw2.tween_property(_body, "rotation_degrees", -2.5, 0.07)
	tw2.tween_property(_body, "rotation_degrees", 2.5, 0.07)
	tw2.tween_property(_body, "rotation_degrees", 0.0, 0.15)


func flash_bg(key: String) -> void:
	var orig: Color = _bg.color
	var flash := accent(key)
	var tw := create_tween()
	_bg.color = flash.darkened(0.55)
	tw.tween_property(_bg, "color", orig, 0.6)
	_display.modulate = Color("#fff3b0")
	var tw2 := create_tween()
	tw2.tween_property(_display, "modulate", Color.WHITE, 0.5)


func spawn_confetti() -> void:
	var vp: Vector2 = _main.get_viewport_rect().size
	for i in 48:
		var c := TextureRect.new()
		c.texture = _confetti_tex[randi() % _confetti_tex.size()]
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c.size = Vector2(CONFETTI_W, CONFETTI_H)
		c.position = Vector2(randf() * vp.x, -24.0)
		c.rotation = randf() * TAU
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.z_index = 50
		_main.add_child(c)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(c, "position:y", vp.y + 40.0, randf_range(0.7, 1.4)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(c, "rotation", randf_range(-6.0, 6.0), 1.2)
		tw.tween_property(c, "modulate:a", 0.0, 0.35).set_delay(0.95)
		_main.get_tree().create_timer(1.5).timeout.connect(c.queue_free)
