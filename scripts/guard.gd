class_name Guard
extends CharacterBody3D

const SPEED := 3.1
const GRAVITY := 26.0
const DETECT := 13.0
const ATTACK_RANGE := 2.3
const ATTACK_DAMAGE := 14.0
const ATTACK_CD := 1.3
const STRIKE_AT := 0.4

var max_hp := 100.0
var hp := 100.0
var alive := true
var home := Vector3.ZERO
var tint := Color(0.75, 0.18, 0.2)

var _model: Node3D
var _anim: AnimationPlayer
var _yaw := 0.0
var _atk_t := 0.0
var _strike_done := true
var _hurt_t := 0.0
var _cur := ""
var _patrol_phase := 0.0


func _ready() -> void:
	add_to_group("guard")
	set_collision_layer_value(1, false)
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	var cap := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	cap.shape = shape
	cap.position = Vector3(0.0, 0.9, 0.0)
	add_child(cap)
	_model = (load("res://models/kk_Knight.glb") as PackedScene).instantiate() as Node3D
	add_child(_model)
	Style.recolor(_model, tint)
	_anim = AnimRig.attach(_model,
		["res://models/anim_general.glb", "res://models/anim_move.glb", "res://models/anim_combat.glb"],
		["Idle_A", "Walking_A", "Running_A"])
	Style.apply_outline(_model)
	if home == Vector3.ZERO:
		home = global_position
	_patrol_phase = randf() * TAU
	_play("Idle_A")


func _physics_process(delta: float) -> void:
	if not alive:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -1.5
	if _atk_t > 0.0:
		_atk_t -= delta
		if not _strike_done and _atk_t <= (ATTACK_CD - STRIKE_AT):
			_strike_done = true
			_do_strike()
	if _hurt_t > 0.0:
		_hurt_t -= delta

	var p := G.player as Node3D
	var moving := false
	if p != null and is_instance_valid(p) and bool(p.get("alive")):
		var to := p.global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d < DETECT:
			_face(to)
			if d > ATTACK_RANGE:
				var dir := to.normalized()
				velocity.x = dir.x * SPEED
				velocity.z = dir.z * SPEED
				moving = true
			else:
				velocity.x = 0.0
				velocity.z = 0.0
				if _atk_t <= 0.0:
					_begin_attack()
		else:
			_idle_drift(delta)
			moving = velocity.length() > 0.3
	else:
		_idle_drift(delta)
		moving = velocity.length() > 0.3

	move_and_slide()
	if _atk_t <= 0.0:
		_play("Walking_A" if moving else "Idle_A")


func _idle_drift(delta: float) -> void:
	_patrol_phase += delta * 0.5
	var wander := home + Vector3(sin(_patrol_phase) * 3.0, 0.0, cos(_patrol_phase * 0.8) * 3.0)
	var to := wander - global_position
	to.y = 0.0
	if to.length() > 0.6:
		var dir := to.normalized()
		velocity.x = dir.x * SPEED * 0.5
		velocity.z = dir.z * SPEED * 0.5
		_face(to)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _face(to: Vector3) -> void:
	if to.length() > 0.1:
		var target_yaw := atan2(to.x, to.z)
		_yaw = lerp_angle(_yaw, target_yaw, 0.2)
		_model.rotation.y = _yaw


func _begin_attack() -> void:
	_atk_t = ATTACK_CD
	_strike_done = false
	if _anim != null and _anim.has_animation("Melee_1H_Attack_Slice_Diagonal"):
		_anim.play("Melee_1H_Attack_Slice_Diagonal", 0.1)
		_cur = "Melee_1H_Attack_Slice_Diagonal"


func _do_strike() -> void:
	var p := G.player as Node3D
	if p == null or not is_instance_valid(p) or not bool(p.get("alive")):
		return
	var d := p.global_position.distance_to(global_position)
	if d <= ATTACK_RANGE + 0.7 and p.has_method("take_damage"):
		p.call("take_damage", ATTACK_DAMAGE, global_position)
		Fx.burst(get_parent(), p.global_position + Vector3(0.0, 1.1, 0.0), Color(1.0, 0.5, 0.25), 10)


func _play(clip: String) -> void:
	if _anim == null or not _anim.has_animation(clip):
		return
	if _cur == clip and _anim.is_playing():
		return
	_cur = clip
	_anim.play(clip, 0.15)


func take_damage(dmg: float, from_pos: Vector3) -> void:
	if not alive:
		return
	hp = maxf(0.0, hp - dmg)
	Fx.flash(_model, Color(1.0, 1.0, 1.0), 0.1)
	var kb := global_position - from_pos
	kb.y = 0.0
	if kb.length() > 0.1:
		velocity += kb.normalized() * 3.0
	if hp <= 0.0:
		_die()
	else:
		_hurt_t = 0.25
		if _anim != null and _anim.has_animation("Hit_A") and _atk_t <= 0.0:
			_anim.play("Hit_A", 0.05)
			_cur = "Hit_A"


func _die() -> void:
	alive = false
	set_collision_layer_value(3, false)
	if _anim != null and _anim.has_animation("Death_A"):
		_anim.play("Death_A", 0.1)
		_cur = "Death_A"
	Fx.burst(get_parent(), global_position + Vector3(0.0, 1.0, 0.0), Color(0.9, 0.2, 0.2), 20)
	var tree := get_tree()
	if tree != null:
		var t := tree.create_timer(6.0)
		t.timeout.connect(_fade_out)


func _fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(0.01, 0.01, 0.01), 0.6)
	tw.tween_callback(queue_free)
