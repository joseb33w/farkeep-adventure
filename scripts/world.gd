class_name World
extends Node3D
## Builds the entire seamless world in one scene: forest -> walled town -> great keep.

const MON_PATH := "res://models/monument.glb"

var spawn_point := Vector3(0.0, 1.6, 36.0)
var chests: Array = []
var npcs: Array = []
var keep_gate: KeepGate = null
var win_zone: WinZone = null
var key_chest_id := "guardhouse_chest"

var _rng := RandomNumberGenerator.new()


func build() -> void:
	_rng.seed = 20260624
	_build_environment()
	_build_ground()
	_build_path()
	_build_forest()
	_build_town_walls()
	_build_town_buildings()
	_build_monument()
	_build_tavern()
	_build_guardhouse()
	_build_townsfolk()
	_build_guards()
	_build_chests()
	_build_keep_area()
	_build_bounds()


func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/hdri_sky.gdshader")
	var tex: Texture2D = load("res://models/sky.hdr")
	sm.set_shader_parameter("panorama", tex)
	sm.set_shader_parameter("exposure", 1.0)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.74, 0.80, 0.86)
	env.fog_density = 0.012
	env.fog_sky_affect = 0.2
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -38.0, 0.0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.96, 0.86)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30.0, 140.0, 0.0)
	fill.light_energy = 0.25
	fill.light_color = Color(0.6, 0.7, 0.85)
	add_child(fill)


func _build_ground() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(220.0, 220.0)
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.33, 0.46, 0.24)
	m.roughness = 0.95
	mi.set_surface_override_material(0, m)
	add_child(mi)
	mi.position = Vector3(0.0, 0.0, -10.0)
	var body := StaticBody3D.new()
	body.set_collision_layer_value(1, true)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(220.0, 1.0, 220.0)
	cs.shape = box
	cs.position = Vector3(0.0, -0.5, 0.0)
	body.add_child(cs)
	mi.add_child(body)


func _build_path() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6.5, 92.0)
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.36, 0.24)
	m.roughness = 1.0
	mi.set_surface_override_material(0, m)
	add_child(mi)
	mi.position = Vector3(0.0, 0.04, -8.0)


func _build_forest() -> void:
	var trees := ["res://models/tree_1.glb", "res://models/tree_2.glb", "res://models/tree_3.glb"]
	for i in 60:
		var x := _rng.randf_range(-52.0, 52.0)
		var z := _rng.randf_range(-30.0, 64.0)
		if absf(x) < 5.0 and z < 40.0:
			continue
		if absf(x) < 24.0 and z > -20.0 and z < 20.0:
			continue
		var t := (load(trees[_rng.randi() % 3]) as PackedScene).instantiate() as Node3D
		add_child(t)
		t.scale = Vector3.ONE * _rng.randf_range(1.1, 1.9)
		t.rotation.y = _rng.randf() * TAU
		t.position = Vector3(x, 0.0, z)
	_scatter_mm("res://models/bush_1.glb", 40, -54.0, 54.0, -32.0, 64.0)
	_scatter_mm("res://models/grass.glb", 220, -54.0, 54.0, -30.0, 64.0)


func _scatter_mm(path: String, count: int, x0: float, x1: float, z0: float, z1: float) -> void:
	var src := (load(path) as PackedScene).instantiate() as Node3D
	var found := src.find_children("*", "MeshInstance3D", true, false)
	if found.is_empty():
		src.free()
		return
	var mesh: Mesh = (found[0] as MeshInstance3D).mesh
	src.free()
	if mesh == null:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var n := 0
	for i in count:
		var x := _rng.randf_range(x0, x1)
		var z := _rng.randf_range(z0, z1)
		if absf(x) < 23.0 and z > -19.0 and z < 19.0:
			x += 30.0 * signf(x)
		var s := _rng.randf_range(0.8, 1.6)
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * s)
		mm.set_instance_transform(n, Transform3D(b, Vector3(x, 0.0, z)))
		n += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)


