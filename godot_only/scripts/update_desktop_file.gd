# Run with Ctrl+Shift+X.
@tool
extends EditorScript

const DESKTOP_FILE_STRUCTURE = """# This file is auto-generated from godot_only/scripts. Localizations are found in the respective .po files.
[Desktop Entry]
Version=1.0
Name=GodSVG
%s
%s
Exec=godsvg %%U
Icon=godsvg
Terminal=false
Type=Application
MimeType=image/svg+xml;
Categories=Graphics;VectorGraphics;2DGraphics;
%s
StartupWMClass=GodSVG\n"""


func _run() -> void:
	var desktop_file_location := ProjectSettings.globalize_path("assets/GodSVG.desktop")
	var fa := FileAccess.open(ProjectSettings.globalize_path("assets/GodSVG.desktop"), FileAccess.WRITE)
	if not is_instance_valid(fa):
		print_rich("[color=#f66]Failed to open %s." % desktop_file_location)
		return
	
	var generic_name_entries := PackedStringArray(["GenericName=Vector Graphics Editor"])
	var comment_entries := PackedStringArray(["Comment=A vector graphics application for structured SVG editing"])
	var keyword_entries := PackedStringArray(["Keywords=svg;vector;graphics;draw;design;illustration;image;art;diagram;icon;logo;editor;path;shape;2D;code;blue;fox;"])
	for locale in TranslationServer.get_loaded_locales():
		if locale == "en":
			continue
		var translation_obj := TranslationServer.find_translations(locale, true)[0]
		var translated_generic_name := Translator.translate_with_object("Vector Graphics Editor", translation_obj)
		var translated_comment := Translator.translate_with_object("A vector graphics application for structured SVG editing", translation_obj)
		var translated_keyword := Translator.translate_with_object(
				"svg;vector;graphics;draw;design;illustration;image;art;diagram;icon;logo;editor;path;shape;2D;code;blue;fox", translation_obj)
		
		if not translated_generic_name.is_empty():
			generic_name_entries.append("GenericName[%s]=%s" % [locale, translated_generic_name])
		if not translated_comment.is_empty():
			comment_entries.append("Comment[%s]=%s" % [locale, translated_comment])
		if not translated_comment.is_empty():
			keyword_entries.append("Keywords[%s]=svg;vector;graphics;draw;design;illustration;image;art;diagram;icon;logo;editor;path;shape;2D;code;blue;fox;%s;" %\
					[locale, translated_keyword])
	
	fa.store_string(DESKTOP_FILE_STRUCTURE % ["\n".join(generic_name_entries), "\n".join(comment_entries), "\n".join(keyword_entries)])
