extends VBoxContainer

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")
const ColorEditWithOptions = preload("res://src/ui_widgets/color_edit_with_options.gd")
const ExportScaleConfig = preload("res://src/ui_widgets/export_scale_config.gd")

var export_data_object: ImageExportDataWEBP
var undo_redo: UndoRedoRef

@onready var lossless_checkbox: CheckBox = $QualityRelatedHBox/LosslessCheckBox
@onready var quality_hbox: HBoxContainer = %QualityHBox
@onready var quality_label: Label = %QualityHBox/QualityLabel
@onready var quality_edit: LineEdit = %QualityHBox/QualityEdit
@onready var background_label: Label = $BackgroundHBox/BackgroundLabel
@onready var background_edit: ColorEditWithOptions = $BackgroundHBox/BackgroundEdit
@onready var export_scale_config: ExportScaleConfig = $ExportScaleConfig

func _ready() -> void:
	quality_label.text = Translator.translate("Quality") + ":"
	background_label.text = Translator.translate("Background") + ":"
	lossless_checkbox.text = Translator.translate("Lossless")
	HandlerGUI.register_focus_sequence(self, [lossless_checkbox, quality_edit, background_edit, export_scale_config])

func setup(new_export_data_object: ImageExportDataWEBP, dimensions: Vector2) -> void:
	export_data_object = new_export_data_object
	
	lossless_checkbox.toggled.connect(
		func(toggled_on: bool) -> void:
			if is_instance_valid(undo_redo):
				undo_redo.create_action()
				undo_redo.add_do_property(export_data_object, "lossy", not toggled_on)
				undo_redo.add_undo_property(export_data_object, "lossy", export_data_object.lossy)
				undo_redo.commit_action()
			else:
				export_data_object.lossy = not toggled_on
	)
	
	quality_edit.initial_value = export_data_object.quality * 100
	quality_edit.value_changed.connect(
		func(new_value: float) -> void:
			var new_quality := new_value / 100
			quality_edit.text = String.num_uint64(roundi(new_quality * 100))
			if is_instance_valid(undo_redo):
				undo_redo.create_action()
				undo_redo.add_do_property(export_data_object, "quality", new_quality)
				undo_redo.add_undo_property(export_data_object, "quality", export_data_object.quality)
				undo_redo.commit_action()
			else:
				export_data_object.undo_redo = new_quality
	)
	
	background_edit.setup(true, export_data_object.background_color)
	background_edit.color_picked.connect(
		func(new_value: String, is_final: bool, old_final_value: String) -> void:
			var new_background_color := ColorParser.text_to_color(new_value, Color.BLACK, true)
			if is_instance_valid(undo_redo) and is_final:
				undo_redo.create_action()
				undo_redo.add_do_property(export_data_object, "background_color", new_background_color)
				undo_redo.add_undo_property(export_data_object, "background_color", old_final_value)
				undo_redo.commit_action()
			else:
				export_data_object.background_color = new_background_color
	)
	
	export_scale_config.setup(dimensions, export_data_object.upscale_amount)
	export_scale_config.scale_changed.connect(
		func(new_value: float) -> void:
			if is_instance_valid(undo_redo):
				undo_redo.create_action()
				undo_redo.add_do_property(export_data_object, "upscale_amount", new_value)
				undo_redo.add_undo_property(export_data_object, "upscale_amount", export_data_object.upscale_amount)
				undo_redo.commit_action()
			else:
				export_data_object.upscale_amount = new_value
	)
	
	var _on_changed :=\
		func() -> void:
			lossless_checkbox.button_pressed = not export_data_object.lossy
			quality_hbox.visible = export_data_object.lossy
			quality_edit.text = String.num_uint64(roundi(export_data_object.quality * 100))
			background_edit.set_color_no_signal(export_data_object.background_color.to_html(export_data_object.background_color.a < 1.0))
			export_scale_config.set_export_scale(export_data_object.upscale_amount)
	export_data_object.changed.connect(_on_changed)
	tree_exited.connect(export_data_object.changed.disconnect.bind(_on_changed))
	_on_changed.call()
