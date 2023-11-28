extends VBoxContainer

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const TagEditor = preload("tag_editor.tscn")

@onready var tags_container: VBoxContainer = %ScrollContainer/Tags
@onready var svg_tag_editor: MarginContainer = $SVGTagEditor
@onready var add_button: Button = $VBoxContainer/AddButton

func _ready() -> void:
	SVG.root_tag.tag_layout_changed.connect(full_rebuild)
	SVG.root_tag.changed_unknown.connect(full_rebuild)
	full_rebuild()


func full_rebuild() -> void:
	for node in tags_container.get_children():
		node.queue_free()
	svg_tag_editor.tag = SVG.root_tag
	# Only add the first level of tags, they will automatically add their children.
	for tag_idx in SVG.root_tag.get_child_count():
		var tag_editor := TagEditor.instantiate()
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


func _on_tag_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
	event.button_index == MOUSE_BUTTON_LEFT and not event.ctrl_pressed:
		Indications.clear_selection()
		Indications.clear_inner_selection()

func _on_add_button_pressed() -> void:
	var btn_array: Array[Button] = []
	for tag_name in ["path", "circle", "ellipse", "rect", "line"]:
		var add_btn := Button.new()
		add_btn.text = tag_name
		add_btn.add_theme_font_override(&"font", load("res://visual/fonts/FontMono.ttf"))
		add_btn.icon = load("res://visual/icons/tag/" + tag_name + ".svg")
		add_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_btn.pressed.connect(add_tag.bind(tag_name))
		btn_array.append(add_btn)
	
	var add_popup := ContextPopup.instantiate()
	add_child(add_popup)
	add_popup.set_btn_array(btn_array)
	add_popup.set_min_width(add_button.size.x)
	Utils.popup_under_control(add_popup, add_button)
