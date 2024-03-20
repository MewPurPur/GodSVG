extends PanelContainer

const ColorSwatch = preload("res://src/ui_elements/color_swatch_config.tscn")
const ConfigurePopup = preload("res://src/ui_elements/configure_color_popup.tscn")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const plus_icon = preload("res://visual/icons/Plus.svg")

signal color_picked(color: String)
signal layout_changed

var current_palette: ColorPalette
var currently_edited_idx := -1

@onready var palette_label: Label = %MainContainer/HBoxContainer/PaletteLabel
@onready var name_edit: BetterLineEdit = %MainContainer/HBoxContainer/NameEdit
@onready var name_edit_button: Button = %MainContainer/HBoxContainer/EditButton
@onready var colors_container: HFlowContainer = %MainContainer/ColorsContainer
@onready var action_button: Button = $HBoxContainer/ActionButton

# Used to setup a palette for this element.
func assign_palette(palette: ColorPalette) -> void:
	current_palette = palette
	current_palette.changed.connect(rebuild_colors)
	rebuild_colors()

# Rebuilds the content of the colors container.
func rebuild_colors() -> void:
	for child in colors_container.get_children():
		child.queue_free()
	
	set_label_text(current_palette.title)
	if current_palette.title.is_empty():
		popup_edit_name()
	
	for i in current_palette.colors.size():
		var swatch := ColorSwatch.instantiate()
		swatch.color_palette = current_palette
		swatch.idx = i
		swatch.pressed.connect(popup_configure_color.bind(swatch))
		colors_container.add_child(swatch)
		if i == currently_edited_idx:
			# If you add a color, after the rebuild you should instantly edit the new color.
			await get_tree().process_frame
			popup_configure_color(swatch)
	# Add the add button.
	var color_swatch_ref := ColorSwatch.instantiate()
	var fake_swatch := Button.new()
	fake_swatch.begin_bulk_theme_override()
	for stylebox_type in ["normal", "hover", "pressed"]:
		fake_swatch.add_theme_stylebox_override(stylebox_type,
				color_swatch_ref.get_theme_stylebox(stylebox_type))
	fake_swatch.end_bulk_theme_override()
	fake_swatch.icon = plus_icon
	fake_swatch.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fake_swatch.focus_mode = Control.FOCUS_NONE
	fake_swatch.mouse_filter = Control.MOUSE_FILTER_PASS
	fake_swatch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	fake_swatch.custom_minimum_size = color_swatch_ref.custom_minimum_size
	fake_swatch.pressed.connect(popup_add_color)
	colors_container.add_child(fake_swatch)

func popup_configure_color(swatch: Button) -> void:
	var configure_popup := ConfigurePopup.instantiate()
	configure_popup.color_palette = swatch.color_palette
	configure_popup.idx = swatch.idx
	add_child(configure_popup)
	configure_popup.color_edit.value_changed.connect(swatch.change_color)
	configure_popup.color_name_edit.text_submitted.connect(swatch.change_color_name)
	configure_popup.color_deletion_requested.connect(remove_color.bind(swatch.idx))
	Utils.popup_under_rect_center(configure_popup, swatch.get_global_rect(),
			get_viewport())

func popup_edit_name() -> void:
	palette_label.hide()
	name_edit_button.hide()
	name_edit.show()
	name_edit.text = current_palette.title
	name_edit.grab_focus()
	name_edit.caret_column = name_edit.text.length()

func hide_name_edit() -> void:
	palette_label.show()
	name_edit_button.show()
	name_edit.hide()

# Update text color to red if the title won't work (because it's a duplicate).
func _on_name_edit_text_changed(new_text: String) -> void:
	var names: Array[String] = []
	for palette in GlobalSettings.palettes:
		names.append(palette.title)
	name_edit.add_theme_color_override("font_color", GlobalSettings.get_validity_color(
			new_text in names and new_text != current_palette.title))

func _on_name_edit_text_submitted(new_title: String) -> void:
	new_title = new_title.strip_edges()
	var titles: Array[String] = []
	for palette in GlobalSettings.palettes:
		titles.append(palette.title)
	
	if not new_title.is_empty() and new_title != current_palette.title and\
	not new_title in titles:
		current_palette.modify_title(new_title)
	
	set_label_text(current_palette.title)
	hide_name_edit()

