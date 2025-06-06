extends Node

const AlertDialogScene = preload("res://src/ui_widgets/alert_dialog.tscn")
const ConfirmDialogScene = preload("res://src/ui_widgets/confirm_dialog.tscn")
const SettingsMenuScene = preload("res://src/ui_parts/settings_menu.tscn")
const AboutMenuScene = preload("res://src/ui_parts/about_menu.tscn")
const DonateMenuScene = preload("res://src/ui_parts/donate_menu.tscn")
const UpdateMenuScene = preload("res://src/ui_parts/update_menu.tscn")
const ExportMenuScene = preload("res://src/ui_parts/export_menu.tscn")
const ShortcutPanelScene = preload("res://src/ui_parts/shortcut_panel.tscn")

# Menus should be added with add_menu() and removed by being freed.
# To add them as modals that don't hide the previous one, use add_dialog().
var menu_stack: Array[ColorRect]
var popup_stack: Array[Control]

var shortcut_panel: PanelContainer

func _enter_tree() -> void:
	var window := get_window()
	window.files_dropped.connect(_on_files_dropped)
	window.dpi_changed.connect(update_ui_scale)
	window.size_changed.connect(remove_all_popups)

func _ready() -> void:
	Configs.active_tab_changed.connect(update_window_title)
	Configs.active_tab_status_changed.connect(update_window_title)
	update_window_title()
	
	Configs.ui_scale_changed.connect(update_ui_scale)
	await get_tree().process_frame  # Helps make things more consistent.
	update_ui_scale()
	
	if OS.get_name() == "Android":
		shortcut_panel = ShortcutPanelScene.instantiate()
		get_tree().root.add_child(shortcut_panel)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_ABOUT:
		# TODO Keep track of #101410.
		open_about.call_deferred()

# Drag-and-drop of files.
func _on_files_dropped(files: PackedStringArray) -> void:
	if menu_stack.is_empty():
		get_window().grab_focus()
		FileUtils.apply_svgs_from_paths(files)


func add_menu(new_menu: Control) -> void:
	if not menu_stack.is_empty():
		menu_stack.back().hide()
	_add_control(new_menu)

func add_dialog(new_dialog: Control) -> void:
	if not menu_stack.is_empty():
		menu_stack.back().show()
	_add_control(new_dialog)

func _add_control(new_control: Control) -> void:
	# FIXME subpar workaround to drag & drop not able to be canceled manually.
	get_tree().root.propagate_notification(NOTIFICATION_DRAG_END)
	remove_all_popups()
	
	var overlay_ref := ColorRect.new()
	overlay_ref.color = Color(0, 0, 0, 0.4)
	overlay_ref.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_stack.append(overlay_ref)
	get_tree().root.add_child(overlay_ref)
	overlay_ref.add_child(new_control)
	new_control.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	new_control.tree_exiting.connect(_remove_control.bind(overlay_ref))
	throw_mouse_motion_event()

func _remove_control(overlay_ref: ColorRect = null) -> void:
	# If an overlay_ref is passed but doesn't match, do nothing.
	# This is a hack against exiting overlay menus closing other menus than their own.
	var matching_idx := menu_stack.size() - 1
	if is_instance_valid(overlay_ref):
		while matching_idx >= 0:
			if overlay_ref == menu_stack[matching_idx]:
				break
			matching_idx -= 1
	
	if matching_idx < 0:
		return
	
	overlay_ref = menu_stack.pop_at(matching_idx)
	# If a visible control gets removed, unhide the previous one.
	if overlay_ref.visible and matching_idx >= 1:
		menu_stack[matching_idx - 1].show()
	if is_instance_valid(overlay_ref):
		overlay_ref.queue_free()
	throw_mouse_motion_event()

func remove_all_menus() -> void:
	if menu_stack.is_empty():
		return
	
	while not menu_stack.is_empty():
		menu_stack.pop_back().queue_free()
	throw_mouse_motion_event()


