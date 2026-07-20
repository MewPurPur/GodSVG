## A resource passed to ElementRoot.optimize() to determine configs.
@abstract class_name PreviewPresentation extends ConfigResource

const checkerboard = preload("res://assets/icons/CheckerboardMini.svg")

@export var background_color := Color.TRANSPARENT:
	set(new_value):
		if background_color != new_value:
			background_color = new_value
			emit_changed()


@abstract func get_presentation_name() -> String

@abstract func get_extra_info() -> String

@abstract func get_equivalent_export_data() -> ImageExportData

func generate_texture(upscale_amount: float) -> Texture2D:
	var export_data := get_equivalent_export_data()
	if export_data is ImageExportDataRaster:
		export_data.upscale_amount = upscale_amount
	var image := Image.new()
	export_data.load_from_buffer(image, export_data.image_to_buffer(export_data.generate_image()))
	return ImageTexture.create_from_image(image)

func draw_on_button(btn: Button, ci: RID) -> void:
	var sb := btn.get_theme_stylebox("normal")
	var pos := Vector2(sb.content_margin_left, sb.content_margin_top)
	
	RenderingServer.canvas_item_clear(ci)
	if background_color.a < 1.0:
		checkerboard.draw(ci, pos)
	if background_color.a > 0.0:
		RenderingServer.canvas_item_add_rect(ci, Rect2(pos, checkerboard.get_size()), background_color)
	var offset := checkerboard.get_width() + 6
	
	var font := btn.get_theme_font("font")
	var font_size := btn.get_theme_font_size("font_size")
	var text_line := TextLine.new()
	text_line.add_string(get_extra_info(), font, font_size)
	text_line.draw(ci, Vector2(pos.x + offset, pos.y + (checkerboard.get_height() - text_line.get_size().y) * 0.5), btn.get_theme_color("font_color"))
	btn.custom_minimum_size.x = offset + text_line.get_line_width() + sb.content_margin_left + sb.content_margin_right
