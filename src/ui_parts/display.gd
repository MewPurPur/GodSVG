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
const ConfirmDialog := preload("res://src/ui_parts/confirm_dialog.tscn")

@onready var viewport: SubViewport = %Viewport
@onready var controls: Control = %Viewport/Checkerboard/Controls
@onready var grid_visuals: Control = %Viewport/Camera
@onready var reference_button = %LeftMenu/Reference
@onready var visuals_button: Button = %LeftMenu/Visuals
@onready var more_button: Button = %LeftMenu/MoreOptions
@onready var snapper: NumberEditType = %LeftMenu/Snapping/SnapNumberEdit
@onready var snap_button: BetterToggleButtonType = %LeftMenu/Snapping/SnapButton
@onready var panel_container: PanelContainer = $PanelContainer
@onready var viewport_panel: PanelContainer = $ViewportPanel
@onready var debug_container: MarginContainer = $ViewportPanel/DebugContainer
@onready var debug_label: Label = $ViewportPanel/DebugContainer/VBoxContainer/DebugLabel
@onready var input_debug_label: Label = $ViewportPanel/DebugContainer/VBoxContainer/InputDebugLabel

@onready var reference_texture = %ReferenceTexture

var reference_overlay := false

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.LANGUAGE_CHANGED:
		update_translations()
	elif what == Utils.CustomNotification.NUMBER_PRECISION_CHANGED:
		update_snap_config()
	elif what == NOTIFICATION_WM_ABOUT:
		open_about.call_deferred()
	elif what ==  Utils.CustomNotification.THEME_CHANGED:
		update_theme()

func _ready() -> void:
	update_translations()
	update_theme()
	update_snap_config()
	get_window().window_input.connect(_update_input_debug)
	view_settings_updated.emit(grid_visuals.visible, controls.visible,
			viewport.display_texture.rasterized)

	if OS.has_feature("web"):
		reference_button.hide()

func _unhandled_input(input_event: InputEvent) -> void:
	if Input.is_action_pressed("debug"):
		if debug_container.visible:
			debug_container.hide()
		else:
			debug_container.show()
			update_debug()
			input_debug_label.text = ""
	elif input_event.is_action_pressed("load_reference"):
		load_reference_image()
	elif input_event.is_action_pressed("open_settings"):
		_on_settings_pressed()
	elif input_event.is_action_pressed("view_show_grid"):
		toggle_grid_visuals()
	elif input_event.is_action_pressed("view_show_handles"):
		toggle_handles_visuals()
	elif input_event.is_action_pressed("view_rasterized_svg"):
		toggle_rasterization()
	elif input_event.is_action_pressed("view_show_reference"):
		toggle_reference_image()
	elif input_event.is_action_pressed("view_overlay_reference"):
		toggle_reference_overlay()
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
	elif input_event.is_action_pressed("check_updates"):
		open_update_checker()


func update_translations() -> void:
	%LeftMenu/Settings.tooltip_text = TranslationServer.translate("Settings")
	%LeftMenu/Visuals.tooltip_text = TranslationServer.translate("Visuals")
	%LeftMenu/Snapping/SnapButton.tooltip_text = TranslationServer.translate(
			"Enable snapping")
	%LeftMenu/Snapping/SnapNumberEdit.tooltip_text = TranslationServer.translate(
			"Snap size")

func update_theme() -> void:
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


func _on_reference_pressed() -> void:
	var btn_arr: Array[Button] = [
		ContextPopup.create_button(TranslationServer.translate("Load reference image"),
			load_reference_image, false, load("res://visual/icons/Reference.svg")),
		ContextPopup.create_checkbox(TranslationServer.translate("Show reference"),
			toggle_reference_image, reference_texture.visible, ""),
		ContextPopup.create_checkbox(TranslationServer.translate("Overlay reference"),
			toggle_reference_overlay, reference_overlay)
	]
	
	var reference_popup := ContextPopup.new()
	reference_popup.setup(btn_arr, false)
	HandlerGUI.popup_under_rect_center(reference_popup, reference_button.get_global_rect(),
			get_viewport())

