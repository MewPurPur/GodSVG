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

var update_pending := false

func _ready() -> void:
	SVG.root_tag.attribute_changed.connect(queue_update)
	SVG.root_tag.child_tag_attribute_changed.connect(queue_update.unbind(1))
	SVG.root_tag.tag_added.connect(queue_update.unbind(1))
	SVG.root_tag.tag_deleted.connect(queue_update.unbind(2))
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
	# Store the SVG string.
	var img := Image.new()
	img.load_svg_from_string(SVG.string, 1.0 if rasterized else zoom * 4.0)
	# Update the display.
	if not img.is_empty():
		var image_texture := ImageTexture.create_from_image(img)
		texture = image_texture
