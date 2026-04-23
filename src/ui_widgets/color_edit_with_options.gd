extends HBoxContainer

const ColorEdit = preload("res://src/ui_widgets/color_edit.gd")
const PalettePreview = preload("res://src/ui_widgets/palette_preview.gd")

signal color_picked(new_color: String, is_final: bool, old_final_value: String)

var color_options: PackedStringArray

@onready var color_edit: ColorEdit = $ColorEdit
@onready var palette_preview: PalettePreview = $PalettePreview

func setup(alpha_enabled: bool, new_color_options: PackedStringArray, initial_color: Color) -> void:
	if not is_node_ready():
		await ready
	color_edit.alpha_enabled = alpha_enabled
	if alpha_enabled:
		color_edit.custom_minimum_size.x = 82
	color_options = new_color_options
	color_edit.set_initial_value(initial_color.to_html(color_edit.alpha_enabled))
	
	var color_names := PackedStringArray()
	color_names.resize(color_options.size())
	color_names.fill("")
	palette_preview.setup_fake(color_names, color_options, {}, {}, color_edit.get_value())
	palette_preview.custom_minimum_size.x = palette_preview.SWATCH_SIZE * color_options.size() + palette_preview.SEPARATION * (color_options.size() - 1)
	palette_preview.swatch_selected.connect(_on_palette_preview_swatch_selected)
	color_edit.value_changed.connect(_on_color_edit_value_changed)
	HandlerGUI.register_focus_sequence(self, [color_edit, palette_preview])

func set_color_no_signal(new_color: String) -> void:
	color_edit.set_value_no_signal(new_color)
	palette_preview.current_value = new_color

func _on_palette_preview_swatch_selected(index: int) -> void:
	color_edit.set_value(color_options[index])

func _on_color_edit_value_changed(new_value: String, is_final: bool, old_final_value: String) -> void:
	palette_preview.current_value = new_value
	color_picked.emit(new_value, is_final, old_final_value)
