class_name Fx
extends RefCounted
## Stateless JUICE helpers: particle bursts + material flashes.

static func burst(parent: Node, gpos: Vector3, color: Color, amount: int = 16) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.55
	p.explosiveness = 0.92
	p.direction = Vector3.UP
	p.spread = 75.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 6.0
	p.gravity = Vector3(0.0, -11.0, 0.0)
	p.scale_amount_min = 0.10
	p.scale_amount_max = 0.22
	var box := BoxMesh.new()
	box.size = Vector3(0.16, 0.16, 0.16)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material = mat
	p.mesh = box
	parent.add_child(p)
	p.global_position = gpos
	p.emitting = true
	var tree := parent.get_tree()
	if tree != null:
		var t := tree.create_timer(1.0)
		t.timeout.connect(p.queue_free)


static func flash(model_root: Node3D, color: Color = Color(1, 1, 1), dur: float = 0.12) -> void:
	if model_root == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.4
	var meshes: Array = model_root.find_children("*", "MeshInstance3D", true, false)
	for mi: MeshInstance3D in meshes:
		mi.material_override = mat
	var tree := model_root.get_tree()
	if tree != null:
		var t := tree.create_timer(dur)
		t.timeout.connect(func() -> void:
			for mi2: MeshInstance3D in meshes:
				if is_instance_valid(mi2):
					mi2.material_override = null)
