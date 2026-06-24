class_name Chest
extends Interactable

signal opened_chest(chest_id: String, is_key: bool, coins: int)

var chest_id := "chest"
var is_key_chest := false
var coins := 8
var opened := false

var _model: Node3D


func _setup() -> void:
	reach = 3.0
	_model = (load("res://models/chest.glb") as PackedScene).instantiate() as Node3D
	add_child(_model)
	Style.apply_outline(_model, 0.02)
	if is_key_chest:
		var omni := OmniLight3D.new()
		omni.light_color = Color(1.0, 0.85, 0.35)
		omni.light_energy = 2.2
		omni.omni_range = 5.0
		omni.position = Vector3(0.0, 1.2, 0.0)
		add_child(omni)


func get_prompt() -> String:
	if opened:
		return ""
	return "Open Chest"


func can_interact() -> bool:
	return not opened


func mark_opened_silent() -> void:
	opened = true
	if _model != null:
		_model.rotation.x = -0.2


func do_interact(_player: Node3D) -> void:
	if opened:
		return
	opened = true
	var tw := _model.create_tween()
	tw.tween_property(_model, "scale", Vector3(1.18, 1.22, 1.18), 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_model, "scale", Vector3.ONE, 0.18)
	Fx.burst(get_parent(), global_position + Vector3(0.0, 1.0, 0.0), Color(1.0, 0.84, 0.3), 22)
	if is_key_chest:
		_float_reward("res://models/key.glb", Color(1.0, 0.85, 0.3))
		G.give_key()
	else:
		_float_reward("res://models/coin_stack.glb", Color(1.0, 0.82, 0.3))
		G.add_coins(coins)
	opened_chest.emit(chest_id, is_key_chest, coins)


func _float_reward(path: String, _c: Color) -> void:
	var ps: Resource = load(path)
	if ps == null:
		return
	var r := (ps as PackedScene).instantiate() as Node3D
	get_parent().add_child(r)
	r.global_position = global_position + Vector3(0.0, 1.1, 0.0)
	r.scale = Vector3(0.6, 0.6, 0.6)
	var tw := r.create_tween()
	tw.set_parallel(true)
	tw.tween_property(r, "position:y", r.position.y + 2.2, 1.1)
	tw.tween_property(r, "scale", Vector3(1.3, 1.3, 1.3), 1.1)
	tw.chain().tween_callback(r.queue_free)
