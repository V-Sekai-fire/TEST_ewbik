@tool
extends EditorPlugin


const gizmo_plugin_const = preload("res://addons/vrm_pose_constraints/skeleton_plugin.gd")

var gizmo_plugin = gizmo_plugin_const.new()


func _enter_tree():
	add_spatial_gizmo_plugin(gizmo_plugin)


func _exit_tree():
	remove_spatial_gizmo_plugin(gizmo_plugin)
