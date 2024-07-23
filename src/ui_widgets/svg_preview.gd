extends CenterContainer

@onready var checkerboard: TextureRect = $Checkerboard
@onready var texture_preview: TextureRect = $Checkerboard/TexturePreview

func setup(svg_text: String, dimensions: Vector2) -> void:
	var scaling_factor := size.x * 2.0 / maxf(dimensions.x, dimensions.y)
	var img := Image.new()
	var err := img.load_svg_from_string(svg_text, scaling_factor)
	if err == OK:
		img.fix_alpha_edges()
		var img_texture := ImageTexture.create_from_image(img)
		texture_preview.texture = img_texture
		checkerboard.custom_minimum_size = img_texture.get_size() / 2.0
