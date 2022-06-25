@tool
extends EditorNode3DGizmoPlugin

const vrm_top_level_const : Script = preload("res://addons/vrm/vrm_toplevel.gd")

var vrm_top_level : Node3D = null 


func _has_gizmo(for_node_3d : Node3D) -> bool:
	if for_node_3d.get_script() == vrm_top_level_const:
		vrm_top_level = for_node_3d
		return true
	return false

func _lock_rotation(ewbik, constraint_i):
	ewbik.set_kusudama_limit_cone_count(constraint_i, 1)
	ewbik.set_kusudama_limit_cone_center(constraint_i, 0, Vector3(0, 1, 0))
	ewbik.set_kusudama_limit_cone_radius(constraint_i, 0, 0.3)

func _full_rotation(ewbik, constraint_i):
	ewbik.set_kusudama_limit_cone_count(constraint_i, 1)
	ewbik.set_kusudama_limit_cone_center(constraint_i, 0, Vector3(0, 1, 0))
	ewbik.set_kusudama_limit_cone_radius(constraint_i, 0, TAU)

func _redraw(editor_gizmo_3d : EditorNode3DGizmo) -> void:
	var skeleton : Skeleton3D = vrm_top_level.get_node_or_null(vrm_top_level.vrm_skeleton)
	if not skeleton:
		return
	var stack : SkeletonModificationStack3D = skeleton.get_modification_stack()
	if not stack:
		stack = SkeletonModificationStack3D.new()
		stack.add_modification(SkeletonModification3DEWBIK.new())
		stack.enabled = true
		skeleton.set_modification_stack(stack)
	var vrm_human_mapping : Dictionary = vrm_top_level.vrm_meta.humanoid_bone_mapping
	var bone_vrm_mapping : Dictionary
	for key in vrm_human_mapping.keys():
		bone_vrm_mapping[vrm_human_mapping[key]] = key
	for i in range(stack.modification_count):
		var ewbik : SkeletonModification3DEWBIK = stack.get_modification(i)
		ewbik.max_ik_iterations = 30
		ewbik.default_damp = deg2rad(1)
		ewbik.budget_millisecond = 2
		if ewbik.get_constraint_count():
			continue
		# https://github.com/vrm-c/vrm-specification/blob/master/specification/0.0/schema/vrm.humanoid.bone.schema.json
		var humanoid_bone : Array = [
			"hips",
			"leftUpperLeg","rightUpperLeg","leftLowerLeg","rightLowerLeg","leftFoot","rightFoot",
			"spine","chest","neck","head","leftShoulder","rightShoulder","leftUpperArm","rightUpperArm",
			"leftLowerArm","rightLowerArm","leftHand","rightHand","leftToes","rightToes","leftEye","rightEye","jaw",
			# Fingers
			"leftThumbProximal","leftThumbIntermediate","leftThumbDistal",
			"leftIndexProximal","leftIndexIntermediate","leftIndexDistal",
			"leftMiddleProximal","leftMiddleIntermediate","leftMiddleDistal",
			"leftRingProximal","leftRingIntermediate","leftRingDistal",
			"leftLittleProximal","leftLittleIntermediate","leftLittleDistal",
			"rightThumbProximal","rightThumbIntermediate","rightThumbDistal",
			"rightIndexProximal","rightIndexIntermediate","rightIndexDistal",
			"rightMiddleProximal","rightMiddleIntermediate","rightMiddleDistal",
			"rightRingProximal","rightRingIntermediate","rightRingDistal",
			"rightLittleProximal","rightLittleIntermediate","rightLittleDistal", "upperChest"]

		var pins : Dictionary = {
			"leftLowerLeg":{}, 
			"leftFoot": {}, 
			"rightLowerLeg":{}, 
			"rightFoot": {}, 
			"head": {}, 
			"hips": {}, 
			"leftHand":{}, 
			"rightHand": {}
		}
		ewbik.set_pin_count(0)
		var index = 0
		var minimum_twist = deg2rad(-0.5)
		var minimum_twist_diff = deg2rad(0.5)
		var maximum_twist = deg2rad(360)
		for key in pins.keys():
			var node_3d : Node3D = Node3D.new()
			skeleton.add_child(node_3d, true)
			var node_path : NodePath = str(skeleton.get_path_to(skeleton.owner)) + "/../" + str(key)
			var bone_name : StringName = vrm_human_mapping[str(key)]
			node_3d.name = bone_name
			var bone_id : int = skeleton.find_bone(bone_name)
			node_3d.transform = skeleton.get_bone_global_pose(bone_id)
			ewbik.add_pin(bone_name, node_path, true)
			if key == "hips":
				ewbik.set_pin_depth_falloff(index, 0)
			index = index + 1
		ewbik.constraint_count = 0
		for count_i in skeleton.get_bone_count():
			var bone_name = skeleton.get_bone_name(count_i)
			if not bone_vrm_mapping.has(bone_name):
				continue
			var vrm_bone_name = bone_vrm_mapping[bone_name]
			var constraint_i = ewbik.constraint_count
			ewbik.constraint_count = ewbik.constraint_count + 1
			ewbik.set_constraint_name(constraint_i, bone_name)
			ewbik.set_kusudama_limit_cone_count(constraint_i, 0)
			# Female age 9 - 19 https://pubmed.ncbi.nlm.nih.gov/32644411/
			if vrm_bone_name in ["hips"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(0.5))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-0.5))
			elif vrm_bone_name in ["spine"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(60))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-60))
			elif vrm_bone_name in ["chest", "upperChest"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(30))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-30))
			elif vrm_bone_name in ["neck"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(47))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-47))
			elif vrm_bone_name in ["head"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(0.5))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-0.5))
			elif vrm_bone_name in ["leftShoulder", "rightShoulder"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(18))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-30))
			elif vrm_bone_name in ["leftUpperArm", "rightUpperArm"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(18))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-30))
			elif vrm_bone_name in ["leftLowerArm", "rightLowerArm"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(30))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-70))
			elif vrm_bone_name in ["leftHand","rightHand"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(40))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-45))
			elif vrm_bone_name in ["leftUpperLeg", "rightUpperLeg"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(0.5))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-0.5))
			elif vrm_bone_name in ["leftLowerLeg", "rightLowerLeg"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(0.5))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-0.5))
			elif vrm_bone_name in ["leftFoot", "rightFoot"]:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(40))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-40))
			else:
				ewbik.set_kusudama_twist_from(constraint_i, deg2rad(0.5))
				ewbik.set_kusudama_twist_to(constraint_i, deg2rad(-0.5))

		stack.enable_all_modifications(true)
		stack.enabled = true
