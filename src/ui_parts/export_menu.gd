extends PanelContainer

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")
const ColorEdit = preload("res://src/ui_widgets/color_edit.gd")
const BasicDropdown = preload("res://src/ui_widgets/dropdown_basic.gd")
const PreviewRect = preload("res://src/ui_widgets/preview_rect.gd")

const AlertDialogScene = preload("res://src/ui_widgets/alert_dialog.tscn")

var undo_redo := UndoRedoRef.new()
var export_data_resources: Dictionary[String, ImageExportData] = {
	"svg": ImageExportDataSVG.new(),
	"png": ImageExportDataPNG.new(),
	"jpg": ImageExportDataJPG.new(),
	"webp": ImageExportDataWEBP.new(),
	"dds": ImageExportDataDDS.new(),
}
var current_format := ""
var dimensions := Vector2.ZERO

@onready var dimensions_label: Label = %DimensionsLabel
@onready var texture_preview: PreviewRect = %TexturePreview
@onready var format_dropdown: BasicDropdown = %FormatDropdown
@onready var final_size_label: Label = %FinalSizeLabel
@onready var clipboard_button: Button = %ClipboardButton
@onready var cancel_button: Button = %ButtonContainer/CancelButton
@onready var export_button: Button = %ButtonContainer/ExportButton
@onready var file_title: Label = %FileTitle
@onready var info_tooltip: MarginContainer = %InfoTooltip
@onready var titled_panel: HTitledPanel = %TitledPanel
@onready var content_container: VBoxContainer = %ContentContainer

func get_edited_export_data() -> ImageExportData:
	return export_data_resources[current_format]

func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("ui_undo", undo_redo.undo)
	shortcuts.add_shortcut("ui_redo", undo_redo.redo)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	final_size_label.add_theme_color_override("font_color", ThemeUtils.subtle_text_color)
	cancel_button.pressed.connect(queue_free)
	export_button.pressed.connect(_on_export_button_pressed)
	clipboard_button.pressed.connect(_on_clipboard_button_pressed)
	format_dropdown.value_changed.connect(_on_format_dropdown_value_changed)
	
	# Update dimensions label.
	dimensions = State.root_element.get_size()
	dimensions_label.text = Translator.translate("Dimensions") + ": " + get_dimensions_text(dimensions)
	set_current_format("svg")
	
	# Setup the warning for when the image is too big to have a preview.
	var scaling_factor := texture_preview.MAX_IMAGE_DIMENSION / maxf(dimensions.x, dimensions.y)
	info_tooltip.tooltip_text = Translator.translate("Preview image size is limited to {dimensions}").format(
			{"dimensions": get_dimensions_text(Vector2(maxf(dimensions.x * scaling_factor, 1.0), maxf(dimensions.y * scaling_factor, 1.0)), true)})
	info_tooltip.modulate = ThemeUtils.info_icon_color
	
	if Configs.savedata.get_active_tab().svg_file_path.is_empty():
		file_title.add_theme_color_override("font_color", ThemeUtils.subtle_text_color)
		file_title.text = Configs.savedata.get_active_tab().presented_name
	
	%TitleLabel.text = Translator.translate("Export Configuration")
	%FormatHBox/Label.text = Translator.translate("Format") + ":"
	cancel_button.text = Translator.translate("Cancel")
	export_button.text = Translator.translate("Export")
	clipboard_button.tooltip_text = Translator.translate("Copy")
	
	titled_panel.corner_radius_bottom_left = 0
	titled_panel.corner_radius_bottom_right = 5
	titled_panel.corner_radius_top_left = 5
	titled_panel.corner_radius_top_right = 5
	titled_panel.color = ThemeUtils.basic_panel_inner_color
	titled_panel.border_color = ThemeUtils.basic_panel_border_color
	titled_panel.border_width = 2
	titled_panel.title_margin = 2
	titled_panel.panel_margin = 10
	
	HandlerGUI.register_focus_sequence(self, [clipboard_button, format_dropdown, content_container, cancel_button, export_button], true)


func _on_export_button_pressed() -> void:
	FileUtils.open_export_dialog(get_edited_export_data())

func _on_clipboard_button_pressed() -> void:
	var error := ClipboardUtils.copy_image(get_edited_export_data())
	if error.type != ClipboardUtils.ErrorType.OK:
		var alert_dialog := AlertDialogScene.instantiate()
		HandlerGUI.add_dialog(alert_dialog)
		alert_dialog.setup(error.message)

func _on_format_dropdown_value_changed(new_value: String) -> void:
	undo_redo.create_action()
	undo_redo.add_do_method(set_current_format.bind(new_value))
	undo_redo.add_undo_method(set_current_format.bind(current_format))
	undo_redo.commit_action()


func set_current_format(new_format: String) -> void:
	if new_format == current_format or not new_format in export_data_resources:
		return
	if not current_format.is_empty():
		export_data_resources[current_format].changed.disconnect(_on_edited_export_data_changed)
		export_data_resources[current_format].borrowed_undo_redo = null
	current_format = new_format
	format_dropdown.set_value(current_format, false)
	get_edited_export_data().changed.connect(_on_edited_export_data_changed)
	_on_edited_export_data_changed()
	export_data_resources[current_format].borrowed_undo_redo = undo_redo
	
	for child in content_container.get_children():
		child.queue_free()
	get_edited_export_data().inject_ui_to_control(content_container, dimensions)
	
	var file_name := Utils.get_file_name(Configs.savedata.get_active_tab().svg_file_path)
	if not file_name.is_empty():
		file_title.text = file_name + "." + current_format
	clipboard_button.disabled = not ClipboardUtils.is_supported(current_format)

func _on_edited_export_data_changed() -> void:
	var export_data := get_edited_export_data()
	
	if export_data is ImageExportDataRaster:
		for resource in export_data_resources.values():
			if resource is ImageExportDataRaster:
				resource.upscale_amount = export_data.upscale_amount
	
	var export_size: int
	if export_data is ImageExportDataRaster:
		texture_preview.setup_image(export_data)
		var export_size_factor := roundf(export_data.upscale_amount * maxf(dimensions.x, dimensions.y)) / texture_preview.MAX_IMAGE_DIMENSION
		# Calculate or estimate size. WebP fares better when scaled.
		if not export_data is ImageExportDataWEBP:
			export_size_factor **= 2
		export_size = roundi(texture_preview.last_image_size * maxf(1.0, export_size_factor))
		final_size_label.text = Translator.translate("Size") if export_size_factor <= 1.0 else Translator.translate("Estimated size")
	else:
		texture_preview.setup_svg(State.get_export_text(), dimensions)
		export_size = State.get_export_text().length()
		final_size_label.text = Translator.translate("Size")
	
	final_size_label.text += ": " + String.humanize_size(export_size)
	info_tooltip.visible = (export_data is ImageExportDataRaster and\
			roundi(export_data.upscale_amount * maxf(dimensions.x, dimensions.y)) > texture_preview.MAX_IMAGE_DIMENSION)

func get_dimensions_text(sides: Vector2, integer := false) -> String:
	var precision := 0 if integer else 2
	return "%s×%s" % [Utils.num_simple(sides.x, precision), Utils.num_simple(sides.y, precision)]
