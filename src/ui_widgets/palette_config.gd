extends PanelContainer

const ColorSwatch = preload("res://src/ui_widgets/color_swatch_config.tscn")
const ConfigurePopup = preload("res://src/ui_widgets/configure_color_popup.tscn")
const plus_icon = preload("res://visual/icons/Plus.svg")

signal layout_changed

var current_palette: ColorPalette
var currently_edited_idx := -1

@onready var palette_button: Button = $MainContainer/HBoxContainer/PaletteButton
@onready var name_edit: BetterLineEdit = $MainContainer/HBoxContainer/NameEdit
@onready var colors_container: HFlowContainer = $MainContainer/ColorsContainer
@onready var warning_sign: TextureRect = $WarningSign/TextureRect

func setup_theme() -> void:
	palette_button.begin_bulk_theme_override()
	for theming in ["normal", "hover", "pressed"]:
		var stylebox := palette_button.get_theme_stylebox(theming).duplicate()
		stylebox.content_margin_top -= 3
		stylebox.content_margin_bottom -= 2
		stylebox.content_margin_left += 1
		palette_button.add_theme_stylebox_override(theming, stylebox)
	palette_button.end_bulk_theme_override()
	var panel_stylebox := get_theme_stylebox("panel").duplicate()
	panel_stylebox.content_margin_top = panel_stylebox.content_margin_bottom
	add_theme_stylebox_override("panel", panel_stylebox)


# Used to setup a palette for this element.
func assign_palette(palette: ColorPalette) -> void:
	current_palette = palette
	current_palette.layout_changed.connect(rebuild_colors)
	current_palette.layout_changed.connect(display_warnings)
	rebuild_colors()
	display_warnings()

func _ready() -> void:
	palette_button.pressed.connect(_on_palette_button_pressed)
	name_edit.text_change_canceled.connect(_on_name_edit_text_change_canceled)
	name_edit.text_changed.connect(_on_name_edit_text_changed)
	name_edit.text_submitted.connect(_on_name_edit_text_submitted)
	mouse_exited.connect(clear_proposed_drop)
	GlobalSettings.theme_changed.connect(setup_theme)
	setup_theme()

# Rebuilds the content of the colors container.
func rebuild_colors() -> void:
	# Color rebuilding.
	for child in colors_container.get_children():
		child.queue_free()
	
	set_label_text(current_palette.title)
	
	for i in current_palette.colors.size():
		var swatch := ColorSwatch.instantiate()
		swatch.color_palette = current_palette
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
	var color_swatch_ref := ColorSwatch.instantiate()
	fake_swatch.custom_minimum_size = color_swatch_ref.custom_minimum_size
	color_swatch_ref.queue_free()
	fake_swatch.pressed.connect(popup_add_color)
	colors_container.add_child(fake_swatch)

func display_warnings() -> void:
	var warnings := PackedStringArray()
	if current_palette.title.is_empty():
		warnings.append(TranslationServer.translate("Unnamed palettes won't be shown."))
	elif not GlobalSettings.is_palette_valid(current_palette):
		warnings.append(
				TranslationServer.translate("Multiple palettes can't have the same name."))
	if not current_palette.has_unique_definitions():
		warnings.append(
				TranslationServer.translate("This palette has identically defined colors."))
	warning_sign.visible = not warnings.is_empty()
	warning_sign.tooltip_text = "\n".join(warnings)


func popup_configure_color(swatch: Button) -> void:
	var configure_popup := ConfigurePopup.instantiate()
	configure_popup.color_palette = swatch.color_palette
	configure_popup.idx = swatch.idx
	configure_popup.color_deletion_requested.connect(remove_color.bind(swatch.idx))
	HandlerGUI.popup_under_rect_center(configure_popup, swatch.get_global_rect(),
			get_viewport())
	configure_popup.color_edit.value_changed.connect(swatch.change_color)
	configure_popup.color_edit.value_changed.connect(display_warnings.unbind(1))
	configure_popup.color_name_edit.text_submitted.connect(swatch.change_color_name)
	configure_popup.color_name_edit.text_submitted.connect(display_warnings.unbind(1))

func popup_edit_name() -> void:
	palette_button.hide()
	name_edit.show()
	name_edit.text = current_palette.title
	name_edit.grab_focus()
	name_edit.caret_column = name_edit.text.length()

func hide_name_edit() -> void:
	palette_button.show()
	name_edit.hide()

# Update text color to red if the title won't work (because it's a duplicate).
func _on_name_edit_text_changed(new_text: String) -> void:
	for theme_color in ["font_color", "font_hover_color"]:
		name_edit.add_theme_color_override(theme_color, GlobalSettings.get_validity_color(
				false, new_text != current_palette.title and\
				not GlobalSettings.is_palette_title_unused(new_text)))

func _on_name_edit_text_submitted(new_title: String) -> void:
	new_title = new_title.strip_edges()
	if new_title != current_palette.title:
		GlobalSettings.rename_palette(find_palette_index(), new_title)
		set_label_text(current_palette.title)
		layout_changed.emit()
	hide_name_edit()

func _on_name_edit_text_change_canceled() -> void:
	hide_name_edit()

func popup_add_color() -> void:
	currently_edited_idx = current_palette.colors.size()
	current_palette.add_color()
	display_warnings()

func remove_color(idx: int) -> void:
	currently_edited_idx = -1
	current_palette.remove_color(idx)
	display_warnings()

