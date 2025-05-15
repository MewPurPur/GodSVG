# This class adds support for copying images. Currently not supported by Godot.
class_name ClipboardUtils extends RefCounted

## Returns true if this clipboard util is supported on the current platform.
static func is_supported(format: String) -> bool:
	if OS.get_name() == "Web" and format not in ["png", "svg"]:
		return false  # Copying most image formats is not currently supported on web.
	return OS.get_name() in ["Windows", "Linux", "Web"] or "BSD" in OS.get_name()
	
## Returns an object containing the error information, as well as an "OK" type.
static func copy_image(export_data: ImageExportData) -> ClipboardError:
	if not is_supported(export_data.format):
		return ClipboardError.new(ErrorType.UnsupportedPlatform)
	if export_data.format == "svg":
		DisplayServer.clipboard_set(State.get_export_text())
		return ClipboardError.new(ErrorType.Ok)
	var mime_type := ImageExportData.image_types_dict[export_data.format]
	match OS.get_name():
		"Windows":
			_save_temp_to_disk(export_data)
			var e := OS.execute("powershell.exe", ["-Command", """
					Add-Type -AssemblyName System.Windows.Forms;
					$bmp = New-Object Drawing.Bitmap('%s');
					[Windows.Forms.Clipboard]::SetImage($bmp)
				""" % _get_temp_path(export_data)
			])
			_clean_temp(export_data)
			return ClipboardError.new(ErrorType.FailedExecuting if e < 0 else ErrorType.Ok)
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			# Finding out the display manager type.
			var display_manager_arr := []
			OS.execute("echo", ["$XDG_SESSION_TYPE"], display_manager_arr)
			var using_x11 := "x11" in "".join(display_manager_arr)
			
			# System clipboard utils.
			const x11_utils := ["xclip"]
			const wayland_utils := ["xclip", "wl-copy"]
			var usable_utils := (x11_utils if using_x11 else wayland_utils)
			
			# Finding out what system util is available.
			var chosen_util := ""
			for util in usable_utils:
				if OS.execute("which", [util]) == 0:
					chosen_util = util
					break
			
			# Copying the texture to the clipboard.
			if chosen_util != "":
				var exit_code := -2
				_save_temp_to_disk(export_data)
				match chosen_util:
					"xclip":
						exit_code = OS.execute("xclip", ["-selection", "clipboard", "-l", "1", "-quiet", "-t", mime_type, "-i", _get_temp_path(export_data)])
					"wl-copy":
						var cmd := "wl-copy -f -t %s < '%s'" % [mime_type, _get_temp_path(export_data)]
						exit_code = OS.execute("bash", ["-c", cmd])
				_clean_temp(export_data)
				if exit_code != 0:
					return ClipboardError.new(ErrorType.FailedExecuting, chosen_util + " " + str(exit_code))
				else:
					return ClipboardError.new(ErrorType.Ok)
			else:
				return ClipboardError.new(ErrorType.NoClipboardUtil, ", ".join(usable_utils))
		"macOS":
			#_save_temp_to_disk(export_data)
			#var picture_type := export_data.format.to_upper()
			#var e := OS.execute("osascript", ["-e", "set the clipboard to (read (POSIX file \"%s\") as %s picture)" % [_get_temp_path(export_data), picture_type]])
			#_clean_temp(export_data)
			#return ClipboardError.new(ErrorType.FailedExecuting if e == -1 else ErrorType.Ok, "osascript")
			return ClipboardError.new(ErrorType.UnsupportedPlatform)
		"Android":
			# TODO: Implement "copy to clipboard" util for Android.
			return ClipboardError.new(ErrorType.UnsupportedPlatform)
		"Web":
			JavaScriptBridge.eval("""
				window.copyImageToClipboard = (data, mimeType) => {
					const blob = new Blob([data], { "type": mimeType });
					console.log(mimeType);
					navigator.clipboard.write([new ClipboardItem({ [mimeType]: blob })]);
				}
			""")
			
			var image_buf := export_data.image_to_buffer(export_data.generate_image())
			var buf = JavaScriptBridge.create_object("ArrayBuffer", image_buf.size())
			var data = JavaScriptBridge.create_object("Uint8Array", buf)
			for i in len(image_buf):
				data[i] = image_buf[i]
			JavaScriptBridge.get_interface("window").window.copyImageToClipboard(data, mime_type)
			return ClipboardError.new(ErrorType.Ok)
		_:
			return ClipboardError.new(ErrorType.UnsupportedPlatform)

static func _save_temp_to_disk(export_data: ImageExportData) -> void:
	var image_buf := export_data.image_to_buffer(export_data.generate_image())
	var file := FileAccess.open(_get_temp_path(export_data), FileAccess.WRITE)
	file.store_buffer(image_buf)
	file.close()

static func _clean_temp(export_data: ImageExportData) -> void:
	pass#DirAccess.remove_absolute(_get_temp_path(export_data))

static func _get_temp_path(export_data: ImageExportData) -> String:
	return OS.get_temp_dir().path_join("godsvg_tmp_clipboard." + export_data.format)

enum ErrorType {
	Ok,
	Unknown,
	UnsupportedPlatform,
	FailedExecuting,
	NoClipboardUtil
}

class ClipboardError:
	var type: ErrorType
	var extra: String
	var message: String
	func _init(_type: ErrorType, _extra: String = "") -> void:
		type = _type
		extra = _extra
		match type:
			ErrorType.FailedExecuting:
				message = tr("Failed executing '%s'" % extra)
			ErrorType.NoClipboardUtil:
				message = tr("Failed to find a clipboard util. Make sure you've installed one of the following:\n%s" % extra)
			ErrorType.UnsupportedPlatform:
				message = tr("Unsupported platform")
			_:
				message = tr("Unknown error")
