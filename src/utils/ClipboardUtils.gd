# This class adds support for copying images. Currently not supported by Godot.
@abstract class_name ClipboardUtils

## Returns true if this clipboard util is supported on the current platform.
static func is_supported(format: String) -> bool:
	if OS.get_name() == "Web" and format not in ["png", "svg"]:
		return false  # Copying most image formats is not currently supported on web.
	return OS.get_name() in ["Windows", "Linux", "Web"] or "BSD" in OS.get_name()
	
## Returns an object containing the error information, as well as an "OK" type.
static func copy_image(export_data: ImageExportData) -> ClipboardError:
	if not is_supported(export_data.format):
		return ClipboardError.new(ErrorType.UnsupportedPlatform, [])
	if export_data.format == "svg":
		DisplayServer.clipboard_set(State.get_export_text())
		return ClipboardError.new(ErrorType.Ok, [])
	var mime_type := ImageExportData.image_types_dict[export_data.format]
	var cmd_output := []
	match OS.get_name():
		"Windows":
			var temp_path := _save_temp_to_disk(export_data)
			var ps_script := ""
			if export_data.format == "webp":
				ps_script = """
					Add-Type -AssemblyName PresentationCore
					$uri = [Uri]'file:///%s'
					$img = [System.Windows.Media.Imaging.BitmapFrame]::Create($uri)
					[System.Windows.Clipboard]::SetImage($img)
				""" % temp_path.replace('\\', '/')
			else:  # PresentationCore does not appear to support transparency.
				ps_script = """
					Add-Type -AssemblyName System.Windows.Forms;
					$bmp = New-Object Drawing.Bitmap('%s');
					[Windows.Forms.Clipboard]::SetImage($bmp)
				""" % temp_path.replace('\\', '/')
			var e := OS.execute("powershell.exe", ["-Command", ps_script], cmd_output, true)
			_clean_temp(temp_path)
			return ClipboardError.new(ErrorType.FailedExecuting if e < 0 else ErrorType.Ok, cmd_output)
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			# Finding out the display manager type.
			var display_manager_arr := []
			OS.execute("echo", ["$XDG_SESSION_TYPE"], display_manager_arr)
			var using_x11 := "x11" in "".join(display_manager_arr)
			
			# System clipboard utils.
			const x11_utils := ["xclip"]
			const wayland_utils := ["xclip", "wl-copy"]
			var usable_utils := (x11_utils if using_x11 else wayland_utils)
			
			# Trying every available clipboard util
			var cmd := []
			var exit_code := -99
			var temp_path := _save_temp_to_disk(export_data)
			for util in usable_utils:
				if OS.execute("which", [util]) == 0:
					match util:
						"xclip":
							cmd = ["xclip", "-selection", "clipboard", "-l", "1", "-quiet", "-t", mime_type, "-i", temp_path]
							exit_code = OS.execute(cmd[0], cmd.slice(1, len(cmd)-1), cmd_output, true)
						"wl-copy":
							var dict := OS.execute_with_pipe("wl-copy", ["-t", mime_type], false)
							if dict.is_empty():
								return ClipboardError.new(ErrorType.FailedExecuting, cmd_output, " ".join(cmd))
							var stdio: FileAccess = dict.stdio
							stdio.store_buffer(export_data.image_to_buffer(export_data.generate_image()))
							stdio.close()
							while OS.is_process_running(dict.pid):
								OS.delay_msec(10)
							exit_code = OS.get_process_exit_code(dict.pid)
					if exit_code == 0:
						_clean_temp(temp_path)
						return ClipboardError.new(ErrorType.Ok, cmd_output)
			_clean_temp(temp_path)
			if exit_code == -99:
				return ClipboardError.new(ErrorType.NoClipboardUtil, cmd_output, ", ".join(usable_utils))
			else:
				return ClipboardError.new(ErrorType.FailedExecuting, cmd_output, " ".join(cmd))
		"macOS":
			#_save_temp_to_disk(export_data)
			#var picture_type := export_data.format.to_upper()
			#var e := OS.execute("osascript", ["-e", "set the clipboard to (read (POSIX file \"%s\") as %s picture)" % [_get_temp_path(export_data), picture_type]], cmd_output, true)
			#_clean_temp(export_data)
			#return ClipboardError.new(ErrorType.FailedExecuting if e == -1 else ErrorType.Ok, cmd_output, "osascript")
			return ClipboardError.new(ErrorType.UnsupportedPlatform, cmd_output)
		"Android":
			# TODO: Implement "copy to clipboard" util for Android.
			return ClipboardError.new(ErrorType.UnsupportedPlatform, cmd_output)
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
			return ClipboardError.new(ErrorType.Ok, cmd_output)
		_:
			return ClipboardError.new(ErrorType.UnsupportedPlatform, cmd_output)

static func _save_temp_to_disk(export_data: ImageExportData) -> String:
	var image_buf := export_data.image_to_buffer(export_data.generate_image())
	var file := FileAccess.create_temp(FileAccess.ModeFlags.WRITE, "export", export_data.format, true)
	file.store_buffer(image_buf)
	file.close()
	return file.get_path_absolute()

static func _clean_temp(temp_path: String) -> void:
	DirAccess.remove_absolute(temp_path)

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
	var command_output: PackedStringArray
	var message: String
	func _init(_type: ErrorType, _cmd_out: PackedStringArray, _extra: String = "") -> void:
		type = _type
		extra = _extra
		command_output = _cmd_out
		match type:
			ErrorType.FailedExecuting:
				var cmd_out := '\n'.join(_cmd_out).strip_edges().replace("\n\n", '\n')
				message = "Failed executing \"%s\"\n\n%s" % [extra, cmd_out]
				if "xclip" in extra and "no authorization protocol" in cmd_out:
					message += "\n\nConsider installing 'wl-clipboard' if you're using Wayland."
			ErrorType.NoClipboardUtil:
				message = "Failed to find a clipboard util.\nMake sure you've installed one of the following:\n%s" % extra
			ErrorType.UnsupportedPlatform:
				message = "Unsupported platform"
			_:
				message = "Unknown error"
