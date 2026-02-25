extends PanelContainer

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")
const BasicDropdown = preload("res://src/ui_widgets/dropdown_basic.gd")
const PreviewRect = preload("res://src/ui_widgets/preview_rect.gd")

const AlertDialogScene = preload("res://src/ui_widgets/alert_dialog.tscn")

var undo_redo := UndoRedoRef.new()
var export_data := ImageExportData.new()
var dimensions := Vector2.ZERO

@onready var dimensions_label: Label = %DimensionsLabel
@onready var texture_preview: PreviewRect = %TexturePreview
@onready var format_hbox: HBoxContainer = %FormatHBox
@onready var format_dropdown: Dropdown = %FormatHBox/Dropdown
@onready var final_size_label: Label = %FinalSizeLabel
@onready var clipboard_button: Button = %ClipboardButton
@onready var scale_edit: NumberEdit = %Scale
@onready var width_edit: NumberEdit = %Width
@onready var height_edit: NumberEdit = %Height
@onready var size_container: CenterContainer = %SizeContainer
@onready var lossless_checkbox: CheckBox = %LosslessCheckBox
@onready var quality_edit: NumberEdit = %Quality
@onready var quality_hbox: HBoxContainer = %QualityHBox
@onready var cancel_button: Button = %ButtonContainer/CancelButton
@onready var export_button: Button = %ButtonContainer/ExportButton
@onready var file_title: Label = %FileTitle
@onready var info_tooltip: MarginContainer = %InfoTooltip
@onready var quality_related_container: HBoxContainer = %QualityRelatedContainer
@onready var titled_panel: HTitledPanel = %TitledPanel


func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("ui_undo", undo_redo.undo)
	shortcuts.add_shortcut("ui_redo", undo_redo.redo)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	final_size_label.add_theme_color_override("font_color", ThemeUtils.subtle_text_color)
	cancel_button.pressed.connect(queue_free)
	export_button.pressed.connect(_on_export_button_pressed)
	clipboard_button.pressed.connect(_on_clipboard_button_pressed)
	scale_edit.value_changed.connect(_on_scale_edit_value_changed)
	width_edit.value_changed.connect(_on_width_edit_value_changed)
	height_edit.value_changed.connect(_on_height_edit_value_changed)
	quality_edit.value_changed.connect(_on_quality_value_changed)
	lossless_checkbox.toggled.connect(_on_lossless_check_box_toggled)
	format_dropdown.value_changed.connect(_on_dropdown_value_changed)
	
	dimensions = State.root_element.get_size()
	var bigger_dimension := maxf(dimensions.x, dimensions.y)
	
	scale_edit.min_value = 1 / minf(dimensions.x, dimensions.y)
	scale_edit.max_value = 16384 / bigger_dimension
	
	# Update dimensions label.
	dimensions = State.root_element.get_size()
	dimensions_label.text = Translator.translate("Dimensions") + ": " + get_dimensions_text(dimensions)
	update()
	export_data.changed.connect(update)
	
	# Setup the warning for when the image is too big to have a preview.
	var scaling_factor := texture_preview.MAX_IMAGE_DIMENSION / bigger_dimension
	info_tooltip.tooltip_text = Translator.translate("Preview image size is limited to {dimensions}").format(
			{"dimensions": get_dimensions_text(Vector2(maxf(dimensions.x * scaling_factor, 1.0), maxf(dimensions.y * scaling_factor, 1.0)), true)})
	info_tooltip.modulate = ThemeUtils.info_icon_color
	
	if Configs.savedata.get_active_tab().svg_file_path.is_empty():
		file_title.add_theme_color_override("font_color", ThemeUtils.subtle_text_color)
		file_title.text = Configs.savedata.get_active_tab().presented_name
	
	final_size_label.text = Translator.translate("Size") + ": " + String.humanize_size(State.get_export_text().length())
	%TitleLabel.text = Translator.translate("Export Configuration")
	%FormatHBox/Label.text = Translator.translate("Format") + ":"
	%LosslessCheckBox.text = Translator.translate("Lossless")
	%QualityHBox/Label.text = Translator.translate("Quality") + ":"
	%ScaleContainer/Label.text = Translator.translate("Scale")
	%WidthContainer/Label.text = Translator.translate("Width") + ":"
	%HeightContainer/Label.text = Translator.translate("Height") + ":"
	cancel_button.text = Translator.translate("Cancel")
	export_button.text = Translator.translate("Export")
	clipboard_button.tooltip_text = Translator.translate("Copy")
	clipboard_button.disabled = not ClipboardUtils.is_supported(export_data.format)
	
	titled_panel.corner_radius_bottom_left = 0
	titled_panel.corner_radius_bottom_right = 5
	titled_panel.corner_radius_top_left = 5
	titled_panel.corner_radius_top_right = 5
	titled_panel.color = ThemeUtils.basic_panel_inner_color
	titled_panel.border_color = ThemeUtils.basic_panel_border_color
	titled_panel.border_width = 2
	titled_panel.title_margin = 2
	titled_panel.panel_margin = 8
	
	HandlerGUI.register_focus_sequence(self, [clipboard_button, format_dropdown, lossless_checkbox,
			quality_edit, scale_edit, width_edit, height_edit, cancel_button, export_button], true)


