extends VBoxContainer

const settings_menu = preload("settings_menu.tscn")
const about_menu = preload("about_menu.tscn")
const docs = preload("docs.tscn")

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")
const BetterToggleButtonType = preload("res://src/ui_elements/BetterToggleButton.gd")

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const NumberField = preload("res://src/ui_elements/number_field.tscn")

@onready var viewport: SubViewport = $ViewportContainer/Viewport
@onready var controls: Control = %Checkerboard/Controls
@onready var grid_visuals: Camera2D = $ViewportContainer/Viewport/ViewCamera
@onready var visuals_button: Button = %LeftMenu/Visuals
@onready var more_button: Button = %LeftMenu/MoreOptions
@onready var snapper: NumberEditType = %LeftMenu/Snapping/NumberEdit
@onready var snap_button: BetterToggleButtonType = %LeftMenu/Snapping/SnapButton


func _ready() -> void:
	update_snap_config()

func update_snap_config() -> void:
	var snap_config := GlobalSettings.save_data.snap
	var snap_enabled := snap_config > 0.0
	snap_button.button_pressed = snap_enabled
	snapper.editable = snap_enabled
	snapper.current_value = absf(snap_config)

func _on_settings_pressed() -> void:
	var settings_menu_instance := settings_menu.instantiate()
	get_tree().get_root().add_child(settings_menu_instance)

func _on_visuals_button_pressed() -> void:
	var btn_arr: Array[Button] = []
	var show_visuals_btn := CheckBox.new()
	show_visuals_btn.text = tr(&"#show_grid")
	show_visuals_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	show_visuals_btn.button_pressed = grid_visuals.visible
	show_visuals_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	show_visuals_btn.pressed.connect(toggle_grid_visuals)
	
	var show_handles_btn := CheckBox.new()
	show_handles_btn.text = tr(&"#show_handles")
	show_handles_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	show_handles_btn.button_pressed = controls.visible
	show_handles_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	show_handles_btn.pressed.connect(toggle_handles_visuals)
	
	var rasterize_btn := CheckBox.new()
	rasterize_btn.text = tr(&"#rasterize_svg")
	rasterize_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	rasterize_btn.button_pressed = viewport.display_texture.rasterized
	rasterize_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	rasterize_btn.pressed.connect(toggle_rasterization)
	
	btn_arr = [show_visuals_btn, show_handles_btn, rasterize_btn]
	var visuals_popup := ContextPopup.instantiate()
	add_child(visuals_popup)
	visuals_popup.set_btn_array(btn_arr)
	Utils.popup_under_control(visuals_popup, visuals_button, true)

func _on_more_options_pressed() -> void:
	var open_repo_btn := Button.new()
	open_repo_btn.text = tr(&"#repo_button_text")
	open_repo_btn.icon = load("res://visual/icons/Link.svg")
	open_repo_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	open_repo_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	open_repo_btn.pressed.connect(open_godsvg_repo)
	
	var about_btn := Button.new()
	about_btn.text = tr(&"#about_button_text")
	about_btn.icon = load("res://visual/icon.png")
	about_btn.expand_icon = true
	about_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	about_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	about_btn.pressed.connect(open_about)
	
	var docs_btn := Button.new()
	docs_btn.text = tr(&"#docs_button_text")
	docs_btn.icon = load("res://visual/icons/Docs.svg")
	docs_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	docs_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	docs_btn.pressed.connect(open_docs)
	
	var donate_btn := Button.new()
	donate_btn.text = tr(&"#donate_button_text")
	donate_btn.icon = load("res://visual/icons/Heart.svg")
	donate_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	donate_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	donate_btn.pressed.connect(open_sponsor)
	
	var buttons_arr: Array[Button] = [open_repo_btn, about_btn, docs_btn, donate_btn]
	var more_popup := ContextPopup.instantiate()
	add_child(more_popup)
	more_popup.set_btn_array(buttons_arr)
	Utils.popup_under_control(more_popup, more_button, true)

func open_godsvg_repo() -> void:
	OS.shell_open("https://github.com/MewPurPur/GodSVG")

func open_about() -> void:
	var about_menu_instance := about_menu.instantiate()
	get_tree().get_root().add_child(about_menu_instance)

func open_docs() -> void:
	var docs_instance := docs.instantiate()
	get_tree().get_root().add_child(docs_instance)

func open_sponsor() -> void:
	OS.shell_open("https://ko-fi.com/mewpurpur")

func toggle_grid_visuals() -> void:
	grid_visuals.visible = not grid_visuals.visible

func toggle_handles_visuals() -> void:
	controls.visible = not controls.visible

func toggle_rasterization() -> void:
	viewport.display_texture.rasterized = not viewport.display_texture.rasterized


func _on_snap_button_toggled(toggled_on: bool) -> void:
	GlobalSettings.modify_save_data(&"snap",
			absf(GlobalSettings.save_data.snap) * (1 if toggled_on else -1))
	update_snap_config()

func _on_number_edit_value_changed(new_value: float) -> void:
	GlobalSettings.modify_save_data(&"snap",
			new_value * signf(GlobalSettings.save_data.snap))
	update_snap_config()
