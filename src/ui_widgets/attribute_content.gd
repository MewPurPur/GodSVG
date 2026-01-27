extends VBoxContainer

const RootElementEditorScene = preload("res://src/ui_parts/root_element_editor.tscn")

@onready var special_widgets_area: CenterContainer = $HBoxContainer/SpecialWidgetsArea
@onready var main_attributes_area: HFlowContainer = $HBoxContainer/MarginContainer/MainAttributesArea
@onready var other_attributes_area: VBoxContainer = $OtherAttributesArea
@onready var new_attribute_button: Button = $NewAttributeButton

func _ready() -> void:
	new_attribute_button.text = Translator.translate("Add attribute")
	
	if State.selected_xids.size() == 1:
		var xnode := State.root_element.get_xnode(State.selected_xids[0])
		match xnode.name:
			"svg":
				set_special_widget(RootElementEditorScene.instantiate())
		setup_main_attributes(get_main_attributes(xnode.name))
		setup_secondary_attributes(get_secondary_attributes(xnode.name))
	elif State.selected_xids.size() > 1:
		var interesting_main_attributes := get_main_attributes(State.root_element.get_xnode(State.selected_xids[0]).name)
		var interesting_secondary_attributes := get_secondary_attributes(State.root_element.get_xnode(State.selected_xids[0]).name)
		
		for i in range(1, State.selected_xids.size()):
			var new_interesting_main_attributes := get_main_attributes(State.root_element.get_xnode(State.selected_xids[i]).name)
			for attrib_idx in range(interesting_main_attributes.size() - 1, -1, -1):
				if not interesting_main_attributes[attrib_idx] in new_interesting_main_attributes:
					interesting_main_attributes.remove_at(attrib_idx)
			
			var new_interesting_secondary_attributes := get_secondary_attributes(State.root_element.get_xnode(State.selected_xids[i]).name)
			for attrib_idx in range(interesting_secondary_attributes.size() - 1, -1, -1):
				if not interesting_secondary_attributes[attrib_idx] in new_interesting_secondary_attributes:
					interesting_secondary_attributes.remove_at(attrib_idx)
		
		setup_main_attributes(interesting_main_attributes)
		setup_secondary_attributes(interesting_secondary_attributes)


func setup_main_attributes(attributes: PackedStringArray) -> void:
	for attrib in attributes:
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 0)
		var label := Label.new()
		label.add_theme_font_override("font", ThemeUtils.mono_font)
		label.text = attrib
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
		var field := AttributeFieldBuilder.create(attrib)
		vbox.add_child(field)
		main_attributes_area.add_child(vbox)

func setup_secondary_attributes(attributes: PackedStringArray) -> void:
	for attrib in attributes:
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.add_theme_font_override("font", ThemeUtils.mono_font)
		label.text = attrib
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(label)
		var field := AttributeFieldBuilder.create(attrib)
		field.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
		hbox.add_child(field)
		other_attributes_area.add_child(hbox)

func set_special_widget(node: Node) -> void:
	special_widgets_area.add_child(node)
	special_widgets_area.show()


func get_main_attributes(element_name: String) -> PackedStringArray:
	match element_name:
		"circle": return PackedStringArray(["cx", "cy", "r"])
		"ellipse": return PackedStringArray(["cx", "cy", "rx", "ry"])
		"rect": return PackedStringArray(["x", "y", "width", "height", "rx", "ry"])
		"line": return PackedStringArray(["x1", "y1", "x2", "y2"])
		"path": return PackedStringArray(["d"])
		"polygon": return PackedStringArray(["points"])
		"polyline": return PackedStringArray(["points"])
		"linearGradient": return PackedStringArray(["id", "x1", "y1", "x2", "y2"])
		"radialGradient": return PackedStringArray(["id", "cx", "cy", "r"])
		"stop": return PackedStringArray(["offset", "stop-color", "stop-opacity"])
		"use": return PackedStringArray(["href", "transform", "x", "y"])
		_: return PackedStringArray()

func get_secondary_attributes(element_name: String) -> PackedStringArray:
	match element_name:
		"circle": return PackedStringArray(["transform", "opacity", "fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width", "stroke-dasharray"])
		_: return PackedStringArray()
