extends Node

func _ready() -> void:
	if Configs.savedata.has_tabs():
		get_tree().change_scene_to_file.call_deferred("res://src/ui_parts/editor.tscn")
	else:
		get_tree().change_scene_to_file.call_deferred("res://src/ui_parts/start_menu.tscn")
