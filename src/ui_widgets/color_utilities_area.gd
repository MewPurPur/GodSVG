extends VBoxContainer

const PalettePreviewScene = preload("res://src/ui_widgets/palette_preview.tscn")

# If the currentColor keyword is available, but uninteresting, don't show it.
enum CurrentColorAvailability {UNAVAILABLE, UNINTERESTING, INTERESTING}

var is_none_keyword_available := false
var show_url: bool
var show_current_color := false
var current_color := Color.BLACK

@onready var palettes_content_container: VBoxContainer = %PalettesContent
@onready var search_field: BetterLineEdit = %SearchField

var color_config: ColorPickerUtils.ColorConfig
var palette_previews: Array[Control] = []

func _ready() -> void:
	search_field.placeholder_text = Translator.translate("Search color")
	search_field.text_changed.connect(rebuild_content)
	search_field.text_change_canceled.connect(rebuild_content)
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("find", search_field.grab_focus)
	HandlerGUI.register_shortcuts(self, shortcuts)
	HandlerGUI.register_focus_sequence(self, [search_field, palettes_content_container])

func setup_color(new_color_config: ColorPickerUtils.ColorConfig) -> void:
	color_config = new_color_config
	color_config.color_changed.connect(_on_color_changed)
	rebuild_content()

func _on_color_changed() -> void:
	for preview in palette_previews:
		preview.current_value = color_config.color.paint
		preview.queue_redraw()

func rebuild_content(search_text := "") -> void:
	for child in palettes_content_container.get_children():
		child.queue_free()
	palette_previews.clear()
	
	var reserved_colors := PackedStringArray()
	var reserved_color_names := PackedStringArray()
	var reserved_paints: Dictionary[int, Color]
	var reserved_textures: Dictionary[int, DPITexture]
	if is_none_keyword_available:
		reserved_colors.append("none")
		reserved_color_names.append("No color")
		reserved_paints[reserved_colors.size() - 1] = Color.TRANSPARENT
	if show_current_color:
		reserved_colors.append("currentColor")
		reserved_color_names.append("Current color")
		reserved_paints[reserved_colors.size() - 1] = current_color
	if show_url:
		for element in State.root_element.get_all_valid_element_descendants():
			if element.has_attribute("id"):
				if element is ElementBaseGradient:
					if element is ElementLinearGradient:
						reserved_color_names.append("Linear gradient")
					elif element is ElementRadialGradient:
						reserved_color_names.append("Radial gradient")
					var color := element.get_attribute_value("id")
					reserved_colors.append("url(#%s)" % color)
					reserved_textures[reserved_colors.size() - 1] = State.root_element.get_element_by_id(color).generate_texture()
	
	var reserved_swatch_container := PalettePreviewScene.instantiate()
	reserved_swatch_container.setup_fake(reserved_color_names, reserved_colors, reserved_paints, reserved_textures, color_config.color.paint)
	reserved_swatch_container.swatch_selected.connect(_on_swatch_selected.bind(reserved_colors))
	palettes_content_container.add_child(reserved_swatch_container)
	palette_previews.append(reserved_swatch_container)
	
	for palette in Configs.savedata.get_palettes():
		if not Configs.savedata.is_palette_valid(palette):
			continue
		
		var trimmed_palette: Palette
		if search_text.is_empty():
			trimmed_palette = Palette.new(palette.title)
			trimmed_palette.setup(palette.get_colors(), palette.get_color_names())
		else:
			trimmed_palette = Palette.new(palette.title)
			for i in palette.get_color_count():
				if search_text.is_subsequence_ofn(palette.get_color_name(i)):
					trimmed_palette.insert_color(trimmed_palette.get_color_count(), palette.get_color(i), palette.get_color_name(i))
		
		if trimmed_palette.get_color_count() == 0:
			continue
		
		var palette_container := VBoxContainer.new()
		# Don't add a label for the reserved palette with an empty name.
		if not trimmed_palette.title.is_empty():
			var palette_label := Label.new()
			palette_label.text = palette.title
			palette_label.theme_type_variation = "TitleLabel"
			palette_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			palette_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
			palette_container.add_child(palette_label)
		
		var swatch_container := PalettePreviewScene.instantiate()
		swatch_container.setup(trimmed_palette, color_config.color.paint)
		swatch_container.swatch_selected.connect(_on_swatch_selected.bind(trimmed_palette.get_colors()))
		palette_container.add_child(swatch_container)
		palettes_content_container.add_child(palette_container)
		palette_previews.append(swatch_container)
	
	HandlerGUI.register_focus_sequence(palettes_content_container, palette_previews)

func _on_swatch_selected(index: int, color_strings: PackedStringArray) -> void:
	var color := color_strings[index]
	if color_config.color.paint == color:
		return
	color_config.set_color_to_string(color)