func _build_town_walls() -> void:
	var wall := "res://models/wall_straight.glb"
	var ws := 2.2
	for zc in [18.0, -18.0]:
		for xc in [-18.0, -12.0, -6.0, 6.0, 12.0, 18.0]:
			_place(wall, Vector3(xc, 0.0, zc), 0.0, ws, true, false)
		_place("res://models/wall_gate.glb", Vector3(0.0, 0.0, zc), 0.0, ws, false, true)
		_cam_blocker(Vector3(0.0, 0.0, zc))
	for xc in [-22.0, 22.0]:
		for zc in [-15.0, -9.0, -3.0, 3.0, 9.0, 15.0]:
			_place(wall, Vector3(xc, 0.0, zc), 90.0, ws, true, false)
	for c in [Vector2(-22, 18), Vector2(22, 18), Vector2(-22, -18), Vector2(22, -18)]:
		_place("res://models/building_tower.glb", Vector3(c.x, 0.0, c.y), 0.0, 3.5, true, true)


func _build_town_buildings() -> void:
	var b := 4.0
	_place("res://models/building_church.glb", Vector3(-14.0, 0.0, -12.0), 35.0, 4.5, true, true)
	_place("res://models/building_blacksmith.glb", Vector3(14.0, 0.0, -12.0), -35.0, b, true, true)
	_place("res://models/building_market.glb", Vector3(-15.0, 0.0, 10.0), 80.0, b, true, true)
	_place("res://models/building_home_A.glb", Vector3(15.0, 0.0, 11.0), -80.0, b, true, true)
	_place("res://models/building_home_B.glb", Vector3(-18.0, 0.0, 0.0), 90.0, b, true, true)
	_place("res://models/building_tavern.glb", Vector3(17.0, 0.0, -5.0), -100.0, b, true, true)
	_place("res://models/building_well.glb", Vector3(8.0, 0.0, 7.0), 0.0, 3.0, true, true)


func _build_monument() -> void:
	var plaza := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 7.0
	cyl.bottom_radius = 7.0
	cyl.height = 0.3
	plaza.mesh = cyl
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.62, 0.6, 0.56)
	pm.roughness = 0.9
	plaza.set_surface_override_material(0, pm)
	add_child(plaza)
	plaza.position = Vector3(0.0, 0.06, 0.0)

	var ps: Resource = load(MON_PATH)
	if ps != null:
		var mon := (ps as PackedScene).instantiate() as Node3D
		add_child(mon)
		var raw := _local_aabb(mon)
		var s := 1.0
		if raw.size.y > 0.01:
			s = clampf(6.0 / raw.size.y, 0.05, 30.0)
		mon.scale = Vector3.ONE * s
		mon.rotation.y = 0.0
		mon.global_position = Vector3(0.0, 0.2, 0.0)
		Style.apply_outline(mon, 0.02)
		_add_box_collider(mon, 0.7)
	else:
		var ob := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.6, 6.0, 1.6)
		ob.mesh = bm
		var om := StandardMaterial3D.new()
		om.albedo_color = Color(0.7, 0.66, 0.5)
		ob.set_surface_override_material(0, om)
		add_child(ob)
		ob.position = Vector3(0.0, 3.0, 0.0)
		Style.apply_outline(ob, 0.03)
		_add_box_collider(ob, 0.9)


func _build_tavern() -> void:
	var c := Vector3(-9.0, 0.0, 7.0)
	_room(c, 8.0, 8.0, 0.0)
	_place("res://models/barrel.glb", c + Vector3(-2.5, 0.0, -2.5), 0.0, 1.0, false, true)
	_place("res://models/barrel.glb", c + Vector3(2.5, 0.0, -2.0), 0.0, 1.0, false, true)
	_place("res://models/bench.glb", c + Vector3(0.0, 0.0, -2.6), 90.0, 1.0, false, false)
	_torch(c + Vector3(-3.6, 0.0, 0.0))
	_torch(c + Vector3(3.6, 0.0, 0.0))
	var ch: Chest = Chest.new()
	ch.chest_id = "tavern_chest"
	ch.coins = 10
	add_child(ch)
	ch.global_position = c + Vector3(2.6, 0.0, 2.0)
	chests.append(ch)


func _build_guardhouse() -> void:
	var c := Vector3(12.0, 0.0, 2.0)
	_room(c, 8.0, 8.0, -90.0)
	_place("res://models/banner.glb", c + Vector3(0.0, 0.0, -3.4), 0.0, 2.4, false, false)
	_torch(c + Vector3(-3.4, 0.0, -2.0))
	var ch: Chest = Chest.new()
	ch.chest_id = key_chest_id
	ch.is_key_chest = true
	add_child(ch)
	ch.global_position = c + Vector3(0.0, 0.0, -2.4)
	chests.append(ch)


