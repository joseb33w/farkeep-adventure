extends Node3D
## Far Keep -- seamless open-world adventure orchestrator.

var world: World
var player: Player
var cam: CamRig
var hud: Hud
var chat: ChatPanel
var board: LeaderboardPanel

var playing := false
var _hud_move := Vector2.ZERO
var _autosave_t := 0.0
var _start_layer: CanvasLayer
var _name_input: LineEdit
var _loading_label: Label
var _victory_layer: CanvasLayer
var _nearest: Interactable = null
var _debug := false


func _ready() -> void:
	var w := get_window()
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

	world = World.new()
	add_child(world)
	world.build()

	player = Player.new()
	add_child(player)
	player.global_position = world.spawn_point
	G.player = player

	cam = CamRig.new()
	add_child(cam)
	cam.set_target(player)
	G.cam = cam

	hud = Hud.new()
	add_child(hud)
	hud.move_vec.connect(func(v: Vector2) -> void: _hud_move = v)
	hud.look_delta.connect(func(d: Vector2) -> void: cam.add_look(d.x, d.y))
	hud.attack_pressed.connect(_on_attack)
	hud.interact_pressed.connect(_on_interact)
	hud.menu_pressed.connect(_open_board)

	chat = ChatPanel.new()
	add_child(chat)
	board = LeaderboardPanel.new()
	add_child(board)

	player.hp_changed.connect(func(hp: float, mx: float) -> void: hud.set_health(hp, mx))
	player.died.connect(_on_player_died)

	for c in world.chests:
		(c as Chest).opened_chest.connect(_on_chest_opened)
	for n in world.npcs:
		(n as Npc).talk_requested.connect(_on_talk)
	if world.keep_gate != null:
		world.keep_gate.gate_opened.connect(_on_gate_opened)
		world.keep_gate.need_key.connect(func() -> void: hud.show_toast("The gate is locked. Find the Keep's key."))
	if world.win_zone != null:
		world.win_zone.reached.connect(_on_reach_keep)

	_build_start_screen()
	if OS.has_feature("web"):
		var h: String = str(JavaScriptBridge.eval("window.location.hash", true))
		if h.findn("auto") != -1:
			_debug = true
			get_tree().create_timer(0.6).timeout.connect(_on_begin)


# ---------------- start / name screen ----------------
func _build_start_screen() -> void:
	get_tree().paused = true
	_start_layer = CanvasLayer.new()
	_start_layer.layer = 80
	_start_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_start_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.06, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_start_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	center.add_child(vb)
	var title := Label.new()
	title.text = "FAR KEEP"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := Label.new()
	sub.text = "Roam the forest, explore the walled town of Vellmoor,\nand reach the Great Keep at the edge of the land."
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var hint := Label.new()
	hint.text = "Move: left stick / WASD     Look: drag right / mouse\nAttack: button / J     Use: button / E"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.8))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	var nl := Label.new()
	nl.text = "Name:"
	nl.add_theme_font_size_override("font_size", 22)
	row.add_child(nl)
	_name_input = LineEdit.new()
	_name_input.text = G.display_name
	_name_input.custom_minimum_size = Vector2(240, 44)
	_name_input.max_length = 18
	row.add_child(_name_input)
	var begin := Button.new()
	begin.text = "Begin the Journey"
	begin.custom_minimum_size = Vector2(320, 56)
	begin.add_theme_font_size_override("font_size", 24)
	begin.pressed.connect(_on_begin)
	vb.add_child(begin)
	_loading_label = Label.new()
	_loading_label.text = ""
	_loading_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.7))
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_loading_label)


func _on_begin() -> void:
	G.set_player_name(_name_input.text)
	_loading_label.text = "Loading your journey..."
	if not G.save_loaded.is_connected(_on_save_loaded):
		G.save_loaded.connect(_on_save_loaded, CONNECT_ONE_SHOT)
	G.load_remote()


func _on_save_loaded(data: Dictionary) -> void:
	_apply_save(data)
	if _start_layer != null:
		_start_layer.queue_free()
		_start_layer = null
	get_tree().paused = false
	playing = true
	_update_objective()


func _apply_save(data: Dictionary) -> void:
	if data.has("pos_x"):
		var pos := Vector3(float(data.get("pos_x", 0.0)), float(data.get("pos_y", 1.6)), float(data.get("pos_z", 36.0)))
		pos.y = maxf(pos.y, 1.2)
		player.global_position = pos
		cam.yaw = float(data.get("yaw", 0.0))
		cam.set_target(player)
		var inv: Variant = data.get("inventory", null)
		if inv is Dictionary:
			G.inventory = inv
			if not G.inventory.has("coins"):
				G.inventory["coins"] = 0
			if not G.inventory.has("chests"):
				G.inventory["chests"] = []
		var gates: Variant = data.get("opened_gates", null)
		if gates is Array:
			G.opened_gates = gates
		G.elapsed = float(data.get("elapsed_seconds", 0.0))
		G.reached_keep = bool(data.get("reached_keep", false))
		var oc: Array = G.inventory.get("chests", [])
		for c in world.chests:
			if oc.has((c as Chest).chest_id):
				(c as Chest).mark_opened_silent()
		if G.opened_gates.has("keep_gate") and world.keep_gate != null:
			world.keep_gate.set_open_immediate()
	else:
		if not G.inventory.has("chests"):
			G.inventory["chests"] = []
	hud.set_coins(int(G.inventory.get("coins", 0)), G.has_key())


