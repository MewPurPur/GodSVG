extends Node

var has_overlay := false
var overlay_ref: ColorRect

func add_overlay(overlay_menu: Node) -> void:
	# A bit hacky, but I couldn't find out a better way at the time.
	# I'm sure there is a better way of doing things though.
	if has_overlay:
		for child in overlay_ref.get_children():
			child.tree_exiting.disconnect(remove_overlay)
			child.queue_free()
		if overlay_menu is Control:
			overlay_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		overlay_ref.add_child(overlay_menu)
		overlay_menu.tree_exiting.connect(remove_overlay)
	else:
		overlay_ref = ColorRect.new()
		overlay_ref.color = Color(0, 0, 0, 0.4)
		get_tree().get_root().add_child(overlay_ref)
		overlay_ref.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if overlay_menu is Control:
			overlay_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		overlay_ref.add_child(overlay_menu)
		overlay_menu.tree_exiting.connect(remove_overlay)
		has_overlay = true
		overlay_ref.process_mode = PROCESS_MODE_ALWAYS
		get_tree().paused = true

func remove_overlay() -> void:
	overlay_ref.queue_free()
	has_overlay = false
	get_tree().paused = false
