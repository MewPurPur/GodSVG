extends Node
# Credit: 
# https://github.com/Pukkah/HTML5-File-Exchange-for-Godot
# https://github.com/Orama-Interactive/Pixelorama/blob/master/src/Autoload/HTML5FileExchange.gd


signal _in_focus
const ImportWarningDialog = preload("res://src/ui_parts/import_warning_dialog.tscn")


func _ready() -> void:
	if OS.has_feature("web"):
		_define_js()
	else:
		process_mode = PROCESS_MODE_DISABLED


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_in_focus.emit()


func _define_js() -> void:
	JavaScriptBridge.eval("""
var fileData;
var fileName;
var canceled;
function upload_svg() {
	canceled = true;
	var input = document.createElement('INPUT');
	input.setAttribute("type", "file");
	input.setAttribute("accept", ".svg");
	input.click();
	input.addEventListener('change', event => {
		if (event.target.files.length > 0){
			canceled = false;}
		var file = event.target.files[0];
		var reader = new FileReader();
		fileName = file.name;
		reader.readAsText(file);
		reader.onloadend = function (evt) {
			if (evt.target.readyState == FileReader.DONE) {
				fileData = evt.target.result;
			}
		}
	});
}
	""", true
	)


func load_svg() -> void:
	JavaScriptBridge.eval("upload_svg();", true)  # Open file dialog.
	await _in_focus  # Wait until dialog closed
	await get_tree().create_timer(1.0).timeout  # Give some time for async JS data load.
	if JavaScriptBridge.eval("canceled;", true):
		return
	var file_data
	while true:
		file_data = JavaScriptBridge.eval("fileData;", true)
		if file_data != null:
			break
		await get_tree().create_timer(0.5).timeout
	
	var file_name: String = JavaScriptBridge.eval("fileName;", true)
	if file_name.get_extension() == "svg":
		var warning_panel := ImportWarningDialog.instantiate()
		warning_panel.imported.connect(_import.bind(file_data, file_name))
		warning_panel.set_svg(file_data)
		HandlerGUI.add_overlay(warning_panel)


func _import(svg_text: String, file_name: String):
	SVG.apply_svg_text(svg_text)
	GlobalSettings.modify_save_data(&"current_file_path", file_name)
	JavaScriptBridge.eval("fileData = null;", true)


func save_svg() -> void:
	JavaScriptBridge.download_buffer(
		SVG.text.to_utf8_buffer(),
		GlobalSettings.save_data.current_file_path
	)


func save_png(img: Image) -> void:
	JavaScriptBridge.download_buffer(
		img.save_png_to_buffer(),
		Utils.get_file_name(GlobalSettings.save_data.current_file_path) + ".png"
	)