func set_label_text(new_text: String) -> void:
	if new_text.is_empty():
		palette_button.text = TranslationServer.translate("Unnamed")
	else:
		palette_button.text = new_text
	palette_button.begin_bulk_theme_override()
	if current_palette.title.is_empty():
		for theme_name in ["font_color", "font_hover_color", "font_pressed_color"]:
			palette_button.add_theme_color_override(theme_name,
					ThemeUtils.common_subtle_text_color)
	else:
		if not GlobalSettings.is_palette_valid(current_palette):
			for theme_name in ["font_color", "font_hover_color", "font_pressed_color"]:
				palette_button.add_theme_color_override(theme_name,
						GlobalSettings.savedata.basic_color_error)
		else:
			for theme_name in ["font_color", "font_hover_color", "font_pressed_color"]:
				palette_button.remove_theme_color_override(theme_name)
	palette_button.end_bulk_theme_override()

func delete() -> void:
	GlobalSettings.delete_palette(find_palette_index())
	layout_changed.emit()

func move_up() -> void:
	GlobalSettings.move_palette_up(find_palette_index())
	layout_changed.emit()

func move_down() -> void:
	GlobalSettings.move_palette_down(find_palette_index())
	layout_changed.emit()

func paste_palette() -> void:
	var old_title := current_palette.title
	var pasted_palettes := ColorPalette.text_to_palettes(DisplayServer.clipboard_get())
	if pasted_palettes.is_empty():
		return
	GlobalSettings.replace_palette(find_palette_index(), pasted_palettes[0])
	if old_title != pasted_palettes[0].title:
		layout_changed.emit()

func open_palette_options() -> void:
	var btn_arr: Array[Button] = []
	btn_arr.append(ContextPopup.create_button("Pure",
			apply_preset.bind(ColorPalette.Preset.PURE),
			current_palette.is_same_as_preset(ColorPalette.Preset.PURE),
			load("res://visual/icons/PresetPure.svg")))
	btn_arr.append(ContextPopup.create_button("Grayscale",
			apply_preset.bind(ColorPalette.Preset.GRAYSCALE),
			current_palette.is_same_as_preset(ColorPalette.Preset.GRAYSCALE),
			load("res://visual/icons/PresetGrayscale.svg")))
	btn_arr.append(ContextPopup.create_button("Empty",
			apply_preset.bind(ColorPalette.Preset.EMPTY),
			current_palette.is_same_as_preset(ColorPalette.Preset.EMPTY),
			load("res://visual/icons/Clear.svg")))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(context_popup, palette_button.get_global_rect(),
			get_viewport())

func apply_preset(preset: ColorPalette.Preset) -> void:
	GlobalSettings.palette_apply_preset(find_palette_index(), preset)


func find_palette_index() -> int:
	for idx in GlobalSettings.savedata.palettes.size():
		if GlobalSettings.savedata.palettes[idx] == current_palette:
			return idx
	return -1

func _on_palette_button_pressed() -> void:
	var palette_idx := find_palette_index()
	var btn_arr: Array[Button] = []
	btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Rename"),
			popup_edit_name, false, load("res://visual/icons/Rename.svg")))
	if palette_idx >= 1:
		btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Move Up"),
				move_up, false, load("res://visual/icons/MoveUp.svg")))
	if palette_idx < GlobalSettings.savedata.palettes.size() - 1:
		btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Move Down"),
				move_down, false, load("res://visual/icons/MoveDown.svg")))
	btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Copy as XML"),
			DisplayServer.clipboard_set.bind(GlobalSettings.savedata.palettes[palette_idx].\
			to_text()), false, load("res://visual/icons/Copy.svg")))
	btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Paste XML"),
			paste_palette, !ColorPalette.is_valid_palette(DisplayServer.clipboard_get()),
			load("res://visual/icons/Paste.svg")))
	btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Apply Preset"),
			open_palette_options, false, load("res://visual/icons/Import.svg")))
	btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Delete"),
			delete, false, load("res://visual/icons/Delete.svg")))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(context_popup, palette_button.get_global_rect(),
			get_viewport())


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
	
	if not (typeof(data) == TYPE_ARRAY and data.size() == 2 and\
	typeof(data[0]) == TYPE_OBJECT and data[0] is ColorPalette and\
	typeof(data[1]) == TYPE_INT) or\
	not Rect2(Vector2.ZERO, colors_container.size).grow(buffer).has_point(pos):
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
		swatch.proposed_drop_data = [current_palette, new_idx]
		swatch.queue_redraw()
	return data[0] != current_palette or (data[0] == current_palette and\
			data[1] != new_idx and data[1] != new_idx - 1)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if proposed_drop_idx == -1:
		return
	
	if data[0] == current_palette:
		currently_edited_idx = -1
		current_palette.move_color(data[1], proposed_drop_idx)
	else:
		currently_edited_idx = -1
		current_palette.colors.insert(proposed_drop_idx, data[0].colors[data[1]])
		current_palette.color_names.insert(proposed_drop_idx, data[0].color_names[data[1]])
		current_palette.emit_changed()
		data[0].remove_color(data[1])


func clear_proposed_drop() -> void:
	proposed_drop_idx = -1
	for swatch in get_swatches():
		swatch.proposed_drop_data.clear()
		swatch.queue_redraw()
