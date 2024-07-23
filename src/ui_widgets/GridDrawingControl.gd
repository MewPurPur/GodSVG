class_name PanelGrid extends GridContainer

const font = preload("res://visual/fonts/Font.ttf")

@export var items: PackedStringArray
@export var stylebox: StyleBox

func setup() -> void:
	for item in items:
		var panel_container := PanelContainer.new()
		panel_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_container.add_theme_stylebox_override("panel", stylebox)
		var label := Label.new()
		label.text = item
		panel_container.add_child(label)
		add_child(panel_container)
