extends CenterContainer

const MAX_IMAGE_DIMENSION = 512

@onready var checkerboard: TextureRect = $Checkerboard
@onready var texture_preview: TextureRect = $Checkerboard/TexturePreview

func setup_svg(svg_text: String, dimensions: Vector2) -> void:
	var scaling_factor := size.x / maxf(dimensions.x, dimensions.y)
	var img := Image.new()
	var err := img.load_svg_from_string(svg_text, scaling_factor)
	if err == OK:
		img.fix_alpha_edges()
		_set_image(img)

func setup_image(config: ImageExportData, full_scale := false) -> void:
	var final_image_config: ImageExportData
	if full_scale:
		final_image_config = config
	else:
		final_image_config = ImageExportData.new()
		final_image_config.format = config.format
		final_image_config.lossy = config.lossy
		final_image_config.quality = config.quality
		var svg_size := SVG.root_element.get_size()
		final_image_config.upscale_amount = minf(config.upscale_amount,
				MAX_IMAGE_DIMENSION / maxf(svg_size.x, svg_size.y))
	
	var buffer := final_image_config.image_to_buffer(final_image_config.generate_image())
	var image := Image.new()
	match config.format:
		"png": image.load_png_from_buffer(buffer)
		"jpg", "jpeg": image.load_jpg_from_buffer(buffer)
		"webp": image.load_webp_from_buffer(buffer)
	
	var factor := size.x / maxf(image.get_width(), image.get_height())
	var interp := Image.INTERPOLATE_NEAREST if factor >= 3 else Image.INTERPOLATE_BILINEAR
	image.resize(int(image.get_width() * factor), int(image.get_height() * factor), interp)
	_set_image(image)

func _set_image(image: Image) -> void:
	var image_texture := ImageTexture.create_from_image(image)
	texture_preview.texture = image_texture
	checkerboard.custom_minimum_size = image_texture.get_size()
