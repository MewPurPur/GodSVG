extends Node

signal _in_focus

const ImportWarningDialog = preload("res://src/ui_parts/import_warning_dialog.tscn")
const AlertDialog = preload("res://src/ui_parts/alert_dialog.tscn")
const ConfirmDialog = preload("res://src/ui_parts/confirm_dialog.tscn")
const SettingsMenu = preload("res://src/ui_parts/settings_menu.tscn")
const AboutMenu = preload("res://src/ui_parts/about_menu.tscn")
const DonateMenu = preload("res://src/ui_parts/donate_menu.tscn")
const UpdateMenu = preload("res://src/ui_parts/update_menu.tscn")

var overlay_stack: Array[ColorRect]
var popup_overlay_stack: Array[Control]


func _enter_tree() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	get_tree().root.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	get_window().files_dropped.connect(_on_files_dropped)
	get_window().dpi_changed.connect(update_ui_scale)
	get_window().size_changed.connect(remove_all_popup_overlays)
	if OS.has_feature("web"):
		_define_web_js()

func _ready() -> void:
	GlobalSettings.ui_scale_changed.connect(update_ui_scale)
	await get_tree().process_frame
	update_ui_scale()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_in_focus.emit()
	elif what == NOTIFICATION_WM_ABOUT:
		open_about()

# Drag-and-drop of files.
func _on_files_dropped(files: PackedStringArray) -> void:
	if overlay_stack.is_empty():
		FileUtils.apply_svg_from_path(files[0])


func add_overlay(overlay_menu: Control) -> void:
	# FIXME subpar workaround to drag & drop not able to be cancelled manually.
	get_tree().root.propagate_notification(NOTIFICATION_DRAG_END)
	
	remove_all_popup_overlays()
	
	if not overlay_stack.is_empty():
		overlay_stack.back().hide()
	
	var overlay_ref = ColorRect.new()
	overlay_ref.color = Color(0, 0, 0, 0.4)
	overlay_ref.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_ref.process_mode = PROCESS_MODE_ALWAYS
	overlay_stack.append(overlay_ref)
	get_tree().get_root().add_child(overlay_ref)
	overlay_ref.add_child(overlay_menu)
	overlay_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay_menu.tree_exiting.connect(remove_overlay.bind(overlay_ref))
	get_tree().paused = true

func remove_overlay(overlay_ref: ColorRect = null) -> void:
	if overlay_stack.is_empty():
		return
	# If an overlay_ref is passed but doesn't match, do nothing.
	# This is a hack against exiting overlay menus closing other menus than their own.
	if is_instance_valid(overlay_ref) and overlay_ref != overlay_stack.back():
		return
	
	overlay_ref = overlay_stack.pop_back()
	if is_instance_valid(overlay_ref):
		overlay_ref.queue_free()
	if overlay_stack.is_empty():
		get_tree().paused = false
	else:
		overlay_stack.back().show()

func remove_all_overlays() -> void:
	while not overlay_stack.is_empty():
		remove_overlay()


func add_popup_overlay(popup: Control) -> void:
	var overlay_ref := Control.new()
	overlay_ref.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_ref.gui_input.connect(_parse_popup_overlay_event)
	overlay_ref.process_mode = PROCESS_MODE_ALWAYS
	popup_overlay_stack.append(overlay_ref)
	get_tree().get_root().add_child(overlay_ref)
	overlay_ref.add_child(popup)
	popup.reset_size()
	popup.tree_exiting.connect(remove_popup_overlay.bind(overlay_ref))

func remove_popup_overlay(overlay_ref: Control = null) -> void:
	if popup_overlay_stack.is_empty():
		return
	# Refer to remove_overlay() for why the logic is like this.
	if is_instance_valid(overlay_ref) and overlay_ref != popup_overlay_stack.back():
		return
	
	overlay_ref = popup_overlay_stack.pop_back()
	if is_instance_valid(overlay_ref):
		overlay_ref.queue_free()

