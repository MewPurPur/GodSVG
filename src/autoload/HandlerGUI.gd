## An autoload that handles various core UI functions.
extends Node

const AlertDialogScene = preload("res://src/ui_widgets/alert_dialog.tscn")
const ConfirmDialogScene = preload("res://src/ui_widgets/confirm_dialog.tscn")
const SettingsMenuScene = preload("res://src/ui_parts/settings_menu.tscn")
const AboutMenuScene = preload("res://src/ui_parts/about_menu.tscn")
const DonateMenuScene = preload("res://src/ui_parts/donate_menu.tscn")
const UpdateMenuScene = preload("res://src/ui_parts/update_menu.tscn")
const ExportMenuScene = preload("res://src/ui_parts/export_menu.tscn")
const ShortcutPanelScene = preload("res://src/ui_parts/shortcut_panel.tscn")

signal popups_cleared

## A stack of the current menus, dialogs in the foreground, center of the screen, that also darken the background for more focus.
## Menus should be added with add_menu(), which hides previous menus, or add_dialog() which doesn't hide previous menus.
## Menus are removed by being freed, which automatically removes them from the stack.
## This is typically done by tying a cancel button to queue_free, or pressing Esc.
var menu_stack: Array[ColorRect] = []

## A stack of the current popups. They are cleared by pressing Esc, clicking outside, or other ways.
## Popups are always on top of the menu stack, and changes to the menu stack clear all popups.
var popup_stack: Array[Control] = []

## A submenu of the current popup. Doesn't block inputs to the current popup.
## Cleared when pressing Esc. If you click outside both popups, the current popup is cleared too.
## The source is the control that triggered the submenu, hovering elsewhere in the popup clears the submenu.
var popup_submenu: Control
var popup_submenu_source: Control

var shortcut_panel: PanelContainer

## A dictionary for shortcut registrations for each node. If a node is freed, its shortcut registrations are cleared.
## Every time a shortcut is pressed, the list of registrations is walked through to find if there's an appropriate one.
## For a registratition to be appropriate, its behavior must coincide with where the node is relative to the menu/popup stack.
var shortcut_registrations: Dictionary[Node, ShortcutsRegistration] = {}

## A dictionary of focus masters and their focus sequences.
var focus_sequences: Dictionary[Control, Array] = {}


func _enter_tree() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("quit", prompt_quit, ShortcutsRegistration.Behavior.PASS_THROUGH_ALL)
	shortcuts.add_shortcut("toggle_fullscreen", toggle_fullscreen, ShortcutsRegistration.Behavior.PASS_THROUGH_ALL)
	shortcuts.add_shortcut("about_info", open_about, ShortcutsRegistration.Behavior.PASS_THROUGH_ALL)
	shortcuts.add_shortcut("about_donate", open_donate, ShortcutsRegistration.Behavior.PASS_THROUGH_ALL)
	shortcuts.add_shortcut("check_updates", open_update_checker, ShortcutsRegistration.Behavior.PASS_THROUGH_ALL)
	shortcuts.add_shortcut("open_settings", open_settings, ShortcutsRegistration.Behavior.PASS_THROUGH_ALL)
	shortcuts.add_shortcut("about_repo", OS.shell_open.bind("https://github.com/MewPurPur/GodSVG"), ShortcutsRegistration.Behavior.PASS_THROUGH_ALL)
	shortcuts.add_shortcut("about_website", OS.shell_open.bind("https://godsvg.com"), ShortcutsRegistration.Behavior.PASS_THROUGH_ALL)
	shortcuts.add_shortcut("open_externally", func() -> void: FileUtils.open_svg(Configs.savedata.get_active_tab().svg_file_path),
			ShortcutsRegistration.Behavior.PASS_THROUGH_ALL)
	shortcuts.add_shortcut("open_in_folder", func() -> void: FileUtils.open_svg_folder(Configs.savedata.get_active_tab().svg_file_path),
			ShortcutsRegistration.Behavior.PASS_THROUGH_ALL)
	register_shortcuts(self, shortcuts)
	# Connect window signals to appropriate methods.
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

