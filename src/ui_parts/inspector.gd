extends VBoxContainer

const TagFrame = preload("tag_frame.tscn")

@onready var tags_container: VBoxContainer = %Tags
@onready var add_button: Button = $AddButton

func _ready() -> void:
	SVG.root_tag.tag_layout_changed.connect(full_rebuild)
	SVG.root_tag.changed_unknown.connect(full_rebuild)
	full_rebuild()


func full_rebuild() -> void:
	for node in tags_container.get_children():
		node.queue_free()
	# Only add the first level of tags, they will automatically add their children.
	for tag_idx in SVG.root_tag.get_child_count():
		var tag_editor := TagFrame.instantiate()
		tag_editor.tag = SVG.root_tag.child_tags[tag_idx]
		tag_editor.tid = PackedInt32Array([tag_idx])
		tags_container.add_child(tag_editor)

func add_tag(tag_name: String) -> void:
	var new_tid := PackedInt32Array([SVG.root_tag.get_child_count()])
	var new_tag: Tag
	match tag_name:
		"circle": new_tag = TagCircle.new()
		"ellipse": new_tag = TagEllipse.new()
		"rect": new_tag = TagRect.new()
		"path": new_tag = TagPath.new()
		"line": new_tag = TagLine.new()
	SVG.root_tag.add_tag(new_tag, new_tid)


func _on_add_button_pressed() -> void:
	var btn_array: Array[Button] = []
	for tag_name in ["path", "circle", "ellipse", "rect", "line"]:
		var btn := Utils.create_btn(tag_name, add_tag.bind(tag_name), false,
				SVGDB.get_tag_icon(tag_name))
		btn.add_theme_font_override("font", load("res://visual/fonts/FontMono.ttf"))
		btn_array.append(btn)
	
	var add_popup := ContextPopup.new()
	add_popup.setup(btn_array, true, add_button.size.x)
	HandlerGUI.popup_under_rect(add_popup, add_button.get_global_rect(), get_viewport())
