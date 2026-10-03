class_name DoodleFont
extends Node

const BTN_CELL := 128
const BTN_FONT := 64
const BTN_FONT_OP := 80
const ICON_SIZE := 56
const DISP_W := 340
const EXPR_H := 66
const EXPR_FONT := 38
const MAIN_Y := 74
const MAIN_H := 76
const MAIN_FONT := 58
const DISP_H := 150

var _vp_btns: SubViewport
var _vp_disp: SubViewport
var _expr_label: Label
var _main_label: Label
var _seed := 7
var _no_snap := false


func setup(p_main: Control) -> void:
	_no_snap = DisplayServer.get_name() == "headless"


func _make_vp(w: int, h: int, parent: Node) -> SubViewport:
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.size = Vector2i(w, h)
	vp.gui_disable_input = true
	vp.handle_input_locally = false
	parent.add_child(vp)
	return vp


func prerender(order: Array, col: Color, font_size: int, parent: Node) -> Dictionary:
	_vp_btns = _make_vp(order.size() * BTN_CELL, BTN_CELL, parent)
	for i in order.size():
		var l := Label.new()
		l.text = str(order[i])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.position = Vector2(i * BTN_CELL, 0)
		l.size = Vector2(BTN_CELL, BTN_CELL)
		l.add_theme_font_size_override("font_size", font_size)
		l.add_theme_color_override("font_color", col)
		_vp_btns.add_child(l)
	await parent.get_tree().process_frame
	await parent.get_tree().process_frame
	var out := {}
	var full := _snap(_vp_btns)
	if full.get_width() > 1:
		for i in order.size():
			var cell := full.get_region(Rect2(i * BTN_CELL, 0, BTN_CELL, BTN_CELL))
			out[str(order[i])] = ImageTexture.create_from_image(_centered(_wobble(cell, _seed + i * 13)))
	_vp_btns.queue_free()
	_vp_btns = null
	return out


static func _centered(src: Image) -> Image:
	var r := src.get_used_rect()
	var dst := Image.create_empty(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	if r.size.x <= 0 or r.size.y <= 0:
		return dst
	var crop := src.get_region(r)
	var sc: float = minf(float(ICON_SIZE) / maxf(r.size.x, 1.0), float(ICON_SIZE) / maxf(r.size.y, 1.0))
	sc = minf(sc, 1.0)
	var nw := maxi(int(r.size.x * sc), 2)
	var nh := maxi(int(r.size.y * sc), 2)
	crop.resize(nw, nh, Image.INTERPOLATE_NEAREST)
	dst.blit_rect(crop, Rect2(0, 0, nw, nh), Vector2((ICON_SIZE - nw) / 2, (ICON_SIZE - nh) / 2))
	return dst


func setup_display(parent: Node) -> void:
	_vp_disp = _make_vp(DISP_W, DISP_H, parent)
	_expr_label = Label.new()
	_expr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_expr_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_expr_label.position = Vector2(0, 0)
	_expr_label.size = Vector2(DISP_W, EXPR_H)
	_expr_label.add_theme_font_size_override("font_size", EXPR_FONT)
	_vp_disp.add_child(_expr_label)
	_main_label = Label.new()
	_main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_main_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_main_label.position = Vector2(0, MAIN_Y)
	_main_label.size = Vector2(DISP_W, MAIN_H)
	_main_label.add_theme_font_size_override("font_size", MAIN_FONT)
	_vp_disp.add_child(_main_label)


func render_expr(text: String, col: Color) -> ImageTexture:
	if _no_snap or not is_instance_valid(_expr_label):
		return null
	_expr_label.text = text
	_expr_label.add_theme_color_override("font_color", col)
	var full := await _snap_async()
	if full.get_width() <= 1:
		return null
	var crop := full.get_region(Rect2(0, 0, DISP_W, EXPR_H))
	return ImageTexture.create_from_image(_wobble(crop, _seed + 555))


func render_display(text: String, col: Color) -> ImageTexture:
	if _no_snap or not is_instance_valid(_main_label):
		return null
	_main_label.text = text
	_main_label.add_theme_color_override("font_color", col)
	var full := await _snap_async()
	if full.get_width() <= 1:
		return null
	var crop := full.get_region(Rect2(0, MAIN_Y, DISP_W, MAIN_H))
	return ImageTexture.create_from_image(_wobble(crop, _seed + 999))


func _snap(vp: SubViewport) -> Image:
	var empty := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	if _no_snap or vp == null:
		return empty
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var tex: Texture2D = vp.get_texture()
	if tex == null:
		return empty
	var img := tex.get_image()
	if img == null or img.is_empty():
		return empty
	return img


func _snap_async() -> Image:
	_vp_disp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	return _snap(_vp_disp)


static func _wobble(src: Image, seed: int) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	if w <= 1 or h <= 1:
		return src
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var p1 := rng.randf_range(0.0, TAU)
	var p2 := rng.randf_range(0.0, TAU)
	var p3 := rng.randf_range(0.0, TAU)
	var dst := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var dx := int(1.8 * sin(y * 0.33 + p1) + 0.9 * sin(y * 0.11 + p2))
		dst.blit_rect(src, Rect2(0, y, w, 1), Vector2(dx, y))
	var tmp := dst.duplicate()
	dst.fill(Color(0, 0, 0, 0))
	for x in w:
		var dy := int(1.8 * sin(x * 0.31 + p3) + 0.9 * sin(x * 0.13 + p1))
		dst.blit_rect(tmp, Rect2(x, 0, 1, h), Vector2(x, dy))
	return dst
