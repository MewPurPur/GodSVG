@abstract class_name ImageExportDataRaster extends ImageExportData

const NumberEditScene = preload("res://src/ui_widgets/number_edit.tscn")
const ColorEditWithOptionsScene = preload("res://src/ui_widgets/color_edit_with_options.tscn")
const ExportScaleConfigScene = preload("res://src/ui_widgets/export_scale_config.tscn")

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

# These methods would be used in the UI of all inheritting classes, so define them here.
func set_upscale_amount(new_value: float) -> void:
	if is_instance_valid(borrowed_undo_redo):
		borrowed_undo_redo.create_action("")
		borrowed_undo_redo.add_do_property(self, "upscale_amount", new_value)
		borrowed_undo_redo.add_undo_property(self, "upscale_amount", upscale_amount)
		borrowed_undo_redo.commit_action()
	else:
		upscale_amount = new_value

func set_background_color(new_value: String, is_final: bool, old_final_value: String) -> void:
	var new_background_color := ColorParser.text_to_color(new_value, Color.BLACK, true)
	if is_instance_valid(borrowed_undo_redo) and is_final:
		borrowed_undo_redo.create_action("")
		borrowed_undo_redo.add_do_property(self, "background_color", new_background_color)
		borrowed_undo_redo.add_undo_property(self, "background_color", old_final_value)
		borrowed_undo_redo.commit_action()
	else:
		background_color = new_background_color


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
