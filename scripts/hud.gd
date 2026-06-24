class_name Hud
extends CanvasLayer

signal move_vec(v: Vector2)
signal look_delta(d: Vector2)
signal attack_pressed()
signal interact_pressed()
signal menu_pressed()

const LOOK_SENS := 0.006
const JOY_RADIUS := 90.0

var _root: Control
var _stick: Control
var _hp_bg: ColorRect
var _hp_fill: ColorRect
var _obj: Label
var _timer: Label
var _coins: Label
var _toast: Label
var _compass: Control
var _attack_btn: Button
var _interact_btn: Button
var _menu_btn: Button

var _touch_active := 0
var _joy_index := -1
var _joy_origin := Vector2.ZERO
var _joy_cur := Vector2.ZERO
var _look_index := -1
var _mouse_look := false
var _compass_angle := 0.0
var _safe := {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_stick = Control.new()
	_stick.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick.draw.connect(_draw_stick)
	_root.add_child(_stick)

	_hp_bg = ColorRect.new()
	_hp_bg.color = Color(0.1, 0.05, 0.05, 0.7)
	_hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hp_bg)
	_hp_fill = ColorRect.new()
	_hp_fill.color = Color(0.85, 0.25, 0.25)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hp_fill)

	_obj = _mk_label(26, Color(1.0, 0.92, 0.65), HORIZONTAL_ALIGNMENT_CENTER)
	_obj.text = "Reach the Great Keep"
	_timer = _mk_label(20, Color(0.85, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	_coins = _mk_label(20, Color(1.0, 0.88, 0.5), HORIZONTAL_ALIGNMENT_LEFT)
	_coins.text = "Coins: 0"

	_compass = Control.new()
	_compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compass.custom_minimum_size = Vector2(48, 48)
	_compass.draw.connect(_draw_compass)
	_root.add_child(_compass)

	_toast = _mk_label(24, Color(1.0, 0.85, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	_toast.visible = false

	_attack_btn = _mk_button("Attack", Color(0.8, 0.3, 0.25))
	_attack_btn.pressed.connect(func() -> void: attack_pressed.emit())
	_interact_btn = _mk_button("Use", Color(0.3, 0.6, 0.85))
	_interact_btn.pressed.connect(func() -> void: interact_pressed.emit())
	_interact_btn.visible = false
	_interact_btn.add_theme_font_size_override("font_size", 17)
	_interact_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_interact_btn.clip_text = false
	_menu_btn = _mk_button("Board", Color(0.45, 0.4, 0.55))
	_menu_btn.pressed.connect(func() -> void: menu_pressed.emit())

	get_viewport().size_changed.connect(_relayout)
	_read_safe()
	_relayout()


func _mk_label(sz: int, col: Color, align: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	return l


func _mk_button(txt: String, col: Color) -> Button:
	var b := Button.new()
	b.text = txt
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r, col.g, col.b, 0.82)
	sb.set_corner_radius_all(40)
	b.add_theme_stylebox_override("normal", sb)
	var sbp := sb.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(col.r, col.g, col.b, 1.0)
	b.add_theme_stylebox_override("pressed", sbp)
	b.add_theme_font_size_override("font_size", 22)
	_root.add_child(b)
	return b


func _read_safe() -> void:
	if not OS.has_feature("web"):
		return
	var js := "(()=>{const d=document.createElement('div');d.style.cssText='position:fixed;top:env(safe-area-inset-top);bottom:env(safe-area-inset-bottom);left:env(safe-area-inset-left);right:env(safe-area-inset-right)';document.body.appendChild(d);const r=getComputedStyle(d);const o={top:parseFloat(r.top)||0,bottom:parseFloat(r.bottom)||0,left:parseFloat(r.left)||0,right:parseFloat(r.right)||0};d.remove();return JSON.stringify(o);})()"
	var raw: String = str(JavaScriptBridge.eval(js, true))
	if raw == "":
		return
	var v: Variant = JSON.parse_string(raw)
	if v is Dictionary:
		_safe = v


func _relayout() -> void:
	var vp := get_viewport().get_visible_rect().size
	var st := maxf(12.0, float(_safe.get("top", 0.0)))
	var sb := maxf(16.0, float(_safe.get("bottom", 0.0)))
	var sl := maxf(14.0, float(_safe.get("left", 0.0)))
	var sr := maxf(14.0, float(_safe.get("right", 0.0)))

	_hp_bg.position = Vector2(sl, st)
	_hp_bg.size = Vector2(220, 22)
	_hp_fill.position = _hp_bg.position + Vector2(2, 2)
	_hp_fill.size = Vector2(216, 18)
	_set_hp_width()
	_coins.position = Vector2(sl, st + 28)
	_coins.size = Vector2(240, 26)

	var ow := minf(vp.x - 28.0, 520.0)
	_obj.position = Vector2((vp.x - ow) * 0.5, st + 58)
	_obj.size = Vector2(ow, 30)
	_compass.position = Vector2(vp.x * 0.5 - 24, st + 92)
	_compass.size = Vector2(48, 48)
	_timer.position = Vector2(vp.x * 0.5 - 120, st + 142)
	_timer.size = Vector2(240, 26)

	_toast.position = Vector2(vp.x * 0.5 - 300, vp.y * 0.42)
	_toast.size = Vector2(600, 40)

	var bs := 116.0
	_attack_btn.size = Vector2(bs, bs)
	_attack_btn.position = Vector2(vp.x - sr - bs, vp.y - sb - bs)
	_interact_btn.size = Vector2(bs, bs * 0.7)
	_interact_btn.position = Vector2(vp.x - sr - bs, vp.y - sb - bs - bs * 0.7 - 14)
	_menu_btn.size = Vector2(108, 50)
	_menu_btn.position = Vector2(vp.x - sr - 108, st)
	_stick.queue_redraw()
	_compass.queue_redraw()


func _set_hp_width() -> void:
	pass


func set_health(hp: float, mx: float) -> void:
	var r := clampf(hp / maxf(1.0, mx), 0.0, 1.0)
	_hp_fill.size = Vector2(216.0 * r, 18)


func set_objective(t: String) -> void:
	_obj.text = t


func set_prompt(t: String) -> void:
	if t == "":
		_interact_btn.visible = false
	else:
		_interact_btn.visible = true
		_interact_btn.text = t


func set_coins(n: int, has_key: bool) -> void:
	_coins.text = ("Coins: %d   [KEY]" % n) if has_key else ("Coins: %d" % n)


func set_timer(sec: float) -> void:
	var m := int(sec) / 60
	var s := int(sec) % 60
	_timer.text = "%d:%02d" % [m, s]


func set_compass(rel_angle: float) -> void:
	_compass_angle = rel_angle
	_compass.queue_redraw()


func show_toast(t: String) -> void:
	_toast.text = t
	_toast.visible = true
	var tw := _toast.create_tween()
	_toast.modulate.a = 1.0
	tw.tween_interval(1.6)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func() -> void: _toast.visible = false)


func _draw_stick() -> void:
	if _joy_index != -1:
		_stick.draw_circle(_joy_origin, JOY_RADIUS, Color(1, 1, 1, 0.14))
		_stick.draw_circle(_joy_origin, JOY_RADIUS, Color(1, 1, 1, 0.30), false, 3.0)
		var knob := _joy_origin + _joy_cur * JOY_RADIUS
		_stick.draw_circle(knob, 34.0, Color(1, 1, 1, 0.5))


func _draw_compass() -> void:
	var c := Vector2(24, 24)
	var a := _compass_angle
	var fwd := Vector2(sin(a), -cos(a))
	var side := Vector2(fwd.y, -fwd.x)
	var pts := PackedVector2Array([c + fwd * 22.0, c - fwd * 10.0 + side * 12.0, c - fwd * 10.0 - side * 12.0])
	_compass.draw_colored_polygon(pts, Color(1.0, 0.85, 0.4, 0.95))


func _unhandled_input(event: InputEvent) -> void:
	var half := get_viewport().get_visible_rect().size.x * 0.5
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_active += 1
			if t.position.x < half and _joy_index == -1:
				_joy_index = t.index
				_joy_origin = t.position
				_joy_cur = Vector2.ZERO
				_stick.queue_redraw()
			elif t.position.x >= half and _look_index == -1:
				_look_index = t.index
		else:
			_touch_active = max(0, _touch_active - 1)
			if t.index == _joy_index:
				_joy_index = -1
				_joy_cur = Vector2.ZERO
				move_vec.emit(Vector2.ZERO)
				_stick.queue_redraw()
			elif t.index == _look_index:
				_look_index = -1
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_index:
			var off := (d.position - _joy_origin) / JOY_RADIUS
			_joy_cur = off.limit_length(1.0)
			move_vec.emit(Vector2(_joy_cur.x, -_joy_cur.y))
			_stick.queue_redraw()
		elif d.index == _look_index:
			look_delta.emit(d.relative * LOOK_SENS)
	elif event is InputEventMouseButton:
		if _touch_active > 0:
			return
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_mouse_look = mb.pressed
	elif event is InputEventMouseMotion:
		if _touch_active > 0:
			return
		var mm := event as InputEventMouseMotion
		if _mouse_look:
			look_delta.emit(mm.relative * LOOK_SENS)