# ---------------- gameplay loop ----------------
func _process(delta: float) -> void:
	if not playing or get_tree().paused:
		return
	G.elapsed += delta
	hud.set_timer(G.elapsed)
	var total := (_hud_move + _key_move()).limit_length(1.0)
	player.move_input = total
	player.cam_yaw = cam.yaw
	_update_nearest()
	_update_compass()
	_autosave_t += delta
	if _autosave_t >= 8.0:
		_autosave_t = 0.0
		_save()
	if _debug and OS.has_feature("web"):
		JavaScriptBridge.eval("window.__fk={px:%.2f,pz:%.2f,yaw:%.3f,key:%s,won:%s,playing:true};" % [
			player.global_position.x, player.global_position.z, cam.yaw,
			("true" if G.has_key() else "false"), ("true" if G.reached_keep else "false")], true)


func _key_move() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y -= 1.0
	return v


func _unhandled_input(event: InputEvent) -> void:
	if not playing or get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).physical_keycode
		if k == KEY_J or k == KEY_SPACE or k == KEY_ENTER:
			_on_attack()
		elif k == KEY_E or k == KEY_F:
			_on_interact()
		elif k == KEY_L or k == KEY_TAB:
			_open_board()


func _on_attack() -> void:
	if playing and player != null:
		player.attack()


func _update_nearest() -> void:
	var best: Interactable = null
	var bd := 9999.0
	for node in get_tree().get_nodes_in_group("interactable"):
		var it := node as Interactable
		if it == null or not it.is_near() or not it.can_interact():
			continue
		var d := it.global_position.distance_to(player.global_position)
		if d < bd:
			bd = d
			best = it
	_nearest = best
	hud.set_prompt(best.get_prompt() if best != null else "")


func _on_interact() -> void:
	if _nearest != null and is_instance_valid(_nearest) and _nearest.can_interact():
		_nearest.do_interact(player)


func _on_talk(npc: Npc) -> void:
	chat.open_chat(npc)


func _on_chest_opened(chest_id: String, is_key: bool, _coins: int) -> void:
	var oc: Array = G.inventory.get("chests", [])
	if not oc.has(chest_id):
		oc.append(chest_id)
	G.inventory["chests"] = oc
	hud.set_coins(int(G.inventory.get("coins", 0)), G.has_key())
	if is_key:
		hud.show_toast("You found the Keep's key!")
	else:
		hud.show_toast("You found some coins.")
	_update_objective()
	_save()


func _on_gate_opened(_id: String) -> void:
	hud.show_toast("The Keep's gate grinds open!")
	_update_objective()
	_save()


func _on_reach_keep() -> void:
	if G.reached_keep and _victory_layer != null:
		return
	var first := not G.reached_keep
	G.reached_keep = true
	G.submit_score(G.elapsed)
	_save()
	_show_victory(first)


func _on_player_died() -> void:
	hud.show_toast("You fall... but rise again at the forest's edge.")
	var t := get_tree().create_timer(1.4)
	t.timeout.connect(func() -> void:
		if player != null:
			player.respawn(world.spawn_point)
			cam.set_target(player))


# ---------------- objective + compass ----------------
func _objective_target() -> Vector3:
	if not G.has_key():
		return Vector3(12.0, 0.0, 2.0)
	if world.keep_gate != null and world.keep_gate.locked:
		return world.keep_gate.global_position
	if world.win_zone != null:
		return world.win_zone.global_position
	return Vector3(0.0, 0.0, -48.0)


func _update_objective() -> void:
	if not G.has_key():
		hud.set_objective("Find the Keep's key (guardhouse)")
	elif world.keep_gate != null and world.keep_gate.locked:
		hud.set_objective("Open the Keep's locked gate")
	else:
		hud.set_objective("Reach the Great Keep!")


func _update_compass() -> void:
	var to := _objective_target() - player.global_position
	to.y = 0.0
	if to.length() < 0.5:
		return
	hud.set_compass(atan2(to.x, to.z) - cam.yaw)


# ---------------- victory ----------------
func _show_victory(first: bool) -> void:
	if _victory_layer != null:
		_victory_layer.queue_free()
	_victory_layer = CanvasLayer.new()
	_victory_layer.layer = 70
	_victory_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_victory_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_victory_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)
	var t := Label.new()
	t.text = "THE GREAT KEEP IS YOURS"
	t.add_theme_font_size_override("font_size", 48)
	t.add_theme_color_override("font_color", Color(1.0, 0.88, 0.5))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var m := int(G.elapsed) / 60
	var s := int(G.elapsed) % 60
	var tl := Label.new()
	tl.text = "Your time: %d:%02d" % [m, s]
	tl.add_theme_font_size_override("font_size", 28)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tl)
	if first:
		var note := Label.new()
		note.text = "Your time has been recorded on the shared leaderboard."
		note.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(note)
	var b1 := Button.new()
	b1.text = "View Leaderboard"
	b1.custom_minimum_size = Vector2(300, 52)
	b1.pressed.connect(_open_board)
	vb.add_child(b1)
	var b2 := Button.new()
	b2.text = "Keep Exploring"
	b2.custom_minimum_size = Vector2(300, 52)
	b2.pressed.connect(func() -> void:
		if _victory_layer != null:
			_victory_layer.queue_free()
			_victory_layer = null)
	vb.add_child(b2)


func _open_board() -> void:
	board.open_panel()


# ---------------- save ----------------
func _save() -> void:
	if player == null:
		return
	G.save_remote(player.global_position, cam.yaw)