func add_popup(new_popup: Control) -> void:
	var overlay_ref := Control.new()
	overlay_ref.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_ref.gui_input.connect(_parse_popup_overlay_event)
	popup_stack.append(overlay_ref)
	get_tree().root.add_child(overlay_ref)
	overlay_ref.add_child(new_popup)
	if new_popup is PanelContainer:
		var stylebox := new_popup.get_theme_stylebox("panel").duplicate()
		stylebox.shadow_color = Color(0, 0, 0, 0.1)
		stylebox.shadow_size = 8
		new_popup.add_theme_stylebox_override("panel", stylebox)
	
	new_popup.reset_size()
	new_popup.tree_exiting.connect(remove_popup.bind(overlay_ref))
	throw_mouse_motion_event()

func remove_popup(overlay_ref: Control = null) -> void:
	if popup_stack.is_empty():
		return
	# Refer to remove_menu() for why the logic is like this.
	if is_instance_valid(overlay_ref) and overlay_ref != popup_stack.back():
		return
	
	overlay_ref = popup_stack.pop_back()
	if is_instance_valid(overlay_ref):
		overlay_ref.queue_free()
	throw_mouse_motion_event()

func remove_all_popups() -> void:
	if popup_stack.is_empty():
		return
	
	while not popup_stack.is_empty():
		popup_stack.pop_back().queue_free()
	throw_mouse_motion_event()


# Should usually be the global rect of a control.
func popup_under_rect(popup: Control, rect: Rect2, vp: Viewport) -> void:
	add_popup(popup)
	var screen_transform := vp.get_screen_transform()
	var screen_h := vp.get_visible_rect().size.y
	var popup_pos := Vector2(rect.position.x, 0)
	# Popup below if there's enough space or we're in the bottom half of the screen.
	if rect.position.y + rect.size.y + popup.size.y < screen_h or\
	rect.position.y + rect.size.y / 2 <= screen_h / 2.0:
		popup_pos.y = rect.position.y + rect.size.y
	else:
		popup_pos.y = rect.position.y - popup.size.y
	popup_pos += screen_transform.get_origin() / screen_transform.get_scale()
	popup.position = popup_clamp_pos(popup, popup_pos, vp)

# Should usually be the global rect of a control.
func popup_under_rect_center(popup: Control, rect: Rect2, vp: Viewport) -> void:
	add_popup(popup)
	var screen_transform := vp.get_screen_transform()
	var screen_h := vp.get_visible_rect().size.y
	var popup_pos := Vector2(rect.position.x - popup.size.x / 2.0 + rect.size.x / 2, 0)
	# Popup below if there's enough space or we're in the bottom half of the screen.
	if rect.position.y + rect.size.y + popup.size.y < screen_h or\
	rect.position.y + rect.size.y / 2 <= screen_h / 2.0:
		popup_pos.y = rect.position.y + rect.size.y
	else:
		popup_pos.y = rect.position.y - popup.size.y
	# Align horizontally and other things.
	popup_pos += screen_transform.get_origin() / screen_transform.get_scale()
	popup.position = popup_clamp_pos(popup, popup_pos, vp)

# Should usually be the global position of the mouse.
func popup_under_pos(popup: Control, pos: Vector2, vp: Viewport) -> void:
	add_popup(popup)
	var screen_transform := vp.get_screen_transform()
	pos += screen_transform.get_origin() / screen_transform.get_scale()
	popup.position = popup_clamp_pos(popup, pos, vp)

# Helper.
func popup_clamp_pos(popup: Control, attempt_pos: Vector2, vp: Viewport) -> Vector2:
	var screen_transform := vp.get_screen_transform()
	var vp_pos := screen_transform.get_origin() / screen_transform.get_scale()
	for axis in 2:
		attempt_pos[axis] = clampf(attempt_pos[axis], vp_pos[axis],
				vp_pos[axis] + vp.get_visible_rect().size[axis] - popup.size[axis])
	return attempt_pos


func _parse_popup_overlay_event(event: InputEvent) -> void:
	if not popup_stack.is_empty():
		if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT,
		MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			remove_popup()
	get_viewport().set_input_as_handled()

var last_mouse_click_double := false

