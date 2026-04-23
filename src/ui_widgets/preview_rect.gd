extends CenterContainer

const MAX_IMAGE_DIMENSION = 512

@onready var checkerboard: TextureRect = $Checkerboard
@onready var texture_preview: TextureRect = $Checkerboard/TexturePreview

## The size of the last setup image, in bytes.
var last_image_size: int

func setup_svg_without_dimensions(svg_text: String) -> void:
	var root := SVGParser.markup_to_root(svg_text).svg
	if is_instance_valid(root):
		setup_svg(svg_text, root.get_size())
	else:
		hide()

func setup_svg(svg_text: String, dimensions: Vector2) -> void:
	if not is_node_ready():
		await ready
	var scaling_factor := size.x / maxf(dimensions.x, dimensions.y)
	var img := Image.new()
	var err := img.load_svg_from_string(svg_text, scaling_factor)
	if err == OK:
		img.fix_alpha_edges()
		_set_image(img)

func setup_image(config: ImageExportDataRaster) -> void:
	var final_image_config: ImageExportDataRaster = config.duplicate()
	var svg_size := State.root_element.get_size()
	final_image_config.upscale_amount = minf(config.upscale_amount, MAX_IMAGE_DIMENSION / maxf(svg_size.x, svg_size.y))
	var image := Image.new()
	var buffer := final_image_config.image_to_buffer(final_image_config.generate_image())
	last_image_size = buffer.size()
	config.load_from_buffer(image, buffer)
	
	var factor := minf(size.x / image.get_width(), size.y / image.get_height())
	image.resize(maxi(int(image.get_width() * factor), 1), maxi(int(image.get_height() * factor), 1),
			Image.INTERPOLATE_NEAREST if factor >= 2 else Image.INTERPOLATE_BILINEAR)
	_set_image(image)

func _set_image(image: Image) -> void:
	var image_texture := ImageTexture.create_from_image(image)
	texture_preview.texture = image_texture
	checkerboard.custom_minimum_size = image_texture.get_size()
	checkerboard.material.set_shader_parameter("uv_scale", 256 / maxf(image_texture.get_width(), image_texture.get_height()))

func shrink_to_fit(true_minimum_width: float, true_minimum_height: float) -> void:
	if not is_node_ready():
		await ready
	custom_minimum_size = Vector2(maxf(checkerboard.custom_minimum_size.x, true_minimum_width),
			maxf(checkerboard.custom_minimum_size.y, true_minimum_height))
