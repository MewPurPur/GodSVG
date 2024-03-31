extends PanelContainer

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")
const SVGFileDialog = preload("res://src/ui_parts/svg_file_dialog.tscn")

var upscale_amount := -1.0
var extension := ""
var dimensions := Vector2.ZERO

@onready var dimensions_label: Label = %DimensionsLabel
@onready var texture_preview: CenterContainer = %TexturePreview
@onready var format_hbox: HBoxContainer = %FormatHBox
@onready var format_dropdown: HBoxContainer = %FormatHBox/Dropdown
@onready var final_dimensions_label: Label = %FinalDimensions
@onready var scale_edit: NumberEditType = %Scale
@onready var scale_container: VBoxContainer = %ScaleContainer
@onready var fallback_format_label: Label = %FallbackFormatLabel

func _ready() -> void:
	scale_edit.value_changed.connect(_on_scale_value_changed)
	format_dropdown.value_changed.connect(_on_dropdown_value_changed)
	extension = format_dropdown.value
	update_extension_configuration()
	dimensions = SVG.root_tag.get_size()
	scale_edit.min_value = 1/minf(dimensions.x, dimensions.y)
	scale_edit.max_value = 16384/maxf(dimensions.x, dimensions.y)
	scale_edit.set_value(minf(scale_edit.get_value(),
			2048/maxf(dimensions.x, dimensions.y)))
	fallback_format_label.text = tr("Format") + ": svg"
	update_dimensions_label()
	update_final_scale()
	texture_preview.setup(SVG.text, dimensions)


func update_dimensions_label() -> void:
	var valid_dimensions := is_finite(dimensions.x) and is_finite(dimensions.y)
	dimensions_label.text = tr("Size") + ": "
	if valid_dimensions:
		dimensions_label.text += NumberParser.num_to_text(dimensions.x) +\
				"×" + NumberParser.num_to_text(dimensions.y)
	else:
		dimensions_label.text += tr("Invalid")
	# If the size is invalid, only SVG exports are relevant. So hide the dropdown.
	fallback_format_label.visible = !valid_dimensions
	format_hbox.visible = valid_dimensions

func _on_dropdown_value_changed(new_value: String) -> void:
	extension = new_value
	update_extension_configuration()


func native_file_export(has_selected: bool, files: PackedStringArray,
_filter_idx: int) -> void:
	if has_selected:
		export(files[0])

func _on_ok_button_pressed() -> void:
	if OS.has_feature("web"):
		match extension:
			"png":
				HandlerGUI.web_save_png(create_image())
			_:
				HandlerGUI.web_save_svg()
	else:
		SVG.open_save_dialog(extension, native_file_export, export)

func export(path: String) -> void:
	if path.get_extension().is_empty():
		path += "." + extension
	
	GlobalSettings.modify_save_data("last_used_dir", path.get_base_dir())
	
	match extension:
		"png":
			create_image().save_png(path)
		_:
			# SVG / fallback.
			GlobalSettings.modify_save_data("current_file_path", path)
			SVG.save_svg_to_file(path)
	HandlerGUI.remove_overlay()

func _on_cancel_button_pressed() -> void:
	HandlerGUI.remove_overlay()


func _on_scale_value_changed(_new_value: float) -> void:
	update_final_scale()

func update_final_scale() -> void:
	upscale_amount = scale_edit.get_value()
	var exported_size: Vector2i = dimensions * upscale_amount
	final_dimensions_label.text = tr("Final size") +\
			": %d×%d" % [exported_size.x, exported_size.y]

func update_extension_configuration() -> void:
	scale_container.visible = (extension == "png")

func create_image() -> Image:
	var export_svg := SVG.root_tag.create_duplicate()
	if export_svg.attributes.viewBox.get_list().is_empty():
		export_svg.attributes.viewBox.set_list([0, 0, export_svg.width, export_svg.height])
	export_svg.attributes.width.set_num(export_svg.width * upscale_amount)
	export_svg.attributes.height.set_num(export_svg.height * upscale_amount)
	var img := Image.new()
	img.load_svg_from_string(SVGParser.svg_to_text(export_svg))
	img.fix_alpha_edges()  # See godot issue 82579.
	return img
