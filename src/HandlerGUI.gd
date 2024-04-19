extends Node

signal _in_focus

const ImportWarningDialog = preload("res://src/ui_parts/import_warning_dialog.tscn")
const AlertDialog = preload("res://src/ui_parts/alert_dialog.tscn")

var overlay_stack: Array[ColorRect]
var popup_overlay_stack: Array[Control]


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().wrap_controls = true  # Prevents the main window from getting too small.
	get_window().files_dropped.connect(_on_files_dropped)

func _ready() -> void:
	if OS.has_feature("web"):
		_define_web_js()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_in_focus.emit()
		Utils.CustomNotification.DISPLAY_SCALE_CHANGED:
			GlobalSettings.setup_display_scale()

# Drag-and-drop of files.
func _on_files_dropped(files: PackedStringArray) -> void:
	if overlay_stack.is_empty():
		SVG.apply_svg_from_path(files[0])


func add_overlay(overlay_menu: Control) -> void:
	while not popup_overlay_stack.is_empty():
		remove_popup_overlay()
	
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
	if overlay_ref != null and overlay_ref != overlay_stack.back():
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
	if overlay_ref != null and overlay_ref != popup_overlay_stack.back():
		return
	
	overlay_ref = popup_overlay_stack.pop_back()
	if is_instance_valid(overlay_ref):
		overlay_ref.queue_free()


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
	# So, it turns out that when you double click, only the press will count as such.
	# I don't like that, and it causes problems! So mark the release as double_click too.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			last_mouse_click_double = true
		elif last_mouse_click_double and event.is_released():
			event.double_click = true
			last_mouse_click_double = false
	
	if not overlay_stack.is_empty():
		return
	
	if event.is_action_pressed("save"):
		get_viewport().set_input_as_handled()
		SVG.open_save_dialog("svg", SVG.native_file_save, SVG.save_svg_to_file)

func _unhandled_input(event: InputEvent) -> void:
	# Clear popups or overlays.
	if event.is_action_pressed("ui_cancel"):
		if not popup_overlay_stack.is_empty():
			get_viewport().set_input_as_handled()
			remove_popup_overlay()
		elif not overlay_stack.is_empty():
			get_viewport().set_input_as_handled()
			remove_overlay()
	
	if event.is_action_pressed("redo"):
		get_viewport().set_input_as_handled()
		SVG.redo()
	elif event.is_action_pressed("undo"):
		get_viewport().set_input_as_handled()
		SVG.undo()
	
	if get_viewport().gui_is_dragging():
		return
	
	if event.is_action_pressed("ui_cancel"):
		Indications.clear_all_selections()
	elif event.is_action_pressed("delete"):
		Indications.delete_selected()
	elif event.is_action_pressed("move_up"):
		Indications.move_up_selected()
	elif event.is_action_pressed("move_down"):
		Indications.move_down_selected()
	elif event.is_action_pressed("duplicate"):
		Indications.duplicate_selected()
	elif event.is_action_pressed("select_all"):
		Indications.select_all()
	elif event is InputEventKey:
		Indications.respond_to_key_input(event)


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
		warning_panel.imported.connect(_import.bind(file_data, file_name))
		warning_panel.set_svg(file_data)
		HandlerGUI.add_overlay(warning_panel)
	else:
		var error := ""
		if extension.is_empty():
			error = "The file extension is empty. Only \"svg\" files are supported."
		else:
			error = tr("\"{passed_extension}\" is a unsupported file extension. Only \"svg\" files are supported.").format({"passed_extension": extension})
		var alert_dialog := AlertDialog.instantiate()
		HandlerGUI.add_overlay(alert_dialog)
		alert_dialog.setup(error, tr("Alert!"), 280.0)


func _import(svg_text: String, file_name: String) -> void:
	SVG.apply_svg_text(svg_text)
	GlobalSettings.modify_save_data("current_file_path", file_name)
	JavaScriptBridge.eval("fileData = undefined;", true)


func web_save_svg() -> void:
	JavaScriptBridge.download_buffer(SVG.text.to_utf8_buffer(),
			GlobalSettings.save_data.current_file_path.get_file())

func web_save_png(img: Image) -> void:
	JavaScriptBridge.download_buffer(img.save_png_to_buffer(),
			Utils.get_file_name(GlobalSettings.save_data.current_file_path) + ".png")


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
