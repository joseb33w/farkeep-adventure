class_name Npc
extends Interactable

signal talk_requested(npc: Npc)

var npc_name := "Townsfolk"
var persona := ""
var opening := ""
var model_path := "res://models/kk_Mage.glb"
var history: Array = []

var _model: Node3D
var _anim: AnimationPlayer


func _setup() -> void:
	reach = 3.0
	_model = (load(model_path) as PackedScene).instantiate() as Node3D
	add_child(_model)
	_anim = AnimRig.attach(_model,
		["res://models/anim_general.glb", "res://models/anim_move.glb"], ["Idle_A", "Walking_A"])
	Style.apply_outline(_model)
	if _anim.has_animation("Idle_A"):
		_anim.play("Idle_A")
		_anim.seek(randf() * 1.5, true)
	var tag := Label3D.new()
	tag.text = npc_name
	tag.font_size = 44
	tag.pixel_size = 0.011
	tag.position = Vector3(0.0, 2.35, 0.0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color(1.0, 0.94, 0.68)
	tag.outline_size = 10
	tag.outline_modulate = Color(0.1, 0.08, 0.06)
	add_child(tag)


func _process(_delta: float) -> void:
	if _player_near and _model != null and G.player != null and is_instance_valid(G.player):
		var to := (G.player as Node3D).global_position - global_position
		to.y = 0.0
		if to.length() > 0.25:
			_model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z), 0.15)


func get_prompt() -> String:
	return "Talk to %s" % npc_name


func do_interact(_player: Node3D) -> void:
	talk_requested.emit(self)
