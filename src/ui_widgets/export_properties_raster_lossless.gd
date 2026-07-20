extends VBoxContainer

const ColorEditWithOptions = preload("res://src/ui_widgets/color_edit_with_options.gd")
const ExportScaleConfig = preload("res://src/ui_widgets/export_scale_config.gd")

var export_data_object: ImageExportDataRaster
var undo_redo: UndoRedoRef

@onready var background_label: Label = $BackgroundHBox/BackgroundLabel
@onready var background_edit: ColorEditWithOptions = $BackgroundHBox/BackgroundEdit
@onready var export_scale_config: ExportScaleConfig = $ExportScaleConfig

func _ready() -> void:
	background_label.text = Translator.translate("Background") + ":"
	HandlerGUI.register_focus_sequence(self, [background_edit, export_scale_config])

func setup(new_export_data_object: ImageExportDataRaster, dimensions: Vector2) -> void:
	export_data_object = new_export_data_object
	
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
	# The actual limit is ~2 million pixels, but that doesn't seem relevant.
	if export_data_object is ImageExportDataPNG:
		export_scale_config.max_dimension = 65535
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
			background_edit.set_color_no_signal(export_data_object.background_color.to_html(export_data_object.background_color.a < 1.0))
			export_scale_config.set_export_scale(export_data_object.upscale_amount)
	export_data_object.changed.connect(_on_changed)
	tree_exited.connect(export_data_object.changed.disconnect.bind(_on_changed))
	_on_changed.call()
