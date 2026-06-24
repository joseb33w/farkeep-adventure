extends Node
## Autoload "G": global game state + Supabase bridge (via web/bridge.js).

signal save_loaded(data: Dictionary)
signal leaderboard_loaded(rows: Array)
signal inventory_changed()

var user_id: String = "local-dev"
var display_name: String = "Wanderer"
var inventory: Dictionary = {"coins": 0, "keep_key": false}
var opened_gates: Array = []
var elapsed: float = 0.0
var reached_keep: bool = false
var player: Node3D = null
var cam: Node = null

var _fk = null
var _cb_load = null
var _cb_save = null
var _cb_score = null
var _cb_lb = null


func _ready() -> void:
	if OS.has_feature("web"):
		_fk = JavaScriptBridge.get_interface("farkeep")
	if _fk != null:
		user_id = str(_fk.getUserId())
		var n: String = str(_fk.getName())
		if n != "":
			display_name = n
		_cb_load = JavaScriptBridge.create_callback(_on_load)
		_cb_save = JavaScriptBridge.create_callback(_on_save)
		_cb_score = JavaScriptBridge.create_callback(_on_score)
		_cb_lb = JavaScriptBridge.create_callback(_on_lb)


func has_key() -> bool:
	return bool(inventory.get("keep_key", false))


func add_coins(n: int) -> void:
	inventory["coins"] = int(inventory.get("coins", 0)) + n
	inventory_changed.emit()


func give_key() -> void:
	inventory["keep_key"] = true
	inventory_changed.emit()


func mark_gate_opened(id: String) -> void:
	if not opened_gates.has(id):
		opened_gates.append(id)


func set_player_name(n: String) -> void:
	var clean := n.strip_edges()
	if clean == "":
		clean = "Wanderer"
	display_name = clean.substr(0, 18)
	if _fk != null:
		_fk.setName(display_name)


func load_remote() -> void:
	if _fk != null:
		_fk.load(_cb_load)
	else:
		save_loaded.emit({})


func save_remote(pos: Vector3, yaw: float) -> void:
	if _fk == null:
		return
	var inv_json: String = JSON.stringify(inventory)
	var gates_json: String = JSON.stringify(opened_gates)
	_fk.save(display_name, pos.x, pos.y, pos.z, yaw, inv_json, gates_json, elapsed, reached_keep, _cb_save)


func submit_score(time_sec: float) -> void:
	if _fk != null:
		_fk.submitScore(display_name, time_sec, _cb_score)


func fetch_leaderboard() -> void:
	if _fk != null:
		_fk.leaderboard(_cb_lb)
	else:
		leaderboard_loaded.emit([])


func _parse(args: Array) -> Dictionary:
	if args.is_empty():
		return {}
	var raw: String = str(args[0])
	if raw == "":
		return {}
	var v: Variant = JSON.parse_string(raw)
	return v if v is Dictionary else {}


func _on_load(args: Array) -> void:
	var d: Dictionary = _parse(args)
	var save_data: Dictionary = {}
	if bool(d.get("ok", false)) and d.get("save", null) != null:
		var s: Variant = d["save"]
		if s is Dictionary:
			save_data = s
	save_loaded.emit(save_data)


func _on_save(_args: Array) -> void:
	pass


func _on_score(_args: Array) -> void:
	pass


func _on_lb(args: Array) -> void:
	var d: Dictionary = _parse(args)
	var rows: Array = []
	var r: Variant = d.get("rows", [])
	if r is Array:
		rows = r
	leaderboard_loaded.emit(rows)
