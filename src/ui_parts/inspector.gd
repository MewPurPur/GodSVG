extends VBoxContainer

const ElementFrame = preload("res://src/ui_widgets/element_frame.tscn")
const BasicXNodeFrame = preload("res://src/ui_widgets/basic_xnode_frame.tscn")

@onready var xnodes_container: VBoxContainer = %RootChildren
@onready var add_button: Button = $AddButton


func _ready() -> void:
	GlobalSettings.language_changed.connect(update_translation)
	update_translation()
	SVG.elements_layout_changed.connect(full_rebuild)
	SVG.changed_unknown.connect(full_rebuild)
	full_rebuild()


func update_translation() -> void:
	add_button.text = TranslationServer.translate("Add element")


func full_rebuild() -> void:
	for node in xnodes_container.get_children():
		node.queue_free()
	for xnode_editor in XNodeChildrenBuilder.create(SVG.root_element):
		xnodes_container.add_child(xnode_editor)

func add_element(element_name: String) -> void:
	var new_element := DB.element_with_setup(element_name)
	var loc: PackedInt32Array
	if element_name in ["linearGradient", "radialGradient", "stop"]:
		loc = PackedInt32Array([0])
	else:
		loc = PackedInt32Array([SVG.root_element.get_child_count()])
	SVG.root_element.add_xnode(new_element, loc)
	SVG.queue_save()


func _on_add_button_pressed() -> void:
	var btn_array: Array[Button] = []
	for element_name in PackedStringArray(["path", "circle", "ellipse", "rect", "line",
	"g", "linearGradient", "radialGradient", "stop"]):
		var btn := ContextPopup.create_button(element_name, add_element.bind(element_name),
				false, DB.get_element_icon(element_name))
		btn.add_theme_font_override("font", ThemeUtils.mono_font)
		btn_array.append(btn)
	var separator_indices := PackedInt32Array([1, 5])
	
	var add_popup := ContextPopup.new()
	add_popup.setup(btn_array, true, add_button.size.x, separator_indices)
	HandlerGUI.popup_under_rect(add_popup, add_button.get_global_rect(), get_viewport())
