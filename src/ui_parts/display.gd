extends VBoxContainer


signal view_settings_updated(show_grid: bool, show_handles: bool, rasterized_svg: bool)
signal snap_settings_updated(snap_enabled: bool, snap_amount: float)

const settings_menu = preload("settings_menu.tscn")
const about_menu = preload("about_menu.tscn")
const donate_menu = preload("res://src/ui_parts/donate_menu.tscn")
const update_menu = preload("res://src/ui_parts/update_menu.tscn")

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")
const BetterToggleButtonType = preload("res://src/ui_elements/BetterToggleButton.gd")

const NumberField = preload("res://src/ui_elements/number_field.tscn")

@onready var viewport: SubViewport = $ViewportPanel/ViewportContainer/Viewport
@onready var controls: Control = %Checkerboard/Controls
@onready var grid_visuals: Control = %Camera
@onready var visuals_button: Button = %LeftMenu/Visuals
@onready var more_button: Button = %LeftMenu/MoreOptions
@onready var snapper: NumberEditType = %LeftMenu/Snapping/SnapNumberEdit
@onready var snap_button: BetterToggleButtonType = %LeftMenu/Snapping/SnapButton
@onready var panel_container: PanelContainer = $PanelContainer
@onready var viewport_panel: PanelContainer = $ViewportPanel


func _ready() -> void:
	update_snap_config()
	view_settings_updated.emit(grid_visuals.visible, controls.visible,
			viewport.display_texture.rasterized)


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed("open_settings"):
		_on_settings_pressed()
	elif input_event.is_action_pressed("view_show_grid"):
		toggle_grid_visuals()
	elif input_event.is_action_pressed("view_show_handles"):
		toggle_handles_visuals()
	elif input_event.is_action_pressed("view_rasterized_svg"):
		toggle_rasterization()
	elif input_event.is_action_pressed("snap_toggle"):
		toggle_snap()
	elif input_event.is_action_pressed("about_repo"):
		open_godsvg_repo()
	elif input_event.is_action_pressed("about_website"):
		open_godsvg_website()
	elif input_event.is_action_pressed("about_info"):
		open_about()
	elif input_event.is_action_pressed("about_donate"):
		open_sponsor()


func _notification(what: int) -> void:
	if what == Utils.CustomNotification.NUMBER_PRECISION_CHANGED:
		update_snap_config()
	elif what == NOTIFICATION_WM_ABOUT:
		open_about.call_deferred()
	elif what in [NOTIFICATION_READY, Utils.CustomNotification.THEME_CHANGED]:
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = ThemeGenerator.overlay_panel_inner_color
		stylebox.set_content_margin_all(6)
		panel_container.add_theme_stylebox_override("panel", stylebox)
		var frame := StyleBoxFlat.new()
		frame.draw_center = false
		frame.border_width_left = 2
		frame.border_width_top = 2
		frame.border_color = ThemeGenerator.connected_button_border_color_pressed
		frame.content_margin_left = 2
		frame.content_margin_top = 2
		viewport_panel.add_theme_stylebox_override("panel", frame)


func update_snap_config() -> void:
	var snap_config := GlobalSettings.save_data.snap
	var snap_enabled := snap_config > 0.0
	snap_button.button_pressed = snap_enabled
	snapper.editable = snap_enabled
	snapper.set_value(absf(snap_config))
	snap_settings_updated.emit(snap_enabled, absf(snap_config))


func _on_settings_pressed() -> void:
	var settings_menu_instance := settings_menu.instantiate()
	HandlerGUI.add_overlay(settings_menu_instance)


func _on_visuals_button_pressed() -> void:
	var btn_arr: Array[Button] = [
		Utils.create_checkbox(tr("Show Grid"), toggle_grid_visuals, grid_visuals.visible),
		Utils.create_checkbox(tr("Show Handles"), toggle_handles_visuals, controls.visible),
		Utils.create_checkbox(tr("Rasterized SVG"), toggle_rasterization,
				viewport.display_texture.rasterized),
	]
	
	var visuals_popup := ContextPopup.new()
	visuals_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(visuals_popup, visuals_button.get_global_rect(),
			get_viewport())

func _on_more_options_pressed() -> void:
	var about_btn := Utils.create_btn(tr("About…"), open_about, false,
			load("res://visual/icon.svg"))
	about_btn.expand_icon = true
	var buttons_arr: Array[Button] = [
		about_btn,
		Utils.create_btn(tr("Donate…"), open_sponsor, false,
				load("res://visual/icons/Heart.svg")),
		Utils.create_btn(tr("GodSVG Repository"), open_godsvg_repo, false,
				load("res://visual/icons/Link.svg")),
		Utils.create_btn(tr("GodSVG Website"), open_godsvg_website, false,
				load("res://visual/icons/Link.svg")),
		Utils.create_btn(tr("Check for Updates"), open_update_checker, false,
				load("res://visual/icons/Reload.svg"))
	]
	var separator_indices: Array[int] = [2,4]

	var more_popup := ContextPopup.new()
	more_popup.setup(buttons_arr, true, -1, separator_indices)
	HandlerGUI.popup_under_rect_center(more_popup, more_button.get_global_rect(),
			get_viewport())

func open_godsvg_repo() -> void:
	OS.shell_open("https://github.com/MewPurPur/GodSVG")

func open_godsvg_website() -> void:
	OS.shell_open("https://github.com/MewPurPur/GodSVG")

func open_about() -> void:
	var about_menu_instance := about_menu.instantiate()
	HandlerGUI.add_overlay(about_menu_instance)

func open_sponsor() -> void:
	var donate_menu_instance := donate_menu.instantiate()
	HandlerGUI.add_overlay(donate_menu_instance)

func open_update_checker() -> void:
	var update_menu_instance := update_menu.instantiate()
	HandlerGUI.add_overlay(update_menu_instance)


func toggle_grid_visuals() -> void:
	grid_visuals.visible = not grid_visuals.visible
	view_settings_updated.emit(grid_visuals.visible, controls.visible, viewport.display_texture.rasterized)


func toggle_handles_visuals() -> void:
	controls.visible = not controls.visible
	view_settings_updated.emit(grid_visuals.visible, controls.visible, viewport.display_texture.rasterized)


func toggle_rasterization() -> void:
	viewport.display_texture.rasterized = not viewport.display_texture.rasterized
	view_settings_updated.emit(grid_visuals.visible, controls.visible, viewport.display_texture.rasterized)


func toggle_snap() -> void:
	snap_button.button_pressed = not snap_button.button_pressed


func set_snap_amount(snap_value: float) -> void:
	snapper.set_value(snap_value)


func _on_snap_button_toggled(toggled_on: bool) -> void:
	GlobalSettings.modify_save_data("snap",
			absf(GlobalSettings.save_data.snap) * (1 if toggled_on else -1))
	update_snap_config()

func _on_snap_number_edit_value_changed(new_value: float) -> void:
	GlobalSettings.modify_save_data("snap",
			new_value * signf(GlobalSettings.save_data.snap))
	update_snap_config()
