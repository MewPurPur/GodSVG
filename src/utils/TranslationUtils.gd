## A utility class for handling localization.
@abstract class_name TranslationUtils

# Returns a human-readable name for the given locale.
# Handles special cases for certain locales, falls back to TranslationServer for others.
static func _get_locale_name(locale: String) -> String:
	match locale:
		"pt_BR": return "Brazilian Portuguese"
		"zh_CN": return "Simplified Chinese"
	return TranslationServer.get_locale_name(locale)

## Converts a locale string to a language-REGION format.
static func get_locale_string(locale: String) -> String:
	if not "_" in locale:
		return locale.to_upper()
	var separator_pos := locale.find("_")
	return locale.left(separator_pos) + "-" + locale.right(-separator_pos - 1).to_upper()

## Returns a display-friendly locale string with both name and code, such as "Brazilian Portuguese (pt-BR)".
static func get_locale_display(locale: String) -> String:
	return "%s (%s)" % [_get_locale_name(locale), get_locale_string(locale)]


## Returns the translated description for a given action. If for_button is true, uses a shorter description.
static func get_action_description(action_name: String, for_button := false) -> String:
	match action_name:
		"export": return Translator.translate("Export")
		"import": return Translator.translate("Import")
		"save": return Translator.translate("Save SVG")
		"save_as": return Translator.translate("Save SVG as")
		"close_tab": return Translator.translate("Close tab")
		"close_tabs_to_left": return Translator.translate("Close tabs to the left")
		"close_tabs_to_right": return Translator.translate("Close tabs to the right")
		"close_all_other_tabs": return Translator.translate("Close all other tabs")
		"close_empty_tabs": return Translator.translate("Close empty tabs")
		"close_saved_tabs": return Translator.translate("Close saved tabs")
		"new_tab": return Translator.translate("Create tab") if for_button else Translator.translate("Create a new tab")
		"select_next_tab": return Translator.translate("Select the next tab")
		"select_previous_tab": return Translator.translate("Select the previous tab")
		"optimize": return Translator.translate("Optimize") if for_button else Translator.translate("Optimize SVG")
		"copy_svg_text": return Translator.translate("Copy all text") if for_button else Translator.translate("Copy the SVG text")
		"reset_svg": return Translator.translate("Reset SVG")
		"open_externally": return Translator.translate("Open externally") if for_button else Translator.translate("Open SVG externally")
		"open_in_folder": return Translator.translate("Show in File Manager") if for_button else Translator.translate("Show SVG in File Manager")
		"ui_undo": return Translator.translate("Undo")
		"ui_redo": return Translator.translate("Redo")
		"ui_copy": return Translator.translate("Copy")
		"ui_paste": return Translator.translate("Paste")
		"ui_cut": return Translator.translate("Cut")
		"evaluate": return Translator.translate("Evaluate")
		"select_all": return Translator.translate("Select all")
		"duplicate": return Translator.translate("Duplicate") if for_button else Translator.translate("Duplicate the selection")
		"delete": return Translator.translate("Delete") if for_button else Translator.translate("Delete the selection")
		"move_up": return Translator.translate("Move up") if for_button else Translator.translate("Move the selection up")
		"move_down": return Translator.translate("Move down") if for_button else Translator.translate("Move the selection down")
		"find": return Translator.translate("Find")
		"zoom_in": return Translator.translate("Zoom in")
		"zoom_out": return Translator.translate("Zoom out")
		"zoom_reset": return Translator.translate("Zoom reset")
		"view_show_grid": return Translator.translate("Show grid")
		"view_show_handles": return Translator.translate("Show handles")
		"view_rasterized_svg": return Translator.translate("Show rasterized SVG")
		"toggle_snap": return Translator.translate("Toggle snapping")
		"load_reference": return Translator.translate("Load reference image")
		"view_show_reference": return Translator.translate("Show reference image")
		"view_overlay_reference": return Translator.translate("Overlay reference image")
		"debug": return Translator.translate("View debug information")
		"advanced_debug": return Translator.translate("View advanced debug information")
		"move_relative": return get_path_command_description("m")
		"move_absolute": return get_path_command_description("M")
		"line_relative": return get_path_command_description("l")
		"line_absolute": return get_path_command_description("L")
		"horizontal_line_relative": return get_path_command_description("h")
		"horizontal_line_absolute": return get_path_command_description("H")
		"vertical_line_relative": return get_path_command_description("v")
		"vertical_line_absolute": return get_path_command_description("V")
		"close_path_relative": return get_path_command_description("z")
		"close_path_absolute": return get_path_command_description("Z")
		"elliptical_arc_relative": return get_path_command_description("a")
		"elliptical_arc_absolute": return get_path_command_description("A")
		"quadratic_bezier_relative": return get_path_command_description("q")
		"quadratic_bezier_absolute": return get_path_command_description("Q")
		"shorthand_quadratic_bezier_relative": return get_path_command_description("t")
		"shorthand_quadratic_bezier_absolute": return get_path_command_description("T")
		"cubic_bezier_relative": return get_path_command_description("c")
		"cubic_bezier_absolute": return get_path_command_description("C")
		"shorthand_cubic_bezier_relative": return get_path_command_description("s")
		"shorthand_cubic_bezier_absolute": return get_path_command_description("S")
		"open_settings": return Translator.translate("Settings") if for_button else Translator.translate("Open Settings menu")
		"about_info": return Translator.translate("About…") if for_button else Translator.translate("Open About menu")
		"about_donate": return Translator.translate("Donate…") if for_button else Translator.translate("Open Donate menu")
		"about_repo": return Translator.translate("GodSVG repository") if for_button else Translator.translate("Open GodSVG repository")
		"about_website": return Translator.translate("GodSVG website") if for_button else Translator.translate("Open GodSVG website")
		"check_updates": return Translator.translate("Check for updates")
		"quit": return Translator.translate("Quit the application")
		"toggle_fullscreen": return Translator.translate("Toggle fullscreen")
		_: return action_name