func remove_all_popup_overlays() -> void:
	while not popup_overlay_stack.is_empty():
		remove_popup_overlay()


# Should usually be the global rect of a control.
func popup_under_rect(popup: Control, rect: Rect2, vp: Viewport) -> void:
	add_popup_overlay(popup)
	var screen_transform := vp.get_screen_transform()
	var screen_h := vp.get_visible_rect().size.y / screen_transform.get_scale().y
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
	add_popup_overlay(popup)
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
	add_popup_overlay(popup)
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
	if not popup_overlay_stack.is_empty():
		if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT,
		MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			remove_popup_overlay()
	get_viewport().set_input_as_handled()

var last_mouse_click_double := false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		var confirm_dialog := ConfirmDialog.instantiate()
		add_overlay(confirm_dialog)
		confirm_dialog.setup(TranslationServer.translate("Quit GodSVG"),
				TranslationServer.translate("Do you want to quit GodSVG?"),
				TranslationServer.translate("Quit"), get_tree().quit)
	
	# Clear popups or overlays.
	if not popup_overlay_stack.is_empty() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		remove_popup_overlay()
		return
	elif not overlay_stack.is_empty() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		remove_overlay()
		return
	
	# So, it turns out that when you double click, only the press will count as such.
	# I don't like that, and it causes problems! So mark the release as double_click too.
	# TODO Godot PR #92582 fixes this.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			last_mouse_click_double = true
		elif last_mouse_click_double and event.is_released():
			event.double_click = true
			last_mouse_click_double = false
	
	# Stuff that should replace the existing overlays.
	for action in ["about_info", "about_donate", "check_updates", "open_settings"]:
		if event.is_action_pressed(action):
			remove_all_overlays()
			get_viewport().set_input_as_handled()
			ShortcutUtils.fn_call(action)
			return
	
	# Stuff that links externally.
	for action in ["about_repo", "about_website"]:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			ShortcutUtils.fn_call(action)
			return
	
	# Stop the logic below from running if there's overlays.
	if not popup_overlay_stack.is_empty() or not overlay_stack.is_empty():
		return
	
	# Global actions that should happen regardless of the context.
	for action in ["import", "export", "save", "copy_svg_text", "clear_svg", "optimize",
	"clear_file_path", "reset_svg"]:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			ShortcutUtils.fn_call(action)

func _unhandled_input(event: InputEvent) -> void:
	if not popup_overlay_stack.is_empty() or not overlay_stack.is_empty() or\
	get_viewport().gui_is_dragging():
		return
	
	for action in ["redo", "undo", "ui_cancel", "delete", "move_up", "move_down",
	"duplicate", "select_all"]:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			ShortcutUtils.fn_call(action)
			return
	if event is InputEventKey:
		Indications.respond_to_key_input(event)


func update_ui_scale() -> void:
	var window := get_window()
	if not window.is_node_ready():
		await window.ready
	
	# Get window size without the decorations.
	var usable_screen_size := Vector2(DisplayServer.screen_get_usable_rect(
			DisplayServer.window_get_current_screen()).size -\
			window.get_size_with_decorations() + window.size)
	
	# How much can window content size be multiplied by before it extends over the usable screen size.
	var diff := usable_screen_size / window.get_contents_minimum_size()
	var max_scale := floorf(minf(diff.x, diff.y) * 4.0) / 4.0
	var desired_scale: float = GlobalSettings.ui_scale * _calculate_auto_scale()
	
	if not desired_scale > max_scale:
		window.min_size = window.get_contents_minimum_size() * desired_scale
		window.content_scale_factor = desired_scale
	else:
		window.min_size = usable_screen_size
		window.content_scale_factor = max_scale


func open_update_checker() -> void:
	var confirmation_dialog := ConfirmDialog.instantiate()
	add_overlay(confirmation_dialog)
	confirmation_dialog.setup(TranslationServer.translate("Check for updates?"),
			TranslationServer.translate("This requires GodSVG to connect to the internet."),
			TranslationServer.translate("OK"), _list_updates)

