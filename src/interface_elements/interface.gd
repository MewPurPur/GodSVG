extends VBoxContainer

const TagEditor = preload("tag_editor.tscn")

@onready var shapes: VBoxContainer = $VBoxContainer/ScrollContainer/Shapes

func add_shape(shape : GDScript) -> void :
	print(shape)
	var shape_editor := TagEditor.instantiate()
	shape_editor.tag_index = SVG.data.tags.size()
	shape_editor.deleted.connect(_on_tag_deleted)
	shape_editor.tag = shape.new()
	shapes.add_child(shape_editor) 

# In the end all connection should go directly to add_shape with argument in binds 
# But right now there is a bug preventing it so keeping them here for now
func add_circle() -> void:
	add_shape(SVGTagCircle)

func add_ellipse() -> void:
	add_shape(SVGTagEllipse)

func add_rect() -> void:
	add_shape(SVGTagRect)

func add_path() -> void:
	add_shape(SVGTagPath)

func _change_view_box(w: int, h: int) -> void:
	SVG.data.w = w
	SVG.data.h = h
	SVG.update()
	%Checkerboard.size = Vector2(w, h) * 15


func _on_tag_deleted(index: int) -> void:
	for tag_editor in shapes.get_children():
		if &"tag_index" in tag_editor and tag_editor.tag_index > index:
			tag_editor.tag_index -= 1
