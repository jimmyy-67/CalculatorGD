class_name PrinterShow
extends Node

const RIG_SCENE: PackedScene = preload("res://assets/printer/printer_rig.tscn")

const VP_PATH := "RigViewport"
const PROOT_PATH := "RigViewport/PrinterRoot"
const HOLDER_PATH := "RigViewport/PrinterRoot/PaperHolder"
const L1_PATH := "RigViewport/PrinterRoot/PaperHolder/PaperL1"
const L2_PATH := "RigViewport/PrinterRoot/PaperHolder/PaperL2"
const LQ_PATH := "RigViewport/PrinterRoot/PaperHolder/PaperLQ"
const SHEET_PATH := "RigViewport/PrinterRoot/PaperHolder/PaperSheet"
const HAND_PATH := "RigViewport/PrinterRoot/Hand"
const LED_PATH := "RigViewport/PrinterRoot/LED"
const CAM_PATH := "RigViewport/PrinterCam"

var _main: Control
var _body: PanelContainer
var _bg: ColorRect
var _fx: MemeEffects
var _audio_21: AudioStreamPlayer
var _audio_print: AudioStreamPlayer
var _rig: SubViewportContainer
var _busy := false
var _click_catcher: Control
var _revealed := false
var _wob1: Tween
var _wob2: Tween
var _touch_pos := Vector2(-1, -1)
signal hand_clicked


func setup(p_main: Control, p_body: PanelContainer, p_bg: ColorRect, p_fx: MemeEffects) -> void:
	_main = p_main
	_body = p_body
	_bg = p_bg
	_fx = p_fx
	_audio_21 = AudioStreamPlayer.new()
	_audio_21.bus = "Master"
	_main.add_child(_audio_21)
	if ResourceLoader.exists("res://assets/memes/twenty-one.mp3"):
		_audio_21.stream = load("res://assets/memes/twenty-one.mp3") as AudioStream
	_audio_print = AudioStreamPlayer.new()
	_audio_print.bus = "Master"
	_main.add_child(_audio_print)
	if ResourceLoader.exists("res://assets/memes/printer.mp3"):
		_audio_print.stream = load("res://assets/memes/printer.mp3") as AudioStream
	_main.get_tree().create_timer(0.6).timeout.connect(_prewarm)


func is_busy() -> bool:
	return _busy


func _ensure_rig() -> SubViewportContainer:
	if not is_instance_valid(_rig):
		_rig = RIG_SCENE.instantiate() as SubViewportContainer
		_main.add_child(_rig)
	return _rig


