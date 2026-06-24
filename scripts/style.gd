class_name Style
extends RefCounted
## Cel-look helpers: inverted-hull ink outline + robust character recolor.

const OUTLINE := preload("res://shaders/outline.gdshader")


static func apply_outline(root: Node3D, width: float = 0.022, color: Color = Color(0.05, 0.04, 0.06)) -> void:
	for m: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null:
			continue
		var count: int = max(1, m.mesh.get_surface_count())
		for s in range(count):
			var base: Material = m.get_active_material(s)
			var mat: Material = base.duplicate() if base != null else StandardMaterial3D.new()
			var sh := ShaderMaterial.new()
			sh.shader = OUTLINE
			sh.set_shader_parameter("outline", width)
			sh.set_shader_parameter("col", color)
			mat.next_pass = sh
			m.set_surface_override_material(s, mat)


static func recolor(root: Node3D, tint: Color) -> void:
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for s in range(max(1, mi.mesh.get_surface_count())):
			var base: Material = mi.get_active_material(s)
			var m := (base.duplicate() if base != null else StandardMaterial3D.new()) as StandardMaterial3D
			if m == null:
				continue
			m.albedo_color = tint
			mi.set_surface_override_material(s, m)
