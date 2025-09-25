extends MarginContainer

const collapsed_arrow = preload("res://assets/icons/SmallLeftArrow.svg")
const expanded_arrow = preload("res://assets/icons/SmallDownArrow.svg")

@onready var label: Label = %Label
@onready var panel: PanelContainer = $Panel

var collapsed := true
var short_text := ""
var full_text := ""

func _ready() -> void:
	label.add_theme_color_override("font_color", ThemeUtils.dim_text_color)
	panel.draw.connect(_on_panel_draw)

func setup(new_full_text: String, new_short_text: String) -> void:
	short_text = new_short_text
	full_text = new_full_text
	update_text()

func _on_panel_draw() -> void:
	var arrow_texture := collapsed_arrow if collapsed else expanded_arrow
	var texture_size := arrow_texture.get_size()
	panel.draw_texture_rect(arrow_texture, Rect2(Vector2(panel.size.x - texture_size.x - 4, panel.size.y / 2 - texture_size.y / 2), texture_size),
			false, ThemeUtils.context_icon_normal_color)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		collapsed = not collapsed
		update_text()

func update_text() -> void:
	label.text = short_text if collapsed else full_text
	queue_redraw()
