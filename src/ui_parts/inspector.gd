extends VBoxContainer

const ElementFrame = preload("element_frame.tscn")

@onready var elements_container: VBoxContainer = %Elements
@onready var add_button: Button = $AddButton


func _notification(what: int) -> void:
	if what == Utils.CustomNotification.LANGUAGE_CHANGED:
		update_translation()

func _ready() -> void:
	update_translation()
	SVG.elements_layout_changed.connect(full_rebuild)
	SVG.changed_unknown.connect(full_rebuild)
	full_rebuild()


func update_translation() -> void:
	add_button.text = TranslationServer.translate("Add element")


func full_rebuild() -> void:
	for node in elements_container.get_children():
		node.queue_free()
	# Only add the first level of elements, they will automatically add their children.
	for element_idx in SVG.root_element.get_child_count():
		var element_editor := ElementFrame.instantiate()
		element_editor.element = SVG.root_element.get_child(element_idx)
		elements_container.add_child(element_editor)

func add_element(element_name: String) -> void:
	var new_element := DB.element_with_setup(element_name)
	var loc: PackedInt32Array
	if element_name in ["linearGradient", "radialGradient"]:
		loc = PackedInt32Array([0])
	else:
		loc = PackedInt32Array([SVG.root_element.get_child_count()])
	SVG.root_element.add_element(new_element, loc)


func _on_add_button_pressed() -> void:
	var btn_array: Array[Button] = []
	for element_name in PackedStringArray(["path", "circle", "ellipse", "rect", "line",
	"g", "linearGradient", "radialGradient"]):
		var btn := ContextPopup.create_button(element_name, add_element.bind(element_name),
				false, DB.get_element_icon(element_name))
		btn.add_theme_font_override("font", load("res://visual/fonts/FontMono.ttf"))
		btn_array.append(btn)
	var separator_indices: Array[int] = [1, 5]
	
	var add_popup := ContextPopup.new()
	add_popup.setup(btn_array, true, add_button.size.x, separator_indices)
	HandlerGUI.popup_under_rect(add_popup, add_button.get_global_rect(), get_viewport())
