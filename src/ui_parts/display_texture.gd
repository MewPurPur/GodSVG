extends TextureRect

var rasterized := false:
	set(new_value):
		if new_value != rasterized:
			rasterized = new_value
			queue_update()

var zoom := 1.0:
	set(new_value):
		var old_zoom := zoom
		zoom = new_value
		# No need to recalibrate when zooming out, the concern is pixelation.
		if old_zoom < zoom:
			queue_update()

var image_zoom := 0.0

var update_pending := false

func _ready() -> void:
	SVG.root_tag.attribute_changed.connect(queue_update)
	SVG.root_tag.child_tag_attribute_changed.connect(queue_update)
	SVG.root_tag.tag_added.connect(queue_update)
	SVG.root_tag.tag_deleted.connect(queue_update.unbind(1))
	SVG.root_tag.tag_moved.connect(queue_update.unbind(2))
	SVG.root_tag.changed_unknown.connect(queue_update)
	queue_update()

func queue_update() -> void:
	update_pending = true

func _process(_delta: float) -> void:
	if update_pending:
		svg_update()
		update_pending = false

func svg_update() -> void:
	var bigger_side := maxf(SVG.root_tag.attributes.width.get_value(),
			SVG.root_tag.attributes.height.get_value())
	var img := Image.new()
	# Don't waste time resizing if the new image won't be bigger.
	var new_image_zoom := 1.0 if rasterized else minf(zoom * 4.0, 16384 / bigger_side)
	if not rasterized and new_image_zoom <= image_zoom:
		return
	else:
		image_zoom = new_image_zoom
	
	img.load_svg_from_string(SVG.string, image_zoom)
	if not img.is_empty():
		texture = ImageTexture.create_from_image(img)
