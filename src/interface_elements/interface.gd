extends VBoxContainer

const TagEditor = preload("tag_editor.tscn")

@onready var shapes: VBoxContainer = $VBoxContainer/ScrollContainer/Shapes

func _ready() -> void:
	SVG.data.resized.connect(update_viewbox)
	SVG.data.tag_added.connect(full_rebuild)
	SVG.data.tag_moved.connect(full_rebuild)
	SVG.data.tag_deleted.connect(full_rebuild)
	SVG.data.changed_unknown.connect(full_rebuild)


func update_viewbox() -> void:
	$MainConfiguration/ViewBoxEdit/WidthEdit.value = SVG.data.w
	$MainConfiguration/ViewBoxEdit/HeightEdit.value = SVG.data.h

func full_rebuild() -> void:
	update_viewbox()
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

func _change_view_box(w: int, h: int) -> void:
	SVG.data.w = w
	SVG.data.h = h


func _on_tag_selected(index: int) -> void:
	for tag_editor in shapes.get_children():
		if &"tag_index" in tag_editor and tag_editor.tag_index != index:
			tag_editor.is_selected = false


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(SVG.code_editor.text)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
	event.button_index == MOUSE_BUTTON_LEFT:
		for tag_editor in shapes.get_children():
			tag_editor.is_selected = false
