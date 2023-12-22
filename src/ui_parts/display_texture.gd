extends TextureRect

var zoom := 1.0:
	set(new_value):
		zoom = new_value
		queue_update()

var view_rect := Rect2():
	set(new_value):
		view_rect = new_value
		queue_update()

var rasterized := false:
	set(new_value):
		if new_value != rasterized:
			rasterized = new_value
			if zoom != 1.0:
				queue_update()


var image_zoom := 0.0
var update_pending := false


func _ready() -> void:
	SVG.root_tag.tag_layout_changed.connect(queue_update)
	SVG.root_tag.changed_unknown.connect(queue_update)
	SVG.root_tag.attribute_changed.connect(queue_update.unbind(1))
	SVG.root_tag.child_attribute_changed.connect(queue_update.unbind(1))
	queue_update()

func queue_update() -> void:
	update_pending = true

func _process(_delta: float) -> void:
	if update_pending:
		svg_update()
		update_pending = false


func svg_update() -> void:
	# TODO optimize this?
	var svg_tag := SVG.root_tag.create_duplicate()
	svg_tag.attributes.viewBox.set_rect(view_rect)
	svg_tag.attributes.width.set_num(view_rect.size.x)
	svg_tag.attributes.height.set_num(view_rect.size.y)
	
	image_zoom = 1.0 if rasterized else minf(zoom,
			16384 / maxf(svg_tag.get_width(), svg_tag.get_height()))
	
	var img := Image.new()
	img.load_svg_from_string(SVGParser.svg_to_text(svg_tag), image_zoom)
	texture = ImageTexture.create_from_image(img)
	position = view_rect.position
	size = view_rect.size
