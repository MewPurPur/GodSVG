extends VBoxContainer

const PaletteConfigWidget = preload("res://src/ui_elements/palette_config.tscn")
const plus_icon = preload("res://visual/icons/Plus.svg")

var proposed_drop_palette: ColorPalette
var proposed_drop_idx := -1


func add_palette() -> void:
	for palette in GlobalSettings.palettes:
		# If there's an unnamed pallete, don't add a new one (there'll be a name clash).
		if palette.title.is_empty():
			return
	
	GlobalSettings.palettes.append(ColorPalette.new())
	GlobalSettings.save_palettes()
	rebuild_color_palettes()

func rebuild_color_palettes() -> void:
	for palette_config in get_children():
		palette_config.queue_free()
	for palette in GlobalSettings.palettes:
		var palette_config := PaletteConfigWidget.instantiate()
		add_child(palette_config)
		palette_config.assign_palette(palette)
		palette_config.layout_changed.connect(rebuild_color_palettes)
	# Add the button for adding a new palette.
	var add_palette_button := Button.new()
	add_palette_button.theme_type_variation = "TranslucentButton"
	add_palette_button.icon = plus_icon
	add_palette_button.tooltip_text = tr("Add palette")
	add_palette_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_palette_button.focus_mode = Control.FOCUS_NONE
	add_palette_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(add_palette_button)
	add_palette_button.pressed.connect(add_palette)
