class_name AnimRig
extends RefCounted
## Copies clips from the kk_rig_medium_* libraries onto a fresh AnimationPlayer parented
## under a KayKit model. Same 23-bone Rig_Medium skeleton -> tracks resolve with NO BoneMap.
## The new AnimationPlayer's root_node defaults to ".." (the model), so track paths like
## "Rig_Medium/Skeleton3D:hips" resolve against <model>/Rig_Medium/Skeleton3D.

static func attach(model: Node3D, lib_paths: Array, loop_clips: Array) -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	ap.name = "AnimRig"
	model.add_child(ap)
	var lib := AnimationLibrary.new()
	for lp_v in lib_paths:
		var lp: String = String(lp_v)
		var ps: Resource = load(lp)
		if ps == null:
			continue
		var src: Node = (ps as PackedScene).instantiate()
		var found: Array = src.find_children("*", "AnimationPlayer", true, false)
		if found.size() > 0:
			var src_ap := found[0] as AnimationPlayer
			for clip: String in src_ap.get_animation_list():
				if lib.has_animation(clip):
					continue
				var anim: Animation = src_ap.get_animation(clip).duplicate(true)
				if loop_clips.has(clip):
					anim.loop_mode = Animation.LOOP_LINEAR
				lib.add_animation(clip, anim)
		src.free()
	ap.add_animation_library("", lib)
	return ap
