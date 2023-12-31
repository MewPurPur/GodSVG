## A popup for picking a color.
extends Popup

const GoodColorPickerType = preload("res://src/ui_elements/good_color_picker.gd")
const ColorSwatchType = preload("res://src/ui_elements/color_swatch.gd")

const ColorSwatch = preload("res://src/ui_elements/color_swatch.tscn")

signal color_picked(new_color: String, final: bool)
var current_value: String

var palette_mode := true

@onready var palettes_content: ScrollContainer = %Content/Palettes
@onready var palettes_content_container: VBoxContainer = %Content/Palettes/VBox
@onready var color_picker_content: VBoxContainer = %Content/ColorPicker
@onready var color_picker: GoodColorPickerType = %Content/ColorPicker
@onready var switch_mode_button: Button = $PanelContainer/MainContainer/SwitchMode
@onready var panel_container: PanelContainer = $PanelContainer

var swatches_list: Array[ColorSwatchType] = []  # Updated manually.

func _ready() -> void:
	update_palettes()
	update_color_picker()

func update_palettes() -> void:
	var reserved_color_palette := ColorPalette.new("", [NamedColor.new("none")])
	# TODO Gradients should be added here.
	var displayed_palettes: Array[ColorPalette] = [reserved_color_palette]
	displayed_palettes += GlobalSettings.get_palettes()
	for palette in displayed_palettes:
		if palette.named_colors.is_empty():
			continue
		
		var palette_container := VBoxContainer.new()
		# Only the reserved palette should have an empty name.
		if not palette.name.is_empty():
			var palette_label := Label.new()
			palette_label.text = palette.name
			palette_label.add_theme_font_size_override(&"font_size", 16)
			palette_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			palette_container.add_child(palette_label)
		
		var swatch_container := HFlowContainer.new()
		swatch_container.add_theme_constant_override(&"h_separation", 3)
		for named_color in palette.named_colors:
			var swatch := ColorSwatch.instantiate()
			swatch.named_color = named_color
			swatch.pressed.connect(pick_palette_color.bind(named_color.color))
			swatch_container.add_child(swatch)
			swatches_list.append(swatch)
		palette_container.add_child(swatch_container)
		palettes_content_container.add_child(palette_container)
		disable_swatches()

func disable_swatches() -> void:
	for swatch in swatches_list:
		if swatch.named_color.color == current_value:
			swatch.disabled = true
			swatch.mouse_default_cursor_shape = Control.CURSOR_ARROW
		else:
			swatch.disabled = false
			swatch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func update_color_picker() -> void:
	color_picker.setup_color(current_value)

func pick_palette_color(color: String) -> void:
	color_picked.emit(color, true)

func pick_color(color: String) -> void:
	current_value = color
	disable_swatches()
	color_picked.emit(color, false)


# Switching between palette mode and color picker mode.
func _switch_mode() -> void:
	palette_mode = not palette_mode
	switch_mode_button.text = tr(&"#palettes" if palette_mode else &"#color_picker")
	color_picker_content.visible = not palette_mode
	palettes_content.visible = palette_mode


func _on_popup_hide() -> void:
	color_picked.emit(current_value, true)
	queue_free()
