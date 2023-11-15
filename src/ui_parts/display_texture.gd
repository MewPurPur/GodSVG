extends TextureRect

const strip_count = 8

var rasterized := false:
	set(new_value):
		if new_value != rasterized:
			rasterized = new_value
			queue_update()

var zoom := 1.0:
	set(new_value):
		zoom = new_value
		queue_update(false)

var image_zoom := 0.0

var update_pending := false
var svg_change_pending := false

# TODO a bug in ThorVG locks this. The TextureRect should be a Control.
# I had to draw the SVG with the rendering server, I got some white textures otherwise.
#var surface := RenderingServer.canvas_item_create()

func _ready() -> void:
	#RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	SVG.root_tag.attribute_changed.connect(queue_update)
	SVG.root_tag.child_attribute_changed.connect(queue_update)
	SVG.root_tag.tag_layout_changed.connect(queue_update)
	SVG.root_tag.changed_unknown.connect(queue_update)
	queue_update()

func queue_update(svg_changed := true) -> void:
	update_pending = true
	if svg_changed:
		svg_change_pending = true

func _process(_delta: float) -> void:
	if update_pending:
		svg_update(svg_change_pending)
		update_pending = false
		svg_change_pending = false


# Strips of the final image.

func svg_update(svg_changed := true) -> void:
	var bigger_side := maxf(SVG.root_tag.attributes.width.get_value(),
			SVG.root_tag.attributes.height.get_value())
	
	var new_image_zoom := 1.0 if rasterized else minf(zoom * 3.0, 16384 / bigger_side)
	if not svg_changed and not rasterized and new_image_zoom <= image_zoom:
		return  # Don't waste time resizing if the new image won't be bigger.
	else:
		image_zoom = new_image_zoom
	
	# TODO delete this when the ThorVG bug is fixed.
	var img := Image.new()
	img.load_svg_from_string(SVG.string, image_zoom)
	texture = ImageTexture.create_from_image(img)
	
	# TODO this is locked by a bug in ThorVG.
	#var task_id := WorkerThreadPool.add_group_task(generate_strip, strip_count)
	#WorkerThreadPool.wait_for_group_task_completion(task_id)
	#queue_redraw()

#var svg_strips: Array[Texture2D] = [null, null, null, null, null, null, null, null]

# TODO this is locked by a bug in ThorVG.
# 4 strips to be handled by WorkerThreadPool for faster image loading.
#func generate_strip(index: int) -> void:
	#var svg_tag := SVG.root_tag.create_duplicate()
	#svg_tag.attributes.width.set_value(svg_tag.attributes.width.get_value() / strip_count)
	#var viewbox_attrib_value: Rect2 = svg_tag.attributes.viewBox.get_value()
	#var strip_width := viewbox_attrib_value.size.x / strip_count
	#var offset := index * strip_width
	#svg_tag.attributes.viewBox.set_value(Rect2(viewbox_attrib_value.position +\
			#Vector2(offset, 0), Vector2(strip_width, viewbox_attrib_value.size.y)))
	#var svg_strip_string := SVGParser.svg_to_text(svg_tag)
	#var img := Image.new()
	#img.load_svg_from_string(svg_strip_string, image_zoom)
	#svg_strips[index] = ImageTexture.create_from_image(img)
#
#func _draw() -> void:
	#RenderingServer.canvas_item_clear(surface)
	#RenderingServer.canvas_item_set_default_texture_filter(surface,
			#RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST if rasterized else\
			#RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_LINEAR)
	#for strip_idx in svg_strips.size():
		#var strip := svg_strips[strip_idx]
		#if strip != null:
			#var rect := get_rect()
			#rect.size.x /= strip_count
			#rect.position.x += strip_idx * rect.size.x
			#strip.draw_rect(surface, rect, false)
