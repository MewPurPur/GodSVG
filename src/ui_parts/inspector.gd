extends VTitledPanel

@onready var xnodes_container: VBoxContainer = %RootChildren
@onready var add_button: Button = $ActionContainer/AddButton


func _ready() -> void:
	Configs.theme_changed.connect(update_theme)
	Configs.language_changed.connect(update_translation)
	update_theme()
	update_translation()
	State.xnode_layout_changed.connect(full_rebuild)
	State.svg_unknown_change.connect(full_rebuild)
	add_button.pressed.connect(_on_add_button_pressed)


func update_theme() -> void:
	color = Color.TRANSPARENT
	border_color = ThemeUtils.common_panel_inner_color
	title_color = Color(ThemeUtils.common_panel_inner_color, 0.4)

func update_translation() -> void:
	add_button.text = Translator.translate("Add element")


func full_rebuild() -> void:
	for node in xnodes_container.get_children():
		node.queue_free()
	for xnode_editor in XNodeChildrenBuilder.create(State.root_element):
		xnodes_container.add_child(xnode_editor)

func add_element(element_name: String) -> void:
	var new_element := DB.element_with_setup(element_name, [])
	var loc: PackedInt32Array
	if element_name in ["linearGradient", "radialGradient", "stop"]:
		loc = PackedInt32Array([0])
	else:
		loc = PackedInt32Array([State.root_element.get_child_count()])
	State.root_element.add_xnode(new_element, loc)
	State.queue_svg_save()


func _on_add_button_pressed() -> void:
	var btn_array: Array[Button] = []
	for element_name in PackedStringArray(["path", "circle", "ellipse", "rect", "line",
	"polygon", "polyline", "g", "linearGradient", "radialGradient", "stop"]):
		var btn := ContextPopup.create_button(element_name, add_element.bind(element_name),
				false, DB.get_element_icon(element_name))
		btn.add_theme_font_override("font", ThemeUtils.mono_font)
		btn_array.append(btn)
	var separator_indices := PackedInt32Array([1, 4, 7])
	
	var add_popup := ContextPopup.new()
	add_popup.setup(btn_array, true, add_button.size.x, -1, separator_indices)
	HandlerGUI.popup_under_rect(add_popup, add_button.get_global_rect(), get_viewport())
