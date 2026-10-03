class_name SixSevenRaid
extends Node

const RAID_SECS := 5.0
const RAID_COLS := 5
const RAID_ROWS := 4

var _main: Control
var _bg: ColorRect
var _audio_67: AudioStreamPlayer
var _frames_67: Array[SpriteFrames] = []
var _tex67_static: Texture2D
var _wallpaper: TextureRect
var _wallpaper_tex: Texture2D


func setup(p_main: Control, p_bg: ColorRect) -> void:
	_main = p_main
	_bg = p_bg
	_load_assets()


func play() -> void:
	if _audio_67 and _audio_67.stream:
		_audio_67.play()
		_main.get_tree().create_timer(RAID_SECS).timeout.connect(_stop_audio)
	_show_wallpaper(true)
	_main.get_tree().create_timer(RAID_SECS).timeout.connect(_show_wallpaper.bind(false))
	_spawn_67_rain()
	var slots: Array = range(RAID_COLS * RAID_ROWS)
	slots.shuffle()
	_spawn_67_wave(slots.slice(0, 8), RAID_SECS)
	_main.get_tree().create_timer(1.2).timeout.connect(_spawn_67_wave.bind(slots.slice(8, 14), RAID_SECS - 1.2))
	_main.get_tree().create_timer(2.6).timeout.connect(_spawn_67_wave.bind(slots.slice(14, 20), RAID_SECS - 2.6))


func _load_assets() -> void:
	_frames_67.clear()
	for folder in ["res://assets/memes/67-kid", "res://assets/memes/67-low"]:
		var sf := SpriteFrames.new()
		sf.set_animation_speed("default", 10)
		sf.set_animation_loop("default", true)
		var count := 0
		for i in range(24):
			var p := "%s/f%02d.png" % [folder, i]
			if ResourceLoader.exists(p):
				var t := load(p) as Texture2D
				if t:
					sf.add_frame("default", t)
					count += 1
		if count > 0:
			_frames_67.append(sf)
	if ResourceLoader.exists("res://assets/memes/67.png"):
		_tex67_static = load("res://assets/memes/67.png") as Texture2D
	if ResourceLoader.exists("res://assets/memes/67wallpaper.png"):
		_wallpaper_tex = load("res://assets/memes/67wallpaper.png") as Texture2D
		_build_wallpaper()
	_audio_67 = AudioStreamPlayer.new()
	_audio_67.bus = "Master"
	_main.add_child(_audio_67)
	if ResourceLoader.exists("res://assets/memes/six-seven.mp3"):
		_audio_67.stream = load("res://assets/memes/six-seven.mp3") as AudioStream


func _stop_audio() -> void:
	if _audio_67 and _audio_67.playing:
		_audio_67.stop()


func _build_wallpaper() -> void:
	if _wallpaper or not _wallpaper_tex:
		return
	_wallpaper = TextureRect.new()
	_wallpaper.texture = _wallpaper_tex
	_wallpaper.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wallpaper.modulate.a = 0.0
	_main.add_child(_wallpaper)
	_main.move_child(_wallpaper, 1)


func _show_wallpaper(on: bool) -> void:
	if not _wallpaper:
		return
	var tw := create_tween()
	tw.tween_property(_wallpaper, "modulate:a", 1.0 if on else 0.0, 0.4)


