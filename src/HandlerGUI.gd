extends Node

var has_overlay := false
var overlay_ref: ColorRect


func _ready() -> void:
	get_window().files_dropped.connect(_on_files_dropped)

func _on_files_dropped(files: PackedStringArray) -> void:
	if not has_overlay:
		SVG.apply_svg_from_path(files[0])


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


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"import"):
		get_viewport().set_input_as_handled()
		SVG.open_import_dialog()
	elif event.is_action_pressed(&"export"):
		get_viewport().set_input_as_handled()
		SVG.open_export_dialog()
	elif event.is_action_pressed(&"save"):
		get_viewport().set_input_as_handled()
		SVG.open_save_dialog("svg", SVG.native_file_save, SVG.save_svg_to_file)

func _unhandled_input(event) -> void:
	if event.is_action_pressed(&"redo"):
		get_viewport().set_input_as_handled()
		SVG.redo()
	elif event.is_action_pressed(&"undo"):
		get_viewport().set_input_as_handled()
		SVG.undo()
	
	if get_viewport().gui_is_dragging():
		return
	
	if event.is_action_pressed(&"ui_cancel"):
		Indications.clear_all_selections()
	elif event.is_action_pressed(&"delete"):
		Indications.delete_selected()
	elif event.is_action_pressed(&"move_up"):
		Indications.move_up_selected()
	elif event.is_action_pressed(&"move_down"):
		Indications.move_down_selected()
	elif event.is_action_pressed(&"duplicate"):
		Indications.duplicate_selected()
	elif event.is_action_pressed(&"select_all"):
		Indications.select_all()
	elif event is InputEventKey:
		Indications.respond_to_key_input(event)
