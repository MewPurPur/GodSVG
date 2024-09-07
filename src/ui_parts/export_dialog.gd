extends PanelContainer

const NumberEditType = preload("res://src/ui_widgets/number_edit.gd")

var upscale_amount := -1.0
var quality := 0.8
var lossless := true
var extension := ""
var dimensions := Vector2.ZERO

@onready var dimensions_label: Label = %DimensionsLabel
@onready var texture_preview: CenterContainer = %TexturePreview
@onready var format_hbox: HBoxContainer = %FormatHBox
@onready var format_dropdown: HBoxContainer = %FormatHBox/Dropdown
@onready var final_dimensions_label: Label = %FinalDimensions
@onready var scale_edit: NumberEditType = %Scale
@onready var scale_container: VBoxContainer = %ScaleContainer
@onready var lossless_checkbox: CheckBox = %LosslessCheckBox
@onready var quality_edit: NumberEditType = %Quality
@onready var quality_hbox: HBoxContainer = %QualityHBox
@onready var fallback_format_label: Label = %FallbackFormatLabel
@onready var cancel_button: Button = %ButtonContainer/CancelButton

func _ready() -> void:
	cancel_button.pressed.connect(HandlerGUI.remove_overlay)
	scale_edit.value_changed.connect(update_final_scale.unbind(1))
	quality_edit.value_changed.connect(_on_quality_value_changed)
	format_dropdown.value_changed.connect(_on_dropdown_value_changed)
	extension = format_dropdown.value
	update_extension_configuration()
	dimensions = SVG.root_element.get_size()
	var bigger_dimension := maxf(dimensions.x, dimensions.y)
	scale_edit.min_value = 1 / minf(dimensions.x, dimensions.y)
	scale_edit.max_value = 16384 / bigger_dimension
	scale_edit.set_value(minf(scale_edit.get_value(), 2048 / bigger_dimension))
	texture_preview.setup(SVG.get_export_text(), dimensions)
	
	# Update dimensions label.
	var valid_dimensions := is_finite(dimensions.x) and is_finite(dimensions.y)
	dimensions_label.text = TranslationServer.translate("Size") + ": "
	if valid_dimensions:
		dimensions_label.text += String.num(dimensions.x, 2) + "×" +\
				String.num(dimensions.y, 2)
	else:
		dimensions_label.text += TranslationServer.translate("Invalid")
	# If the size is invalid, only SVG exports are relevant. So hide the dropdown.
	fallback_format_label.visible = !valid_dimensions
	format_hbox.visible = valid_dimensions
	update_final_scale()
	fallback_format_label.text = TranslationServer.translate("Format") + ": svg"
	$VBoxContainer/Label.text = TranslationServer.translate("Export Configuration")
	%FormatHBox/Label.text = TranslationServer.translate("Format")
	%LosslessCheckBox.text = TranslationServer.translate("Lossless")
	%QualityHBox/Label.text = TranslationServer.translate("Quality")
	%ScaleContainer/HBoxContainer/Label.text = TranslationServer.translate("Scale")
	$VBoxContainer/ButtonContainer/CancelButton.text =\
			TranslationServer.translate("Cancel")
	$VBoxContainer/ButtonContainer/ExportButton.text =\
			TranslationServer.translate("Export")


func _on_dropdown_value_changed(new_value: String) -> void:
	extension = new_value
	update_extension_configuration()


func _on_export_button_pressed() -> void:
	if OS.has_feature("web"):
		var svg_image := FileUtils.generate_image_from_elements(upscale_amount)
		match extension:
			"png": FileUtils.web_save_png(svg_image)
			"jpg": FileUtils.web_save_jpg(svg_image)
			"webp": FileUtils.web_save_webp(svg_image)
			_: FileUtils.web_save_svg()
	else:
		FileUtils.open_save_dialog(extension,
				FileUtils.native_file_export.bind(extension, upscale_amount),
				FileUtils.finish_export.bind(extension, upscale_amount, quality, lossless))

func _on_lossless_check_box_toggled(toggled_on: bool) -> void:
	lossless = toggled_on
	if extension == "webp":
		quality_hbox.visible = not lossless

func _on_quality_value_changed(_new_value: float) -> void:
	quality = _new_value / 100

func update_final_scale() -> void:
	upscale_amount = scale_edit.get_value()
	var exported_size: Vector2i = dimensions * upscale_amount
	final_dimensions_label.text = TranslationServer.translate("Final size") +\
			": %d×%d" % [exported_size.x, exported_size.y]

func update_extension_configuration() -> void:
	scale_container.visible = extension in ["png", "jpg", "webp"]
	lossless_checkbox.visible = (extension == "webp")
	quality_hbox.visible = extension in ["jpg", "webp"]
	_on_lossless_check_box_toggled(lossless)
