extends PanelContainer

const ColorSwatch = preload("res://src/ui_widgets/color_swatch_config.gd")

const ColorSwatchScene = preload("res://src/ui_widgets/color_swatch_config.tscn")
const ColorConfigurationPopupScene = preload("res://src/ui_widgets/color_configuration_popup.tscn")
const plus_icon = preload("res://assets/icons/Plus.svg")

signal layout_changed

var palette: Palette
var currently_edited_idx := -1

@onready var palette_button: Button = $MainContainer/HBoxContainer/PaletteButton
@onready var name_edit: BetterLineEdit = $MainContainer/HBoxContainer/NameEdit
@onready var colors_container: HFlowContainer = $MainContainer/ColorsContainer
@onready var warning_sign: TextureRect = $WarningSign/TextureRect

func sync_theming() -> void:
	warning_sign.modulate = ThemeUtils.warning_icon_color
	palette_button.begin_bulk_theme_override()
	const CONST_ARR: PackedStringArray = ["normal", "hover", "pressed"]
	for theme_type in CONST_ARR:
		var stylebox := palette_button.get_theme_stylebox(theme_type).duplicate()
		stylebox.content_margin_top -= 3.0
		stylebox.content_margin_bottom -= 2.0
		stylebox.content_margin_left += 1.0
		palette_button.add_theme_stylebox_override(theme_type, stylebox)
	var panel_stylebox := get_theme_stylebox("panel").duplicate()
	panel_stylebox.content_margin_top = panel_stylebox.content_margin_bottom
	add_theme_stylebox_override("panel", panel_stylebox)
	palette_button.end_bulk_theme_override()


# Used to setup a palette for this element.
func assign_palette(new_palette: Palette) -> void:
	palette = new_palette
	palette.layout_changed.connect(rebuild_colors)
	palette.layout_changed.connect(display_warnings)
	rebuild_colors()
	display_warnings()

func _ready() -> void:
	palette_button.pressed.connect(_on_palette_button_pressed)
	name_edit.text_change_canceled.connect(_on_name_edit_text_change_canceled)
	name_edit.text_changed.connect(_on_name_edit_text_changed)
	name_edit.text_submitted.connect(_on_name_edit_text_submitted)
	mouse_exited.connect(clear_proposed_drop)
	Configs.theme_changed.connect(sync_theming)
	sync_theming()

# Rebuilds the content of the colors container.
func rebuild_colors() -> void:
	# Color rebuilding.
	for child in colors_container.get_children():
		child.queue_free()
	
	set_label_text(palette.title)
	
	for i in palette.get_color_count():
		var swatch := ColorSwatchScene.instantiate()
		swatch.palette = palette
		swatch.idx = i
		swatch.pressed.connect(popup_configure_color.bind(swatch))
		colors_container.add_child(swatch)
		if i == currently_edited_idx:
			# If you add a color, after the rebuild you should instantly edit the new color.
			await colors_container.sort_children
			await get_tree().process_frame
			if is_instance_valid(swatch):
				swatch.pressed.emit()
	# Add the add button.
	var fake_swatch := Button.new()
	fake_swatch.theme_type_variation = "Swatch"
	fake_swatch.icon = plus_icon
	fake_swatch.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fake_swatch.focus_mode = Control.FOCUS_NONE
	fake_swatch.mouse_filter = Control.MOUSE_FILTER_PASS
	fake_swatch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var color_swatch_ref := ColorSwatchScene.instantiate()
	fake_swatch.custom_minimum_size = color_swatch_ref.custom_minimum_size
	color_swatch_ref.queue_free()
	fake_swatch.pressed.connect(popup_add_color)
	colors_container.add_child(fake_swatch)

func display_warnings() -> void:
	var warnings := PackedStringArray()
	if palette.title.is_empty():
		warnings.append(Translator.translate("Unnamed palettes won't be shown."))
	elif not Configs.savedata.is_palette_valid(palette):
		warnings.append(Translator.translate("Multiple palettes can't have the same name."))
	if not palette.has_unique_definitions():
		warnings.append(Translator.translate("This palette has identically defined colors."))
	warning_sign.visible = not warnings.is_empty()
	warning_sign.tooltip_text = "\n".join(warnings)


