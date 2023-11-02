extends TextureRect

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

func _ready() -> void:
	SVG.root_tag.attribute_changed.connect(queue_update)
	SVG.root_tag.child_tag_attribute_changed.connect(queue_update)
	SVG.root_tag.tags_added.connect(queue_update.unbind(1))
	SVG.root_tag.tags_deleted.connect(queue_update.unbind(1))
	SVG.root_tag.tags_moved.connect(queue_update.unbind(2))
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

func svg_update(svg_changed := true) -> void:
	var bigger_side := maxf(SVG.root_tag.attributes.width.get_value(),
			SVG.root_tag.attributes.height.get_value())
	var img := Image.new()
	var new_image_zoom := 1.0 if rasterized else minf(zoom * 4.0, 16384 / bigger_side)
	if not svg_changed and not rasterized and new_image_zoom <= image_zoom:
		return  # Don't waste time resizing if the new image won't be bigger.
	else:
		image_zoom = new_image_zoom
	
	img.load_svg_from_string(SVG.string, image_zoom)
	if not img.is_empty():
		texture = ImageTexture.create_from_image(img)
