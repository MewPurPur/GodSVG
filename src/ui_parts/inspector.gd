extends VTitledPanel

const InvalidSyntaxWarning = preload("res://src/ui_widgets/invalid_syntax_warning.tscn")

@onready var xnodes_container: VBoxContainer = %RootChildren
@onready var add_button: Button = $ActionContainer/AddButton

var is_unstable := false

func _ready() -> void:
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	State.parsing_finished.connect(react_to_last_parsing)
	react_to_last_parsing()
	State.xnode_layout_changed.connect(full_rebuild)
	State.svg_unknown_change.connect(full_rebuild)
	State.svg_switched_to_another.connect(full_rebuild)
	full_rebuild()
	add_button.pressed.connect(_on_add_button_pressed)


func sync_theming() -> void:
	color = Color.TRANSPARENT
	border_color = ThemeUtils.subtle_panel_border_color
	title_color = ThemeUtils.basic_panel_inner_color

func sync_localization() -> void:
	add_button.text = Translator.translate("Add element")


func full_rebuild() -> void:
	for node in xnodes_container.get_children():
		node.queue_free()
	
	if is_unstable:
		xnodes_container.add_child(InvalidSyntaxWarning.instantiate())
	else:
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
	State.save_svg()


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


func react_to_last_parsing() -> void:
	var new_is_unstable := (State.last_parse_error != SVGParser.ParseError.OK and State.stable_editor_markup.is_empty())
	if is_unstable != new_is_unstable:
		is_unstable = new_is_unstable