func _spawn_67_rain() -> void:
	if _tex67_static == null:
		return
	var vp: Vector2 = _main.get_viewport_rect().size
	var cols := [Color("#2ed573"), Color.WHITE, Color("#7bed9f")]
	for i in 46:
		var t := TextureRect.new()
		t.texture = _tex67_static
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var ss: float = randf_range(40.0, 110.0)
		t.size = Vector2(ss, ss)
		t.modulate = cols[randi() % cols.size()]
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.z_index = 55
		t.rotation = randf_range(-0.3, 0.3)
		_main.add_child(t)
		var x: float = randf() * vp.x
		var start_y: float = -60.0 - randf() * 200.0
		t.position = Vector2(x, start_y)
		var delay: float = randf_range(0.0, RAID_SECS - 1.5)
		var fall: float = randf_range(1.8, 3.0)
		var drift: float = randf_range(-60.0, 60.0)
		var tw = t.create_tween().set_parallel(true)
		tw.tween_property(t, "position:x", x + drift, fall).set_delay(delay)
		tw.tween_property(t, "position:y", vp.y + 60.0, fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(delay)
		var fade = t.create_tween()
		fade.tween_interval(delay + fall - 0.3)
		fade.tween_property(t, "modulate:a", 0.0, 0.3)
		_main.get_tree().create_timer(delay + fall + 0.5).timeout.connect(t.queue_free)


func _spawn_67_wave(slots: Array, life: float) -> void:
	var vp: Vector2 = _main.get_viewport_rect().size
	var use_anim: bool = not _frames_67.is_empty()
	for slot in slots:
		var s: int = int(slot)
		var row: int = s / RAID_COLS
		var target: Vector2 = _raid_slot_pos(s)
		var base_scale: float = _raid_row_scale(row)
		var a = null
		if use_anim:
			var asp := AnimatedSprite2D.new()
			asp.sprite_frames = _frames_67[randi() % _frames_67.size()]
			asp.speed_scale = randf_range(0.8, 1.4)
			asp.play("default")
			a = asp
		elif _tex67_static:
			var tr := TextureRect.new()
			tr.texture = _tex67_static
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			var ss: float = 130.0 * base_scale
			tr.size = Vector2(ss, ss)
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.flip_h = randi() % 2 == 0
			a = tr
		else:
			return
		if a == null:
			return
		a.z_index = 40 + row * 5
		a.rotation = randf_range(-0.25, 0.25)
		a.scale = Vector2.ONE * base_scale
		var m := 80.0
		var start := Vector2(target.x, -m)
		if target.x < vp.x * 0.25:
			start = Vector2(-m, target.y)
		elif target.x > vp.x * 0.75:
			start = Vector2(vp.x + m, target.y)
		elif target.y > vp.y * 0.5:
			start = Vector2(target.x, vp.y + m)
		if a is TextureRect:
			start -= (a as TextureRect).size * 0.5
			target -= (a as TextureRect).size * 0.5
		a.position = start
		_main.add_child(a)
		var tw = a.create_tween().set_parallel(true)
		tw.tween_property(a, "position", target, randf_range(0.45, 0.9)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var dance = a.create_tween().set_loops()
		dance.tween_property(a, "rotation", randf_range(-0.35, 0.35), 0.28)
		dance.tween_property(a, "rotation", randf_range(-0.35, 0.35), 0.28)
		var pulse = a.create_tween().set_loops()
		pulse.tween_property(a, "scale", Vector2.ONE * base_scale * 1.08, 0.35)
		pulse.tween_property(a, "scale", Vector2.ONE * base_scale * 0.94, 0.35)
		var fade = a.create_tween()
		fade.tween_interval(maxf(life - 0.4, 0.2))
		fade.tween_property(a, "modulate:a", 0.0, 0.4)
		_main.get_tree().create_timer(life + 0.3).timeout.connect(a.queue_free)


func _raid_slot_pos(slot: int) -> Vector2:
	var vp: Vector2 = _main.get_viewport_rect().size
	var col: int = slot % RAID_COLS
	var row: int = slot / RAID_COLS
	var area := Rect2(vp.x * 0.06, vp.y * 0.08, vp.x * 0.88, vp.y * 0.80)
	var cell := Vector2(area.size.x / RAID_COLS, area.size.y / RAID_ROWS)
	var center := Vector2(
		area.position.x + cell.x * (col + 0.5) + randf_range(-cell.x * 0.12, cell.x * 0.12),
		area.position.y + cell.y * (row + 0.5) + randf_range(-cell.y * 0.12, cell.y * 0.12)
	)
	return center


func _raid_row_scale(row: int) -> float:
	return [0.65, 0.85, 1.05, 1.25][clampi(row, 0, 3)]
