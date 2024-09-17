extends TextureRect

var view_rect := Rect2():
	set(new_value):
		if view_rect != new_value:
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
	SVG.changed.connect(queue_update)
	Indications.zoom_changed.connect(queue_update)
	queue_update()


func queue_update() -> void:
	update_pending = true

func _process(_delta: float) -> void:
	if update_pending:
		update_pending = false
		
		var image_zoom := 1.0 if rasterized and Indications.zoom > 1.0 else Indications.zoom
		var pixel_size := 1 / image_zoom
		
		# Translate to canvas coords.
		var display_rect := view_rect.grow(pixel_size * 2)
		display_rect.position = display_rect.position.snapped(Vector2(pixel_size, pixel_size))
		display_rect.position.x = maxf(display_rect.position.x, 0.0)
		display_rect.position.y = maxf(display_rect.position.y, 0.0)
		display_rect.size = display_rect.size.snapped(Vector2(pixel_size, pixel_size))
		display_rect.end.x = minf(display_rect.end.x, SVG.root_element.width)
		display_rect.end.y = minf(display_rect.end.y, SVG.root_element.height)
		
		var svg_text := SVGParser.root_cutout_to_text(SVG.root_element, display_rect.size.x,
				display_rect.size.y, Rect2(SVG.root_element.world_to_canvas(display_rect.position),
				display_rect.size / SVG.root_element.canvas_transform.get_scale()))
		var img := Image.new()
		var err := img.load_svg_from_string(svg_text, image_zoom)
		if err == OK:
			position = display_rect.position
			# TODO check if deferred is still needed.
			set_deferred("size", display_rect.size)
			texture = ImageTexture.create_from_image(img)
