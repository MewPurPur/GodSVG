# We're not serializing this class at the moment, but its duplicate() method and changed signal are used.
@abstract class_name ImageExportData extends Resource

static func get_extension_mime_type(extension: String) -> String:
	match extension:
		"svg": return "image/svg+xml"
		"png": return "image/png"
		"jpg", "jpeg", "jpe", "jfif", "jfi", "jif": return "image/jpeg"
		"webp": return "image/webp"
		"dds": return "image/vnd-ms.dds"
	return ""

@abstract func get_format() -> String

@abstract func image_to_buffer(image: Image) -> PackedByteArray

func inject_in_export_svg(_export_svg: ElementRoot) -> void:
	return


func generate_image() -> Image:
	var export_svg := State.root_element.duplicate()
	inject_in_export_svg(export_svg)
	var img := Image.new()
	img.load_svg_from_string(SVGParser.root_to_export_markup(export_svg))
	return img
