class_name ImageExportDataSVG extends ImageExportData

func get_format() -> String:
	return "svg"

func image_to_buffer(_image: Image) -> PackedByteArray:
	return State.get_export_text().to_utf8_buffer()

func inject_ui_to_control(_main_container: VBoxContainer, _dimensions: Vector2) -> void:
	return