func _on_name_edit_text_change_canceled() -> void:
	hide_name_edit()

func popup_add_color() -> void:
	currently_edited_idx = current_palette.colors.size()
	current_palette.add_color()

func remove_color(idx: int) -> void:
	currently_edited_idx = -1
	current_palette.remove_color(idx)

func set_label_text(new_text: String) -> void:
	if new_text.is_empty():
		palette_label.text = tr("Unnamed")
		palette_label.add_theme_color_override("font_color",
				GlobalSettings.basic_color_error)
	else:
		palette_label.text = new_text
		palette_label.remove_theme_color_override("font_color")

func delete(idx: int) -> void:
	GlobalSettings.palettes.remove_at(idx)
	GlobalSettings.save_palettes()
	layout_changed.emit()

func move_up(idx: int) -> void:
	var palette: ColorPalette = GlobalSettings.palettes.pop_at(idx)
	GlobalSettings.palettes.insert(idx - 1, palette)
	GlobalSettings.save_palettes()
	layout_changed.emit()

func move_down(idx: int) -> void:
	var palette: ColorPalette = GlobalSettings.palettes.pop_at(idx)
	GlobalSettings.palettes.insert(idx + 1, palette)
	GlobalSettings.save_palettes()
	layout_changed.emit()

func paste_palette(idx: int) -> void:
	GlobalSettings.palettes[idx] = ColorPalette.from_text(DisplayServer.clipboard_get())
	# If another palette has the same title, disable the title.
	for i in GlobalSettings.palettes.size():
		if i == idx:
			continue
		if GlobalSettings.palettes[i].title == GlobalSettings.palettes[idx].title:
			GlobalSettings.palettes[idx].title = ""
			break
	GlobalSettings.save_palettes()
	layout_changed.emit()


func _on_action_button_pressed() -> void:
	var palette_idx := -1
	for idx in GlobalSettings.palettes.size():
		if GlobalSettings.palettes[idx].title == current_palette.title:
			palette_idx = idx
	
	var btn_arr: Array[Button] = []
	
	if palette_idx >= 1:
		btn_arr.append(Utils.create_btn(tr("Move Up"), move_up.bind(palette_idx),
				false, load("res://visual/icons/MoveUp.svg")))
	if palette_idx < GlobalSettings.palettes.size() - 1:
		btn_arr.append(Utils.create_btn(tr("Move Down"), move_down.bind(palette_idx),
				false, load("res://visual/icons/MoveDown.svg")))
	btn_arr.append(Utils.create_btn(tr("Copy as XML"),
			DisplayServer.clipboard_set.bind(GlobalSettings.palettes[palette_idx].to_text()),
			false, load("res://visual/icons/Copy.svg")))
	btn_arr.append(Utils.create_btn(tr("Paste XML"), paste_palette.bind(palette_idx),
			!ColorPalette.is_valid_palette(DisplayServer.clipboard_get()),
			load("res://visual/icons/Paste.svg")))
	btn_arr.append(Utils.create_btn(tr("Delete"), delete.bind(palette_idx),
			false, load("res://visual/icons/Delete.svg")))
	
	
	var context_popup := ContextPopup.instantiate()
	add_child(context_popup)
	context_popup.set_button_array(btn_arr, true)
	Utils.popup_under_rect_center(context_popup, action_button.get_global_rect(),
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
		current_palette.move_color(data[1], proposed_drop_idx)
	else:
		current_palette.colors.insert(proposed_drop_idx, data[0].colors[data[1]])
		current_palette.color_names.insert(proposed_drop_idx, data[0].color_names[data[1]])
		current_palette.emit_changed()
		data[0].remove_color(data[1])

func _on_mouse_exited() -> void:
	clear_proposed_drop()

func clear_proposed_drop() -> void:
	proposed_drop_idx = -1
	for swatch in get_swatches():
		swatch.proposed_drop_data.clear()
		swatch.queue_redraw()
