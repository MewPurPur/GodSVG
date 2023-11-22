extends Dialog

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")
const SVGFileDialog = preload("svg_file_dialog.tscn")

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
	extension = dropdown.current_value
	update_extension_configuration()
	dimensions = SVG.root_tag.get_size()
	scale_edit.min_value = 1/minf(dimensions.x, dimensions.y)
	update_dimensions_label()
	update_final_scale()
	var scaling_factor := 512.0 / maxf(dimensions.x, dimensions.y)
	var img := Image.new()
	img.load_svg_from_string(SVG.text, scaling_factor)
	if not img.is_empty():
		texture_preview.texture = ImageTexture.create_from_image(img)


func update_dimensions_label() -> void:
	dimensions_label.text = tr(&"#size") +\
			": %s×%s" % [String.num(dimensions.x, 4), String.num(dimensions.y, 4)]

func _on_dropdown_value_changed(new_value: String) -> void:
	extension = new_value
	update_extension_configuration()


func native_file_export(has_selected: bool, files: PackedStringArray, _filter_idx: int):
	if has_selected:
		export(files[0])

func _on_ok_button_pressed() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG):
		DisplayServer.file_dialog_show(
				"Export a ." + extension + " file",
				OS.get_system_dir(OS.SYSTEM_DIR_PICTURES), "", false,
				DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
				["*." + extension], native_file_export)
	else:
		var svg_export_dialog := SVGFileDialog.instantiate()
		svg_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		get_tree().get_root().add_child(svg_export_dialog)
		svg_export_dialog.file_selected.connect(export)

func export(path: String) -> void:
	var FA := FileAccess.open(path, FileAccess.WRITE)
	match extension:
		"png":
			var img := texture_preview.texture.get_image()
			var exported_size := dimensions * upscale_amount
			# It's a single SVG, so just use the most expensive interpolation.
			img.resize(int(exported_size.x), int(exported_size.y), Image.INTERPOLATE_LANCZOS)
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
