@tool
extends EditorScript


var vrm_bone_profile : SkeletonProfileHumanoid = SkeletonProfileHumanoid.new()

func _lock_rotation(ewbik, constraint_i):
	ewbik.set_kusudama_limit_cone_count(constraint_i, 1)
	ewbik.set_kusudama_limit_cone_center(constraint_i, 0, Vector3(0, 1, 0))
	ewbik.set_kusudama_limit_cone_radius(constraint_i, 0, 0)

func _full_rotation(ewbik, constraint_i):
	ewbik.set_kusudama_limit_cone_count(constraint_i, 1)
	ewbik.set_kusudama_limit_cone_center(constraint_i, 0, Vector3(0, 1, 0))
	ewbik.set_kusudama_limit_cone_radius(constraint_i, 0, TAU)

var vrm_to_godot : Dictionary = {
	"root": "Root",
	"hips": "Hips",
	"spine": "Spine",
	"chest": "Chest",
	"upperChest": "UpperChest",
	"neck": "Neck",
	"head": "Head",
	"leftEye": "LeftEye",
	"rightEye": "RightEye",
	"jaw": "Jaw",
	"leftShoulder": "LeftShoulder",
	"leftUpperArm": "LeftUpperArm",
	"leftLowerArms": "LeftLowerArm",
	"leftHand": "LeftHand",
	"leftThumbProximal": "LeftThumbProximal",
	"leftThumbIntermediate": "LeftThumbIntermediate",
	"leftThumbDistal": "LeftThumbDistal",
	"leftIndexProximal": "LeftIndexProximal",
	"leftIndexIntermediate": "LeftIndexIntermediate",
	"leftIndexDistal": "LeftIndexDistal",
	"leftMiddleProximal": "LeftMiddleProximal",
	"leftMiddleIntermediate": "LeftMiddleIntermediate",
	"leftMiddleDistal": "LeftMiddleDistal",
	"leftRingProximal": "LeftRingProximal",
	"leftRingIntermediate": "LeftRingIntermediate",
	"leftRingDistal": "LeftRingDistal",
	"leftLittleProximal": "LeftLittleProximal",
	"leftLittleIntermediate": "LeftLittleIntermediate",
	"leftLittleDistal": "LeftLittleDistal",
	"rightShoulder": "RightShoulder",
	"rightUpperArm": "RightUpperArm",
	"rightLowerArm": "RightLowerArm",
	"rightHand": "RightHand",
	"rightThumbProximal": "RightThumbProximal",
	"rightThumbIntermediate": "RightThumbIntermediate",
	"rightThumbDistal": "RightThumbDistal",
	"rightIndexProximal": "RightIndexProximal",
	"rightIndexIntermediate": "RightIndexIntermediate",
	"rightIndexDistal": "RightIndexDistal",
	"rightMiddleProximal": "RightMiddleProximal",
	"rightMiddleIntermediate": "RightMiddleIntermediate",
	"rightMiddleDistal": "RightMiddleDistal",
	"rightRingProximal": "RightRingProximal",
	"rightRingIntermediate": "RightRingIntermediate",
	"rightRingDistal": "RightRingDistal",
	"rightLittleProximal": "RightLittleProximal",
	"rightLittleIntermediate": "RightLittleIntermediate",
	"rightLittleDistal": "RightLittleDistal",
	"leftUpperLeg": "LeftUpperLeg",
	"leftLowerLeg": "LeftLowerLeg",
	"leftFoot": "LeftFoot",
	"leftToes": "LeftToes",
	"rightUpperLeg": "RightUpperLeg",
	"rightLowerLeg": "RightLowerLeg",
	"rightFoot": "RightFoot",
	"rightToes": "RightToes",
}

func _run():
	var root : Node3D = get_editor_interface().get_edited_scene_root()
	var queue : Array
	queue.push_back(root)
	var string_builder : Array
	var vrm_top_level : Node3D
	var skeleton : Skeleton3D
	var ewbik : EWBIK = null
	while not queue.is_empty():
		var front = queue.front()
		var node : Node = front
		if node is Skeleton3D:
			skeleton = node
		if node.script and node.script.resource_path == "res://addons/vrm/vrm_toplevel.gd":
			vrm_top_level = node
		if node is EWBIK:
			ewbik = node
		var child_count : int = node.get_child_count()
		for i in child_count:
			queue.push_back(node.get_child(i))
		queue.pop_front()
	if ewbik != null:
		ewbik.queue_free()
	ewbik = EWBIK.new()
	skeleton.add_child(ewbik, true)
	ewbik.owner = skeleton.owner
	ewbik.name = "EWBIK"
	ewbik.skeleton = ewbik.get_path_to(skeleton)
	var vrm_profile : Dictionary
	var humanoid_profile : Dictionary
	var vrm_meta = vrm_top_level.get("vrm_meta")
	ewbik.pin_count = vrm_bone_profile.bone_size
	for key in vrm_bone_profile.bone_size:
		ewbik.max_ik_iterations = 30
		ewbik.default_damp = deg2rad(1)
		ewbik.budget_millisecond = 2
		var minimum_twist = deg2rad(-0.5)
		var minimum_twist_diff = deg2rad(0.5)
		var maximum_twist = deg2rad(360)
		var profile_name : String = vrm_bone_profile.get_bone_name(key)
		var node_3d : Node3D = skeleton.get_node_or_null(profile_name)
		if node_3d == null:
			node_3d = Node3D.new()
		skeleton.add_child(node_3d, true)
		if profile_name.is_empty():
			continue
		var node_path : NodePath = str(profile_name)
		var bone_index = skeleton.find_bone(profile_name)
		var bone_global_pose = skeleton.global_pose_to_world_transform(skeleton.get_bone_global_pose(bone_index))
		node_3d.name = profile_name
		node_3d.transform = bone_global_pose
		root.add_child(node_3d, true)
		node_3d.owner = root
		ewbik.set_pin_bone_name(key, profile_name)
		ewbik.set_pin_nodepath(key, node_path)
		ewbik.set_pin_use_node_rotation(key, true)
		ewbik.set_pin_depth_falloff(key, 1)
	ewbik.constraint_count = 0
	for count_i in skeleton.get_bone_count():
		var bone_name = skeleton.get_bone_name(count_i)
		var constraint_i = ewbik.constraint_count
		ewbik.constraint_count = ewbik.constraint_count + 1
		ewbik.set_constraint_name(constraint_i, bone_name)
		ewbik.set_kusudama_limit_cone_count(constraint_i, 0)
		skeleton.notify_property_list_changed()
		# Female age 9 - 19 https://pubmed.ncbi.nlm.nih.gov/32644411/
		if bone_name in ["Hips"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
		elif bone_name in ["Spine"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-60))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(60))
		elif bone_name in ["chest", "upperChest"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-30))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(30))
		elif bone_name in ["neck"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-47))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(47))
		elif bone_name in ["head"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
		elif bone_name in ["leftShoulder", "rightShoulder"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-18))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(30))
		elif bone_name in ["leftUpperArm", "rightUpperArm"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-18))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(30))
		elif bone_name in ["leftLowerArm", "rightLowerArm"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-30))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(70))
		elif bone_name in ["leftHand","rightHand"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-40))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(45))
		elif bone_name in ["leftUpperLeg", "rightUpperLeg"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
		elif bone_name in ["leftLowerLeg", "rightLowerLeg"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-0.5))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(0.5))
		elif bone_name in ["leftFoot", "rightFoot"]:
			ewbik.set_kusudama_twist_from(constraint_i, deg2rad(-40))
			ewbik.set_kusudama_twist_to(constraint_i, deg2rad(40))

	
