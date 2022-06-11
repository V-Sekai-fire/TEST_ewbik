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
	var skeleton : Skeleton3D = vrm_top_level.get_node(vrm_top_level.vrm_skeleton)
	if not skeleton:
		return
	var stack : SkeletonModificationStack3D = skeleton.get_modification_stack()
	if not stack:
		return
	var vrm_human_mapping : Dictionary = vrm_top_level.vrm_meta.humanoid_bone_mapping
	var bone_vrm_mapping : Dictionary
	for key in vrm_human_mapping.keys():
		bone_vrm_mapping[vrm_human_mapping[key]] = key
	for i in range(stack.modification_count):
		var ewbik : SkeletonModification3DEWBIK = stack.get_modification(i)
		if ewbik.get_constraint_count():
			continue
		ewbik.constraint_count = 0
		ewbik.constraint_count = skeleton.get_bone_count()
		for count_i in range(ewbik.constraint_count):
			var bone_name : String = skeleton.get_bone_name(count_i)
			ewbik.set_constraint_name(count_i, bone_name)
			ewbik.set_kusudama_twist_from(count_i, 0.0)
			ewbik.set_kusudama_twist_to(count_i, TAU)
			ewbik.set_kusudama_limit_cone_count(count_i, 0)