# Handles drag-and-drop of files.
func _on_files_dropped(files: PackedStringArray) -> void:
	if menu_stack.is_empty():
		get_window().grab_focus()
		FileUtils.apply_svgs_from_paths(files)

## Registers the given set of shortcuts to the given node.
func register_shortcuts(node: Node, registrations: ShortcutsRegistration) -> void:
	shortcut_registrations[node] = registrations
	if not node.tree_exiting.is_connected(forget_all_shortcuts):
		node.tree_exiting.connect(forget_all_shortcuts.bind(node))

## Removes all shortcuts registered to a node.
func forget_all_shortcuts(node: Node) -> void:
	shortcut_registrations.erase(node)


## Registers a focus sequence to an owner.
func register_focus_sequence(focus_master: Control, sequence: Array[Control], focus_first_control := false) -> void:
	focus_sequences[focus_master] = sequence
	if not focus_master.tree_exiting.is_connected(forget_focus_sequence):
		focus_master.tree_exiting.connect(forget_focus_sequence.bind(focus_master))
	for control in sequence:
		control.visibility_changed.connect(
			func() -> void:
				if not control.visible and control.has_focus():
					for control2 in sequence:
						if control2.visible:
							control2.grab_focus(true)
							return
		)
	
	if focus_first_control:
		for control in sequence:
			if control.visible:
				control.grab_focus(true)
				return

## Removes all shortcuts registered to a node.
func forget_focus_sequence(focus_master: Control) -> void:
	focus_sequences.erase(focus_master)


## Adds a new menu to menu_stack which hides the previous one.
func add_menu(new_menu: Control) -> void:
	if not menu_stack.is_empty():
		menu_stack.back().hide()
	_add_control(new_menu)

## Adds a new menu to the menu_stack that is overlaid on top of the previous one.
func add_dialog(new_dialog: Control) -> void:
	if not menu_stack.is_empty():
		menu_stack.back().show()
	_add_control(new_dialog)

# Common logic for add_menu() and add_dialog().
func _add_control(new_control: Control) -> void:
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
	
	# TODO Right now, I have to force a drag from a control inside the tree,
	# otherwise the current dragging operation can turn into drag and drop. Wtf Godot?
	overlay_ref.force_drag(0, null)
	get_viewport().gui_cancel_drag()

func _remove_control(overlay_ref: ColorRect = null) -> void:
	# Make sure that when a popup is being replaced, it doesn't close the new one's overlay.
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

## Frees all nodes in the menu_stack, emptying it.
func remove_all_menus() -> void:
	if not menu_stack.is_empty():
		while not menu_stack.is_empty():
			menu_stack.pop_back().queue_free()
		throw_mouse_motion_event()


# The passed popup control may be added to a shadow panel. The shadow panel is
# returned by the method if that's the case. Otherwise, the original panel is returned.
func add_popup(new_popup: Control, add_shadow := true) -> Control:
	var overlay_ref := Control.new()
	overlay_ref.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_ref.gui_input.connect(_parse_popup_overlay_event)
	popup_stack.append(overlay_ref)
	get_tree().root.add_child(overlay_ref)
	
	# TODO Right now, I have to force a drag from a control inside the tree,
	# otherwise the current dragging operation can turn into drag and drop. Wtf Godot?
	overlay_ref.force_drag(0, null)
	get_viewport().gui_cancel_drag()
	
	if add_shadow:
		var shadow_container := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.1)
		sb.shadow_color = Color(0, 0, 0, 0.1)
		sb.shadow_size = 8
		if new_popup is PanelContainer:
			var stylebox_wrapped := new_popup.get_theme_stylebox("panel")
			sb.corner_radius_top_left = stylebox_wrapped.corner_radius_top_left
			sb.corner_radius_bottom_left = stylebox_wrapped.corner_radius_bottom_left
			sb.corner_radius_top_right = stylebox_wrapped.corner_radius_top_right
			sb.corner_radius_bottom_right = stylebox_wrapped.corner_radius_bottom_right
		new_popup.resized.connect(shadow_container.reset_size)
		shadow_container.add_theme_stylebox_override("panel", sb)
		shadow_container.add_child(new_popup)
		overlay_ref.add_child(shadow_container)
		shadow_container.reset_size()
		new_popup.tree_exiting.connect(remove_popup.bind(overlay_ref))
		throw_mouse_motion_event()
		return shadow_container
	else:
		overlay_ref.add_child(new_popup)
		new_popup.reset_size()
		new_popup.tree_exiting.connect(remove_popup.bind(overlay_ref))
		throw_mouse_motion_event()
		return new_popup

