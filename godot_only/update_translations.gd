# Run with Ctrl+Shift+X.
@tool
extends EditorScript

const HEADER = """#, fuzzy
msgid \"\"
msgstr \"\"
\"Project-Id-Version: GodSVG\\n\"
\"POT-Creation-Date: \\n\"
\"PO-Revision-Date: \\n\"
\"Last-Translator: \\n\"
\"Language-Team: \\n\"
\"MIME-Version: 1.0\\n\"
\"Content-Type: text/plain; charset=UTF-8\\n\"
\"Content-Transfer-Encoding: 8bit\\n\"
\"X-Generator: Poedit 3.4.2\\n\"\n"""

# Don't have a better solution than handling all these different whitespace variations...
const delimiters = {
	'TranslationServer.translate("': '")',
	'TranslationServer.translate(\n\t\t\t"': '")',
	'TranslationServer.translate(\n\t\t\t\t"': '")',
	'TranslationServer.translate(\n\t\t\t\t\t"': '")',
	"TranslationServer.translate('": "')",
	'TranslationServer.translate("""': '""")',
	'TranslationServer.translate_plural("': '")',
	"TranslationServer.translate_plural('": "')",
	'TranslationServer.translate_plural("""': '""")',
}

var strings: PackedStringArray = PackedStringArray(["translation-credits"])

func _run() -> void:
	search_directory(ProjectSettings.globalize_path("src"))
	update_translations()


func search_directory(dir: String) -> void:
	for dir_name in DirAccess.get_directories_at(dir):
		search_directory(dir.path_join(dir_name))
	
	for file_name in DirAccess.get_files_at(dir):
		var file_text := FileAccess.get_file_as_string(dir.path_join(file_name))
		for start_delim: String in delimiters:
			var end_delim: String = delimiters[start_delim]
			var cursor := 0
			while true:
				cursor = file_text.find(start_delim, cursor)
				if cursor == -1:
					break
				
				var string_start := cursor + start_delim.length()
				cursor = file_text.find(end_delim, cursor)
				var string := file_text.substr(string_start, cursor - string_start)
				if not string in strings:
					strings.append(string)

func update_translations() -> void:
	var location := ProjectSettings.globalize_path("translations/GodSVG.pot")
	var fa := FileAccess.open(location, FileAccess.WRITE)
	fa.store_string(HEADER)
	
	for string in strings:
		fa.store_string('\nmsgid "%s"\nmsgstr ""\n' % string)
	fa = null
	print("Created translations/GodSVG.pot with %d strings" % (strings.size() + 1))
	
	var files := DirAccess.get_files_at(ProjectSettings.globalize_path("translations"))
	for file in files:
		if file.get_extension() != "po":
			continue
		
		var args := PackedStringArray(["--update", "--quiet", "--verbose", "--backup=off",
				ProjectSettings.globalize_path("translations").path_join(file), location])
		var output := []
		var result := OS.execute("msgmerge", args, output, true)
		if result == -1:
			print("msgmerge failed.")
		else:
			if not output.is_empty():
				print("Updated translations/%s: %s" % [file, output[0].rstrip("\n")])
			else:
				print("Updated translations%s" % file)
