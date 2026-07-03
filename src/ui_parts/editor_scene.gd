extends HBoxContainer

const MacMenuScene = preload("res://src/ui_parts/mac_menu.tscn")
const GlobalActionsScene = preload("res://src/ui_parts/global_actions.tscn")
const CodeEditorScene = preload("res://src/ui_parts/code_editor.tscn")
const InspectorScene = preload("res://src/ui_parts/inspector.tscn")
const ViewportScene = preload("res://src/ui_parts/display.tscn")
const PreviewsScene = preload("res://src/ui_parts/previews.tscn")

@onready var panel_container: PanelContainer = $PanelContainer

func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("save", FileUtils.save_svg, ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	shortcuts.add_shortcut("save_as", FileUtils.save_svg_as, ShortcutsRegistration.Behavior.PASS_THROUGH_POPUPS)
	shortcuts.add_shortcut("optimize", State.optimize)
	shortcuts.add_shortcut("reset_svg", FileUtils.reset_svg)
	shortcuts.add_shortcut("ui_undo", func() -> void: Configs.savedata.get_active_tab().undo())
	shortcuts.add_shortcut("ui_redo", func() -> void: Configs.savedata.get_active_tab().redo())
	shortcuts.add_shortcut("ui_cancel", State.clear_all_selections)
	shortcuts.add_shortcut("delete", State.delete_selected)
	shortcuts.add_shortcut("duplicate", State.duplicate_selected)
	shortcuts.add_shortcut("move_up", State.move_up_selected)
	shortcuts.add_shortcut("move_down", State.move_down_selected)
	shortcuts.add_shortcut("set_as_origin", State.set_selected_as_origin)
	shortcuts.add_shortcut("reverse_order", State.reverse_order_selected)
	shortcuts.add_shortcut("select_all", State.select_all)
	
	shortcuts.add_shortcut("move_absolute", State.respond_to_key_input.bind("M"))
	shortcuts.add_shortcut("move_relative", State.respond_to_key_input.bind("m"))
	shortcuts.add_shortcut("line_absolute", State.respond_to_key_input.bind("L"))
	shortcuts.add_shortcut("line_relative", State.respond_to_key_input.bind("l"))
	shortcuts.add_shortcut("horizontal_line_absolute", State.respond_to_key_input.bind("H"))
	shortcuts.add_shortcut("horizontal_line_relative", State.respond_to_key_input.bind("h"))
	shortcuts.add_shortcut("vertical_line_absolute", State.respond_to_key_input.bind("V"))
	shortcuts.add_shortcut("vertical_line_relative", State.respond_to_key_input.bind("v"))
	shortcuts.add_shortcut("close_path_absolute", State.respond_to_key_input.bind("Z"))
	shortcuts.add_shortcut("close_path_relative", State.respond_to_key_input.bind("z"))
	shortcuts.add_shortcut("elliptical_arc_absolute", State.respond_to_key_input.bind("A"))
	shortcuts.add_shortcut("elliptical_arc_relative", State.respond_to_key_input.bind("a"))
	shortcuts.add_shortcut("cubic_bezier_absolute", State.respond_to_key_input.bind("C"))
	shortcuts.add_shortcut("cubic_bezier_relative", State.respond_to_key_input.bind("c"))
	shortcuts.add_shortcut("shorthand_cubic_bezier_absolute", State.respond_to_key_input.bind("S"))
	shortcuts.add_shortcut("shorthand_cubic_bezier_relative", State.respond_to_key_input.bind("s"))
	shortcuts.add_shortcut("quadratic_bezier_absolute", State.respond_to_key_input.bind("Q"))
	shortcuts.add_shortcut("quadratic_bezier_relative", State.respond_to_key_input.bind("q"))
	shortcuts.add_shortcut("shorthand_quadratic_bezier_absolute", State.respond_to_key_input.bind("T"))
	shortcuts.add_shortcut("shorthand_quadratic_bezier_relative", State.respond_to_key_input.bind("t"))
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	Configs.layout_changed.connect(update_layout)
	update_layout()
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	Configs.ui_scale_changed.connect(apply_cutout_margin)
	await get_tree().process_frame
	apply_cutout_margin()
	
	if NativeMenu.has_feature(NativeMenu.FEATURE_GLOBAL_MENU):
		add_child(MacMenuScene.instantiate())

func apply_cutout_margin() -> void:
	var stylebox := panel_container.get_theme_stylebox("panel")
	
	var radii := _get_rounded_corner_radius()
	var margin_left = max(radii[0], radii[3]) / 3
	var margin_right = max(radii[1], radii[2]) / 3
	var margin_top = max(radii[0], radii[1]) / 3
	var margin_bottom = max(radii[2], radii[3]) / 3
	
	var safe_area := DisplayServer.get_display_safe_area()
	var s_right_padding = (DisplayServer.screen_get_size().x - safe_area.size.x) - safe_area.position.x
	margin_left = max(margin_left, safe_area.position.x)
	margin_right = max(margin_right, s_right_padding)
	
	var ui_scale = get_window().content_scale_factor
	stylebox.content_margin_left = margin_left / ui_scale
	stylebox.content_margin_right = margin_right / ui_scale
	stylebox.content_margin_top = margin_top / ui_scale
	stylebox.content_margin_bottom = margin_bottom / ui_scale
	panel_container.add_theme_stylebox_override("panel", stylebox)

## Returns an array of rounded corner radii in the following order: [topLeft, topRight, bottomRight, bottomLeft].
## Available only on Android 12 and later.
func _get_rounded_corner_radius() -> Array[int]:
	var result: Array[int] = [0, 0, 0, 0]
	var android_runtime = Engine.get_singleton("AndroidRuntime")
	if not android_runtime:
		return result
	var version = JavaClassWrapper.wrap("android.os.Build$VERSION")
	if version.SDK_INT < 31:
		return result

	var insets = android_runtime.getActivity().getWindow().getDecorView().getRootWindowInsets()
	var RoundedCorner = JavaClassWrapper.wrap("android.view.RoundedCorner")
	
	var topLeft = insets.getRoundedCorner(RoundedCorner.POSITION_TOP_LEFT)
	if topLeft != null:
		result[0] = topLeft.getRadius()
	
	var topRight = insets.getRoundedCorner(RoundedCorner.POSITION_TOP_RIGHT)
	if topRight != null:
		result[1] = topRight.getRadius()
	
	var bottomRight = insets.getRoundedCorner(RoundedCorner.POSITION_BOTTOM_RIGHT)
	if bottomRight != null:
		result[2] = bottomRight.getRadius()
	
	var bottomLeft = insets.getRoundedCorner(RoundedCorner.POSITION_BOTTOM_LEFT)
	if bottomLeft != null:
		result[3] = bottomLeft.getRadius()
	
	return result

func sync_theming() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = ThemeUtils.overlay_panel_inner_color
	stylebox.set_content_margin_all(0)
	panel_container.add_theme_stylebox_override("panel", stylebox)
	apply_cutout_margin()


func update_layout() -> void:
	for child in panel_container.get_children():
		child.queue_free()
	
	var top_left := Configs.savedata.get_layout_parts(SaveData.LayoutLocation.TOP_LEFT)
	var bottom_left := Configs.savedata.get_layout_parts(SaveData.LayoutLocation.BOTTOM_LEFT)
	
	# Set up the horizontal splitter.
	var horizontal_splitter := HSplitContainer.new()
	horizontal_splitter.size_flags_horizontal = Control.SIZE_FILL
	horizontal_splitter.add_theme_constant_override("separation", 8)
	horizontal_splitter.split_offsets = PackedInt32Array([Configs.savedata.horizontal_splitter_offset])
	horizontal_splitter.dragged.connect(_on_horizontal_splitter_dragged)
	panel_container.add_child(horizontal_splitter)
	
	var left_margin_container := MarginContainer.new()
	left_margin_container.custom_minimum_size.x = 408
	left_margin_container.begin_bulk_theme_override()
	left_margin_container.add_theme_constant_override("margin_top", 6)
	left_margin_container.add_theme_constant_override("margin_bottom", 6)
	left_margin_container.add_theme_constant_override("margin_left", 6)
	left_margin_container.end_bulk_theme_override()
	horizontal_splitter.add_child(left_margin_container)
	
	var right_margin_container := MarginContainer.new()
	right_margin_container.add_theme_constant_override("margin_top", 6)
	right_margin_container.add_child(create_layout_node(Utils.LayoutPart.VIEWPORT))
	horizontal_splitter.add_child(right_margin_container)
	
	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 6)
	left_margin_container.add_child(left_vbox)
	
	var global_actions := GlobalActionsScene.instantiate()
	left_vbox.add_child(global_actions)
	var left_vertical_split_container := VSplitContainer.new()
	left_vertical_split_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vertical_split_container.add_theme_constant_override("separation", 10)
	left_vertical_split_container.split_offsets = PackedInt32Array([Configs.savedata.left_vertical_splitter_offset])
	left_vertical_split_container.dragged.connect(_on_left_vertical_splitter_dragged)
	
	if not top_left.is_empty():
		left_vertical_split_container.add_child(_create_part_box(top_left))
	if not bottom_left.is_empty():
		left_vertical_split_container.add_child(_create_part_box(bottom_left))
	
	left_vbox.add_child(left_vertical_split_container)
	
	var focus_sequence: Array[Control] = [global_actions]
	focus_sequence.append_array(left_vertical_split_container.get_children())
	HandlerGUI.register_focus_sequence(self, focus_sequence)

