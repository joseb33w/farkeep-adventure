class_name Player
extends CharacterBody3D

signal hp_changed(hp: float, max_hp: float)
signal died()

const WALK_SPEED := 3.6
const RUN_SPEED := 6.6
const ACCEL := 13.0
const GRAVITY := 26.0
const ATTACK_RANGE := 3.0
const ATTACK_DAMAGE := 40.0
const ATTACK_COOLDOWN := 0.55
const STRIKE_AT := 0.22

var max_hp := 100.0
var hp := 100.0
var move_input := Vector2.ZERO   # x = right, y = forward(+)
var cam_yaw := 0.0
var alive := true

var _model: Node3D
var _anim: AnimationPlayer
var _yaw := 0.0
var _attack_t := 0.0
var _strike_done := true
var _hurt_t := 0.0
var _cur := ""


func _ready() -> void:
	add_to_group("player")
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	var cap := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.7
	cap.shape = shape
	cap.position = Vector3(0.0, 0.9, 0.0)
	add_child(cap)
	_model = (load("res://models/kk_Barbarian.glb") as PackedScene).instantiate() as Node3D
	add_child(_model)
	_anim = AnimRig.attach(_model,
		["res://models/anim_general.glb", "res://models/anim_move.glb", "res://models/anim_combat.glb"],
		["Idle_A", "Walking_A", "Running_A"])
	Style.apply_outline(_model)
	_play("Idle_A")
	hp_changed.emit(hp, max_hp)


func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if _attack_t > 0.0:
		_attack_t -= delta
		if not _strike_done and _attack_t <= (ATTACK_COOLDOWN - STRIKE_AT):
			_strike_done = true
			_strike()
	if _hurt_t > 0.0:
		_hurt_t -= delta

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -1.5

	var planar := move_input
	if planar.length() > 1.0:
		planar = planar.normalized()
	var mag := planar.length()
	var dir := Basis(Vector3.UP, cam_yaw) * Vector3(planar.x, 0.0, -planar.y)
	dir.y = 0.0
	var speed := 0.0
	if mag > 0.05:
		dir = dir.normalized()
		speed = RUN_SPEED if mag > 0.7 else WALK_SPEED
		var target_yaw := atan2(dir.x, dir.z)
		_yaw = lerp_angle(_yaw, target_yaw, 1.0 - exp(-12.0 * delta))
		_model.rotation.y = _yaw
	else:
		dir = Vector3.ZERO

	var hvel := Vector3(velocity.x, 0.0, velocity.z)
	hvel = hvel.lerp(dir * speed, 1.0 - exp(-ACCEL * delta))
	velocity.x = hvel.x
	velocity.z = hvel.z
	move_and_slide()
	_update_anim(mag, speed)


func _update_anim(mag: float, speed: float) -> void:
	if _attack_t > 0.0:
		return
	var want := "Idle_A"
	if mag > 0.05:
		want = "Running_A" if speed >= RUN_SPEED else "Walking_A"
	_play(want)


func _play(clip: String, speed := 1.0) -> void:
	if _anim == null or not _anim.has_animation(clip):
		return
	if _cur == clip and _anim.is_playing():
		return
	_cur = clip
	_anim.play(clip, 0.15, speed)


func attack() -> void:
	if not alive or _attack_t > 0.0:
		return
	var tgt := _nearest_guard(ATTACK_RANGE + 1.2)
	if tgt != null:
		var to := tgt.global_position - global_position
		to.y = 0.0
		if to.length() > 0.1:
			_yaw = atan2(to.x, to.z)
			_model.rotation.y = _yaw
	_attack_t = ATTACK_COOLDOWN
	_strike_done = false
	if _anim != null and _anim.has_animation("Melee_1H_Attack_Chop"):
		_anim.play("Melee_1H_Attack_Chop", 0.08)
		_cur = "Melee_1H_Attack_Chop"


func _strike() -> void:
	var forward := Vector3(sin(_yaw), 0.0, cos(_yaw))
	var hit_any := false
	for g in get_tree().get_nodes_in_group("guard"):
		var guard := g as Node3D
		if guard == null or not is_instance_valid(guard):
			continue
		if not guard.has_method("take_damage") or not bool(guard.get("alive")):
			continue
		var to := guard.global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d <= ATTACK_RANGE and d > 0.05 and forward.dot(to / d) > 0.15:
			guard.call("take_damage", ATTACK_DAMAGE, global_position)
			Fx.burst(get_parent(), guard.global_position + Vector3(0.0, 1.2, 0.0), Color(1.0, 0.86, 0.32))
			hit_any = true
	if hit_any:
		if G.cam != null and G.cam.has_method("shake"):
			G.cam.shake(0.35)
	else:
		Fx.burst(get_parent(), global_position + forward * 1.5 + Vector3(0.0, 1.2, 0.0), Color(0.82, 0.88, 0.98), 8)


func take_damage(dmg: float, from_pos: Vector3) -> void:
	if not alive or _hurt_t > 0.0:
		return
	hp = maxf(0.0, hp - dmg)
	_hurt_t = 0.45
	hp_changed.emit(hp, max_hp)
	Fx.flash(_model, Color(1.0, 0.35, 0.35), 0.12)
	if G.cam != null and G.cam.has_method("shake"):
		G.cam.shake(0.5)
	var kb := global_position - from_pos
	kb.y = 0.0
	if kb.length() > 0.1:
		velocity += kb.normalized() * 4.5
	if hp <= 0.0:
		_die()


func _die() -> void:
	alive = false
	if _anim != null and _anim.has_animation("Death_A"):
		_anim.play("Death_A", 0.1)
		_cur = "Death_A"
	died.emit()


func respawn(at: Vector3) -> void:
	hp = max_hp
	alive = true
	_attack_t = 0.0
	_hurt_t = 0.0
	velocity = Vector3.ZERO
	global_position = at
	hp_changed.emit(hp, max_hp)
	_play("Idle_A")


func _nearest_guard(rng: float) -> Node3D:
	var best: Node3D = null
	var bd := rng
	for g in get_tree().get_nodes_in_group("guard"):
		var guard := g as Node3D
		if not is_instance_valid(guard) or not bool(guard.get("alive")):
			continue
		var d := guard.global_position.distance_to(global_position)
		if d < bd:
			bd = d
			best = guard
	return best
