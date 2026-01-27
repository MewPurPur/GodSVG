extends VSplitContainer

const ElementButtonScene = preload("res://src/ui_widgets/element_button.tscn")
const AttributeContentScene = preload("res://src/ui_widgets/attribute_content.tscn")

@onready var hierarchy_tree: VBoxContainer = $ScrollContainer/HierarchyTree
@onready var description_panel: PanelContainer = %DescriptionPanel
@onready var attribute_area: PanelContainer = %AttributeArea
@onready var attribute_content: MarginContainer = %AttributeContent

func _ready() -> void:
	State.selection_changed.connect(adapt_to_selection)
	adapt_to_selection()
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	hierarchy_tree.gui_input.connect(_on_hierarchy_tree_gui_input)
	
	var hierarchy: Array[XNode] = [State.root_element]
	hierarchy += State.root_element.get_all_xnode_descendants()
	for xnode in hierarchy:
		var margin_container := MarginContainer.new()
		margin_container.add_theme_constant_override("margin_left", 12 * xnode.xid.size())
		var element_button := ElementButtonScene.instantiate()
		element_button.element = xnode
		margin_container.add_child(element_button)
		hierarchy_tree.add_child(margin_container)

func sync_theming() -> void:
	var description_panel_stylebox := get_theme_stylebox("tabbar_background", "TabContainer").duplicate()
	description_panel_stylebox.expand_margin_top = 8.0
	description_panel.add_theme_stylebox_override("panel", description_panel_stylebox)

func adapt_to_selection() -> void:
	for child in attribute_content.get_children():
		child.queue_free()
	
	for child in description_panel.get_children():
		child.queue_free()
	
	if State.selected_xids.is_empty():
		attribute_area.remove_theme_stylebox_override("panel")
		return
	
	var sb := attribute_area.get_theme_stylebox("panel").duplicate()
	sb.bg_color = ThemeUtils.hover_overlay_color
	attribute_area.add_theme_stylebox_override("panel", sb)
	
	if State.selected_xids.size() == 1:
		var xnode := State.root_element.get_xnode(State.selected_xids[0])
		
		var center_container := CenterContainer.new()
		description_panel.add_child(center_container)
		var margin_container := MarginContainer.new()
		margin_container.begin_bulk_theme_override()
		margin_container.add_theme_constant_override("margin_top", -3)
		margin_container.add_theme_constant_override("margin_bottom", 5)
		margin_container.end_bulk_theme_override()
		center_container.add_child(margin_container)
		var hbox_container := HBoxContainer.new()
		margin_container.add_child(hbox_container)
		var texture_rect := TextureRect.new()
		texture_rect.texture = DB.get_element_icon(xnode.name)
		texture_rect.modulate = ThemeUtils.tinted_contrast_color
		hbox_container.add_child(texture_rect)
		var label := Label.new()
		label.text = xnode.name
		label.begin_bulk_theme_override()
		label.add_theme_font_override("font", ThemeUtils.mono_font)
		label.add_theme_color_override("font_color", ThemeUtils.tinted_contrast_color)
		label.add_theme_constant_override("line_spacing", 0)
		label.end_bulk_theme_override()
		hbox_container.add_child(label)
		
		attribute_content.add_child(AttributeContentScene.instantiate())
	else:
		attribute_content.add_child(AttributeContentScene.instantiate())

func _on_hierarchy_tree_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE] and event.is_pressed():
			State.clear_all_selections()
