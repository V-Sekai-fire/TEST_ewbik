@tool
extends EditorNode3DGizmoPlugin

const vrm_top_level_const : Script = preload("res://addons/vrm/vrm_toplevel.gd")

var vrm_top_level : Node3D = null 

func _has_gizmo(for_node_3d : Node3D) -> bool:
	if for_node_3d.get_script() == vrm_top_level_const:
		vrm_top_level = for_node_3d
		return true
	return false

func _redraw(editor_gizmo_3d : EditorNode3DGizmo) -> void:
	var skeleton : Skeleton3D = vrm_top_level.get_node_or_null(vrm_top_level.vrm_skeleton)
	if not skeleton:
		return
	var stack : SkeletonModificationStack3D = skeleton.get_modification_stack()
	if not stack:
		stack = SkeletonModificationStack3D.new()
		stack.add_modification(SkeletonModification3DEWBIK.new())
		skeleton.set_modification_stack(stack)
	var vrm_human_mapping : Dictionary = vrm_top_level.vrm_meta.humanoid_bone_mapping
	var bone_vrm_mapping : Dictionary
	for key in vrm_human_mapping.keys():
		bone_vrm_mapping[vrm_human_mapping[key]] = key
	for i in range(stack.modification_count):
		var ewbik : SkeletonModification3DEWBIK = stack.get_modification(i)
		ewbik.default_damp = deg2rad(1)
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
			"leftFoot": {}, 
			"rightFoot": {}, 
			"head": {}, 
			"hips": {}, 
			"leftHand":{}, 
			"rightHand": {}
		}
		ewbik.set_pin_count(0)
		var index = 0
		for key in pins.keys():
			var node_3d : Node3D = Node3D.new()
			skeleton.add_child(node_3d, true)
			var node_path : NodePath = "../../" + str(key)
			var bone_name : StringName = vrm_human_mapping[str(key)]
			node_3d.name = bone_name
			var bone_id : int = skeleton.find_bone(bone_name)
			node_3d.transform = skeleton.get_bone_global_pose(bone_id)
			ewbik.add_pin(bone_name, node_path, true)
			if key == "hips":
				ewbik.root_bone = bone_name
				ewbik.set("pins/%s/depth_falloff" % index, 0)
			index = index + 1
		ewbik.constraint_count = 0
		ewbik.constraint_count = skeleton.get_bone_count()
		for count_i in range(skeleton.get_bone_count()):
			var bone_name = skeleton.get_bone_name(count_i)
			if not vrm_human_mapping.has(bone_name):
				continue
			ewbik.set_constraint_name(count_i, bone_name)
			ewbik.set_kusudama_twist_from(count_i, 0)
			ewbik.set_kusudama_twist_to(count_i, 0)
			ewbik.set_kusudama_limit_cone_count(count_i, 1)
			ewbik.set_kusudama_limit_cone_radius(count_i, 0, deg2rad(0))
			# Female age 9 - 19 https://pubmed.ncbi.nlm.nih.gov/32644411/
			if bone_name in [
				vrm_human_mapping["hips"], 
			]:
				ewbik.set_kusudama_twist_from(count_i, 0)
				ewbik.set_kusudama_twist_to(count_i, deg2rad(360))
				ewbik.set_kusudama_limit_cone_count(count_i, 0)
			elif bone_name in [
				vrm_human_mapping["spine"], 
				vrm_human_mapping["chest"],
				vrm_human_mapping["upperChest"],
				vrm_human_mapping["neck"],
				vrm_human_mapping["head"],
			]:
				ewbik.set_kusudama_twist_to(count_i, 5)
				ewbik.set_kusudama_limit_cone_count(count_i, 0)
			elif bone_name in [
				vrm_human_mapping["leftShoulder"],
				vrm_human_mapping["rightShoulder"],
			]:
				ewbik.set_kusudama_twist_to(count_i, deg2rad(45))
			elif bone_name in [
				vrm_human_mapping["leftLowerArm"],
				vrm_human_mapping["rightLowerArm"],
			]:
				ewbik.set_kusudama_twist_to(count_i, deg2rad(170))
			elif bone_name in [
				vrm_human_mapping["leftHand"],
				vrm_human_mapping["rightHand"],
				vrm_human_mapping["leftLowerArm"],
				vrm_human_mapping["rightLowerArm"],
				vrm_human_mapping["leftToes"],
				vrm_human_mapping["rightToes"],
			]:
				ewbik.set_kusudama_twist_to(count_i, deg2rad(45))
			elif bone_name in [
				vrm_human_mapping["leftHand"],
				vrm_human_mapping["rightHand"],
				vrm_human_mapping["rightFoot"], 
				vrm_human_mapping["leftFoot"],
			]:
				ewbik.set_kusudama_twist_to(count_i, deg2rad(5))
			elif bone_name in [
				vrm_human_mapping["leftUpperArm"],
				vrm_human_mapping["rightUpperArm"],
			]:
				ewbik.set_kusudama_twist_to(count_i, deg2rad(150))
			elif bone_name in [
				vrm_human_mapping["rightUpperLeg"],
				vrm_human_mapping["leftUpperLeg"],
				vrm_human_mapping["rightLowerLeg"],
				vrm_human_mapping["leftLowerLeg"],
			]:
				ewbik.set_kusudama_twist_to(count_i, deg2rad(24))
			else:
				ewbik.set_kusudama_twist_to(count_i, deg2rad(0))
		stack.enable_all_modifications(true)
		stack.enabled = true
		
 
