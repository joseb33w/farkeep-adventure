class_name KeepGate
extends Interactable

signal gate_opened(id: String)
signal need_key()

var gate_id := "keep_gate"
var locked := true
var _slab: MeshInstance3D
var _body: StaticBody3D


func _setup() -> void:
	reach = 5.5
	_build_pillar(Vector3(-2.7, 0.0, 0.0))
	_build_pillar(Vector3(2.7, 0.0, 0.0))
	var lintel := _box(Vector3(6.4, 0.9, 1.4), Color(0.46, 0.44, 0.42))
	add_child(lintel)
	lintel.position = Vector3(0.0, 5.4, 0.0)
	_slab = _box(Vector3(4.6, 5.0, 0.5), Color(0.22, 0.17, 0.13))
	var sm := _slab.get_surface_override_material(0) as StandardMaterial3D
	if sm != null:
		sm.metallic = 0.6
		sm.roughness = 0.5
		sm.emission_enabled = true
		sm.emission = Color(0.8, 0.5, 0.15)
		sm.emission_energy_multiplier = 0.6
	add_child(_slab)
	_slab.position = Vector3(0.0, 2.6, 0.0)
	Style.apply_outline(_slab, 0.03)
	_body = StaticBody3D.new()
	_body.set_collision_layer_value(1, true)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.6, 5.0, 0.7)
	cs.shape = box
	cs.position = Vector3(0.0, 2.6, 0.0)
	_body.add_child(cs)
	add_child(_body)


func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	mi.set_surface_override_material(0, m)
	return mi


func _build_pillar(off: Vector3) -> void:
	var p := _box(Vector3(1.4, 6.2, 1.4), Color(0.5, 0.48, 0.45))
	add_child(p)
	p.position = off + Vector3(0.0, 3.1, 0.0)
	Style.apply_outline(p, 0.03)
	var b := StaticBody3D.new()
	b.set_collision_layer_value(1, true)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 6.2, 1.4)
	cs.shape = box
	b.add_child(cs)
	add_child(b)
	b.position = off + Vector3(0.0, 3.1, 0.0)


func get_prompt() -> String:
	if not locked:
		return ""
	if G.has_key():
		return "Open Gate"
	return "Locked"


func can_interact() -> bool:
	return locked


func do_interact(_player: Node3D) -> void:
	if not locked:
		return
	if not G.has_key():
		need_key.emit()
		return
	_open(true)
	gate_opened.emit(gate_id)


func set_open_immediate() -> void:
	_open(false)


func _open(animate: bool) -> void:
	locked = false
	G.mark_gate_opened(gate_id)
	_body.set_collision_layer_value(1, false)
	if animate:
		var tw := _slab.create_tween()
		tw.tween_property(_slab, "position:y", 8.4, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		Fx.burst(get_parent(), global_position + Vector3(0.0, 2.6, 0.0), Color(1.0, 0.9, 0.4), 28)
	else:
		_slab.position.y = 8.4
