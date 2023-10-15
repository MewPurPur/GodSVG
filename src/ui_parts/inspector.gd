extends VBoxContainer

const TagEditor = preload("tag_editor.tscn")

@onready var shapes: VBoxContainer = %Shapes
@onready var svg_tag_editor: MarginContainer = $SVGTagEditor

func _ready() -> void:
	SVG.root_tag.attribute_changed.connect(svg_tag_editor.update_viewbox)
	SVG.root_tag.tag_added.connect(full_rebuild)
	SVG.root_tag.tag_moved.connect(full_rebuild.unbind(2))
	SVG.root_tag.tag_deleted.connect(full_rebuild.unbind(1))
	SVG.root_tag.changed_unknown.connect(full_rebuild)
	full_rebuild()


func full_rebuild() -> void:
	svg_tag_editor.update_viewbox()
	for node in shapes.get_children():
		node.queue_free()
	
	svg_tag_editor.tag = SVG.root_tag
	for tag_idx in SVG.root_tag.get_children_count():
		var tag := SVG.root_tag.child_tags[tag_idx]
		var tag_editor := TagEditor.instantiate()
		tag_editor.tag = tag
		tag_editor.tag_index = tag_idx
		shapes.add_child(tag_editor)


# FIXME In the end all connections should go directly to add_shape with argument in binds 
# But right now there is a bug preventing it so keeping them here for now
func add_circle() -> void:
	SVG.root_tag.add_tag(TagCircle.new())

func add_ellipse() -> void:
	SVG.root_tag.add_tag(TagEllipse.new())

func add_rect() -> void:
	SVG.root_tag.add_tag(TagRect.new())

func add_path() -> void:
	SVG.root_tag.add_tag(TagPath.new())

func add_line() -> void:
	SVG.root_tag.add_tag(TagLine.new())

func _on_viewbox_changed(w: float, h: float) -> void:
	SVG.root_tag.set_dimensions(w, h)


func _on_tag_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
	event.button_index == MOUSE_BUTTON_LEFT and not event.ctrl_pressed:
		Interactions.clear_selection()