func _input(event: InputEvent) -> void:
	# So, it turns out that when you double click, only the press will count as such.
	# I don't like that, and it causes problems! So mark the release as double_click too.
	# TODO Godot PR #92582 fixes this.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			last_mouse_click_double = true
		elif last_mouse_click_double and event.is_released():
			event.double_click = true
			last_mouse_click_double = false


func _unhandled_input(event: InputEvent) -> void:
	# Clear popups or overlays.
	if ShortcutUtils.is_action_pressed(event, "ui_cancel"):
		if not popup_stack.is_empty():
			get_viewport().set_input_as_handled()
			remove_popup()
			return
		elif not menu_stack.is_empty():
			get_viewport().set_input_as_handled()
			_remove_control()
			return
	
	for action in ShortcutUtils.UNIVERSAL_ACTIONS:
		if ShortcutUtils.is_action_pressed(event, action):
			match action:
				"quit": prompt_quit()
				"toggle_fullscreen": toggle_fullscreen()
				"about_info": open_about()
				"about_donate": open_donate()
				"check_updates": open_update_checker()
				"open_settings": open_settings()
				"about_repo": OS.shell_open("https://github.com/MewPurPur/GodSVG")
				"about_website": OS.shell_open("https://godsvg.com")
				"open_externally": FileUtils.open_svg(
						Configs.savedata.get_active_tab().svg_file_path)
				"open_in_folder": FileUtils.open_svg_folder(
						Configs.savedata.get_active_tab().svg_file_path)
			return
	
	# Stop the logic below from running if there's menu overlays.
	if not menu_stack.is_empty():
		return
	
	for action in ShortcutUtils.EFFECT_ACTIONS:
		if ShortcutUtils.is_action_pressed(event, action):
			match action:
				"view_show_grid": State.toggle_show_grid()
				"view_show_handles": State.toggle_show_handles()
				"view_rasterized_svg": State.toggle_view_rasterized()
				"view_show_reference": State.toggle_show_reference()
				"view_overlay_reference": State.toggle_overlay_reference()
				"load_reference": FileUtils.open_image_import_dialog()
				"toggle_snap": Configs.savedata.snap *= -1
	
	if not popup_stack.is_empty():
		return
	
	# Global actions that should happen regardless of the context.
	for action in ShortcutUtils.EDITOR_ACTIONS:
		if ShortcutUtils.is_action_pressed(event, action):
			match action:
				"import": FileUtils.open_svg_import_dialog()
				"export": open_export()
				"save": FileUtils.save_svg()
				"save_as": FileUtils.save_svg_as()
				"close_tab": FileUtils.close_tabs(Configs.savedata.get_active_tab_index())
				"close_all_other_tabs": FileUtils.close_tabs(
						Configs.savedata.get_active_tab_index(),
						FileUtils.TabCloseMode.ALL_OTHERS)
				"close_tabs_to_left": FileUtils.close_tabs(
						Configs.savedata.get_active_tab_index(),
						FileUtils.TabCloseMode.TO_LEFT)
				"close_tabs_to_right": FileUtils.close_tabs(
						Configs.savedata.get_active_tab_index(),
						FileUtils.TabCloseMode.TO_RIGHT)
				"close_empty_tabs": FileUtils.close_tabs(
						Configs.savedata.get_active_tab_index(),
						FileUtils.TabCloseMode.EMPTY)
				"close_saved_tabs": FileUtils.close_tabs(
						Configs.savedata.get_active_tab_index(),
						FileUtils.TabCloseMode.SAVED)
				"new_tab": Configs.savedata.add_empty_tab()
				"select_next_tab": Configs.savedata.set_active_tab_index(
						posmod(Configs.savedata.get_active_tab_index() + 1,
						Configs.savedata.get_tab_count()))
				"select_previous_tab": Configs.savedata.set_active_tab_index(
						posmod(Configs.savedata.get_active_tab_index() - 1,
						Configs.savedata.get_tab_count()))
				"copy_svg_text": DisplayServer.clipboard_set(State.svg_text)
				"optimize": State.optimize()
				"reset_svg": FileUtils.reset_svg()
				"debug": State.toggle_show_debug()
			return
	
	# Stop the logic below from running while GUI dragging is going on.
	if get_viewport().gui_is_dragging():
		return
	
	for action in ShortcutUtils.PRISTINE_ACTIONS:
		if ShortcutUtils.is_action_pressed(event, action):
			match action:
				"ui_undo": Configs.savedata.get_active_tab().undo()
				"ui_redo": Configs.savedata.get_active_tab().redo()
				"ui_cancel": State.clear_all_selections()
				"delete": State.delete_selected()
				"move_up": State.move_up_selected()
				"move_down": State.move_down_selected()
				"duplicate": State.duplicate_selected()
				"select_all": State.select_all()
			return
	
	if ShortcutUtils.is_action_pressed(event, "move_absolute"):
		State.respond_to_key_input("M")
	elif ShortcutUtils.is_action_pressed(event, "move_relative"):
		State.respond_to_key_input("m")
	elif ShortcutUtils.is_action_pressed(event, "line_absolute"):
		State.respond_to_key_input("L")
	elif ShortcutUtils.is_action_pressed(event, "line_relative"):
		State.respond_to_key_input("l")
	elif ShortcutUtils.is_action_pressed(event, "horizontal_line_absolute"):
		State.respond_to_key_input("H")
	elif ShortcutUtils.is_action_pressed(event, "horizontal_line_relative"):
		State.respond_to_key_input("h")
	elif ShortcutUtils.is_action_pressed(event, "vertical_line_absolute"):
		State.respond_to_key_input("V")
	elif ShortcutUtils.is_action_pressed(event, "vertical_line_relative"):
		State.respond_to_key_input("v")
	elif ShortcutUtils.is_action_pressed(event, "close_path_absolute"):
		State.respond_to_key_input("Z")
	elif ShortcutUtils.is_action_pressed(event, "close_path_relative"):
		State.respond_to_key_input("z")
	elif ShortcutUtils.is_action_pressed(event, "elliptical_arc_absolute"):
		State.respond_to_key_input("A")
	elif ShortcutUtils.is_action_pressed(event, "elliptical_arc_relative"):
		State.respond_to_key_input("a")
	elif ShortcutUtils.is_action_pressed(event, "cubic_bezier_absolute"):
		State.respond_to_key_input("C")
	elif ShortcutUtils.is_action_pressed(event, "cubic_bezier_relative"):
		State.respond_to_key_input("c")
	elif ShortcutUtils.is_action_pressed(event, "shorthand_cubic_bezier_absolute"):
		State.respond_to_key_input("S")
	elif ShortcutUtils.is_action_pressed(event, "shorthand_cubic_bezier_relative"):
		State.respond_to_key_input("s")
	elif ShortcutUtils.is_action_pressed(event, "quadratic_bezier_absolute"):
		State.respond_to_key_input("Q")
	elif ShortcutUtils.is_action_pressed(event, "quadratic_bezier_relative"):
		State.respond_to_key_input("q")
	elif ShortcutUtils.is_action_pressed(event, "shorthand_quadratic_bezier_absolute"):
		State.respond_to_key_input("T")
	elif ShortcutUtils.is_action_pressed(event, "shorthand_quadratic_bezier_relative"):
		State.respond_to_key_input("t")