func _build_townsfolk() -> void:
	_npc("Innkeeper Bram", "res://models/kk_Mage.glb", Vector3(-9.0, 0.0, 5.0),
		"You are Bram, the warm, talkative innkeeper of the Far Keep tavern in the walled town of Vellmoor. You know the townsfolk, the guards who serve the keep's lord, and rumors that the key to the keep's locked gate is hidden in a chest in the guardhouse. Speak in a friendly, folksy medieval style. Keep replies to 1-3 sentences.",
		"Welcome in, traveler! Pull up a stool. You look like someone bound for the Great Keep.")
	_npc("Mira the Trader", "res://models/kk_Ranger.glb", Vector3(-12.0, 0.0, 9.0),
		"You are Mira, a sharp, practical traveling trader in the market of Vellmoor. You sell trinkets and gossip. You warn travelers that the keep's guards are hostile to outsiders and that you'll need a key to open the keep's gate. Speak briskly and a little wry. Keep replies to 1-3 sentences.",
		"Buying or just browsing? Careful past the back gate -- the guards don't take kindly to wanderers.")
	_npc("The Hooded Stranger", "res://models/kk_Rogue_Hooded.glb", Vector3(8.0, 0.0, 4.0),
		"You are a mysterious hooded stranger lingering by the well in Vellmoor. You speak in cryptic, intriguing hints. You know the key to the keep lies behind a guard in the guardhouse, and that the Great Keep stands at the far edge of the land. Keep replies to 1-3 sentences and stay enigmatic.",
		"...You seek the keep. The key sleeps where steel keeps watch. Mind the guards.")


func _build_guards() -> void:
	_guard(Vector3(12.0, 0.0, 0.0))
	_guard(Vector3(-3.0, 0.0, -10.0))
	_guard(Vector3(4.0, 0.0, -14.0))


func _build_chests() -> void:
	var c1: Chest = Chest.new()
	c1.chest_id = "forest_chest"
	c1.coins = 6
	add_child(c1)
	c1.global_position = Vector3(9.0, 0.0, 28.0)
	chests.append(c1)
	var c2: Chest = Chest.new()
	c2.chest_id = "well_chest"
	c2.coins = 8
	add_child(c2)
	c2.global_position = Vector3(5.0, 0.0, 1.0)
	chests.append(c2)


func _build_keep_area() -> void:
	for z in [-24.0, -30.0, -36.0]:
		_torch(Vector3(-4.5, 0.0, z))
		_torch(Vector3(4.5, 0.0, z))
	keep_gate = KeepGate.new()
	add_child(keep_gate)
	keep_gate.global_position = Vector3(0.0, 0.0, -40.0)
	for xc in [-7.0, -11.0, 7.0, 11.0]:
		_place("res://models/wall_straight.glb", Vector3(xc, 0.0, -40.0), 0.0, 3.5, true, false)
	_place("res://models/building_castle.glb", Vector3(0.0, 0.0, -58.0), 0.0, 6.5, true, true)
	_place("res://models/building_tower.glb", Vector3(-12.0, 0.0, -56.0), 0.0, 5.0, true, true)
	_place("res://models/building_tower.glb", Vector3(12.0, 0.0, -56.0), 0.0, 5.0, true, true)
	win_zone = WinZone.new()
	add_child(win_zone)
	win_zone.global_position = Vector3(0.0, 0.0, -48.0)
	var beacon := OmniLight3D.new()
	beacon.light_color = Color(1.0, 0.85, 0.4)
	beacon.light_energy = 4.0
	beacon.omni_range = 18.0
	add_child(beacon)
	beacon.position = Vector3(0.0, 14.0, -48.0)


func _build_bounds() -> void:
	for spec in [Vector3(0, 0, 66), Vector3(0, 0, -72), Vector3(-58, 0, 0), Vector3(58, 0, 0)]:
		var body := StaticBody3D.new()
		body.set_collision_layer_value(1, true)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var along_z: bool = absf(spec.x) > absf(spec.z)
		box.size = Vector3(2.0, 12.0, 150.0) if along_z else Vector3(130.0, 12.0, 2.0)
		cs.shape = box
		body.add_child(cs)
		add_child(body)
		body.global_position = spec + Vector3(0.0, 6.0, 0.0)


