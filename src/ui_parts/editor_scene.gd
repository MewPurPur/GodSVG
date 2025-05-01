extends HBoxContainer

const MacMenuScene = preload("res://src/ui_parts/mac_menu.tscn")
const GlobalActionsScene = preload("res://src/ui_parts/global_actions.tscn")
const CodeEditorScene = preload("res://src/ui_parts/code_editor.tscn")
const InspectorScene = preload("res://src/ui_parts/inspector.tscn")
const ViewportScene = preload("res://src/ui_parts/display.tscn")

@onready var panel_container: PanelContainer = $PanelContainer

func _ready() -> void:
	Configs.theme_changed.connect(update_theme)
	Configs.layout_changed.connect(update_layout)
	update_layout()
	update_theme()
	if NativeMenu.has_feature(NativeMenu.FEATURE_GLOBAL_MENU):
		add_child(MacMenuScene.instantiate())

func update_theme() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = ThemeUtils.overlay_panel_inner_color
	stylebox.set_content_margin_all(0)
	panel_container.add_theme_stylebox_override("panel", stylebox)


func update_layout() -> void:
	for child in panel_container.get_children():
		child.queue_free()
	
	var top_left := Configs.savedata.get_layout_parts(SaveData.LayoutLocation.TOP_LEFT)
	var bottom_left := Configs.savedata.get_layout_parts(SaveData.LayoutLocation.BOTTOM_LEFT)
	
	# Set up the horizontal splitter.
	var horizontal_splitter := HSplitContainer.new()
	horizontal_splitter.size_flags_horizontal = Control.SIZE_FILL
	horizontal_splitter.add_theme_constant_override("separation", 6)
	horizontal_splitter.split_offset = Configs.savedata.horizontal_splitter_offset
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
	
	if not top_left.is_empty() and not bottom_left.is_empty():
		# Layout parts both on top and on the bottom.
		var left_vertical_split_container := VSplitContainer.new()
		left_vertical_split_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		left_vertical_split_container.add_theme_constant_override("separation", 10)
		left_vertical_split_container.split_offset = Configs.savedata.left_vertical_splitter_offset
		left_vertical_split_container.dragged.connect(_on_left_vertical_splitter_dragged)
		left_vertical_split_container.add_child(create_layout_node(top_left[0]))
		left_vertical_split_container.add_child(create_layout_node(bottom_left[0]))
		left_vbox.add_child(left_vertical_split_container)
	elif top_left.size() == 2 or bottom_left.size() == 2:
		# Tabs for the different layout parts.
		var layout_parts := top_left if bottom_left.is_empty() else bottom_left
		var vbox := VBoxContainer.new()
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var buttons_hbox := HBoxContainer.new()
		buttons_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(buttons_hbox)
		
		var layout_nodes: Dictionary[Utils.LayoutPart, Node] = {}
		for part in layout_parts:
			var layout_node := create_layout_node(part)
			layout_nodes[part] = layout_node
			layout_node.hide()
			vbox.add_child(layout_node)
		
		var btn_group := ButtonGroup.new()
		for i in layout_parts.size():
			var part := layout_parts[i]
			var btn := Button.new()
			# Make the text update when the language changes.
			var set_btn_text_func := func() -> void:
					btn.text = TranslationUtils.get_layout_part_name(part)
			Configs.language_changed.connect(set_btn_text_func)
			set_btn_text_func.call()
			# Set up other button properties.
			btn.toggle_mode = true
			btn.icon = Utils.get_layout_part_icon(part)
			btn.theme_type_variation = "FlatButton"
			btn.focus_mode = Control.FOCUS_NONE
			btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
			btn.button_group = btn_group
			for node_part in layout_nodes:
				btn.toggled.connect(func(_toggled_on: bool) -> void:
						layout_nodes[node_part].visible = (node_part == part))
			if part == Utils.LayoutPart.INSPECTOR:
				State.requested_scroll_to_selection.connect(
						btn.set_pressed.bind(true).unbind(2))
			buttons_hbox.add_child(btn)
			if i == 0:
				btn.button_pressed = true
				layout_nodes[part].show()
		left_vbox.add_child(vbox)
	else:
		# Layout parts disabled.
		if not top_left.is_empty():
			left_vbox.add_child(create_layout_node(top_left[0]))
		elif not bottom_left.is_empty():
			left_vbox.add_child(create_layout_node(bottom_left[0]))

func _on_horizontal_splitter_dragged(offset: int) -> void:
	Configs.savedata.horizontal_splitter_offset = offset

func _on_left_vertical_splitter_dragged(offset: int) -> void:
	Configs.savedata.left_vertical_splitter_offset = offset


func create_layout_node(layout_part: Utils.LayoutPart) -> Node:
	match layout_part:
		Utils.LayoutPart.CODE_EDITOR: return CodeEditorScene.instantiate()
		Utils.LayoutPart.INSPECTOR: return InspectorScene.instantiate()
		Utils.LayoutPart.VIEWPORT: return ViewportScene.instantiate()
		_: return Control.new()
