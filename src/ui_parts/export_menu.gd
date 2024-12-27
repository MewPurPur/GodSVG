extends PanelContainer

const NumberEditType = preload("res://src/ui_widgets/number_edit.gd")
const DropdownType = preload("res://src/ui_widgets/dropdown.gd")

var UR := UndoRedo.new()
var export_data := ImageExportData.new()
var dimensions := Vector2.ZERO

@onready var dimensions_label: Label = %DimensionsLabel
@onready var texture_preview: CenterContainer = %TexturePreview
@onready var format_hbox: HBoxContainer = %FormatHBox
@onready var format_dropdown: DropdownType = %FormatHBox/Dropdown
@onready var final_size_label: Label = %FinalSizeLabel
@onready var scale_edit: NumberEditType = %Scale
@onready var width_edit: NumberEditType = %Width
@onready var height_edit: NumberEditType = %Height
@onready var size_container: CenterContainer = %SizeContainer
@onready var lossless_checkbox: CheckBox = %LosslessCheckBox
@onready var quality_edit: NumberEditType = %Quality
@onready var quality_hbox: HBoxContainer = %QualityHBox
@onready var cancel_button: Button = %ButtonContainer/CancelButton
@onready var export_button: Button = %ButtonContainer/ExportButton
@onready var file_title: Label = %FileTitle
@onready var info_tooltip: MarginContainer = %InfoTooltip
@onready var quality_related_container: HBoxContainer = %QualityRelatedContainer
@onready var titled_panel: HTitledPanel = %TitledPanel

func _exit_tree() -> void:
	UR.free()

func _ready() -> void:
	cancel_button.pressed.connect(queue_free)
	export_button.pressed.connect(_on_export_button_pressed)
	scale_edit.value_changed.connect(_on_scale_edit_value_changed)
	width_edit.value_changed.connect(_on_width_edit_value_changed)
	height_edit.value_changed.connect(_on_height_edit_value_changed)
	quality_edit.value_changed.connect(_on_quality_value_changed)
	lossless_checkbox.toggled.connect(_on_lossless_check_box_toggled)
	format_dropdown.value_changed.connect(_on_dropdown_value_changed)
	
	dimensions = SVG.root_element.get_size()
	var bigger_dimension := maxf(dimensions.x, dimensions.y)
	scale_edit.min_value = 1 / minf(dimensions.x, dimensions.y)
	scale_edit.max_value = 16384 / bigger_dimension
	
	# Update dimensions label.
	dimensions = SVG.root_element.get_size()
	dimensions_label.text = Translator.translate("Dimensions") + ": " +\
			get_dimensions_text(dimensions)
	update()
	export_data.changed.connect(update)
	
	# Setup the warning for when the image is too big to have a preview.
	var scaling_factor: float = texture_preview.MAX_IMAGE_DIMENSION / bigger_dimension
	info_tooltip.tooltip_text = Translator.translate(
			"Preview image size is limited to {dimensions}").format(
			{"dimensions": get_dimensions_text(dimensions * scaling_factor, true)})
	
	final_size_label.text = Translator.translate("Size") + ": " +\
			String.humanize_size(SVG.get_export_text().length())
	%TitleLabel.text = Translator.translate("Export Configuration")
	%FormatHBox/Label.text = Translator.translate("Format") + ":"
	%LosslessCheckBox.text = Translator.translate("Lossless")
	%QualityHBox/Label.text = Translator.translate("Quality") + ":"
	%ScaleContainer/Label.text = Translator.translate("Scale")
	%WidthContainer/Label.text = Translator.translate("Width") + ":"
	%HeightContainer/Label.text = Translator.translate("Height") + ":"
	cancel_button.text = Translator.translate("Cancel")
	export_button.text = Translator.translate("Export")
	
	titled_panel.corner_radius_bottom_left = 0
	titled_panel.corner_radius_bottom_right = 5
	titled_panel.corner_radius_top_left = 5
	titled_panel.corner_radius_top_right = 5
	titled_panel.color = ThemeUtils.common_panel_inner_color
	titled_panel.border_color = ThemeUtils.common_panel_border_color
	titled_panel.border_width = 2
	titled_panel.title_margin = 2
	titled_panel.panel_margin = 8


func _on_export_button_pressed() -> void:
	FileUtils.open_export_dialog(export_data)