func remove_popup(overlay_ref: Control = null) -> void:
	clear_submenu()
	if popup_stack.is_empty():
		return
	
	# Make sure that when a popup is being replaced, it doesn't close the new one's overlay.
	var matching_idx := popup_stack.size() - 1
	if is_instance_valid(overlay_ref):
		while matching_idx >= 0:
			if overlay_ref == popup_stack[matching_idx]:
				break
			matching_idx -= 1
	
	if matching_idx < 0:
		return
	
	overlay_ref = popup_stack.pop_at(matching_idx)
	if is_instance_valid(overlay_ref):
		overlay_ref.queue_free()
	
	if popup_stack.is_empty():
		popups_cleared.emit()
	throw_mouse_motion_event()

func remove_all_popups() -> void:
	if not popup_stack.is_empty():
		while not popup_stack.is_empty():
			popup_stack.pop_back().queue_free()
		popups_cleared.emit()
		throw_mouse_motion_event()


# Should usually be the global rect of a control.
func popup_under_rect(popup: Control, rect: Rect2, vp: Viewport) -> void:
	var top_popup := add_popup(popup)
	var screen_transform := vp.get_screen_transform()
	var screen_h := vp.get_visible_rect().size.y
	var popup_pos := Vector2(rect.position.x, 0)
	# Popup below if there's enough space or we're in the bottom half of the screen.
	if rect.position.y + rect.size.y + top_popup.size.y < screen_h or rect.position.y + rect.size.y / 2 <= screen_h / 2.0:
		popup_pos.y = rect.position.y + rect.size.y
	else:
		popup_pos.y = rect.position.y - top_popup.size.y
	popup_pos += screen_transform.get_origin() / screen_transform.get_scale()
	top_popup.position = popup_clamp_pos(top_popup, popup_pos, vp)

# Should usually be the global rect of a control.
func popup_under_rect_center(popup: Control, rect: Rect2, vp: Viewport) -> void:
	var top_popup := add_popup(popup)
	var screen_transform := vp.get_screen_transform()
	var screen_h := vp.get_visible_rect().size.y
	var popup_pos := Vector2(rect.position.x - top_popup.size.x / 2.0 + rect.size.x / 2, 0)
	# Popup below if there's enough space or we're in the bottom half of the screen.
	if rect.position.y + rect.size.y + top_popup.size.y < screen_h or rect.position.y + rect.size.y / 2 <= screen_h / 2.0:
		popup_pos.y = rect.position.y + rect.size.y
	else:
		popup_pos.y = rect.position.y - top_popup.size.y
	# Align horizontally and other things.
	popup_pos += screen_transform.get_origin() / screen_transform.get_scale()
	top_popup.position = popup_clamp_pos(top_popup, popup_pos, vp)