func _create_part_box(layout_parts: Array[Utils.LayoutPart]) -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var layout_part_container := LayoutPartContainer.new()
	layout_part_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var layout_nodes: Dictionary[Utils.LayoutPart, Node] = {}
	for part in layout_parts:
		var layout_node := create_layout_node(part)
		layout_nodes[part] = layout_node
		layout_node.hide()
		layout_part_container.add_child(layout_node)
	
	if layout_parts.size() > 1:
		var buttons_hbox := HBoxContainer.new()
		buttons_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(buttons_hbox)
		var btn_group := ButtonGroup.new()
		for i in layout_parts.size():
			var part := layout_parts[i]
			var btn := Button.new()
			# Make the text update when the language changes.
			var set_btn_text_func := func() -> void:
					btn.text = TranslationUtils.get_layout_part_name(part)
			Configs.language_changed.connect(set_btn_text_func)
			btn.tree_exited.connect(Configs.language_changed.disconnect.bind(set_btn_text_func))
			set_btn_text_func.call()
			# Set up other button properties.
			btn.toggle_mode = true
			btn.icon = Utils.get_layout_part_icon(part)
			btn.theme_type_variation = "FlatButton"
			btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
			btn.button_group = btn_group
			for node_part in layout_nodes:
				btn.toggled.connect(func(_toggled_on: bool) -> void:
						layout_nodes[node_part].visible = (node_part == part))
			if part == Utils.LayoutPart.INSPECTOR:
				State.requested_scroll_to_selection.connect(btn.set_pressed.bind(true).unbind(3))
			buttons_hbox.add_child(btn)
			if i == 0:
				btn.button_pressed = true
				layout_nodes[part].show()
		
		var focus_sequence: Array[Control] = []
		focus_sequence.append_array(buttons_hbox.get_children())
		HandlerGUI.register_focus_sequence(vbox, focus_sequence)
	else:
		layout_nodes[layout_parts[0]].show()
	
	vbox.add_child(layout_part_container)
	return vbox

func _on_horizontal_splitter_dragged(offset: int) -> void:
	Configs.savedata.horizontal_splitter_offset = offset

func _on_left_vertical_splitter_dragged(offset: int) -> void:
	Configs.savedata.left_vertical_splitter_offset = offset


func create_layout_node(layout_part: Utils.LayoutPart) -> Node:
	match layout_part:
		Utils.LayoutPart.CODE_EDITOR: return CodeEditorScene.instantiate()
		Utils.LayoutPart.INSPECTOR: return InspectorScene.instantiate()
		Utils.LayoutPart.VIEWPORT: return ViewportScene.instantiate()
		Utils.LayoutPart.PREVIEWS: return PreviewsScene.instantiate()
		_: return Control.new()


class LayoutPartContainer extends Container:
	func _notification(what: int) -> void:
		if what == NOTIFICATION_SORT_CHILDREN:
			var child_rect := Rect2(Vector2.ZERO, size)
			for child in get_children():
				if child is Control:
					fit_child_in_rect(child, child_rect)
	
	func _get_minimum_size() -> Vector2:
		var max_size := Vector2()
		for child in get_children():
			if child is Control:
				max_size = max_size.max(child.get_combined_minimum_size())
		return max_size
