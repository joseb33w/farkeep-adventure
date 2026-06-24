class_name CamRig
extends Node3D
## Third-person follow camera: rotates by yaw/pitch, pulls in on world collision, supports shake.

var target: Node3D = null
var yaw := 0.0
var pitch := -0.34
var dist := 6.8
var height := 1.65

var _cam: Camera3D
var _ray: RayCast3D
var _shake := 0.0


func _ready() -> void:
	_ray = RayCast3D.new()
	_ray.enabled = true
	_ray.hit_from_inside = true
	_ray.set_collision_mask_value(1, true)
	_ray.set_collision_mask_value(5, true)
	_ray.target_position = Vector3(0.0, 0.0, dist)
	add_child(_ray)
	_cam = Camera3D.new()
	_cam.current = true
	_cam.fov = 70.0
	_cam.position = Vector3(0.0, 0.0, dist)
	add_child(_cam)


func set_target(t: Node3D) -> void:
	target = t
	if t != null:
		global_position = t.global_position + Vector3(0.0, height, 0.0)


func _process(delta: float) -> void:
	if target != null and is_instance_valid(target):
		var tp := target.global_position + Vector3(0.0, height, 0.0)
		global_position = global_position.lerp(tp, 1.0 - exp(-16.0 * delta))
	pitch = clampf(pitch, -1.15, 0.18)
	rotation = Vector3(pitch, yaw, 0.0)
	var want_z := dist
	if _ray.is_colliding():
		var cp := _ray.get_collision_point()
		want_z = clampf(global_position.distance_to(cp) - 0.3, 0.8, dist)
	var sx := 0.0
	var sy := 0.0
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 2.4)
		var amt := _shake * 0.14
		sx = randf_range(-amt, amt)
		sy = randf_range(-amt, amt)
	_cam.position = Vector3(sx, sy, want_z)


func shake(amount: float) -> void:
	_shake = minf(1.2, _shake + amount)


func add_look(dx: float, dy: float) -> void:
	yaw -= dx
	pitch -= dy
