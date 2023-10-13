extends VBoxContainer

const TagEditor = preload("tag_editor.tscn")

@onready var shapes: VBoxContainer = %Shapes
@onready var viewbox_edit: HBoxContainer = $MainConfiguration/ViewBoxEdit

func _ready() -> void:
	SVG.data.resized.connect(viewbox_edit.update_viewbox)
	SVG.data.tag_added.connect(full_rebuild)
	SVG.data.tag_moved.connect(full_rebuild)
	SVG.data.tag_deleted.connect(full_rebuild.unbind(1))
	SVG.data.changed_unknown.connect(full_rebuild)
	full_rebuild()


func full_rebuild() -> void:
	viewbox_edit.update_viewbox()
	for node in shapes.get_children():
		node.queue_free()
	
	for tag_idx in SVG.data.tags.size():
		var tag := SVG.data.tags[tag_idx]
		var tag_editor := TagEditor.instantiate()
		tag_editor.tag = tag
		tag_editor.tag_index = tag_idx
		shapes.add_child(tag_editor)


# In the end all connections should go directly to add_shape with argument in binds 
# But right now there is a bug preventing it so keeping them here for now
func add_circle() -> void:
	SVG.data.add_tag(SVGTagCircle.new())

func add_ellipse() -> void:
	SVG.data.add_tag(SVGTagEllipse.new())

func add_rect() -> void:
	SVG.data.add_tag(SVGTagRect.new())

func add_path() -> void:
	SVG.data.add_tag(SVGTagPath.new())

func add_line() -> void:
	SVG.data.add_tag(SVGTagLine.new())

func _on_viewbox_changed(w: float, h: float) -> void:
	SVG.data.set_dimensions(w, h)


func _on_tag_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
	event.button_index == MOUSE_BUTTON_LEFT and not event.ctrl_pressed:
		Selections.clear_selection()
