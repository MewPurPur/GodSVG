extends PanelContainer

const GoodColorPicker = preload("res://src/ui_widgets/good_color_picker.gd")

signal color_picker_layout_changed

@onready var picker_shape_button: Button = %ShapeButton
@onready var section_label: Label = %SectionLabel
@onready var color_model_buttons_array: Array[Button] = [%ColorModelsContainer/ColorModelButton1,
		%ColorModelsContainer/ColorModelButton2, %ColorModelsContainer/ColorModelButton3]

func _ready() -> void:
	picker_shape_button.text = "VHS Circle"
	picker_shape_button.pressed.connect(_on_picker_shape_button_pressed)
	section_label.text = Translator.translate("Color models") + ":"
	color_picker_layout_changed.connect(sync_color_models)
	sync_color_models()
	var focus_sequence: Array[Control] = [picker_shape_button]
	focus_sequence.append_array(color_model_buttons_array)
	HandlerGUI.register_focus_sequence(self, focus_sequence, true)

func _on_picker_shape_button_pressed() -> void:
	var btn_arr: Array[ContextButton] = []
	for picker_shape in ColorPickerUtils.PickerShape.values():
		btn_arr.append(ContextButton.create_custom(ColorPickerUtils.picker_shape_to_string(picker_shape),
				_on_picker_shape_picked.bind(picker_shape), ColorPickerUtils.picker_shape_to_icon(picker_shape),
				Configs.savedata.color_picker_current_shape == picker_shape))
	HandlerGUI.popup_under_rect(ContextPopup.create(btn_arr, true, picker_shape_button.size.x), picker_shape_button.get_global_rect(), get_viewport())

func sync_color_models() -> void:
	for idx in 3:
		var btn := color_model_buttons_array[idx]
		if btn.pressed.is_connected(_on_occupied_color_space_button_pressed):
			btn.pressed.disconnect(_on_occupied_color_space_button_pressed)
		if btn.pressed.is_connected(_on_free_color_space_button_pressed):
			btn.pressed.disconnect(_on_free_color_space_button_pressed)
		
		if idx > Configs.savedata.color_picker_active_models.size():
			btn.disabled = true
		else:
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			if idx == Configs.savedata.color_picker_active_models.size():
				btn.text = "..."
				btn.pressed.connect(_on_free_color_space_button_pressed.bind(btn))
			else:
				btn.text = ColorPickerUtils.color_model_to_string(Configs.savedata.color_picker_active_models[idx])
				btn.pressed.connect(_on_occupied_color_space_button_pressed.bind(idx, btn))
	picker_shape_button.text = ColorPickerUtils.picker_shape_to_string(Configs.savedata.color_picker_current_shape)

func _on_picker_shape_picked(picker_shape: ColorPickerUtils.PickerShape) -> void:
	Configs.savedata.color_picker_current_shape = picker_shape
	color_picker_layout_changed.emit()

func _on_occupied_color_space_button_pressed(index: int, button: Button) -> void:
	var btn_arr: Array[ContextButton] = [
		ContextButton.create_custom(Translator.translate("Edit"), edit_color_model.bind(index), preload("res://assets/icons/Edit.svg"))
	]
	if index > 0:
		btn_arr.append(ContextButton.create_custom(Translator.translate("Move left"),
				move_color_model_index.bind(index, false), preload("res://assets/icons/MoveLeft.svg")))
	if index < Configs.savedata.color_picker_active_models.size() - 1:
		btn_arr.append(ContextButton.create_custom(Translator.translate("Move right"),
				move_color_model_index.bind(index, true), preload("res://assets/icons/MoveRight.svg")))
	
	btn_arr.append(ContextButton.create_custom(Translator.translate("Delete"), delete_color_model.bind(index), preload("res://assets/icons/Delete.svg")))
	HandlerGUI.popup_under_rect_center(ContextPopup.create(btn_arr), button.get_global_rect(), get_viewport())

func _on_free_color_space_button_pressed(button: Button) -> void:
	var btn_arr: Array[ContextButton] = []
	for model in ColorPickerUtils.ColorModel.values():
		btn_arr.append(ContextButton.create_custom(ColorPickerUtils.color_model_to_string(model),
				add_color_model.bind(model), null, model in Configs.savedata.color_picker_active_models))
	HandlerGUI.popup_under_rect_center(ContextPopup.create(btn_arr), button.get_global_rect(), get_viewport())

func add_color_model(new_color_model: ColorPickerUtils.ColorModel) -> void:
	Configs.savedata.add_color_picker_active_model(new_color_model)
	color_picker_layout_changed.emit()

func delete_color_model(index: int) -> void:
	Configs.savedata.remove_color_picker_active_model(index)
	color_picker_layout_changed.emit()

func move_color_model_index(index: int, move_right: bool) -> void:
	var new_index := index + (1 if move_right else -1)
	Configs.savedata.move_color_picker_active_model(index, new_index)
	color_model_buttons_array[new_index].grab_focus(not get_viewport().gui_get_focus_owner().has_focus(true))
	color_picker_layout_changed.emit()

func edit_color_model(index: int) -> void:
	var btn_arr: Array[ContextButton] = []
	for model in ColorPickerUtils.ColorModel.values():
		btn_arr.append(ContextButton.create_custom(ColorPickerUtils.color_model_to_string(model),
				set_color_model.bind(index, model), null, model in Configs.savedata.color_picker_active_models))
	HandlerGUI.popup_under_rect_center(ContextPopup.create(btn_arr, false, color_model_buttons_array[index].size.x),
			color_model_buttons_array[index].get_global_rect(), get_viewport())
	color_picker_layout_changed.emit()

func set_color_model(index: int, new_color_model: ColorPickerUtils.ColorModel) -> void:
	Configs.savedata.set_color_picker_active_model(index, new_color_model)
	color_picker_layout_changed.emit()