func play() -> void:
	if _busy:
		return
	_busy = true
	var rig := _ensure_rig()
	var vp: SubViewport = rig.get_node(VP_PATH) as SubViewport
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var holder: Node3D = rig.get_node(HOLDER_PATH) as Node3D
	var line1: Label3D = rig.get_node(L1_PATH) as Label3D
	var line2: Label3D = rig.get_node(L2_PATH) as Label3D
	var sheet: MeshInstance3D = rig.get_node(SHEET_PATH) as MeshInstance3D
	var shmat := sheet.material_override as ShaderMaterial
	holder.position = Vector3(0, 0.72, 1.13)
	holder.rotation = Vector3(-0.1, 0, 0)
	holder.scale = Vector3(1, 0.05, 1)
	shmat.set_shader_parameter("sway", 1.0)
	line1.modulate.a = 0.0
	line2.modulate.a = 0.0
	line2.outline_modulate.a = 0.0
	var lineq: Label3D = rig.get_node(LQ_PATH) as Label3D
	lineq.text = "= ?"
	lineq.modulate.a = 0.0
	lineq.outline_modulate.a = 0.0
	var hand: Node3D = rig.get_node(HAND_PATH) as Node3D
	hand.visible = false
	hand.position = Vector3(0, -2.2, 2.0)
	hand.rotation = Vector3(1.2, 2.95, 0.0)
	hand.scale = Vector3.ONE * 1.15
	_revealed = false
	rig.pivot_offset = _main.get_viewport_rect().size * 0.5
	rig.scale = Vector2(0.9, 0.9)
	var proot: Node3D = rig.get_node(PROOT_PATH) as Node3D
	proot.rotation = Vector3.ZERO
	proot.position = Vector3.ZERO
	if _wob1 and _wob1.is_valid():
		_wob1.kill()
	if _wob2 and _wob2.is_valid():
		_wob2.kill()
	_wob1 = proot.create_tween().set_loops(14)
	_wob1.tween_property(proot, "rotation:z", 0.015, 0.3)
	_wob1.tween_property(proot, "rotation:z", -0.015, 0.3)
	_wob2 = proot.create_tween().set_loops(14)
	_wob2.tween_property(proot, "position:x", 0.03, 0.4)
	_wob2.tween_property(proot, "position:x", -0.03, 0.4)
	var orig: Color = _bg.color
	_bg.color = Color("#1d3b2a")
	if _audio_print and _audio_print.stream:
		_audio_print.play()
	_body.pivot_offset = _body.size * 0.5
	var h1 := create_tween().set_parallel(true)
	h1.tween_property(_body, "modulate:a", 0.0, 0.4)
	h1.tween_property(_body, "scale", Vector2(0.85, 0.85), 0.4)
	var s1 := create_tween().set_parallel(true)
	s1.tween_property(rig, "modulate:a", 1.0, 0.4)
	s1.tween_property(rig, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var cam: Camera3D = rig.get_node(CAM_PATH) as Camera3D
	cam.position = Vector3(0, 2.7, 5.9)
	cam.look_at(Vector3(0, 1.0, 0))
	await _main.get_tree().create_timer(0.55).timeout
	_blink_led(rig)
	var tw = holder.create_tween().set_parallel(true)
	tw.tween_property(holder, "scale:y", 1.0, 4.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(line1, "modulate:a", 1.0, 1.2).set_delay(0.8)
	tw.tween_property(lineq, "modulate:a", 1.0, 1.2).set_delay(2.6)
	tw.tween_property(lineq, "outline_modulate:a", 1.0, 1.2).set_delay(2.6)
	await _main.get_tree().create_timer(4.0).timeout
	if _audio_print and _audio_print.playing:
		_audio_print.stop()
	hand.visible = true
	hand.position = Vector3(0, -2.2, 2.0)
	hand.rotation = Vector3(1.2, 2.95, 0.0)
	hand.scale = Vector3.ONE * 1.15
	_fx.show_popup("Click to reveal...", "21", 7.5)
	_arm_click_catcher()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var tree := _main.get_tree()
	var lineq_node: Label3D = rig.get_node(LQ_PATH) as Label3D
	var q_world: Vector3 = lineq_node.global_position
	var last_nag := Time.get_ticks_msec()
	while true:
		await tree.process_frame
		if is_instance_valid(hand) and is_instance_valid(cam) and is_instance_valid(vp):
			_update_hand_follow(hand, cam, vp, q_world)
		if _revealed:
			break
		if Time.get_ticks_msec() - last_nag > 8000:
			last_nag = Time.get_ticks_msec()
			_fx.show_popup("Click to reveal...", "21", 7.5)
	_stop_click_catcher()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_revealed = true
	hand.rotation = Vector3(1.2, 2.95, 0.0)
	var ptw := hand.create_tween()
	ptw.tween_property(hand, "position", hand.position + Vector3(0, 0.08, -0.5), 0.12)
	ptw.tween_property(hand, "position", Vector3(2.2, -1.8, 2.6), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	lineq.text = ""
	lineq.modulate.a = 0.0
	lineq.outline_modulate.a = 0.0
	line2.modulate.a = 0.0
	line2.outline_modulate.a = 0.0
	var rletw := create_tween().set_parallel(true)
	rletw.tween_property(line2, "modulate:a", 1.0, 0.15).set_delay(0.1)
	rletw.tween_property(line2, "outline_modulate:a", 1.0, 0.15).set_delay(0.1)
	if _audio_21 and _audio_21.stream:
		_audio_21.play()
	_fx.show_popup("9 + 10 = 21?!", "21", 1.6)
	_fx.spawn_confetti()
	await _main.get_tree().create_timer(1.8).timeout
	hand.visible = false
	await _main.get_tree().create_timer(1.2).timeout
	var fall = holder.create_tween().set_parallel(true)
	fall.tween_property(holder, "position:y", holder.position.y - 4.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(holder, "rotation:x", 0.5, 1.1)
	fall.tween_property(shmat, "shader_parameter/sway", 1.8, 0.5)
	await _main.get_tree().create_timer(1.2).timeout
	var h3 := create_tween()
	h3.tween_property(rig, "modulate:a", 0.0, 0.5)
	await _main.get_tree().create_timer(0.6).timeout
	var h2 := create_tween().set_parallel(true)
	h2.tween_property(_body, "modulate:a", 1.0, 0.5)
	h2.tween_property(_body, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _main.get_tree().create_timer(0.6).timeout
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var bgtw := create_tween()
	bgtw.tween_property(_bg, "color", orig, 0.8)
	_busy = false


func _arm_click_catcher() -> void:
	if not is_instance_valid(_click_catcher):
		_click_catcher = Control.new()
		_click_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
		_click_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
		_click_catcher.z_index = 200
		_click_catcher.gui_input.connect(_on_catcher_input)
		_click_catcher.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_main.add_child(_click_catcher)
	else:
		_click_catcher.visible = true
		_click_catcher.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_revealed = false
	_touch_pos = Vector2(-1, -1)


func _stop_click_catcher() -> void:
	if is_instance_valid(_click_catcher):
		_click_catcher.visible = false


func _on_catcher_input(event: InputEvent) -> void:
	if _revealed:
		return
	if event is InputEventScreenDrag:
		_touch_pos = event.position
		return
	if event is InputEventScreenTouch and event.pressed:
		_touch_pos = event.position
		_revealed = true
		_stop_click_catcher()
		hand_clicked.emit()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_revealed = true
		_stop_click_catcher()
		hand_clicked.emit()


func reveal() -> void:
	_revealed = true


func _prewarm() -> void:
	if _rig:
		return
	_rig = RIG_SCENE.instantiate() as SubViewportContainer
	_main.add_child(_rig)
	var vp: SubViewport = _rig.get_node(VP_PATH) as SubViewport
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	if is_instance_valid(vp):
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _update_hand_follow(hand: Node3D, cam: Camera3D, vp: SubViewport, q_world: Vector3) -> void:
	var main_vp := _main.get_viewport()
	if main_vp == null:
		return
	var m := main_vp.get_mouse_position()
	if _touch_pos.x >= 0.0:
		m = _touch_pos
	var ws := main_vp.get_visible_rect().size
	var vs := Vector2(vp.size)
	if ws.x <= 1.0 or ws.y <= 1.0 or vs.x <= 1.0 or vs.y <= 1.0:
		return
	var vp_mouse := m * vs / ws
	var target: Vector3 = cam.project_position(vp_mouse, 3.5)
	var root := hand.get_parent() as Node3D
	var parent_inv := Transform3D.IDENTITY
	if root:
		parent_inv = root.global_transform.affine_inverse()
	target = parent_inv * target
	target.x = clampf(target.x, -1.8, 1.8)
	target.y = clampf(target.y, -1.6, 1.4)
	target.z = clampf(target.z, 1.6, 2.6)
	hand.position = hand.position.lerp(target, 0.35)
	var t: float = Time.get_ticks_msec() / 1000.0
	var qw: Vector3 = q_world + Vector3(sin(t * 2.2) * 0.05, sin(t * 3.1) * 0.05, 0.0)
	var o: Vector3 = hand.global_position
	var y := qw - o
	if y.length() < 0.001:
		return
	y = y.normalized()
	var to_cam: Vector3 = cam.global_position - o
	if to_cam.length() < 0.001:
		return
	to_cam = to_cam.normalized()
	var x := y.cross(-to_cam)
	if x.length() < 0.05:
		return
	x = x.normalized()
	var z := x.cross(y).normalized()
	var want := Basis(x, y, z)
	var cur: Basis = hand.global_transform.basis.orthonormalized()
	var blended := cur.slerp(want, 0.35).orthonormalized()
	var sc := hand.scale
	var gt := hand.global_transform
	gt.basis = Basis(blended.x * sc.x, blended.y * sc.y, blended.z * sc.z)
	hand.global_transform = gt


func _blink_led(rig: SubViewportContainer) -> void:
	var led: MeshInstance3D = rig.get_node(LED_PATH) as MeshInstance3D
	if not is_instance_valid(led):
		return
	var led_m := led.material_override as StandardMaterial3D
	if led_m == null:
		return
	var blink = rig.create_tween().set_loops(22)
	blink.tween_property(led_m, "emission_energy_multiplier", 0.2, 0.12)
	blink.tween_property(led_m, "emission_energy_multiplier", 2.0, 0.12)