func _place(path: String, pos: Vector3, yaw_deg: float, s: float, collide: bool, outline: bool) -> Node3D:
	var ps: Resource = load(path)
	if ps == null:
		return null
	var m := (ps as PackedScene).instantiate() as Node3D
	add_child(m)
	m.scale = Vector3.ONE * s
	m.rotation.y = deg_to_rad(yaw_deg)
	m.global_position = pos
	if outline:
		Style.apply_outline(m, 0.015)
	if collide:
		_add_box_collider(m, 0.92)
	return m


func _room(center: Vector3, w: float, d: float, door_yaw_deg: float) -> void:
	for fx in [-2.0, 2.0]:
		for fz in [-2.0, 2.0]:
			_place("res://models/floor_wood.glb", center + Vector3(fx, 0.0, fz), 0.0, 1.0, false, false)
	var door_dir := Vector3(sin(deg_to_rad(door_yaw_deg)), 0.0, cos(deg_to_rad(door_yaw_deg)))
	var sides := [
		{"n": Vector3(0, 0, 1), "yaw": 0.0, "off": Vector3(0, 0, d * 0.5)},
		{"n": Vector3(0, 0, -1), "yaw": 180.0, "off": Vector3(0, 0, -d * 0.5)},
		{"n": Vector3(1, 0, 0), "yaw": 90.0, "off": Vector3(w * 0.5, 0, 0)},
		{"n": Vector3(-1, 0, 0), "yaw": -90.0, "off": Vector3(-w * 0.5, 0, 0)},
	]
	for sd in sides:
		var n: Vector3 = sd["n"]
		var yaw: float = sd["yaw"]
		var off: Vector3 = sd["off"]
		var tangent := Vector3(n.z, 0.0, -n.x)
		var is_door: bool = n.dot(door_dir) > 0.7
		for k: float in [-2.0, 2.0]:
			var p: Vector3 = center + off + tangent * k
			if is_door and k == 2.0:
				_place("res://models/d_wall_doorway.glb", p, yaw, 1.0, false, false)
				_wall_collider(p, yaw)
			else:
				_place("res://models/d_wall.glb", p, yaw, 1.0, true, false)


func _wall_collider(pos: Vector3, yaw_deg: float) -> void:
	var side := Vector3(cos(deg_to_rad(yaw_deg)), 0.0, -sin(deg_to_rad(yaw_deg)))
	for sx: float in [-1.4, 1.4]:
		var body := StaticBody3D.new()
		body.set_collision_layer_value(1, true)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.2, 4.0, 1.0)
		cs.shape = box
		body.add_child(cs)
		add_child(body)
		body.global_position = pos + side * sx + Vector3(0.0, 2.0, 0.0)


func _cam_blocker(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.set_collision_layer_value(1, false)
	body.set_collision_layer_value(5, true)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.5, 6.0, 1.6)
	cs.shape = box
	body.add_child(cs)
	add_child(body)
	body.global_position = pos + Vector3(0.0, 3.0, 0.0)


func _torch(pos: Vector3) -> void:
	var t := _place("res://models/torch.glb", pos, 0.0, 1.4, false, false)
	var o := OmniLight3D.new()
	o.light_color = Color(1.0, 0.7, 0.35)
	o.light_energy = 2.6
	o.omni_range = 7.0
	add_child(o)
	o.global_position = pos + Vector3(0.0, 1.8, 0.0)


func _npc(nm: String, model: String, pos: Vector3, persona: String, opening: String) -> void:
	var n: Npc = Npc.new()
	n.npc_name = nm
	n.model_path = model
	n.persona = persona
	n.opening = opening
	add_child(n)
	n.global_position = pos
	npcs.append(n)


func _guard(pos: Vector3) -> void:
	var g: Guard = Guard.new()
	g.home = pos
	add_child(g)
	g.global_position = pos


func _add_box_collider(model: Node3D, shrink: float) -> void:
	var aabb := _local_aabb(model)
	if aabb.size == Vector3.ZERO:
		return
	var body := StaticBody3D.new()
	body.set_collision_layer_value(1, true)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size * shrink
	col.shape = box
	col.position = aabb.get_center()
	body.add_child(col)
	model.add_child(body)


func _local_aabb(model: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var inv := model.global_transform.affine_inverse()
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var a := mi.mesh.get_aabb()
		var rel := inv * mi.global_transform
		a = rel * a
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out
