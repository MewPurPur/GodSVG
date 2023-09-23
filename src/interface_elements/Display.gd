extends VBoxContainer

@onready var viewport: Viewport = $ViewportContainer/Viewport
@onready var zoom_reset_button: Button = %ZoomReset
@onready var display: TextureRect = %Checkerboard

const minimum_visible_proportion := 0.2
const settings_menu := preload("res://src/interface_elements/settings_menu.tscn")

var zoom_level := 1.0:
	set(value):
		zoom_level = clampf(value, 0.125, 8.0)
		zoom_reset_button.text = String.num(zoom_level * 100) + "%"
		viewport.size_2d_override = viewport.size / zoom_level
		clamp_view()


func zoom_in() -> void:
	zoom_level *= 2

func zoom_out() -> void:
	zoom_level /= 2

func zoom_reset() -> void:
	zoom_level = 1.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		display.position += event.relative / zoom_level
		clamp_view()

	if event is InputEventPanGesture:
		if event.ctrl_pressed:
			zoom_level *= 1 + event.delta.y / 2
		else:
			display.position -= event.delta * 32 / zoom_level
			clamp_view()

	if event is InputEventMagnifyGesture:
		zoom_level *= event.factor

	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom_in()
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out()

	if event is InputEventMouseButton:
		if event.ctrl_pressed:
			pass

func clamp_view() -> void:
	var min_pos := vec_min((minimum_visible_proportion - 1) * display.size,
			minimum_visible_proportion * viewport.size / zoom_level - display.size)
	var max_pos := vec_max(viewport.size / zoom_level - minimum_visible_proportion *\
			display.size, (1 - minimum_visible_proportion) * viewport.size / zoom_level)
	display.position = display.position.clamp(min_pos, max_pos)

func vec_min(first: Vector2, second: Vector2) -> Vector2:
	return Vector2(minf(first.x, second.x), minf(first.y, second.y))

func vec_max(first: Vector2, second: Vector2) -> Vector2:
	return Vector2(maxf(first.x, second.x), maxf(first.y, second.y))


func _on_settings_pressed() -> void:
	var settings_menu_instance := settings_menu.instantiate()
	get_tree().get_root().add_child(settings_menu_instance)