func get_window_default_size() -> Vector2i:
	return Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"))

func get_usable_rect() -> Vector2i:
	var window := get_window()
	return Vector2i(DisplayServer.screen_get_usable_rect(
			DisplayServer.window_get_current_screen()).size -\
			window.get_size_with_decorations() + window.size)

func get_max_ui_scale(usable_screen_size: Vector2i) -> float:
	var window_default_size := get_window_default_size()
	# How much can the default size be increased before it takes all usable screen space.
	var max_expansion := Vector2(usable_screen_size) / Vector2(window_default_size)
	return clampf(snappedf(minf(max_expansion.x, max_expansion.y) - 0.005, 0.01), 0.75, 4.0)

func get_min_ui_scale(usable_screen_size: Vector2i) -> float:
	return maxf(snappedf(get_max_ui_scale(usable_screen_size) / 2.0 - 0.125, 0.25), 0.75)

func get_auto_ui_scale() -> float:
	# Usable rect might not be reliable on web, so attempt to use devicePixelRatio.
	if OS.get_name() == "Web":
		var pixel_ratio: float = JavaScriptBridge.eval("window.devicePixelRatio || 1", true)
		if is_finite(pixel_ratio):
			return snappedf(pixel_ratio, 0.25)
	
	var usable_screen_size := get_usable_rect()
	if usable_screen_size.x == 0 or usable_screen_size.y == 0:
		return 1.0
	
	# The wider the screen, the bigger the automatically chosen UI scale.
	var aspect_ratio := usable_screen_size.aspect()
	var max_ui_scale := get_max_ui_scale(usable_screen_size)
	var auto_scale := max_ui_scale * clampf(aspect_ratio * 0.375, 0.6, 0.8)
	if OS.get_name() == "Android":
		auto_scale *= 1.1  # Default to giving mobile a bit more space.
	return clampf(snappedf(auto_scale, 0.25), get_min_ui_scale(usable_screen_size), max_ui_scale)


