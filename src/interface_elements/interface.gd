extends VBoxContainer

const TagEditor = preload("tag_editor.tscn")

@onready var shapes: VBoxContainer = $Shapes

func add_circle() -> void:
	var circle_editor := TagEditor.instantiate()
	circle_editor.tag_index = SVG.data.tags.size()
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
	var rect := SVGTagRect.new()
	for attribute in rect.attributes:
		match attribute:
			"width": rect.attributes[attribute].value = 1.0
			"height": rect.attributes[attribute].value = 1.0
			_: rect.attributes[attribute].value = rect.attributes[attribute].default
	rect_editor.tag = rect
	shapes.add_child(rect_editor)

func _change_view_box(w: int, h: int) -> void:
	SVG.data.w = w
	SVG.data.h = h
	SVG.update()
	%Checkerboard.size = Vector2(w,h) * 15
