extends PanelContainer

const ColorEditWithOptions = preload("res://src/ui_widgets/color_edit_with_options.gd")
const DropdownBasic = preload("res://src/ui_widgets/dropdown_basic.gd")
const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

enum PresentationType {LOSSLESS, JPG, LOSSY_WEBP}

signal presentation_changed

var undo_redo := UndoRedoRef.new()
var presentation_type_resources: Dictionary[PresentationType, PreviewPresentation] = {}
var current_presentation_type: PresentationType = PresentationType.LOSSLESS

@onready var background_label: Label = %BackgroundVBox/BackgroundLabel
@onready var background_edit: ColorEditWithOptions = %BackgroundVBox/BackgroundEdit
@onready var presentation_type_dropdown: DropdownBasic = $VBoxContainer/PresentationTypeDropdown
@onready var quality_hbox: HBoxContainer = %QualityHBox
@onready var quality_label: Label = %QualityHBox/QualityLabel
@onready var quality_edit: LineEdit = %QualityHBox/QualityEdit

func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("ui_undo", undo_redo.undo)
	shortcuts.add_shortcut("ui_redo", undo_redo.redo)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	var res := Configs.savedata.preview_presentation
	presentation_type_resources[PresentationType.LOSSLESS] = res if res is PreviewPresentationLossless else PreviewPresentationLossless.new()
	presentation_type_resources[PresentationType.JPG] = res if res is PreviewPresentationJPG else PreviewPresentationJPG.new()
	presentation_type_resources[PresentationType.LOSSY_WEBP] = res if res is PreviewPresentationLossyWEBP else PreviewPresentationLossyWEBP.new()
	
	background_edit.setup(true, res.background_color)
	background_label.text = Translator.translate("Background") + ":"
	for type in presentation_type_resources:
		presentation_type_resources[type].background_color = res.background_color
	background_edit.color_picked.connect(_on_background_edit_color_picked)
	
	quality_label.text = Translator.translate("Quality") + ":"
	quality_edit.value_changed.connect(_on_quality_edit_value_changed)
	
	presentation_type_dropdown.values = range(PresentationType.size())
	var presentation_type_value_text_map: Dictionary[PresentationType, String] = {}
	for type in presentation_type_resources:
		presentation_type_value_text_map[type] = presentation_type_resources[type].get_presentation_name()
	presentation_type_dropdown.value_text_map = presentation_type_value_text_map
	presentation_type_dropdown.value_changed.connect(_apply_presentation_type)
	
	if not Configs.savedata.preview_presentation.changed.is_connected(presentation_changed.emit):
		Configs.savedata.preview_presentation.changed.connect(presentation_changed.emit)
	
	var initial_type := get_current_presentation_type()
	presentation_type_dropdown.set_value(initial_type, false)
	_apply_presentation_type(initial_type, false)
	
	HandlerGUI.register_focus_sequence(self, [background_edit, presentation_type_dropdown, quality_edit])


func _on_quality_edit_value_changed(new_value: float) -> void:
	var new_quality := new_value / 100.0
	var old_quality: float = Configs.savedata.preview_presentation.quality
	
	if is_equal_approx(new_quality, old_quality):
		return
	
	undo_redo.create_action()
	undo_redo.add_do_method(_set_quality.bind(new_quality))
	undo_redo.add_undo_method(_set_quality.bind(old_quality))
	undo_redo.commit_action()


func _on_background_edit_color_picked(new_color: String, is_final: bool, old_final_value: String) -> void:
	var parsed_new_color := ColorParser.text_to_color(new_color, Color.BLACK, true)
	
	if not is_final:
		_set_background_color(parsed_new_color)
		return
	
	var parsed_old_color := ColorParser.text_to_color(old_final_value, Color.BLACK, true)
	undo_redo.create_action()
	undo_redo.add_do_method(_set_background_color.bind(parsed_new_color))
	undo_redo.add_undo_method(_set_background_color.bind(parsed_old_color))
	undo_redo.commit_action()


func get_current_presentation_type() -> PresentationType:
	if Configs.savedata.preview_presentation is PreviewPresentationJPG:
		return PresentationType.JPG
	if Configs.savedata.preview_presentation is PreviewPresentationLossyWEBP:
		return PresentationType.LOSSY_WEBP
	return PresentationType.LOSSLESS


func _apply_presentation_type(new_value: PresentationType, create_action := true) -> void:
	var active_type := get_current_presentation_type()
	if create_action:
		if new_value == active_type:
			return
		undo_redo.create_action()
		undo_redo.add_do_method(_apply_presentation_type.bind(new_value, false))
		undo_redo.add_undo_method(_apply_presentation_type.bind(active_type, false))
		undo_redo.commit_action()
		return
	
	var old_presentation := Configs.savedata.preview_presentation
	if is_instance_valid(old_presentation) and old_presentation.changed.is_connected(presentation_changed.emit):
		old_presentation.changed.disconnect(presentation_changed.emit)
	
	Configs.savedata.preview_presentation = presentation_type_resources[new_value]
	current_presentation_type = new_value
	
	if not Configs.savedata.preview_presentation.changed.is_connected(presentation_changed.emit):
		Configs.savedata.preview_presentation.changed.connect(presentation_changed.emit)
	
	presentation_type_dropdown.set_value(new_value, false)
	
	background_edit.set_color_no_signal(Configs.savedata.preview_presentation.background_color.to_html(
			Configs.savedata.preview_presentation.background_color.a < 1.0))
	
	match new_value:
		PresentationType.LOSSLESS:
			quality_hbox.hide()
		PresentationType.JPG, PresentationType.LOSSY_WEBP:
			quality_hbox.show()
			quality_edit.set_value(roundi(Configs.savedata.preview_presentation.quality * 100), false)
	
	presentation_changed.emit()


func _set_quality(new_quality: float) -> void:
	Configs.savedata.preview_presentation.quality = new_quality
	quality_edit.set_value(roundi(new_quality * 100), false)

func _set_background_color(new_color: Color) -> void:
	for type in presentation_type_resources:
		presentation_type_resources[type].background_color = new_color
	background_edit.set_color_no_signal(new_color.to_html(new_color.a < 1.0))