# Should usually be the global position of the mouse.
func popup_under_pos(popup: Control, pos: Vector2, vp: Viewport) -> void:
	var top_popup := add_popup(popup)
	var screen_transform := vp.get_screen_transform()
	pos += screen_transform.get_origin() / screen_transform.get_scale()
	top_popup.position = popup_clamp_pos(top_popup, pos, vp)

# Should usually be the global rect of a control.
func popup_submenu_to_right_or_left_side(submenu: Control, source: Control) -> void:
	var shadow_container := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.1)
	sb.shadow_color = Color(0, 0, 0, 0.1)
	sb.shadow_size = 8
	if submenu is PanelContainer:
		var stylebox_wrapped := submenu.get_theme_stylebox("panel")
		sb.corner_radius_top_left = stylebox_wrapped.corner_radius_top_left
		sb.corner_radius_bottom_left = stylebox_wrapped.corner_radius_bottom_left
		sb.corner_radius_top_right = stylebox_wrapped.corner_radius_top_right
		sb.corner_radius_bottom_right = stylebox_wrapped.corner_radius_bottom_right
	submenu.resized.connect(shadow_container.reset_size)
	shadow_container.add_theme_stylebox_override("panel", sb)
	shadow_container.add_child(submenu)
	get_tree().root.add_child(shadow_container)
	shadow_container.reset_size()
	submenu.tree_exiting.connect(clear_submenu)
	
	popup_submenu_source = source
	popup_submenu = shadow_container
	
	var vp := source.get_viewport()
	var rect := source.get_global_rect()
	var screen_transform := vp.get_screen_transform()
	var screen_w := vp.get_visible_rect().size.x
	var popup_pos := Vector2(rect.position.x, rect.position.y)
	if rect.position.x + popup_submenu.size.x + popup_submenu.size.x > screen_w:
		popup_pos.x -= popup_submenu.size.x
	else:
		popup_pos.x += rect.size.x
	popup_pos += screen_transform.get_origin() / screen_transform.get_scale()
	popup_submenu.position = popup_clamp_pos(popup_submenu, popup_pos, vp)

func clear_submenu() -> void:
	popup_submenu_source = null
	if is_instance_valid(popup_submenu):
		popup_submenu.queue_free()
	throw_mouse_motion_event()


# Helper.
func popup_clamp_pos(popup: Control, attempt_pos: Vector2, vp: Viewport) -> Vector2:
	var screen_transform := vp.get_screen_transform()
	var vp_pos := screen_transform.get_origin() / screen_transform.get_scale()
	for axis in 2:
		attempt_pos[axis] = clampf(attempt_pos[axis], vp_pos[axis], vp_pos[axis] + vp.get_visible_rect().size[axis] - popup.size[axis])
	return attempt_pos


func _parse_popup_overlay_event(event: InputEvent) -> void:
	if not popup_stack.is_empty():
		if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
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
	
	if not (event is InputEventAction or event is InputEventKey):
		return
	
	var focus_owner := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focus_owner) and not is_node_on_top_menu_or_popup(focus_owner):
		get_viewport().set_input_as_handled()
		_react_to_action(event)
		return
	if not is_instance_valid(focus_owner):
		return
	
	# Intercept focus in favor of our own system.
	if not focus_owner is TextEdit:
		if ShortcutUtils.is_action_pressed(event, "ui_focus_next", true):
			get_viewport().set_input_as_handled()
			if not focus_owner.has_focus(true):
				focus_owner.grab_focus()
			else:
				gather_focus(focus_owner, true).grab_focus()
		elif ShortcutUtils.is_action_pressed(event, "ui_focus_prev", true):
			get_viewport().set_input_as_handled()
			if not focus_owner.has_focus(true):
				focus_owner.grab_focus()
			else:
				gather_focus(focus_owner, false).grab_focus()

func gather_focus(control: Control, is_next: bool) -> Control:
	var new_focus := _gather_focus_internal(control, is_next)
	while not (is_instance_valid(new_focus) and new_focus.is_visible_in_tree() and new_focus.focus_mode == Control.FOCUS_ALL):
		var new_focus_candidate := _gather_focus_internal(new_focus, is_next)
		if not is_instance_valid(new_focus_candidate):
			return control
		new_focus = new_focus_candidate
	return new_focus

