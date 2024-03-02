extends Node

signal _in_focus

const ImportWarningDialog := preload("res://src/ui_parts/import_warning_dialog.tscn")
const AlertDialog := preload("res://src/ui_parts/alert_dialog.tscn")

var has_overlay := false
var overlay_ref: ColorRect


func _ready() -> void:
	get_window().files_dropped.connect(_on_files_dropped)
	if OS.has_feature("web"):
		_define_web_js()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_in_focus.emit()


func _on_files_dropped(files: PackedStringArray) -> void:
	if not has_overlay:
		SVG.apply_svg_from_path(files[0])


func add_overlay(overlay_menu: Node) -> void:
	# A bit hacky, but I couldn't find out a better way at the time.
	# I'm sure there is a better way of doing things though.
	if has_overlay:
		for child in overlay_ref.get_children():
			child.tree_exiting.disconnect(remove_overlay)
			child.queue_free()
		if overlay_menu is Control:
			overlay_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		overlay_ref.add_child(overlay_menu)
		overlay_menu.tree_exiting.connect(remove_overlay)
	else:
		overlay_ref = ColorRect.new()
		overlay_ref.color = Color(0, 0, 0, 0.4)
		get_tree().get_root().add_child(overlay_ref)
		overlay_ref.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if overlay_menu is Control:
			overlay_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		overlay_ref.add_child(overlay_menu)
		overlay_menu.tree_exiting.connect(remove_overlay)
		has_overlay = true
		overlay_ref.process_mode = PROCESS_MODE_ALWAYS
		get_tree().paused = true


func remove_overlay() -> void:
	overlay_ref.queue_free()
	has_overlay = false
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"import"):
		get_viewport().set_input_as_handled()
		SVG.open_import_dialog()
	elif event.is_action_pressed(&"export"):
		get_viewport().set_input_as_handled()
		SVG.open_export_dialog()
	elif event.is_action_pressed(&"save"):
		get_viewport().set_input_as_handled()
		SVG.open_save_dialog("svg", SVG.native_file_save, SVG.save_svg_to_file)


func _unhandled_input(event) -> void:
	if event.is_action_pressed(&"redo"):
		get_viewport().set_input_as_handled()
		SVG.redo()
	elif event.is_action_pressed(&"undo"):
		get_viewport().set_input_as_handled()
		SVG.undo()
	
	if get_viewport().gui_is_dragging():
		return
	
	if event.is_action_pressed(&"ui_cancel"):
		Indications.clear_all_selections()
	elif event.is_action_pressed(&"delete"):
		Indications.delete_selected()
	elif event.is_action_pressed(&"move_up"):
		Indications.move_up_selected()
	elif event.is_action_pressed(&"move_down"):
		Indications.move_down_selected()
	elif event.is_action_pressed(&"duplicate"):
		Indications.duplicate_selected()
	elif event.is_action_pressed(&"select_all"):
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
	var file_data
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
			
			error = tr(
				&"\"{passed_extension}\" is a unsupported file extension. Only \"svg\" files are supported.").format({"passed_extension": extension})
		var alert_dialog := AlertDialog.instantiate()
		HandlerGUI.add_overlay(alert_dialog)
		alert_dialog.setup(error, "Alert!", 280.0)


func _import(svg_text: String, file_name: String):
	SVG.apply_svg_text(svg_text)
	GlobalSettings.modify_save_data(&"current_file_path", file_name)
	JavaScriptBridge.eval("fileData = undefined;", true)


func web_save_svg() -> void:
	JavaScriptBridge.download_buffer(
		SVG.text.to_utf8_buffer(),
		GlobalSettings.save_data.current_file_path.get_file()
	)


func web_save_png(img: Image) -> void:
	JavaScriptBridge.download_buffer(
		img.save_png_to_buffer(),
		Utils.get_file_name(GlobalSettings.save_data.current_file_path) + ".png"
	)


func _define_web_js() -> void:
	JavaScriptBridge.eval("""
var fileData;
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
	""", true
	)
