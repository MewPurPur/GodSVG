extends ScrollContainer

const ColorSwatchScene = preload("res://src/ui_widgets/color_swatch.tscn")

# Useful here, because it avoids the Palette validation.
class MockPalette:
	var title: String
	var colors: PackedStringArray
	var color_names: PackedStringArray
	
	func _init(new_title: String, new_colors: PackedStringArray, new_color_names: PackedStringArray) -> void:
		title = new_title
		colors = new_colors
		color_names = new_color_names

# If the currentColor keyword is available, but uninteresting, don't show it.
enum CurrentColorAvailability {UNAVAILABLE, UNINTERESTING, INTERESTING}

signal color_changed(new_color: String)
var is_none_keyword_available := false
var current_value: String
var show_url: bool
var show_current_color := false
var current_color := Color.BLACK

@onready var palettes_content_container: VBoxContainer = %PalettesContent
@onready var search_field: BetterLineEdit = %SearchField

func _ready() -> void:
	search_field.text_changed.connect(rebuild_content)
	search_field.text_change_canceled.connect(rebuild_content)
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("ui_undo", Callable())
	shortcuts.add_shortcut("ui_redo", Callable())
	shortcuts.add_shortcut("find", search_field.grab_focus)
	HandlerGUI.register_shortcuts(self, shortcuts)

func setup_color(new_color: String) -> void:
	current_value = new_color
	rebuild_content()

func rebuild_content(search_text := "") -> void:
	for child in palettes_content_container.get_children():
		child.queue_free()
	search_field.placeholder_text = Translator.translate("Search color")
	var reserved_colors := PackedStringArray()
	var reserved_color_names := PackedStringArray()
	if is_none_keyword_available:
		reserved_colors.append("none")
		reserved_color_names.append("No color")
	if show_current_color:
		reserved_colors.append("currentColor")
		reserved_color_names.append("Current color")
	if show_url:
		for element in State.root_element.get_all_valid_element_descendants():
			if element.has_attribute("id"):
				if element is ElementLinearGradient:
					reserved_color_names.append("Linear gradient")
					reserved_colors.append("url(#%s)" % element.get_attribute_value("id"))
				elif element is ElementRadialGradient:
					reserved_color_names.append("Radial gradient")
					reserved_colors.append("url(#%s)" % element.get_attribute_value("id"))
	
	var reserved_palette := MockPalette.new("", reserved_colors, reserved_color_names)
	var displayed_palettes: Array[MockPalette] = [reserved_palette]
	for palette in Configs.savedata.get_palettes():
		if Configs.savedata.is_palette_valid(palette):
			displayed_palettes.append(MockPalette.new(palette.title, palette.get_colors(),
					palette.get_color_names()))
	
	for palette in displayed_palettes:
		var indices_to_show := PackedInt32Array()
		for i in palette.colors.size():
			if search_text.is_empty() or search_text.is_subsequence_ofn(palette.color_names[i]):
				indices_to_show.append(i)
		
		if indices_to_show.is_empty():
			continue
		
		var palette_container := VBoxContainer.new()
		# Don't add a label for the reserved palette with an empty name.
		if not palette.title.is_empty():
			var palette_label := Label.new()
			palette_label.text = palette.title
			palette_label.theme_type_variation = "TitleLabel"
			palette_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			palette_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
			palette_container.add_child(palette_label)
		
		var swatch_container := HFlowContainer.new()
		swatch_container.add_theme_constant_override("h_separation", 3)
		for i in indices_to_show:
			var swatch := ColorSwatchScene.instantiate()
			var color_to_show := palette.colors[i]
			swatch.color = color_to_show
			swatch.color_name = palette.color_names[i]
			swatch.current_color = current_color
			swatch.pressed.connect(func() -> void: pick_color(color_to_show))
			swatch_container.add_child(swatch)
			if not current_value.is_empty() and ColorParser.are_colors_same(
			ColorParser.add_hash_if_hex(color_to_show), current_value):
				swatch.disabled = true
				swatch.mouse_default_cursor_shape = Control.CURSOR_ARROW
		palette_container.add_child(swatch_container)
		palettes_content_container.add_child(palette_container)

func pick_color(color: String) -> void:
	current_value = color
	color_changed.emit(color)
	rebuild_content()