func popup_configure_color(swatch: Button) -> void:
	var configure_popup := ColorConfigurationPopupScene.instantiate()
	configure_popup.palette = swatch.palette
	configure_popup.idx = swatch.idx
	configure_popup.color_deletion_requested.connect(remove_color.bind(swatch.idx))
	HandlerGUI.popup_under_rect_center(configure_popup, swatch.get_global_rect(), get_viewport())
	configure_popup.color_edit.value_changed.connect(swatch.change_color)
	configure_popup.color_edit.value_changed.connect(display_warnings.unbind(1))
	configure_popup.color_name_edit.text_submitted.connect(swatch.change_color_name)
	configure_popup.color_name_edit.text_submitted.connect(display_warnings.unbind(1))

func popup_edit_name() -> void:
	palette_button.hide()
	name_edit.show()
	name_edit.text = palette.title
	name_edit.grab_focus()
	name_edit.caret_column = name_edit.text.length()

func hide_name_edit() -> void:
	palette_button.show()
	name_edit.hide()

# Update text color to red if the title won't work (because it's a duplicate).
func _on_name_edit_text_changed(new_text: String) -> void:
	name_edit.begin_bulk_theme_override()
	const CONST_ARR: PackedStringArray = ["font_color", "font_hover_color"]
	for theme_type in CONST_ARR:
		# If the new text matches the current title, show warning color
		# if the palette is currently invalid. If the new text is different,
		# check if it's unused, i.e., would be a valid title.
		name_edit.add_theme_color_override(theme_type,
				Configs.savedata.get_validity_color(false, (new_text != palette.title and not Configs.savedata.is_palette_title_unused(new_text)) or\
				(new_text == palette.title and Configs.savedata.is_palette_valid(palette))))
	name_edit.end_bulk_theme_override()

func _on_name_edit_text_submitted(new_title: String) -> void:
	new_title = new_title.strip_edges()
	if new_title != palette.title:
		Configs.savedata.rename_palette(find_palette_index(), new_title)
		set_label_text(palette.title)
		layout_changed.emit()
	hide_name_edit()

func _on_name_edit_text_change_canceled() -> void:
	hide_name_edit()

func popup_add_color() -> void:
	currently_edited_idx = palette.get_color_count()
	palette.add_new_color()
	display_warnings()

func remove_color(idx: int) -> void:
	currently_edited_idx = -1
	palette.remove_color(idx)
	display_warnings()

func set_label_text(new_text: String) -> void:
	if new_text.is_empty():
		palette_button.text = Translator.translate("Unnamed")
	else:
		palette_button.text = new_text
	palette_button.begin_bulk_theme_override()
	const CONST_ARR: PackedStringArray = ["font_color", "font_hover_color", "font_pressed_color"]
	if palette.title.is_empty():
		for theme_type in CONST_ARR:
			palette_button.add_theme_color_override(theme_type,
					ThemeUtils.subtle_text_color)
	else:
		if not Configs.savedata.is_palette_valid(palette):
			for theme_type in CONST_ARR:
				palette_button.add_theme_color_override(theme_type,
						Configs.savedata.basic_color_error)
		else:
			for theme_type in CONST_ARR:
				palette_button.remove_theme_color_override(theme_type)
	palette_button.end_bulk_theme_override()

func delete() -> void:
	Configs.savedata.delete_palette(find_palette_index())
	layout_changed.emit()

func move_up() -> void:
	Configs.savedata.move_palette_up(find_palette_index())
	layout_changed.emit()

func move_down() -> void:
	Configs.savedata.move_palette_down(find_palette_index())
	layout_changed.emit()

func copy_palette(palette_idx: int) -> void:
	DisplayServer.clipboard_set(Configs.savedata.get_palette(palette_idx).to_text())

func save_palette(palette_idx: int) -> void:
	var saved_palette := Configs.savedata.get_palette(palette_idx)
	FileUtils.open_xml_export_dialog(saved_palette.to_text(), saved_palette.title)

func open_palette_options() -> void:
	var btn_arr: Array[Button] = []
	btn_arr.append(ContextPopup.create_button("Pure",
			apply_preset.bind(Palette.Preset.PURE),
			palette.is_same_as_preset(Palette.Preset.PURE),
			load("res://assets/icons/PresetPure.svg")))
	btn_arr.append(ContextPopup.create_button("Grayscale",
			apply_preset.bind(Palette.Preset.GRAYSCALE),
			palette.is_same_as_preset(Palette.Preset.GRAYSCALE),
			load("res://assets/icons/PresetGrayscale.svg")))
	btn_arr.append(ContextPopup.create_button("Empty",
			apply_preset.bind(Palette.Preset.EMPTY),
			palette.is_same_as_preset(Palette.Preset.EMPTY),
			load("res://assets/icons/Clear.svg")))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(context_popup, palette_button.get_global_rect(), get_viewport())

