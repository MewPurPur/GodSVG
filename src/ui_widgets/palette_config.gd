extends PanelContainer

const PalettePreview = preload("res://src/ui_widgets/palette_preview.gd")

signal layout_changed

var palette: Palette

@onready var palette_button: Button = $MainContainer/HBoxContainer/PaletteButton
@onready var name_edit: BetterLineEdit = $MainContainer/HBoxContainer/NameEdit
@onready var palette_preview: PalettePreview = $MainContainer/PalettePreview
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
	palette_preview.setup(palette)
	palette.changed.connect(display_warnings)
	display_warnings()
	set_label_text(palette.title)

func _ready() -> void:
	palette_button.pressed.connect(_on_palette_button_pressed)
	name_edit.text_change_canceled.connect(_on_name_edit_text_change_canceled)
	name_edit.text_changed.connect(_on_name_edit_text_changed)
	name_edit.text_submitted.connect(_on_name_edit_text_submitted)
	Configs.theme_changed.connect(sync_theming)
	sync_theming()


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
		# If the new text matches the current title, show warning color if the palette is currently invalid.
		# If the new text is different, check if it's unused, i.e., would be a valid title.
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
	DisplayServer.clipboard_set(Configs.savedata.get_palette(palette_idx).get_as_markup())

func save_palette(palette_idx: int) -> void:
	var saved_palette := Configs.savedata.get_palette(palette_idx)
	FileUtils.open_xml_export_dialog(saved_palette.get_as_markup(), saved_palette.title)

func open_palette_options() -> void:
	var btn_arr: Array[ContextButton] = []
	btn_arr.append(ContextButton.create_custom("Pure", apply_preset.bind(Palette.Preset.PURE),
			preload("res://assets/icons/PresetPure.svg"), palette.is_same_as_preset(Palette.Preset.PURE)).set_icon_unmodulated())
	btn_arr.append(ContextButton.create_custom("Grayscale", apply_preset.bind(Palette.Preset.GRAYSCALE),
			preload("res://assets/icons/PresetGrayscale.svg"), palette.is_same_as_preset(Palette.Preset.GRAYSCALE)).set_icon_unmodulated())
	btn_arr.append(ContextButton.create_custom("Empty", apply_preset.bind(Palette.Preset.EMPTY),
			preload("res://assets/icons/Clear.svg"), palette.is_same_as_preset(Palette.Preset.EMPTY)))
	
	var context_popup := ContextPopup.create(btn_arr)
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
	var btn_arr: Array[ContextButton] = []
	btn_arr.append(ContextButton.create_custom(Translator.translate("Rename"), popup_edit_name, preload("res://assets/icons/Rename.svg")))
	if palette_idx >= 1:
		btn_arr.append(ContextButton.create_custom(Translator.translate("Move Up"), move_up, preload("res://assets/icons/MoveUp.svg")))
	if palette_idx < Configs.savedata.get_palette_count() - 1:
		btn_arr.append(ContextButton.create_custom(Translator.translate("Move Down"), move_down, preload("res://assets/icons/MoveDown.svg")))
	btn_arr.append(ContextButton.create_custom(Translator.translate("Apply Preset"), open_palette_options, preload("res://assets/icons/Import.svg")))
	btn_arr.append(ContextButton.create_custom(Translator.translate("Delete"), delete, preload("res://assets/icons/Delete.svg")))
	
	var separator_arr := PackedInt32Array([btn_arr.size()])
	
	btn_arr.append(ContextButton.create_custom(Translator.translate("Copy as XML"), copy_palette.bind(palette_idx), preload("res://assets/icons/Copy.svg")))
	btn_arr.append(ContextButton.create_custom(Translator.translate("Save as XML"), save_palette.bind(palette_idx), preload("res://assets/icons/Export.svg")))
	
	var context_popup := ContextPopup.create(btn_arr, true, -1, separator_arr)
	HandlerGUI.popup_under_rect_center(context_popup, palette_button.get_global_rect(), get_viewport())
