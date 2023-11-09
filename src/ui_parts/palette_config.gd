extends PanelContainer

const ColorSwatch = preload("res://src/ui_elements/color_swatch.tscn")
const ConfigurePopup = preload("res://src/ui_parts/configure_color_popup.tscn")

signal color_picked(color: String)
signal deleted

var current_palette: ColorPalette
var currently_edited_color: NamedColor

@onready var margin_container: MarginContainer = $MarginContainer
@onready var palette_label: Label = %MainContainer/HBoxContainer/PaletteLabel
@onready var name_edit: BetterLineEdit = %MainContainer/HBoxContainer/NameEdit
@onready var name_edit_button: Button = %MainContainer/HBoxContainer/EditButton
@onready var colors_container: HFlowContainer = %MainContainer/ColorsContainer

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
	configure_popup.popup_hide.connect(configure_popup.queue_free)
	Utils.popup_under_control(configure_popup, swatch, true)

func popup_edit_name() -> void:
	palette_label.hide()
	name_edit_button.hide()
	margin_container.add_theme_constant_override(&"margin_top", 1)
	name_edit.show()
	name_edit.text = current_palette.name
	name_edit.grab_focus()
	name_edit.caret_column = name_edit.text.length()

func hide_name_edit() -> void:
	palette_label.show()
	name_edit_button.show()
	name_edit.hide()
	margin_container.remove_theme_constant_override(&"margin_top")

# Update text color to red if the name won't work (because it's a duplicate).
func _on_name_edit_text_changed(new_text: String) -> void:
	var names: Array[String] = []
	for palette in GlobalSettings.get_palettes():
		names.append(palette.name)
	if new_text in names and new_text != current_palette.name:
		name_edit.add_theme_color_override(&"font_color", Color(1.0, 0.6, 0.6))
	else:
		name_edit.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6))

func change_name(new_name: String) -> void:
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

func _on_delete_button_pressed() -> void:
	for palette_idx in GlobalSettings.get_palettes().size():
		if GlobalSettings.get_palettes()[palette_idx].name == current_palette.name:
			GlobalSettings.get_palettes().remove_at(palette_idx)
			GlobalSettings.save_user_data()
			break
	deleted.emit()

func _on_name_edit_focus_exited() -> void:
	hide_name_edit()

func set_label_text(new_text: String) -> void:
	if new_text.is_empty():
		palette_label.text = tr(&"#unnamed")
		palette_label.add_theme_color_override(&"font_color", Color(1.0, 0.5, 0.5))
	else:
		palette_label.text = new_text
		palette_label.remove_theme_color_override(&"font_color")

func delete_color(named_color: NamedColor) -> void:
	current_palette.named_colors.erase(named_color)  # I hope this works.
	rebuild_colors()
