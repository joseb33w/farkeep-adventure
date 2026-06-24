class_name ChatPanel
extends CanvasLayer

signal closed()

const ENDPOINT := "https://npc.myapping.com/chat"
const MAX_TURNS := 12

var _npc: Npc = null
var _http: HTTPRequest
var _busy := false
var _think_t := 0.0
var _think_n := 0

var _dim: ColorRect
var _panel: PanelContainer
var _title: Label
var _log: RichTextLabel
var _think: Label
var _input: LineEdit
var _send: Button


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_http = HTTPRequest.new()
	add_child(_http)
	_http.process_mode = Node.PROCESS_MODE_ALWAYS
	_http.request_completed.connect(_on_http)
	_build_ui()
	visible = false


func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(560, 420)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.14, 0.97)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16)
	sb.border_color = Color(0.8, 0.66, 0.36)
	sb.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_panel.add_child(vb)

	var top := HBoxContainer.new()
	vb.add_child(top)
	_title = Label.new()
	_title.text = "Townsfolk"
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	var close := Button.new()
	close.text = "X"
	close.custom_minimum_size = Vector2(44, 44)
	close.pressed.connect(close_panel)
	top.add_child(close)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(520, 280)
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 19)
	vb.add_child(_log)

	_think = Label.new()
	_think.text = ""
	_think.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_think.add_theme_font_size_override("font_size", 18)
	vb.add_child(_think)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	_input = LineEdit.new()
	_input.placeholder_text = "Say something..."
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.max_length = 160
	_input.text_submitted.connect(func(_t: String) -> void: _on_send())
	row.add_child(_input)
	_send = Button.new()
	_send.text = "Send"
	_send.custom_minimum_size = Vector2(90, 44)
	_send.pressed.connect(_on_send)
	row.add_child(_send)


func open_chat(npc: Npc) -> void:
	_npc = npc
	_title.text = npc.npc_name
	_log.clear()
	if npc.history.is_empty() and npc.opening != "":
		npc.history.append({"role": "assistant", "content": npc.opening})
	for m: Dictionary in npc.history:
		_render(String(m.get("role", "")), String(m.get("content", "")))
	visible = true
	get_tree().paused = true
	_input.grab_focus()


func close_panel() -> void:
	visible = false
	get_tree().paused = false
	_think.text = ""
	closed.emit()


func _render(role: String, content: String) -> void:
	if role == "user":
		_log.append_text("[color=#9ad0ff]You:[/color] %s\n" % content)
	else:
		_log.append_text("[color=#ffd98a]%s:[/color] %s\n" % [_npc.npc_name if _npc != null else "NPC", content])


func _on_send() -> void:
	if _busy or _npc == null:
		return
	var text := _input.text.strip_edges()
	if text == "":
		return
	_input.text = ""
	_npc.history.append({"role": "user", "content": text})
	_render("user", text)
	_set_busy(true)
	var msgs: Array = []
	for m: Dictionary in _npc.history:
		msgs.append({"role": String(m.get("role", "user")), "content": String(m.get("content", ""))})
	var payload := {"persona": _npc.persona, "messages": msgs}
	var err := _http.request(ENDPOINT, ["content-type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		_fail()


func _on_http(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if code != 200:
		_fail()
		return
	var txt := body.get_string_from_utf8()
	var v: Variant = JSON.parse_string(txt)
	var reply := ""
	if v is Dictionary:
		var d: Dictionary = v
		reply = String(d.get("reply", ""))
	if reply.strip_edges() == "":
		_fail()
		return
	if _npc != null:
		_npc.history.append({"role": "assistant", "content": reply})
		_trim()
	_render("assistant", reply)
	_set_busy(false)


func _fail() -> void:
	_render("assistant", "... (lost in thought)")
	_set_busy(false)


func _trim() -> void:
	if _npc == null:
		return
	var maxn := MAX_TURNS * 2
	while _npc.history.size() > maxn:
		_npc.history.remove_at(0)


func _set_busy(b: bool) -> void:
	_busy = b
	_send.disabled = b
	_input.editable = not b
	if not b:
		_think.text = ""


func _process(delta: float) -> void:
	if not _busy:
		return
	_think_t += delta
	if _think_t > 0.35:
		_think_t = 0.0
		_think_n = (_think_n + 1) % 4
		_think.text = "thinking" + ".".repeat(_think_n)