func _gather_focus_internal(control: Control, is_next: bool) -> Control:
	for focus_master in focus_sequences:
		var sequence: Array[Control] = focus_sequences[focus_master]
		var control_idx := sequence.find(control)
		if control_idx != -1:
			var new_control_idx := control_idx + (1 if is_next else -1)
			# Get next control in sequence, otherwise go down a level.
			if new_control_idx >= 0 and new_control_idx <= sequence.size() - 1:
				var new_control := sequence[new_control_idx]
				if new_control in focus_sequences:
					var new_sequence: Array[Control] = focus_sequences[new_control]
					if not new_sequence.is_empty():
						return new_sequence[0] if is_next else new_sequence[-1]
				return new_control
			return focus_master
	return null


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventAction or event is InputEventKey):
		return
	_react_to_action(event)

func _react_to_action(event: InputEvent) -> void:
	if ShortcutUtils.is_action_pressed(event, "ui_cancel"):
		if is_instance_valid(popup_submenu):
			get_viewport().set_input_as_handled()
			clear_submenu()
			return
		elif not popup_stack.is_empty():
			get_viewport().set_input_as_handled()
			remove_popup()
			return
		elif not menu_stack.is_empty():
			get_viewport().set_input_as_handled()
			_remove_control()
			return
	
	for behavior in ShortcutsRegistration.BEHAVIOR_PRIORITY:
		for node in shortcut_registrations:
			if node is CanvasItem and not node.visible:
				continue
			
			var registrations := shortcut_registrations[node]
			for idx in registrations.actions.size():
				if registrations.behaviors[idx] != behavior:
					continue
					
				var action := registrations.actions[idx]
				if ShortcutUtils.is_action_pressed(event, action, action in ShortcutUtils.echoable_actions):
					var should_execute := false
					var should_clear_popups := false
					
					match behavior:
						ShortcutsRegistration.Behavior.PASS_THROUGH_ALL:
							should_execute = true
						ShortcutsRegistration.Behavior.PASS_THROUGH_POPUPS:
							if is_node_on_top_menu(node):
								should_execute = true
								should_clear_popups = true
						ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS:
							if is_node_on_top_menu(node):
								should_execute = true
						ShortcutsRegistration.Behavior.NO_PASSTHROUGH:
							if not get_viewport().gui_is_dragging() and is_node_on_top_menu_or_popup(node):
								should_execute = true
					
					if should_execute:
						registrations.activated.emit(action)
						registrations.callbacks[idx].call()
						if should_clear_popups:
							remove_all_popups()
						get_viewport().set_input_as_handled()
						return


func is_node_on_top_menu(node: Node) -> bool:
	return (menu_stack.is_empty() or menu_stack[-1].is_ancestor_of(node))

func is_node_on_top_menu_or_popup(node: Node) -> bool:
	return ((menu_stack.is_empty() and popup_stack.is_empty()) or (popup_stack.is_empty() and\
			menu_stack[-1].is_ancestor_of(node)) or (not popup_stack.is_empty() and not is_instance_valid(popup_submenu) and\
			popup_stack[-1].is_ancestor_of(node)) or (is_instance_valid(popup_submenu) and popup_submenu.is_ancestor_of(node)))


func get_window_default_size() -> Vector2i:
	return Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))

func get_usable_rect() -> Vector2i:
	var window := get_window()
	return Vector2i(DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size - window.get_size_with_decorations() + window.size)

func get_max_ui_scale(usable_screen_size: Vector2i) -> float:
	var window_default_size := get_window_default_size()
	# How much can the default size be increased before it takes all usable screen space.
	var max_expansion := Vector2(usable_screen_size) / Vector2(window_default_size)
	return clampf(snappedf(minf(max_expansion.x, max_expansion.y) - 0.005, 0.01), 0.75, 4.0)

