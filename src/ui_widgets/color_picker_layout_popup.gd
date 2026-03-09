extends PanelContainer

const GoodColorPicker = preload("res://src/ui_widgets/good_color_picker.gd")

signal color_model_changed

@onready var shape_button: Button = %ShapeButton
@onready var section_label: Label = %SectionLabel
@onready var color_models_container: HBoxContainer = %ColorModelsContainer

func _ready() -> void:
	shape_button.text = "VHS Circle"
	shape_button.pressed.connect(_on_shape_button_pressed)
	section_label.text = Translator.translate("Color models")
	color_model_changed.connect(sync_color_models)
	sync_color_models()

func _on_shape_button_pressed() -> void:
	var btn_arr: Array[ContextButton] = []
	for picker_shape in ColorPickerUtils.PickerShape.values():
		btn_arr.append(ContextButton.create_custom(ColorPickerUtils.picker_shape_to_string(picker_shape),
				(func() -> void: Configs.savedata.color_picker_current_shape = picker_shape),
				null, Configs.savedata.color_picker_current_shape == picker_shape))
	var cp := ContextPopup.create(btn_arr)
	HandlerGUI.popup_under_rect(cp, shape_button.get_global_rect(), get_viewport())

func sync_color_models() -> void:
	for child in color_models_container.get_children():
		color_models_container.remove_child(child)
		child.queue_free()
	
	for idx in 3:
		var btn := Button.new()
		btn.theme_type_variation = "TranslucentButton"
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		color_models_container.add_child(btn)
		if idx < Configs.savedata.color_picker_active_models.size():
			btn.text = ColorPickerUtils.color_model_to_string(Configs.savedata.color_picker_active_models[idx])
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.pressed.connect(_on_occupied_color_space_button_pressed.bind(idx, btn))
		elif idx == Configs.savedata.color_picker_active_models.size():
			btn.text = "..."
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.pressed.connect(_on_free_color_space_button_pressed.bind(idx, btn))
		else:
			btn.disabled = true

func _on_occupied_color_space_button_pressed(index: int, button: Button) -> void:
	var btn_arr: Array[ContextButton] = [
		ContextButton.create_custom(Translator.translate("Edit"),
				Callable(), preload("res://assets/icons/Edit.svg"))
	]
	if index > 0:
		btn_arr.append(ContextButton.create_custom(Translator.translate("Move left"),
				move_color_model_index.bind(index, false), preload("res://assets/icons/MoveLeft.svg")))
	elif index < Configs.savedata.color_picker_active_models.size() - 1:
		btn_arr.append(ContextButton.create_custom(Translator.translate("Move right"),
				move_color_model_index.bind(index, true), preload("res://assets/icons/MoveRight.svg")))
		return
	
	btn_arr.append(ContextButton.create_custom(Translator.translate("Delete"), delete_color_model.bind(index), preload("res://assets/icons/Delete.svg")))
	HandlerGUI.popup_under_rect_center(ContextPopup.create(btn_arr), button.get_global_rect(), get_viewport())

func _on_free_color_space_button_pressed(index: int, button: Button) -> void:
	var btn_arr: Array[ContextButton] = []
	for model in ColorPickerUtils.ColorModel.values():
		btn_arr.append(ContextButton.create_custom(ColorPickerUtils.color_model_to_string(model),
				set_color_model.bind(index, model), null, Configs.savedata.color_picker_current_model == model))
	HandlerGUI.popup_under_rect_center(ContextPopup.create(btn_arr), button.get_global_rect(), get_viewport())

func set_color_model(index: int, new_color_model: ColorPickerUtils.ColorModel) -> void:
	if index >= Configs.savedata.color_picker_active_models.size():
		Configs.savedata.color_picker_active_models.append(new_color_model)
	else:
		Configs.savedata.color_picker_active_models[index] = new_color_model
	color_model_changed.emit()

func delete_color_model(index: int) -> void:
	if index < Configs.savedata.color_picker_active_models.size():
		Configs.savedata.color_picker_active_models.remove_at(index)
	color_model_changed.emit()

func move_color_model_index(index: int, move_right: bool) -> void:
	var new_index := index + (1 if move_right else -1)
	var model_to_move := Configs.savedata.color_picker_active_models[index]
	Configs.savedata.color_picker_active_models[index] = Configs.savedata.color_picker_active_models[new_index]
	Configs.savedata.color_picker_active_models[new_index] = model_to_move
	color_model_changed.emit()