func apply_preset(preset: Palette.Preset) -> void:
	Configs.savedata.get_palette(find_palette_index()).apply_preset(preset)


func find_palette_index() -> int:
	for idx in Configs.savedata.get_palette_count():
		if Configs.savedata.get_palette(idx) == palette:
			return idx
	return -1

func _on_palette_button_pressed() -> void:
	var palette_idx := find_palette_index()
	var separator_idx := 3
	var btn_arr: Array[Button] = []
	btn_arr.append(ContextPopup.create_button(Translator.translate("Rename"),
			popup_edit_name, false, load("res://assets/icons/Rename.svg")))
	if palette_idx >= 1:
		separator_idx += 1
		btn_arr.append(ContextPopup.create_button(Translator.translate("Move Up"),
				move_up, false, load("res://assets/icons/MoveUp.svg")))
	if palette_idx < Configs.savedata.get_palette_count() - 1:
		separator_idx += 1
		btn_arr.append(ContextPopup.create_button(Translator.translate("Move Down"),
				move_down, false, load("res://assets/icons/MoveDown.svg")))
	btn_arr.append(ContextPopup.create_button(Translator.translate("Apply Preset"),
			open_palette_options, false, load("res://assets/icons/Import.svg")))
	btn_arr.append(ContextPopup.create_button(Translator.translate("Delete"),
			delete, false, load("res://assets/icons/Delete.svg")))
	btn_arr.append(ContextPopup.create_button(Translator.translate("Copy as XML"),
			copy_palette.bind(palette_idx), false, load("res://assets/icons/Copy.svg")))
	btn_arr.append(ContextPopup.create_button(Translator.translate("Save as XML"),
			save_palette.bind(palette_idx), false, load("res://assets/icons/Export.svg")))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_arr, true, -1, -1, PackedInt32Array([separator_idx]))
	HandlerGUI.popup_under_rect_center(context_popup, palette_button.get_global_rect(), get_viewport())


# Drag and drop logic.

var proposed_drop_idx := -1

func get_swatches() -> Array[Node]:
	var swatches := colors_container.get_children()
	swatches.resize(swatches.size() - 1)  # The last child is the add button.
	return swatches

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# A buffer around the colors container to make inputs forgiving.
	var buffer := 6
	var pos := colors_container.get_local_mouse_position()
	
	if not (data is ColorSwatch.DragData and Rect2(Vector2.ZERO, colors_container.size).grow(buffer).has_point(pos)):
		clear_proposed_drop()
		return false
	else:
		pos = pos.clamp(Vector2.ZERO, colors_container.size)
	
	var new_idx := 0
	for swatch in get_swatches():
		var v_separation: int = colors_container.get_theme_constant("v_separation")
		var start_y: float = swatch.get_rect().position.y - v_separation / 2.0
		var end_y: float = swatch.get_rect().end.y + v_separation / 2.0
		var center_x: float = swatch.get_rect().get_center().x
		if end_y < pos.y or (center_x < pos.x and end_y > pos.y and start_y < pos.y):
			new_idx += 1
		else:
			break

	proposed_drop_idx = new_idx
	for swatch in get_swatches():
		swatch.proposed_drop_data = ColorSwatch.DragData.new(palette, new_idx)
		swatch.queue_redraw()
	return data.palette != palette or (data.palette == palette and data.index != new_idx and data.index != new_idx - 1)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if proposed_drop_idx == -1:
		return
	
	if data.palette == palette:
		currently_edited_idx = -1
		palette.move_color(data.index, proposed_drop_idx)
	else:
		currently_edited_idx = -1
		palette.insert_color(proposed_drop_idx, data.palette.get_color(data.index),
				data.palette.get_color_name(data.index))
		data.palette.remove_color(data.index)


func clear_proposed_drop() -> void:
	proposed_drop_idx = -1
	for swatch in get_swatches():
		swatch.proposed_drop_data = null
		swatch.queue_redraw()
