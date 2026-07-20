class_name PreviewPresentationJPG extends PreviewPresentation

@export var quality := 0.75:
	set(new_value):
		if new_value != quality:
			quality = new_value
			emit_changed()

func get_presentation_name() -> String:
	return "JPEG"

func get_extra_info() -> String:
	return "JPEG (%s: %s%%)" % [Translator.translate("Quality"), String.num_uint64(roundi(quality * 100))]

func get_equivalent_export_data() -> ImageExportData:
	var export_data := ImageExportDataJPG.new()
	export_data.background_color = Color(background_color, 1.0)
	export_data.quality = quality
	return export_data