func update_ui_scale() -> void:
	var window := get_window()
	if not window.is_node_ready():
		await window.ready
	
	var old_scale_factor := window.content_scale_factor
	var window_default_size := get_window_default_size()
	var usable_screen_size := get_usable_rect()
	var max_scale := get_max_ui_scale(usable_screen_size)
	var min_scale := get_min_ui_scale(usable_screen_size)
	
	var ui_scaling_approach := Configs.savedata.ui_scale
	var final_scale: float
	match ui_scaling_approach:
		SaveData.ScalingApproach.AUTO: final_scale = get_auto_ui_scale()
		SaveData.ScalingApproach.CONSTANT_075: final_scale = 0.75
		SaveData.ScalingApproach.CONSTANT_100: final_scale = 1.0
		SaveData.ScalingApproach.CONSTANT_125: final_scale = 1.25
		SaveData.ScalingApproach.CONSTANT_150: final_scale = 1.50
		SaveData.ScalingApproach.CONSTANT_175: final_scale = 1.75
		SaveData.ScalingApproach.CONSTANT_200: final_scale = 2.0
		SaveData.ScalingApproach.CONSTANT_250: final_scale = 2.5
		SaveData.ScalingApproach.CONSTANT_300: final_scale = 3.0
		SaveData.ScalingApproach.CONSTANT_400: final_scale = 4.0
		SaveData.ScalingApproach.MAX: final_scale = max_scale
	final_scale = clampf(final_scale, min_scale, max_scale)
	
	if not OS.get_name() in ["Android", "Web"]:
		if window.mode == Window.MODE_WINDOWED:
			var resize_factor := final_scale / old_scale_factor
			# The window's minimum size can mess with the size change, so we set it to zero.
			window.min_size = Vector2i.ZERO
			window.size = Vector2i(mini(int(window.size.x * resize_factor),
					usable_screen_size.x), mini(int(window.size.y * resize_factor),
					usable_screen_size.y))
		window.min_size = window_default_size * final_scale
	window.content_scale_factor = final_scale


func prompt_quit() -> void:
	remove_all_menus()
	var confirm_dialog := ConfirmDialogScene.instantiate()
	add_menu(confirm_dialog)
	confirm_dialog.setup(Translator.translate("Quit GodSVG"),
			Translator.translate("Do you want to quit GodSVG?"),
			Translator.translate("Quit"), get_tree().quit)


var was_window_maximized: bool
var window_old_rect: Rect2

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN:
		if DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED:
			was_window_maximized = true
		else:
			was_window_maximized = false
			window_old_rect = Rect2(DisplayServer.window_get_position(),
					DisplayServer.window_get_size())
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	else:
		if was_window_maximized:
			DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(window_old_rect.size)
			# TODO Without at least 3 frames of wait, on my laptop the window would
			# sometimes go a little higher than before after setting its position.
			for i in 3:
				await get_tree().process_frame
			DisplayServer.window_set_position(window_old_rect.position)

