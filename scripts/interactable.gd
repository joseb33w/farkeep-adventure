class_name Interactable
extends Area3D
## Base for proximity interactables. An Area3D (mask = player layer 2) tracks whether the
## player is in reach; main.gd picks the nearest in-range interactable for the HUD prompt.

var reach := 2.8
var _player_near := false


func _ready() -> void:
	add_to_group("interactable")
	set_collision_layer_value(4, true)
	set_collision_mask_value(2, true)
	monitoring = true
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = reach
	cs.shape = sph
	cs.position = Vector3(0.0, 1.0, 0.0)
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_setup()


func _setup() -> void:
	pass


func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true


func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false


func is_near() -> bool:
	return _player_near


func get_prompt() -> String:
	return "Interact"


func can_interact() -> bool:
	return true


func do_interact(_player: Node3D) -> void:
	pass
