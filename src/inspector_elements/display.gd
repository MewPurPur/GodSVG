extends VBoxContainer

const settings_menu = preload("settings_menu.tscn")

@onready var zoom_reset_button: Button = %ZoomReset
@onready var viewport: SubViewport = $ViewportContainer/Viewport
@onready var controls: TextureRect = %Checkerboard/Controls
@onready var grid_button: Button = %LeftMenu/GridVisible
@onready var grid_popup: Popup = %LeftMenu/GridPopup
@onready var more_button: Button = %LeftMenu/MoreOptions
@onready var more_popup: Popup = %LeftMenu/MorePopup

func update_zoom_label(zoom_level: float) -> void:
	await get_tree().process_frame
	zoom_reset_button.text = String.num(zoom_level * 100,
			2 if zoom_level < 0.1 else 1 if zoom_level < 10.0 else 0) + "%"


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
