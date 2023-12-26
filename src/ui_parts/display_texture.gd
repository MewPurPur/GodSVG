extends TextureRect

var view_rect := Rect2():
	set(new_value):
		view_rect = new_value
		queue_update()

var rasterized := false:
	set(new_value):
		if new_value != rasterized:
			rasterized = new_value
			if Indications.zoom != 1.0:
				queue_update()

var update_pending := false


func _ready() -> void:
	SVG.root_tag.tag_layout_changed.connect(queue_update)
	SVG.root_tag.changed_unknown.connect(queue_update)
	SVG.root_tag.attribute_changed.connect(queue_update.unbind(1))
	SVG.root_tag.child_attribute_changed.connect(queue_update.unbind(1))
	Indications.zoom_changed.connect(queue_update)
	queue_update()


func queue_update() -> void:
	update_pending = true

func _process(_delta: float) -> void:
	if update_pending:
		svg_update()
		update_pending = false


func svg_update() -> void:
	var image_zoom := 1.0 if rasterized else Indications.zoom
	var pixel_size := 1 / image_zoom
	
	var svg_tag: TagSVG = SVG.root_tag.create_duplicate()
	# Translate to canvas coords.
	var display_rect := view_rect.grow(pixel_size)
	display_rect.position = display_rect.position.snapped(Vector2(pixel_size, pixel_size))
	display_rect.position.x = maxf(display_rect.position.x, 0.0)
	display_rect.position.y = maxf(display_rect.position.y, 0.0)
	display_rect.size = display_rect.size.snapped(Vector2(pixel_size, pixel_size))
	display_rect.end.x = minf(display_rect.end.x, svg_tag.width)
	display_rect.end.y = minf(display_rect.end.y, svg_tag.height)
	
	svg_tag.attributes.viewBox.set_rect(Rect2(
			svg_tag.world_to_canvas(display_rect.position),
			display_rect.size / svg_tag.canvas_transform.get_scale()))
	svg_tag.attributes.width.set_num(display_rect.size.x)
	svg_tag.attributes.height.set_num(display_rect.size.y)
	
	var img := Image.new()
	img.load_svg_from_string(SVGParser.svg_to_text(svg_tag), image_zoom)
	texture = ImageTexture.create_from_image(img)
	position = display_rect.position
	size = display_rect.size
