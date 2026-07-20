class_name ImageExportDataDDS extends ImageExportDataRaster

func get_format() -> String:
	return "dds"

func image_to_buffer(image: Image) -> PackedByteArray:
	return image.save_dds_to_buffer()

func load_from_buffer(image: Image, buffer: PackedByteArray) -> void:
	image.load_dds_from_buffer(buffer)

func generate_and_save_image_to_path(file_path: String) -> void:
	return generate_image().save_dds(file_path)
