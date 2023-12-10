extends Node

var has_overlay := false

func add_overlay(overlay_menu: Control) -> void:
	if not has_overlay:
		var overlay := ColorRect.new()
		overlay.color = Color(0, 0, 0, 0.4)
		get_tree().get_root().add_child(overlay)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		overlay.add_child(overlay_menu)
		overlay_menu.tree_exiting.connect(remove_overlay.bind(overlay))
		has_overlay = true
		overlay.process_mode = PROCESS_MODE_ALWAYS
		get_tree().paused = true

func remove_overlay(color_rect: ColorRect) -> void:
	color_rect.queue_free()
	has_overlay = false
	get_tree().paused = false
