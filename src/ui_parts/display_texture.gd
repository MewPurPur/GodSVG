extends TextureRect

var update_pending := false

func _ready() -> void:
	SVG.data.resized.connect(queue_update)
	SVG.data.attribute_changed.connect(queue_update)
	SVG.data.tag_added.connect(queue_update)
	SVG.data.tag_deleted.connect(queue_update.unbind(1))
	SVG.data.tag_moved.connect(queue_update)
	SVG.data.changed_unknown.connect(queue_update)
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
	img.load_svg_from_string(SVG.string, 128.0)
	# Update the display.
	var image_texture := ImageTexture.create_from_image(img)
	texture = image_texture