func open_update_checker() -> void:
	remove_all_menus()
	var confirmation_dialog := ConfirmDialogScene.instantiate()
	add_menu(confirmation_dialog)
	confirmation_dialog.setup(Translator.translate("Check for updates?"),
			Translator.translate("This will connect to github.com to compare version numbers. No other data is collected or transmitted."),
			Translator.translate("OK"), _list_updates)

func _list_updates() -> void:
	remove_all_menus()
	var update_menu_instance := UpdateMenuScene.instantiate()
	add_menu(update_menu_instance)

func open_settings() -> void:
	remove_all_menus()
	add_menu(SettingsMenuScene.instantiate())

func open_about() -> void:
	remove_all_menus()
	add_menu(AboutMenuScene.instantiate())

func open_donate() -> void:
	remove_all_menus()
	add_menu(DonateMenuScene.instantiate())

func open_export() -> void:
	remove_all_menus()
	var width := State.root_element.width
	var height := State.root_element.height
	
	var dimensions_valid := (is_finite(width) and is_finite(height) and\
			width > 0.0 and height > 0.0)
	var dimensions_too_different := false
	
	if dimensions_valid:
		dimensions_too_different = (1 / minf(width, height) > 16384 / maxf(width, height))
		if not dimensions_too_different:
			add_menu(ExportMenuScene.instantiate())
			return
	
	var message: String
	if dimensions_too_different:
		message = Translator.translate(
				"The graphic can be exported only as SVG because its proportions are too extreme.")
	else:
		message = Translator.translate(
				"The graphic can be exported only as SVG because its size is not defined.")
	message += "\n\n" + Translator.translate("Do you want to proceed?")
	
	var confirm_dialog := ConfirmDialogScene.instantiate()
	add_menu(confirm_dialog)
	var svg_export_data := ImageExportData.new()
	confirm_dialog.setup(Translator.translate("Export SVG"), message,
			Translator.translate("Export"), FileUtils.open_export_dialog.bind(svg_export_data))


func update_window_title() -> void:
	if Configs.savedata.use_filename_for_window_title and\
	not Configs.savedata.get_active_tab().svg_file_path.is_empty():
		get_window().title = Configs.savedata.get_active_tab().presented_name + " - GodSVG"
	else:
		get_window().title = "GodSVG"


# Helpers

# Used to trigger a mouse motion event, which can be used to update some things,
# when Godot doesn't want to do so automatically.
func throw_mouse_motion_event() -> void:
	var mm_event := InputEventMouseMotion.new()
	var window := get_window()
	# Must multiply by the final transform because the InputEvent is not yet parsed.
	var mouse_position = window.get_mouse_position()
	# TODO This is a workaround because the returned mouse position is sometimes (0, 0),
	# likely a Godot issue. This has been reproduced on Android and on Web.
	# Reproducing on web is especially easy with zoom at something like 110% on Web.
	if mouse_position == Vector2.ZERO:
		return
	
	mm_event.position = mouse_position * window.get_final_transform()
	Input.parse_input_event.call_deferred(mm_event)

# Trigger a shortcut automatically.
func throw_action_event(action: String) -> void:
	var events := InputMap.action_get_events(action)
	for event in events:
		if ShortcutUtils.is_shortcut_valid(event, action):
			# Pressed keys.
			var press_key_event := event.duplicate()
			press_key_event.pressed = true
			Input.parse_input_event(press_key_event)
			# Released keys.
			var release_key_event := press_key_event.duplicate()
			release_key_event.pressed = false
			Input.parse_input_event(release_key_event)
			return
	
	# Pressed action.
	var press_action_event := InputEventAction.new()
	press_action_event.action = action
	press_action_event.pressed = true
	Input.parse_input_event.call_deferred(press_action_event)
	# Released action.
	var release_action_event := InputEventAction.new()
	release_action_event.action = action
	Input.parse_input_event.call_deferred(release_action_event)
