class_name PanelGrid extends GridContainer

@export var items: PackedStringArray
@export var stylebox: StyleBox
@export var dim_last_item := false

func setup() -> void:
	for item_idx in items.size():
		var item := items[item_idx]
		var panel_container := PanelContainer.new()
		panel_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_container.add_theme_stylebox_override("panel", stylebox)
		var label := Label.new()
		label.text = item
		if dim_last_item and item_idx == items.size() - 1:
			label.add_theme_color_override("font_color", Color.GRAY)
		panel_container.add_child(label)
		add_child(panel_container)
