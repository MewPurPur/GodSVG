extends PanelContainer

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")
const SVGFileDialog = preload("res://src/ui_parts/svg_file_dialog.tscn")

var upscale_amount := -1.0
var extension := ""
var dimensions := Vector2.ZERO

@onready var dimensions_label: Label = %DimensionsLabel
@onready var texture_preview: TextureRect = %TexturePreview
@onready var dropdown: HBoxContainer = %Dropdown
@onready var final_dimensions_label: Label = %FinalDimensions
@onready var scale_edit: NumberEditType = %Scale
@onready var scale_container: VBoxContainer = %ScaleContainer

func _ready() -> void:
	scale_edit.value_changed.connect(_on_scale_value_changed)
	dropdown.value_changed.connect(_on_dropdown_value_changed)
	extension = dropdown.value
	update_extension_configuration()
	dimensions = SVG.root_tag.get_size()
	scale_edit.min_value = 1/minf(dimensions.x, dimensions.y)
	scale_edit.max_value = 16384/maxf(dimensions.x, dimensions.y)
	scale_edit.set_value(minf(scale_edit.get_value(),
			2048/maxf(dimensions.x, dimensions.y)))
	update_dimensions_label()
	update_final_scale()
	var scaling_factor := texture_preview.size.x * 2.0 / maxf(dimensions.x, dimensions.y)
	var img := Image.new()
	img.load_svg_from_string(SVG.text, scaling_factor)
	if not img.is_empty():
		img.fix_alpha_edges()
		texture_preview.texture = ImageTexture.create_from_image(img)


func update_dimensions_label() -> void:
	dimensions_label.text = tr(&"#size") + ": " + NumberParser.num_to_text(dimensions.x) +\
			"×" + NumberParser.num_to_text(dimensions.y)

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
				HTML5FileExchange.save_png(_create_img())
			_:
				HTML5FileExchange.save_svg()
	else:
		SVG.open_save_dialog(extension, native_file_export, export)

func export(path: String) -> void:
	if path.get_extension().is_empty():
		path += "." + extension
	
	GlobalSettings.modify_save_data(&"last_used_dir", path.get_base_dir())
	
	match extension:
		"png":
			_create_img().save_png(path)
		_:
			# SVG / fallback.
			GlobalSettings.modify_save_data(&"current_file_path", path)
			SVG.save_svg_to_file(path)
	queue_free()

func _on_cancel_button_pressed() -> void:
	queue_free()


func _on_scale_value_changed(_new_value: float) -> void:
	update_final_scale()

func update_final_scale() -> void:
	upscale_amount = scale_edit.get_value()
	var exported_size: Vector2i = dimensions * upscale_amount
	final_dimensions_label.text = tr(&"#final_size") +\
			": %d×%d" % [exported_size.x, exported_size.y]

func update_extension_configuration() -> void:
	scale_container.visible = (extension == "png")

func _create_img() -> Image:
	var export_svg := SVG.root_tag.create_duplicate()
	export_svg.attributes.width.set_num(export_svg.width * upscale_amount)
	export_svg.attributes.height.set_num(export_svg.height * upscale_amount)
	var img := Image.new()
	img.load_svg_from_string(SVGParser.svg_to_text(export_svg))
	img.fix_alpha_edges()  # See godot issue 82579.
	return img
