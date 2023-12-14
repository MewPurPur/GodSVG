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
		GlobalSettings.modify_save_data(&"last_used_dir", files[0].get_base_dir())

func non_native_file_import(file_path: String) -> void:
	export(file_path)
	GlobalSettings.modify_save_data(&"last_used_dir", file_path.get_base_dir())


func _on_ok_button_pressed() -> void:
	# Open it inside a native file dialog, or our custom one if it's not available.
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG):
		DisplayServer.file_dialog_show("Export a ." + extension + " file",
				Utils.get_last_dir(), "", false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
				["*." + extension], native_file_export)
	else:
		var svg_export_dialog := SVGFileDialog.instantiate()
		svg_export_dialog.current_dir = Utils.get_last_dir()
		svg_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		HandlerGUI.add_overlay(svg_export_dialog)
		svg_export_dialog.file_selected.connect(non_native_file_import)

func export(path: String) -> void:
	var FA := FileAccess.open(path, FileAccess.WRITE)
	match extension:
		"png":
			var export_svg := SVG.root_tag.create_duplicate()
			export_svg.attributes.width.set_num(export_svg.get_width() * upscale_amount)
			export_svg.attributes.height.set_num(export_svg.get_height() * upscale_amount)
			var img := Image.new()
			img.load_svg_from_string(SVGParser.svg_to_text(export_svg))
			img.fix_alpha_edges()  # See godot issue 82579.
			img.save_png(path)
		_:
			# SVG / fallback.
			FA.store_string(SVG.text)
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
