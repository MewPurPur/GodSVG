extends VBoxContainer

const settings_menu = preload("settings_menu.tscn")
const about_menu = preload("about_menu.tscn")
const docs = preload("docs.tscn")

const NumberField = preload("res://src/ui_elements/number_field.tscn")

@onready var zoom_reset_button: Button = %ZoomReset
@onready var zoom_in_button: Button = %ZoomIn
@onready var zoom_out_button: Button = %ZoomOut
@onready var viewport: SubViewport = $ViewportContainer/Viewport
@onready var controls: Control = %Checkerboard/Controls
@onready var grid_visuals: Camera2D = $ViewportContainer/Viewport/ViewCamera
@onready var visuals_button: Button = %LeftMenu/Visuals
@onready var visuals_popup: Popup = %LeftMenu/VisualsPopup
@onready var more_button: Button = %LeftMenu/MoreOptions
@onready var more_popup: Popup = %LeftMenu/MorePopup
@onready var snapper: BetterLineEdit = %LeftMenu/Snapping/NumberEdit

func update_zoom_widget(zoom_level: float) -> void:
	await get_tree().process_frame
	zoom_reset_button.text = String.num(zoom_level * 100,
			2 if zoom_level < 0.1 else 1 if zoom_level < 10.0 else 0) + "%"
	zoom_out_button.disabled = (zoom_level <= viewport.min_zoom)
	zoom_out_button.mouse_default_cursor_shape = Control.CURSOR_ARROW\
			if zoom_out_button.disabled else Control.CURSOR_POINTING_HAND
	zoom_in_button.disabled = (zoom_level >= viewport.max_zoom)
	zoom_in_button.mouse_default_cursor_shape = Control.CURSOR_ARROW\
			if zoom_in_button.disabled else Control.CURSOR_POINTING_HAND


func _on_settings_pressed() -> void:
	more_popup.hide()
	var settings_menu_instance := settings_menu.instantiate()
	get_tree().get_root().add_child(settings_menu_instance)

func _on_visuals_button_pressed() -> void:
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
	
	visuals_popup.set_btn_array([show_visuals_btn, show_handles_btn, rasterize_btn]\
			as Array[Button])
	visuals_popup.popup(Utils.calculate_popup_rect(
			visuals_button.global_position, visuals_button.size, visuals_popup.size, true))

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
	more_popup.set_btn_array(buttons_arr)
	more_popup.popup(Utils.calculate_popup_rect(
			more_button.global_position, more_button.size, more_popup.size, true))

func open_godsvg_repo() -> void:
	more_popup.hide()
	OS.shell_open("https://github.com/MewPurPur/GodSVG")

func open_about() -> void:
	more_popup.hide()
	var about_menu_instance := about_menu.instantiate()
	get_tree().get_root().add_child(about_menu_instance)

func open_docs() -> void:
	more_popup.hide()
	var docs_instance := docs.instantiate()
	get_tree().get_root().add_child(docs_instance)

func open_sponsor() -> void:
	more_popup.hide()
	OS.shell_open("https://ko-fi.com/mewpurpur")

func toggle_grid_visuals() -> void:
	grid_visuals.visible = not grid_visuals.visible

func toggle_handles_visuals() -> void:
	controls.visible = not controls.visible

func toggle_rasterization() -> void:
	viewport.display_texture.rasterized = not viewport.display_texture.rasterized


func _on_snap_button_toggled(toggled_on: bool) -> void:
	snapper.editable = toggled_on
