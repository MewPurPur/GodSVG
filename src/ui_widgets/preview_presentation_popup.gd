extends PanelContainer

const ColorEditWithOptions = preload("res://src/ui_widgets/color_edit_with_options.gd")
const DropdownBasic = preload("res://src/ui_widgets/dropdown_basic.gd")
const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

enum PresentationType {LOSSLESS, JPG, LOSSY_WEBP}

signal presentation_changed

var undo_redo := UndoRedoRef.new()
var presentation_type_resources: Dictionary[PresentationType, PreviewPresentation] = {}

@onready var background_label: Label = %BackgroundVBox/BackgroundLabel
@onready var background_edit: ColorEditWithOptions = %BackgroundVBox/BackgroundEdit
@onready var presentation_type_dropdown: DropdownBasic = $VBoxContainer/PresentationTypeDropdown
@onready var quality_hbox: HBoxContainer = %QualityHBox
@onready var quality_label: Label = %QualityHBox/QualityLabel
@onready var quality_edit: LineEdit = %QualityHBox/QualityEdit

func _ready() -> void:
	var res := Configs.savedata.preview_presentation
	presentation_type_resources[PresentationType.LOSSLESS] = res if res is PreviewPresentationLossless else PreviewPresentationLossless.new()
	presentation_type_resources[PresentationType.JPG] = res if res is PreviewPresentationJPG else PreviewPresentationJPG.new()
	presentation_type_resources[PresentationType.LOSSY_WEBP] = res if res is PreviewPresentationLossyWEBP else PreviewPresentationLossyWEBP.new()
	
	background_edit.setup(true, Configs.savedata.preview_presentation.background_color)
	background_label.text = Translator.translate("Background") + ":"
	for type in presentation_type_resources:
		presentation_type_resources[type].background_color = res.background_color
	background_edit.color_picked.connect(_on_background_edit_color_picked.unbind(2))
	
	quality_label.text = Translator.translate("Quality") + ":"
	quality_edit.value_changed.connect(_on_quality_edit_value_changed)
	
	presentation_type_dropdown.values = range(PresentationType.size())
	var presentation_type_value_text_map: Dictionary[PresentationType, String] = {}
	for type in presentation_type_resources:
		presentation_type_value_text_map[type] = presentation_type_resources[type].get_presentation_name()
	presentation_type_dropdown.value_text_map = presentation_type_value_text_map
	presentation_type_dropdown.value_changed.connect(_on_presentation_type_dropdown_value_changed)
	
	var current_presentation_type: PresentationType
	if res is PreviewPresentationLossless:
		current_presentation_type = PresentationType.LOSSLESS
	elif res is PreviewPresentationJPG:
		current_presentation_type = PresentationType.JPG
	elif res is PreviewPresentationLossyWEBP:
		current_presentation_type = PresentationType.LOSSY_WEBP
	presentation_type_dropdown.set_value(current_presentation_type, false)
	_on_presentation_type_dropdown_value_changed(current_presentation_type)
	
	HandlerGUI.register_focus_sequence(self, [background_edit, presentation_type_dropdown])


func _on_quality_edit_value_changed(new_value: float) -> void:
	Configs.savedata.preview_presentation.quality = new_value / 100
	presentation_changed.emit()

func _on_background_edit_color_picked(new_color: String) -> void:
	for type in presentation_type_resources:
		presentation_type_resources[type].background_color = new_color
	presentation_changed.emit()

func _on_presentation_type_dropdown_value_changed(new_value: PresentationType) -> void:
	if Configs.savedata.preview_presentation.changed.is_connected(presentation_changed.emit):
		Configs.savedata.preview_presentation.changed.disconnect(presentation_changed.emit)
	Configs.savedata.preview_presentation = presentation_type_resources[new_value]
	Configs.savedata.preview_presentation.changed.connect(presentation_changed.emit)
	
	background_edit.set_color_no_signal(Configs.savedata.preview_presentation.background_color.to_html(
			Configs.savedata.preview_presentation.background_color.a < 1.0))
	match new_value:
		PresentationType.LOSSLESS:
			quality_hbox.hide()
		PresentationType.JPG, PresentationType.LOSSY_WEBP:
			quality_hbox.show()
			quality_edit.set_value(roundi(Configs.savedata.preview_presentation.quality * 100), false)
	
	presentation_changed.emit()
