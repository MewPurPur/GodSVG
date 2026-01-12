class_name ImageExportData

const image_types_dict: Dictionary[String, String] = {
	"svg": "image/svg+xml",
	"png": "image/png",
	"jpg": "image/jpeg",
	"jpeg": "image/jpeg",
	"webp": "image/webp",
	"pdc": "image/x-pdc",
}

signal changed

var format := "svg":
	set(new_value):
		if new_value != format:
			format = new_value
			changed.emit()

var upscale_amount := 1.0:
	set(new_value):
		if new_value != upscale_amount:
			upscale_amount = new_value
			changed.emit()

var quality := 0.75:
	set(new_value):
		if new_value != quality:
			quality = new_value
			changed.emit()

var lossy := false:
	set(new_value):
		if new_value != lossy:
			lossy = new_value
			changed.emit()

var tesselation_tolerance_degrees := 4:
	set(new_value):
		if new_value != tesselation_tolerance_degrees:
			tesselation_tolerance_degrees = new_value
			changed.emit()


var precise_path_mode := PDCImage.PrecisePathMode.AUTODETECT:
	set(new_value):
		if new_value != precise_path_mode:
			precise_path_mode = new_value
			changed.emit()


static func svg_to_buffer() -> PackedByteArray:
	return State.get_export_text().to_utf8_buffer()


func image_to_buffer(image: Image) -> PackedByteArray:
	match format:
		"png": return image.save_png_to_buffer()
		"jpg", "jpeg": return image.save_jpg_to_buffer(quality)
		"webp": return image.save_webp_to_buffer(lossy, quality)
		_: return svg_to_buffer()


func generate_image() -> Image:
	var export_svg := State.root_element.duplicate()
	if export_svg.get_attribute_list("viewBox").is_empty():
		export_svg.set_attribute("viewBox", PackedFloat64Array([0.0, 0.0, export_svg.width, export_svg.height]))
	# First ensure there are dimensions.
	# Otherwise changing one side could influence the other.
	export_svg.set_attribute("width", export_svg.width)
	export_svg.set_attribute("height", export_svg.height)
	export_svg.set_attribute("width", export_svg.width * upscale_amount)
	export_svg.set_attribute("height", export_svg.height * upscale_amount)
	var img := Image.new()
	img.load_svg_from_string(SVGParser.root_to_export_markup(export_svg))
	img.fix_alpha_edges()  # See godot issue 82579.
	return img
