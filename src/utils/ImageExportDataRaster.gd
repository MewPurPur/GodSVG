@abstract class_name ImageExportDataRaster extends ImageExportData

@export var upscale_amount := 1.0:
	set(new_value):
		if new_value != upscale_amount:
			upscale_amount = new_value
			emit_changed()

@export var background_color := Color.TRANSPARENT:
	set(new_value):
		if new_value != background_color:
			background_color = new_value
			emit_changed()


@abstract func load_from_buffer(image: Image, buffer: PackedByteArray) -> void

func inject_in_export_svg(export_svg: ElementRoot) -> void:
	if export_svg.get_attribute_list("viewBox").is_empty():
		export_svg.set_attribute("viewBox", PackedFloat64Array([0.0, 0.0, export_svg.width, export_svg.height]))
	# First ensure there are dimensions. Otherwise changing one side could influence the other.
	export_svg.set_attribute("width", export_svg.width)
	export_svg.set_attribute("height", export_svg.height)
	var rect_element := ElementRect.new()
	rect_element.set_attribute("width", export_svg.width)
	rect_element.set_attribute("height", export_svg.height)
	rect_element.set_attribute("fill", "#" + background_color.to_html(false))
	rect_element.set_attribute("fill-opacity", background_color.a)
	export_svg.insert_child(0, rect_element)
	export_svg.set_attribute("width", export_svg.width * upscale_amount)
	export_svg.set_attribute("height", export_svg.height * upscale_amount)
