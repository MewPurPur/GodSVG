extends VBoxContainer

@onready var viewport: Viewport = $ViewportContainer/Viewport
@onready var zoom_reset_button: Button = %ZoomReset
@onready var display: TextureRect = %Checkerboard
@onready var controls: TextureRect = %Checkerboard/Controls
@onready var grid_button: Button = %LeftMenu/GridVisible
@onready var grid_popup: Popup = %LeftMenu/GridPopup
@onready var more_button: Button = %LeftMenu/MoreOptions
@onready var more_popup: Popup = %LeftMenu/MorePopup

const minimum_visible_proportion := 0.2
const settings_menu := preload("settings_menu.tscn")

var zoom_level:
	set(value):
		zoom_level = clampf(value, 0.0625, 8.0)
		zoom_reset_button.text = String.num(zoom_level * 100) + "%"
		viewport.size_2d_override = viewport.size / zoom_level
		clamp_view()
		controls.zoom = zoom_level


func _ready() -> void:
	zoom_level = 2

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

func _on_grid_visible_pressed() -> void:
	grid_popup.popup(Utils.calculate_popup_rect(
			grid_button.global_position, grid_button.size, grid_popup.size, true))

func _on_more_options_pressed() -> void:
	# Add the options the first time this is clicked.
	if more_popup.get_button_count() == 0:
		var butt := Button.new()
		butt.text = "GodSVG repository"
		butt.icon = load("res://visual/icons/Link.svg")
		butt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		more_popup.add_button(butt, true, true)
		butt.pressed.connect(open_godsvg_repo)
	more_popup.popup(Utils.calculate_popup_rect(
			more_button.global_position, more_button.size, more_popup.size, true))

func open_godsvg_repo() -> void:
	OS.shell_open("https://github.com/MewPurPur/GodSVG")
