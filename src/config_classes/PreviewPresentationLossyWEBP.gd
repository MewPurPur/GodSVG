class_name PreviewPresentationLossyWEBP extends PreviewPresentation

@export var quality := 0.75:
	set(new_value):
		if new_value != quality:
			quality = new_value
			emit_changed()

func get_presentation_name() -> String:
	return "WebP (%s)" % Translator.translate("Lossy")

func get_extra_info() -> String:
	return "WebP (%s: %s%%)" % [Translator.translate("Quality"), String.num_uint64(roundi(quality * 100))]

func get_equivalent_export_data() -> ImageExportData:
	var export_data := ImageExportDataWEBP.new()
	export_data.lossy = true
	export_data.quality = quality
	return export_data
