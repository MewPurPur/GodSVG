@abstract class_name ImageExportData extends Resource

const image_types_dict: Dictionary[String, String] = {
	"svg": "image/svg+xml",
	"png": "image/png",
	"jpg": "image/jpeg",
	"jpeg": "image/jpeg",
	"jfif": "image/jpeg",
	"jfi": "image/jpeg",
	"jif": "image/jpeg",
	"jpe": "image/jpeg",
	"webp": "image/webp",
	"dds": "image/vnd-ms.dds",
}

var borrowed_undo_redo: UndoRedoRef

@abstract func get_format() -> String

@abstract func image_to_buffer(image: Image) -> PackedByteArray

@abstract func inject_ui_to_control(main_container: VBoxContainer, dimensions: Vector2) -> void

func inject_in_export_svg(_export_svg: ElementRoot) -> void:
	return


func generate_image() -> Image:
	var export_svg := State.root_element.duplicate()
	inject_in_export_svg(export_svg)
	var img := Image.new()
	img.load_svg_from_string(SVGParser.root_to_export_markup(export_svg))
	return img
