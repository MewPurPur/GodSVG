class_name PreviewPresentationLossless extends PreviewPresentation

func get_presentation_name() -> String:
	return Translator.translate("Lossless")

func get_extra_info() -> String:
	return Translator.translate("Lossless")

func get_equivalent_export_data() -> ImageExportData:
	return ImageExportDataPNG.new()