func get_min_ui_scale(usable_screen_size: Vector2i) -> float:
	return maxf(snappedf(get_max_ui_scale(usable_screen_size) / 2.0 - 0.125, 0.25), 0.75)

func get_auto_ui_scale() -> float:
	var usable_screen_size := get_usable_rect()
	if usable_screen_size.x == 0 or usable_screen_size.y == 0:
		return 1.0
	
	var max_ui_scale := get_max_ui_scale(usable_screen_size)
	var min_ui_scale := get_min_ui_scale(usable_screen_size)
	
	# Usable rect might not be reliable on web, so attempt to use devicePixelRatio.
	if OS.get_name() == "Web":
		var pixel_ratio: float = JavaScriptBridge.eval("window.devicePixelRatio || 1", true)
		if is_finite(pixel_ratio):
			return clampf(snappedf(pixel_ratio, 0.25), min_ui_scale, max_ui_scale)
	
	# The wider the screen, the bigger the automatically chosen UI scale.
	var aspect_ratio := usable_screen_size.aspect()
	var auto_scale := max_ui_scale * clampf(aspect_ratio * 0.375, 0.6, 0.8)
	if OS.get_name() == "Android":
		auto_scale *= 1.1  # Default to giving mobile a bit more space.
	return clampf(snappedf(auto_scale, 0.25), min_ui_scale, max_ui_scale)


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
			window.size = Vector2i(mini(int(window.size.x * resize_factor), usable_screen_size.x),
					mini(int(window.size.y * resize_factor), usable_screen_size.y))
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
			window_old_rect = Rect2(DisplayServer.window_get_position(), DisplayServer.window_get_size())
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
	
	var dimensions_valid := (is_finite(width) and is_finite(height) and width > 0.0 and height > 0.0)
	var dimensions_too_different := false
	
	if dimensions_valid:
		dimensions_too_different = (1 / minf(width, height) > 16384 / maxf(width, height))
		if not dimensions_too_different:
			add_menu(ExportMenuScene.instantiate())
			return
	
	var message: String
	if dimensions_too_different:
		message = Translator.translate("The graphic can be exported only as SVG because its proportions are too extreme.")
	else:
		message = Translator.translate("The graphic can be exported only as SVG because its size is not defined.")
	message += "\n\n" + Translator.translate("Do you want to proceed?")
	
	var svg_export_data := ImageExportData.new()
	var confirm_dialog := ConfirmDialogScene.instantiate()
	add_menu(confirm_dialog)
	confirm_dialog.setup(Translator.translate("Export SVG"), message,
			Translator.translate("Export"), FileUtils.open_export_dialog.bind(svg_export_data))


func update_window_title() -> void:
	if Configs.savedata.use_filename_for_window_title and not Configs.savedata.get_active_tab().svg_file_path.is_empty():
		get_window().title = Configs.savedata.get_active_tab().presented_name + " - GodSVG"
	else:
		get_window().title = "GodSVG"


# Helpers

## Triggers a mouse motion event, which can update hover or mouse shape if Godot didn't do it automatically.
func throw_mouse_motion_event() -> void:
	var mm_event := InputEventMouseMotion.new()
	var window := get_window()
	# Must multiply by the final transform because the InputEvent is not yet parsed.
	var mouse_position := window.get_mouse_position()
	# TODO This is a workaround because the returned mouse position is sometimes (0, 0),
	# likely a Godot issue. This has been reproduced on Android and on Web.
	# Reproducing on web is especially easy with zoom at something like 110%.
	if mouse_position == Vector2.ZERO:
		return
	
	mm_event.position = mouse_position * window.get_final_transform()
	Input.parse_input_event.call_deferred(mm_event)

## Triggers a shortcut.
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