func _list_updates() -> void:
	remove_all_overlays()
	var update_menu_instance := UpdateMenu.instantiate()
	add_overlay(update_menu_instance)

func open_settings() -> void:
	add_overlay(SettingsMenu.instantiate())

func open_about() -> void:
	add_overlay(AboutMenu.instantiate())

func open_donate() -> void:
	add_overlay(DonateMenu.instantiate())


func _calculate_auto_scale() -> float:
	if not GlobalSettings.auto_ui_scale:
		return 1.0
	
	# Credit: Godots (MIT, by MakovWait and contributors)
	
	var screen := DisplayServer.window_get_current_screen()
	if DisplayServer.screen_get_size(screen) == Vector2i():
		return 1.0
	
	# Use the smallest dimension to use a correct display scale on portrait displays.
	var smallest_dimension := mini(
		DisplayServer.screen_get_size(screen).x,
		DisplayServer.screen_get_size(screen).y
	)
	
	var dpi :=  DisplayServer.screen_get_dpi(screen)
	if dpi != 72:
		if dpi < 72:
			return 0.75
		elif dpi <= 96:
			return 1.0
		elif dpi <= 120:
			return 1.25
		elif dpi <= 160:
			return 1.5
		elif dpi <= 200:
			return 2.0
		elif dpi <= 240:
			return 2.5
		elif dpi <= 320:
			return 3.0
		elif dpi <= 480:
			return 4.0
		else:  # dpi > 480
			return 5.0
	elif smallest_dimension >= 1700:
		# Likely a hiDPI display, but we aren't certain due to the returned DPI.
		# Use an intermediate scale to handle this situation.
		return 1.5
	return 1.0


# Web file access code credit (Modified):
# https://github.com/Pukkah/HTML5-File-Exchange-for-Godot
# https://github.com/Orama-Interactive/Pixelorama/blob/master/src/Autoload/HTML5FileExchange.gd

func web_load_svg() -> void:
	JavaScriptBridge.eval("upload_svg();", true)  # Open file dialog.
	await _in_focus  # Wait until dialog closed.
	await get_tree().create_timer(1.5).timeout  # Give some time for async JS data load.
	if JavaScriptBridge.eval("canceled;", true):
		return
	var file_data: Variant
	while true:
		file_data = JavaScriptBridge.eval("fileData;", true)
		if file_data != null:
			break
		await get_tree().create_timer(0.5).timeout
	
	var file_name: String = JavaScriptBridge.eval("fileName;", true)
	var extension := file_name.get_extension()
	if extension == "svg":
		var warning_panel := ImportWarningDialog.instantiate()
		warning_panel.imported.connect(FileUtils.web_import.bind(file_data, file_name))
		warning_panel.set_svg(file_data)
		HandlerGUI.add_overlay(warning_panel)
	else:
		var alert_dialog := AlertDialog.instantiate()
		HandlerGUI.add_overlay(alert_dialog)
		if extension.is_empty():
			alert_dialog.setup(TranslationServer.translate(
					"The file extension is empty. Only \"svg\" files are supported."))
		else:
			alert_dialog.setup(TranslationServer.translate(
					"\"{passed_extension}\" is a unsupported file extension. Only \"svg\" files are supported.").format({"passed_extension": extension}))


const web_glue = """var fileData;
var fileName;
var canceled;
var input = document.createElement('INPUT');
input.setAttribute("type", "file");
input.setAttribute("accept", ".svg");
input.addEventListener('change', event => {
	if (event.target.files.length == 0) {
		return;
	}
	canceled = false;
	var file = event.target.files[0];
	var reader = new FileReader();
	fileName = file.name;
	reader.readAsText(file);
	reader.onloadend = function(evt) {
		if (evt.target.readyState == FileReader.DONE) {
			fileData = evt.target.result;
		}
	}
});

function upload_svg() {
	canceled = true;
	input.click();
};
"""

func _define_web_js() -> void:
	JavaScriptBridge.eval(web_glue, true)
