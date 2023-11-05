## A popup for picking a color.
extends Popup

const GoodColorPickerType = preload("res://src/ui_elements/good_color_picker.gd")

const ColorSwatch = preload("res://src/ui_elements/color_swatch.tscn")

signal color_picked(new_color: String, final: bool)
var current_value: String

@onready var palettes_content: ScrollContainer = %Palettes
@onready var palettes_content_container: VBoxContainer = %Palettes/VBox
@onready var color_picker_content: VBoxContainer = %ColorPicker
@onready var color_picker: GoodColorPickerType = %ColorPicker/ColorPicker
@onready var palette_button: Button = %Tabs/PaletteButton
@onready var color_picker_button: Button = %Tabs/ColorPickerButton
@onready var panel_container: PanelContainer = $PanelContainer

func _ready() -> void:
	palette_button.button_pressed = true
	palette_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
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
			if named_color.color == current_value:
				swatch.disabled = true
				swatch.mouse_default_cursor_shape = Control.CURSOR_ARROW
			swatch.pressed.connect(pick_palette_color.bind(named_color.color))
			swatch_container.add_child(swatch)
		palette_container.add_child(swatch_container)
		palettes_content_container.add_child(palette_container)

func update_color_picker() -> void:
	color_picker.setup_color(current_value)

func pick_palette_color(color: String) -> void:
	color_picked.emit(color, true)

func pick_color(color: String) -> void:
	color_picked.emit(color, false)


# Switching between palette mode and color picker mode.
func _on_palette_button_pressed() -> void:
	palette_button.disabled = true
	color_picker_button.disabled = false
	palette_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	color_picker_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	color_picker_content.hide()
	palettes_content.show()

func _on_color_picker_button_pressed() -> void:
	color_picker_button.disabled = true
	palette_button.disabled = false
	palette_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	color_picker_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	color_picker_content.show()
	palettes_content.hide()


func _on_popup_hide() -> void:
	queue_free()
