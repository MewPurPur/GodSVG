extends VBoxContainer

const TagEditor = preload("tag_editor.tscn")

@onready var tags_container: VBoxContainer = %Tags
@onready var svg_tag_editor: MarginContainer = $SVGTagEditor
@onready var add_popup: Popup = $AddPopup
@onready var add_button: Button = $VBoxContainer/AddButton

func _ready() -> void:
	populate_add_popup()
	SVG.root_tag.attribute_changed.connect(svg_tag_editor.update_svg_attributes)
	SVG.root_tag.tags_added.connect(full_rebuild.unbind(1))
	SVG.root_tag.tags_moved.connect(full_rebuild.unbind(2))
	SVG.root_tag.tags_deleted.connect(full_rebuild.unbind(1))
	SVG.root_tag.changed_unknown.connect(full_rebuild)
	full_rebuild()


func full_rebuild() -> void:
	svg_tag_editor.update_svg_attributes()
	for node in tags_container.get_children():
		node.queue_free()
	svg_tag_editor.tag = SVG.root_tag
	# Only add the first level of tags, they will automatically add their children.
	for tag_idx in SVG.root_tag.get_child_count():
		var tag := SVG.root_tag.child_tags[tag_idx]
		var tag_editor := TagEditor.instantiate()
		tag_editor.tag = tag
		tag_editor.tid = PackedInt32Array([tag_idx])
		tags_container.add_child(tag_editor)

func add_tag(tag_name: String) -> void:
	add_popup.hide()
	var new_tid := PackedInt32Array([SVG.root_tag.get_child_count()])
	var new_tag: Tag
	match tag_name:
		"circle": new_tag = TagCircle.new()
		"ellipse": new_tag = TagEllipse.new()
		"rect": new_tag = TagRect.new()
		"path": new_tag = TagPath.new()
		"line": new_tag = TagLine.new()
	SVG.root_tag.add_tag(new_tag, new_tid)


func _on_tag_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
	event.button_index == MOUSE_BUTTON_LEFT and not event.ctrl_pressed:
		Indications.clear_selection()
		Indications.clear_inner_selection()

func populate_add_popup() -> void:
	var btn_array: Array[Button] = []
	for tag_name in ["circle", "ellipse", "rect", "path", "line"]:
		var add_btn := Button.new()
		add_btn.text = tag_name
		add_btn.add_theme_font_override(&"font", load("res://visual/CodeFont.ttf"))
		add_btn.icon = load("res://visual/icons/tag/" + tag_name + ".svg")
		add_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_btn.pressed.connect(add_tag.bind(tag_name))
		btn_array.append(add_btn)
	
	add_popup.set_btn_array(btn_array)

func _on_add_button_pressed() -> void:
	add_popup.popup(Utils.calculate_popup_rect(add_button.global_position,
			add_button.size, add_popup.size))
