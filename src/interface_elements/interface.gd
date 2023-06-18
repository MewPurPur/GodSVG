extends VBoxContainer

const TagEditor = preload("tag_editor.tscn")

@onready var shapes: VBoxContainer = $Shapes

func add_circle() -> void:
	var circle_editor := TagEditor.instantiate()
	circle_editor.tag_index = SVG.data.tags.size()
	circle_editor.deleted.connect(_on_tag_deleted)
	var circle := SVGTagCircle.new()
	for attribute in circle.attributes:
		match attribute:
			"r": circle.attributes[attribute].value = 1.0
			_: circle.attributes[attribute].value = circle.attributes[attribute].default
	circle_editor.tag = circle
	shapes.add_child(circle_editor)

func add_ellipse() -> void:
	var ellipse_editor := TagEditor.instantiate()
	ellipse_editor.tag_index = SVG.data.tags.size()
	ellipse_editor.deleted.connect(_on_tag_deleted)
	var ellipse := SVGTagEllipse.new()
	for attribute in ellipse.attributes:
		match attribute:
			"rx": ellipse.attributes[attribute].value = 1.0
			"ry": ellipse.attributes[attribute].value = 1.0
			_: ellipse.attributes[attribute].value = ellipse.attributes[attribute].default
	ellipse_editor.tag = ellipse
	shapes.add_child(ellipse_editor)

func add_rect() -> void:
	var rect_editor := TagEditor.instantiate()
	rect_editor.tag_index = SVG.data.tags.size()
	rect_editor.deleted.connect(_on_tag_deleted)
	var rect := SVGTagRect.new()
	for attribute in rect.attributes:
		match attribute:
			"width": rect.attributes[attribute].value = 1.0
			"height": rect.attributes[attribute].value = 1.0
			_: rect.attributes[attribute].value = rect.attributes[attribute].default
	rect_editor.tag = rect
	shapes.add_child(rect_editor)

func add_path() -> void:
	var path_editor := TagEditor.instantiate()
	path_editor.tag_index = SVG.data.tags.size()
	path_editor.deleted.connect(_on_tag_deleted)
	var path := SVGTagPath.new()
	for attribute in path.attributes:
		path.attributes[attribute].value = path.attributes[attribute].default
	path_editor.tag = path
	shapes.add_child(path_editor)

func _change_view_box(w: int, h: int) -> void:
	SVG.data.w = w
	SVG.data.h = h
	SVG.update()
	%Checkerboard.size = Vector2(w, h) * 15


func _on_tag_deleted(index: int) -> void:
	for tag_editor in shapes.get_children():
		if &"tag_index" in tag_editor and tag_editor.tag_index > index:
			tag_editor.tag_index -= 1
