# A popup for picking a color.
extends PanelContainer

const GoodColorPicker = preload("res://src/ui_widgets/good_color_picker.gd")
const ColorSwatch = preload("res://src/ui_widgets/color_swatch.gd")

# Useful here, because it avoids the Palette validation.
class MockPalette:
	var title: String
	var colors: PackedStringArray
	var color_names: PackedStringArray
	
	func _init(new_title: String, new_colors: PackedStringArray,
	new_color_names: PackedStringArray) -> void:
		title = new_title
		colors = new_colors
		color_names = new_color_names

# If the currentColor keyword is available, but uninteresting, don't show it.
enum CurrentColorAvailability {UNAVAILABLE, UNINTERESTING, INTERESTING}

const ColorSwatchScene = preload("res://src/ui_widgets/color_swatch.tscn")

signal color_picked(new_color: String, final: bool)
var is_none_keyword_available := false
var current_value: String
var effective_color: Color
var show_url: bool

var current_color_availability := CurrentColorAvailability.UNAVAILABLE
var current_color := Color.BLACK

var palette_mode := true

var _palettes_pending_update := false  # Palettes will update when visible.

@onready var palettes_content: ScrollContainer = %Content/Palettes
@onready var palettes_content_container: VBoxContainer = %PalettesContent
@onready var search_field: BetterLineEdit = %SearchBox/SearchField
@onready var color_picker_content: VBoxContainer = %Content/ColorPicker
@onready var color_picker: GoodColorPicker = %Content/ColorPicker
@onready var switch_mode_button: Button = $MainContainer/SwitchMode

var swatches_list: Array[ColorSwatch] = []  # Updated manually.

func _ready() -> void:
	color_picker.color_changed.connect(pick_color)
	color_picker.is_none_keyword_available = is_none_keyword_available
	color_picker.is_current_color_keyword_available = (current_color_availability != CurrentColorAvailability.UNAVAILABLE)
	color_picker.update_keyword_button()
	# Setup the switch mode button.
	switch_mode_button.pressed.connect(_on_switch_mode_button_pressed)
	_palettes_pending_update = true
	setup_content()
	
	const CONST_ARR: PackedStringArray = ["normal", "hover", "pressed"]
	for theme_type in CONST_ARR:
		var sb: StyleBoxFlat = switch_mode_button.get_theme_stylebox(theme_type, "TranslucentButton").duplicate()
		sb.corner_radius_top_left = 0
		sb.corner_radius_top_right = 0
		sb.corner_radius_bottom_left = 4
		sb.corner_radius_bottom_right = 4
		sb.content_margin_bottom = 3.0
		sb.content_margin_top = 3.0
		switch_mode_button.add_theme_stylebox_override(theme_type, sb)
	# Setup the rest.
	update_color_picker()
	search_field.text_changed.connect(update_palettes)
	search_field.text_change_canceled.connect(update_palettes)

func update_palettes(search_text := "") -> void:
	for child in palettes_content_container.get_children():
		child.queue_free()
	search_field.placeholder_text = Translator.translate("Search color")
	var reserved_colors := PackedStringArray()
	var reserved_color_names := PackedStringArray()
	if is_none_keyword_available:
		reserved_colors.append("none")
		reserved_color_names.append("No color")
	if current_color_availability == CurrentColorAvailability.INTERESTING:
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
			palette_container.add_child(palette_label)
		
		var swatch_container := HFlowContainer.new()
		swatch_container.add_theme_constant_override("h_separation", 3)
		for i in indices_to_show:
			var swatch := ColorSwatchScene.instantiate()
			var color_to_show := palette.colors[i]
			swatch.color = color_to_show
			swatch.color_name = palette.color_names[i]
			swatch.current_color = current_color
			swatch.pressed.connect(pick_palette_color.bind(color_to_show))
			swatch_container.add_child(swatch)
			swatches_list.append(swatch)
			if not current_value.is_empty() and ColorParser.are_colors_same(
			ColorParser.add_hash_if_hex(color_to_show), current_value):
				swatch.disabled = true
				swatch.mouse_default_cursor_shape = Control.CURSOR_ARROW
		palette_container.add_child(swatch_container)
		palettes_content_container.add_child(palette_container)

func update_color_picker() -> void:
	color_picker.setup_color(current_value, effective_color)

func pick_palette_color(color: String) -> void:
	current_value = color
	queue_free()

func pick_color(color: String) -> void:
	current_value = color
	_palettes_pending_update = true
	color_picked.emit(color, false)


# Switching between palette mode and color picker mode.
func _on_switch_mode_button_pressed() -> void:
	palette_mode = not palette_mode
	setup_content()

func setup_content() -> void:
	switch_mode_button.text = Translator.translate("Palettes") if palette_mode else Translator.translate("Color Picker")
	color_picker_content.visible = not palette_mode
	palettes_content.visible = palette_mode
	if palette_mode and _palettes_pending_update:
		update_palettes()
		_palettes_pending_update = false

func _exit_tree() -> void:
	color_picked.emit(current_value, true)

func _input(event: InputEvent) -> void:
	if ShortcutUtils.is_action_pressed(event, "find"):
		search_field.grab_focus()
		accept_event()
