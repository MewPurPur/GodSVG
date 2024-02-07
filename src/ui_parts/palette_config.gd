extends PanelContainer

const ColorSwatch = preload("res://src/ui_elements/color_swatch.tscn")
const ConfigurePopup = preload("res://src/ui_parts/configure_color_popup.tscn")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")

signal color_picked(color: String)
signal layout_changed

var current_palette: ColorPalette
var currently_edited_color: NamedColor

@onready var margin_container: MarginContainer = $MarginContainer
@onready var palette_label: Label = %MainContainer/HBoxContainer/PaletteLabel
@onready var name_edit: BetterLineEdit = %MainContainer/HBoxContainer/NameEdit
@onready var name_edit_button: Button = %MainContainer/HBoxContainer/EditButton
@onready var colors_container: HFlowContainer = %MainContainer/ColorsContainer
@onready var more_button: Button = $MarginContainer/HBoxContainer/MoreButton

# Used to setup a palette for this element.
func assign_palette(palette: ColorPalette) -> void:
	current_palette = palette
	rebuild_colors()

# Rebuilds the content of a container.
func rebuild_colors() -> void:
	for child in colors_container.get_children():
		child.queue_free()
	
	set_label_text(current_palette.name)
	if current_palette.name.is_empty():
		popup_edit_name()
	else:
		set_label_text(current_palette.name)
	for named_color in current_palette.named_colors:
		var swatch := ColorSwatch.instantiate()
		swatch.named_color = named_color
		swatch.type = swatch.Type.CONFIGURE_COLOR
		swatch.pressed.connect(popup_configure_color.bind(swatch))
		colors_container.add_child(swatch)
		if named_color == currently_edited_color:
			# If you add a color, after the rebuild you should instantly edit the new color.
			# TODO figure out how to do without waiting a frame.
			await get_tree().process_frame
			popup_configure_color(swatch)
	# Add the add button.
	var fake_swatch := ColorSwatch.instantiate()
	fake_swatch.type = fake_swatch.Type.ADD_COLOR
	fake_swatch.pressed.connect(popup_add_color)
	colors_container.add_child(fake_swatch)

func popup_configure_color(swatch: Button) -> void:
	var configure_popup := ConfigurePopup.instantiate()
	configure_popup.named_color = swatch.named_color
	add_child(configure_popup)
	configure_popup.color_edit.value_changed.connect(swatch.change_color)
	configure_popup.color_name_edit.text_submitted.connect(swatch.change_color_name)
	configure_popup.color_deletion_requested.connect(delete_color.bind(swatch.named_color))
	Utils.popup_under_control_centered(configure_popup, swatch)

func popup_edit_name() -> void:
	palette_label.hide()
	name_edit_button.hide()
	name_edit.show()
	name_edit.text = current_palette.name
	name_edit.grab_focus()
	name_edit.caret_column = name_edit.text.length()

func hide_name_edit() -> void:
	palette_label.show()
	name_edit_button.show()
	name_edit.hide()

# Update text color to red if the name won't work (because it's a duplicate).
func _on_name_edit_text_changed(new_text: String) -> void:
	var names: Array[String] = []
	for palette in GlobalSettings.get_palettes():
		names.append(palette.name)
	if new_text in names and new_text != current_palette.name:
		name_edit.add_theme_color_override(&"font_color", Color(1.0, 0.6, 0.6))
	else:
		name_edit.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6))

func _on_name_edit_text_submitted(new_name: String) -> void:
	new_name = new_name.strip_edges()
	var names: Array[String] = []
	for palette in GlobalSettings.get_palettes():
		names.append(palette.name)
	
	if not new_name.is_empty() and new_name != current_palette.name and\
	not new_name in names:
		current_palette.name = new_name
		GlobalSettings.save_user_data()
	
	set_label_text(current_palette.name)
	hide_name_edit()

func popup_add_color() -> void:
	var new_color := NamedColor.new("none", "")
	current_palette.named_colors.append(new_color)
	currently_edited_color = new_color
	rebuild_colors()

func set_label_text(new_text: String) -> void:
	if new_text.is_empty():
		palette_label.text = tr(&"Unnamed")
		palette_label.add_theme_color_override(&"font_color", Color(1.0, 0.5, 0.5))
	else:
		palette_label.text = new_text
		palette_label.remove_theme_color_override(&"font_color")

func delete_color(named_color: NamedColor) -> void:
	current_palette.named_colors.erase(named_color)  # I hope this works.
	rebuild_colors()

func delete(idx: int) -> void:
	GlobalSettings.get_palettes().remove_at(idx)
	GlobalSettings.save_user_data()
	layout_changed.emit()

func move_up(idx: int) -> void:
	var palette: ColorPalette = GlobalSettings.get_palettes().pop_at(idx)
	GlobalSettings.get_palettes().insert(idx - 1, palette)
	GlobalSettings.save_user_data()
	layout_changed.emit()

func move_down(idx: int) -> void:
	var palette: ColorPalette = GlobalSettings.get_palettes().pop_at(idx)
	GlobalSettings.get_palettes().insert(idx + 1, palette)
	GlobalSettings.save_user_data()
	layout_changed.emit()


func _on_more_button_pressed() -> void:
	var palette_idx := -1
	for idx in GlobalSettings.get_palettes().size():
		if GlobalSettings.get_palettes()[idx].name == current_palette.name:
			palette_idx = idx
	
	var btn_arr: Array[Button] = [Utils.create_btn(tr(&"Delete"),
			delete.bind(palette_idx), false, load("res://visual/icons/Delete.svg"))]
	
	if palette_idx >= 1:
		btn_arr.append(Utils.create_btn(tr(&"Move Up"), move_up.bind(palette_idx),
				false, load("res://visual/icons/MoveUp.svg")))
	if palette_idx < GlobalSettings.get_palettes().size() - 1:
		btn_arr.append(Utils.create_btn(tr(&"Move Down"), move_down.bind(palette_idx),
				false, load("res://visual/icons/MoveDown.svg")))
	
	var context_popup := ContextPopup.instantiate()
	add_child(context_popup)
	context_popup.set_button_array(btn_arr, true)
	Utils.popup_under_control_centered(context_popup, more_button)
