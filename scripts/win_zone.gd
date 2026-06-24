class_name WinZone
extends Area3D

signal reached()

var _done := false


func _ready() -> void:
	set_collision_layer_value(4, true)
	set_collision_mask_value(2, true)
	monitoring = true
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(9.0, 7.0, 9.0)
	cs.shape = box
	cs.position = Vector3(0.0, 3.5, 0.0)
	add_child(cs)
	body_entered.connect(_on_enter)


func _on_enter(body: Node) -> void:
	if _done:
		return
	if body.is_in_group("player"):
		_done = true
		reached.emit()
