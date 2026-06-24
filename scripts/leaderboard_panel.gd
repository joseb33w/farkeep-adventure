class_name LeaderboardPanel
extends CanvasLayer

var _dim: ColorRect
var _list: VBoxContainer
var _status: Label


func _ready() -> void:
	layer = 48
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	G.leaderboard_loaded.connect(_on_loaded)


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.6)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 460)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.09, 0.13, 0.98)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(18)
	sb.border_color = Color(0.85, 0.7, 0.38)
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "Fastest to the Keep"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_status)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 46)
	close.pressed.connect(close_panel)
	vb.add_child(close)


func open_panel() -> void:
	visible = true
	get_tree().paused = true
	_status.text = "Loading..."
	for c in _list.get_children():
		c.queue_free()
	G.fetch_leaderboard()


func close_panel() -> void:
	visible = false
	get_tree().paused = false


func _on_loaded(rows: Array) -> void:
	for c in _list.get_children():
		c.queue_free()
	if rows.is_empty():
		_status.text = "No champions yet -- be the first!"
		return
	_status.text = "%d champions" % rows.size()
	var rank := 1
	for r_v in rows:
		if not (r_v is Dictionary):
			continue
		var r: Dictionary = r_v
		var nm := String(r.get("display_name", "?"))
		var t := float(r.get("time_seconds", 0.0))
		var row := HBoxContainer.new()
		var lr := Label.new()
		lr.text = "%d." % rank
		lr.custom_minimum_size = Vector2(40, 0)
		lr.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
		row.add_child(lr)
		var ln := Label.new()
		ln.text = nm
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(ln)
		var lt := Label.new()
		lt.text = _fmt(t)
		lt.add_theme_color_override("font_color", Color(0.7, 0.95, 0.8))
		row.add_child(lt)
		_list.add_child(row)
		rank += 1


func _fmt(sec: float) -> String:
	var m := int(sec) / 60
	var s := int(sec) % 60
	return "%d:%02d" % [m, s]