func _on_visuals_button_pressed() -> void:
	var btn_arr: Array[Button] = [
		ContextPopup.create_checkbox(TranslationServer.translate("Show Grid"),
				toggle_grid_visuals, grid_visuals.visible, "view_show_grid"),
		ContextPopup.create_checkbox(TranslationServer.translate("Show Handles"),
				toggle_handles_visuals, controls.visible, "view_show_handles"),
		ContextPopup.create_checkbox(TranslationServer.translate("Rasterized SVG"),
				toggle_rasterization, viewport.display_texture.rasterized,
				"view_rasterized_svg")]
	
	var visuals_popup := ContextPopup.new()
	visuals_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(visuals_popup, visuals_button.get_global_rect(),
			get_viewport())

func _on_more_options_pressed() -> void:
	var about_btn := ContextPopup.create_button(TranslationServer.translate("About…"),
			open_about, false, load("res://visual/icon.png"), "about_info")
	about_btn.expand_icon = true
	var buttons_arr: Array[Button] = [
		about_btn,
		ContextPopup.create_button(TranslationServer.translate("Donate…"),
				open_sponsor, false, load("res://visual/icons/Heart.svg"), "about_donate"),
		ContextPopup.create_button(TranslationServer.translate("GodSVG repository"),
				open_godsvg_repo, false, load("res://visual/icons/Link.svg"), "about_repo"),
		ContextPopup.create_button(TranslationServer.translate("GodSVG website"),
				open_godsvg_website, false, load("res://visual/icons/Link.svg"),
				"about_website"),
		ContextPopup.create_button(TranslationServer.translate("Check for updates"),
				open_update_checker, false, load("res://visual/icons/Reload.svg"),
				"check_updates")]
	var separator_indices: Array[int] = [2, 4]
	
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
	var confirmation_dialog := ConfirmDialog.instantiate()
	HandlerGUI.add_overlay(confirmation_dialog)
	confirmation_dialog.setup(TranslationServer.translate("Check for updates?"),
			TranslationServer.translate("This requires GodSVG to connect to the internet."),
			TranslationServer.translate("OK"), _list_updates)

func _list_updates() -> void:
	HandlerGUI.remove_all_overlays()
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

func toggle_reference_image() -> void:
	reference_texture.visible = not reference_texture.visible

func toggle_reference_overlay() -> void:
	reference_overlay = not reference_overlay
	if reference_overlay:
		viewport.move_child(reference_texture, viewport.get_child_count() - 1)
	else:
		viewport.move_child(reference_texture, 0)

func load_reference_image() -> void:
	FileUtils.open_reference_load_dialog()
	await Indications.imported_reference
	var ref_path = GlobalSettings.save_data.get("reference_path")
	var img = Image.load_from_file(ref_path)
	reference_texture.texture = ImageTexture.create_from_image(img)
	reference_texture.show()

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

# The strings are intentionally not localized.
func update_debug() -> void:
	var debug_text := ""
	debug_text += "FPS: %s\n" % Performance.get_monitor(Performance.TIME_FPS)
	debug_text += "Static Mem: %s\n" % String.humanize_size(int(Performance.get_monitor(
			Performance.MEMORY_STATIC)))
	debug_text += "Nodes: %s\n" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	debug_text += "Stray nodes: %s\n" % Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	debug_text += "Objects: %s\n" % Performance.get_monitor(Performance.OBJECT_COUNT)
	debug_label.text = debug_text
	# Set up the next update if the container is still visible.
	if debug_container.visible:
		get_tree().create_timer(1.0).timeout.connect(update_debug)

var last_event_text := ""
var last_event_repeat_count := 1

func _update_input_debug(event: InputEvent) -> void:
	if debug_container.visible and event.is_pressed():
		var new_text := input_debug_label.text
		var event_text := event.as_text()
		if event_text == last_event_text:
			last_event_repeat_count += 1
			new_text = new_text.left(new_text.rfind("\n", new_text.length() - 2) + 1)
			event_text += " (%d)" % last_event_repeat_count
		else:
			last_event_text = event_text
			last_event_repeat_count = 1
		if new_text.count("\n") >= 5:
			new_text = new_text.right(-new_text.find("\n") - 1)
		new_text += event_text + "\n"
		input_debug_label.text = new_text