func _on_dropdown_value_changed(new_value: String) -> void:
	var current_format := export_data.format
	UR.create_action("")
	UR.add_do_property(export_data, "format", new_value)
	UR.add_undo_property(export_data, "format", current_format)
	UR.commit_action()

func _on_lossless_check_box_toggled(toggled_on: bool) -> void:
	var current_lossy := export_data.lossy
	UR.create_action("")
	UR.add_do_property(export_data, "lossy", not toggled_on)
	UR.add_undo_property(export_data, "lossy", current_lossy)
	UR.commit_action()

func _on_quality_value_changed(new_value: float) -> void:
	var current_quality := export_data.quality
	UR.create_action("")
	UR.add_do_property(export_data, "quality", new_value / 100)
	UR.add_undo_property(export_data, "quality", current_quality)
	UR.commit_action()

func _on_scale_edit_value_changed(new_value: float) -> void:
	if new_value == export_data.upscale_amount:
		return
	var current_upscale_amount := export_data.upscale_amount
	UR.create_action("")
	UR.add_do_property(export_data, "upscale_amount", new_value)
	UR.add_undo_property(export_data, "upscale_amount", current_upscale_amount)
	UR.commit_action()

func _on_width_edit_value_changed(new_value: float) -> void:
	if roundi(dimensions.x * export_data.upscale_amount) == roundi(new_value):
		return
	var current_upscale_amount := export_data.upscale_amount
	UR.create_action("")
	UR.add_do_property(export_data, "upscale_amount", new_value / dimensions.x)
	UR.add_undo_property(export_data, "upscale_amount", current_upscale_amount)
	UR.commit_action()

func _on_height_edit_value_changed(new_value: float) -> void:
	if roundi(dimensions.y * export_data.upscale_amount) == roundi(new_value):
		return
	var current_upscale_amount := export_data.upscale_amount
	UR.create_action("")
	UR.add_do_property(export_data, "upscale_amount", new_value / dimensions.y)
	UR.add_undo_property(export_data, "upscale_amount", current_upscale_amount)
	UR.commit_action()

# Everything gets updated at once when export config changes for simplicity.
func update() -> void:
	# Determine which fields are visible.
	quality_related_container.visible = export_data.format in ["jpg", "jpeg", "webp"]
	quality_hbox.visible = export_data.format in ["jpg", "jpeg"] or\
			export_data.format == "webp" and export_data.lossy
	lossless_checkbox.visible = (export_data.format == "webp")
	size_container.visible = export_data.format in ["png", "jpg", "jpeg", "webp"]
	
	final_size_label.visible = (export_data.format == "svg")
	file_title.text = Utils.get_file_name(Configs.savedata.current_file_path) + "." +\
			export_data.format
	
	# Display the texture and the warning for inaccurate previews.
	if export_data.format == "svg":
		texture_preview.setup_svg(SVG.get_export_text(), dimensions)
	else:
		texture_preview.setup_image(export_data)
		# Sync width, height, and scale without affecting the upscale amount.
		width_edit.set_value(roundi(dimensions.x * export_data.upscale_amount), false)
		height_edit.set_value(roundi(dimensions.y * export_data.upscale_amount), false)
		if roundi(dimensions.x * scale_edit.get_value()) != width_edit.get_value() and\
		roundi(dimensions.y * scale_edit.get_value()) != height_edit.get_value():
			scale_edit.set_value(export_data.upscale_amount, false)
		# Sync all other widgets, so they are updated on changes from UndoRedo too.
		quality_edit.set_value(export_data.quality * 100, false)
		lossless_checkbox.set_pressed_no_signal(not export_data.lossy)
	format_dropdown.set_value(export_data.format, false)
	
	info_tooltip.visible = (export_data.format != "svg" and export_data.upscale_amount *\
			maxf(dimensions.x, dimensions.y) > texture_preview.MAX_IMAGE_DIMENSION)

func get_dimensions_text(sides: Vector2, integer := false) -> String:
	var precision := 0 if integer else 2
	return String.num(sides.x, precision) + "×" + String.num(sides.y, precision)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if ShortcutUtils.is_action_pressed(event, "redo"):
		if UR.has_redo():
			UR.redo()
		accept_event()
	elif ShortcutUtils.is_action_pressed(event, "undo"):
		if UR.has_undo():
			UR.undo()
		accept_event()