## Returns a translated description for an SVG path command character.
## If omit_relativity is true, doesn't append "(Relative)"/"(Absolute)" suffix.
static func get_path_command_description(command_char: String, omit_relativity := false) -> String:
	var description: String
	match command_char:
		"M", "m": description = Translator.translate("Move to")
		"L", "l": description = Translator.translate("Line to")
		"H", "h": description = Translator.translate("Horizontal Line to")
		"V", "v": description = Translator.translate("Vertical Line to")
		"Z", "z": description = Translator.translate("Close Path")
		"A", "a": description = Translator.translate("Elliptical Arc to")
		"Q", "q": description = Translator.translate("Quadratic Bezier to")
		"T", "t": description = Translator.translate("Shorthand Quadratic Bezier to")
		"C", "c": description = Translator.translate("Cubic Bezier to")
		"S", "s": description = Translator.translate("Shorthand Cubic Bezier to")
		_: return command_char
	
	if omit_relativity:
		return description
	elif Utils.is_string_lower(command_char):
		return description + " (" + Translator.translate("Relative") + ")"
	else:
		return description + " (" + Translator.translate("Absolute") + ")"

## Returns the translated name for a layout part.
static func get_layout_part_name(layout_part: Utils.LayoutPart) -> String:
	match layout_part:
		Utils.LayoutPart.CODE_EDITOR: return Translator.translate("Code editor")
		Utils.LayoutPart.INSPECTOR: return Translator.translate("Inspector")
		Utils.LayoutPart.VIEWPORT: return Translator.translate("Viewport")
		_: return ""

## Generates an alert text for unsupported file extensions.
static func get_extension_alert_text(allowed_extensions: PackedStringArray) -> String:
	for i in allowed_extensions.size():
		allowed_extensions[i] = _get_extension_readable_name(allowed_extensions[i])
	var extension_list := ", ".join(allowed_extensions)
	return Translator.translate("Only {extension_list} files are supported for this operation.").format({"extension_list": extension_list})

## Generates title text for file selection dialogs.
static func get_file_dialog_select_mode_title_text(multi_select: bool, extensions: PackedStringArray) -> String:
	if multi_select:
		return Translator.translate("Select {format} files").format({"format": _get_extension_readable_name("svg")})
	else:
		if extensions == Utils.IMAGE_FORMATS:
			return Translator.translate("Select an image")
		elif extensions == Utils.DYNAMIC_FONT_FORMATS:
			return Translator.translate("Select a font")
		else:
			# "an" because this can currently only show for SVG and XML files.
			return Translator.translate("Select an {format} file").format({"format": _get_extension_readable_name(extensions[0])})

## Generates title text for file save dialogs.
static func get_file_dialog_save_mode_title_text(extension: String) -> String:
	return Translator.translate("Save the {format} file").format({"format": _get_extension_readable_name(extension)})

# Converts a file extension to a human-readable format name.
static func _get_extension_readable_name(extension: String) -> String:
	match extension:
		"svg": return "SVG"
		"png": return "PNG"
		"webp": return "WebP"
		"jpeg": return "JPEG"
		"jpg": return "JPG"
		"xml": return "XML"
		_: return extension