func _on_export_button_pressed() -> void:
	FileUtils.open_export_dialog(export_data)

func _on_clipboard_button_pressed() -> void:
	var error := ClipboardUtils.copy_image(export_data)
	if error.type != ClipboardUtils.ErrorType.OK:
		var alert_dialog := AlertDialogScene.instantiate()
		HandlerGUI.add_dialog(alert_dialog)
		alert_dialog.setup(error.message)

func _on_dropdown_value_changed(new_value: String) -> void:
	var current_format := export_data.format
	undo_redo.create_action()
	undo_redo.add_do_property(export_data, "format", new_value)
	undo_redo.add_undo_property(export_data, "format", current_format)
	undo_redo.commit_action()

func _on_lossless_check_box_toggled(toggled_on: bool) -> void:
	var current_lossy := export_data.lossy
	undo_redo.create_action()
	undo_redo.add_do_property(export_data, "lossy", not toggled_on)
	undo_redo.add_undo_property(export_data, "lossy", current_lossy)
	undo_redo.commit_action()

func _on_quality_value_changed(new_value: float) -> void:
	var current_quality := export_data.quality
	undo_redo.create_action()
	undo_redo.add_do_property(export_data, "quality", new_value / 100)
	undo_redo.add_undo_property(export_data, "quality", current_quality)
	undo_redo.commit_action()

func _on_scale_edit_value_changed(new_value: float) -> void:
	if new_value == export_data.upscale_amount:
		return
	var current_upscale_amount := export_data.upscale_amount
	undo_redo.create_action()
	undo_redo.add_do_property(export_data, "upscale_amount", new_value)
	undo_redo.add_undo_property(export_data, "upscale_amount", current_upscale_amount)
	undo_redo.commit_action()


func _on_width_edit_value_changed(new_value: float) -> void:
	_dimension_component_change_common_logic(0, new_value)

func _on_height_edit_value_changed(new_value: float) -> void:
	_dimension_component_change_common_logic(1, new_value)

func _dimension_component_change_common_logic(component_index: int, new_value: float) -> void:
	if roundi(dimensions[component_index] * export_data.upscale_amount) == roundi(new_value):
		return
	var current_upscale_amount := export_data.upscale_amount
	undo_redo.create_action()
	undo_redo.add_do_property(export_data, "upscale_amount", new_value / dimensions[component_index])
	undo_redo.add_undo_property(export_data, "upscale_amount", current_upscale_amount)
	undo_redo.commit_action()


# Everything gets updated at once when export config changes for simplicity.
func update() -> void:
	# Determine which fields are visible.
	quality_related_container.visible = export_data.format in ["jpg", "jpeg", "webp"]
	quality_hbox.visible = export_data.format in ["jpg", "jpeg"] or export_data.format == "webp" and export_data.lossy
	lossless_checkbox.visible = (export_data.format == "webp")
	size_container.visible = export_data.format in ["png", "jpg", "jpeg", "webp"]
	
	final_size_label.visible = (export_data.format == "svg")
	
	var file_name := Utils.get_file_name(Configs.savedata.get_active_tab().svg_file_path)
	if not file_name.is_empty():
		file_title.text = file_name + "." + export_data.format
	
	# Display the texture and the warning for inaccurate previews.
	if export_data.format == "svg":
		texture_preview.setup_svg(State.get_export_text(), dimensions)
	else:
		texture_preview.setup_image(export_data)
		# Sync width, height, and scale without affecting the upscale amount.
		width_edit.set_value(roundi(dimensions.x * export_data.upscale_amount), false)
		height_edit.set_value(roundi(dimensions.y * export_data.upscale_amount), false)
		if roundi(dimensions.x * scale_edit.get_value()) != width_edit.get_value() and roundi(dimensions.y * scale_edit.get_value()) != height_edit.get_value():
			scale_edit.set_value(export_data.upscale_amount, false)
		# Sync all other widgets, so they are updated on changes from UndoRedo too.
		quality_edit.set_value(export_data.quality * 100, false)
		lossless_checkbox.set_pressed_no_signal(not export_data.lossy)
	format_dropdown.set_value(export_data.format, false)
	
	info_tooltip.visible = (export_data.format != "svg" and\
			roundi(export_data.upscale_amount * maxf(dimensions.x, dimensions.y)) > texture_preview.MAX_IMAGE_DIMENSION)
	
	clipboard_button.disabled = not ClipboardUtils.is_supported(export_data.format)

func get_dimensions_text(sides: Vector2, integer := false) -> String:
	var precision := 0 if integer else 2
	return "%s×%s" % [Utils.num_simple(sides.x, precision), Utils.num_simple(sides.y, precision)]
