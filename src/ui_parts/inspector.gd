extends VBoxContainer

const TagFrame = preload("tag_frame.tscn")

@onready var tags_container: VBoxContainer = %Tags
@onready var add_button: Button = $AddButton


func _notification(what: int) -> void:
	if what == Utils.CustomNotification.LANGUAGE_CHANGED:
		update_translation()

func _ready() -> void:
	update_translation()
	SVG.tag_layout_changed.connect(full_rebuild)
	SVG.changed_unknown.connect(full_rebuild)
	full_rebuild()


func update_translation() -> void:
	add_button.text = TranslationServer.translate("Add element")


func full_rebuild() -> void:
	for node in tags_container.get_children():
		node.queue_free()
	# Only add the first level of tags, they will automatically add their children.
	for tag_idx in SVG.root_tag.get_child_count():
		var tag_editor := TagFrame.instantiate()
		tag_editor.tag = SVG.root_tag.child_tags[tag_idx]
		tags_container.add_child(tag_editor)

func add_tag(tag_name: String) -> void:
	var new_tag := DB.tag(tag_name)
	if tag_name in ["linearGradient", "radialGradient"]:
		SVG.root_tag.add_tag(new_tag, PackedInt32Array([0]))
	else:
		SVG.root_tag.add_tag(new_tag, PackedInt32Array([SVG.root_tag.get_child_count()]))


func _on_add_button_pressed() -> void:
	var btn_array: Array[Button] = []
	for tag_name in PackedStringArray(["path", "circle", "ellipse", "rect", "line",
	"g", "linearGradient", "radialGradient"]):
		var btn := ContextPopup.create_button(tag_name, add_tag.bind(tag_name), false,
				DB.get_tag_icon(tag_name))
		btn.add_theme_font_override("font", load("res://visual/fonts/FontMono.ttf"))
		btn_array.append(btn)
	var separator_indices: Array[int] = [1, 5]
	
	var add_popup := ContextPopup.new()
	add_popup.setup(btn_array, true, add_button.size.x, separator_indices)
	HandlerGUI.popup_under_rect(add_popup, add_button.get_global_rect(), get_viewport())
