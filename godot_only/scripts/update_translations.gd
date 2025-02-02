# Run with Ctrl+Shift+X.
@tool
extends EditorScript

const TRANSLATIONS_DIR = "assets/translations"

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
\"Content-Transfer-Encoding: 8bit\\n\"\n"""

# Don't have a better solution than handling all these different whitespace variations...
var delimiters: Dictionary[String, String] = {}
func populate_delimiters() -> void:
	for method in ["translate"]:
		for quote in ["'", '"', '"""']:
			delimiters["Translator." + method + "(" + quote] = quote + ")"
			for i in range(2, 8):
				delimiters["Translator." + method + "(\n" + "\t".repeat(i) + quote] = quote + ")"

var messages: Array[Message] = [Message.new("translation-credits", PackedStringArray())]


class Message:
	# The files this message is in are added as comments. The lines aren't
	# kept track of, as they don't provide useful context and change frequently.
	var files := PackedStringArray()
	var msgid := String()
	
	func _init(p_msgid: String, p_files: PackedStringArray):
		msgid = p_msgid
		files = p_files.duplicate()
	
	func _to_string() -> String:
		var ret := "\n"
		for file in files:
			ret += "#: %s\n" % file
		return ret + 'msgid "%s"\nmsgstr ""\n' % msgid


func _run() -> void:
	populate_delimiters()
	if not OS.execute("msgmerge", PackedStringArray()) == -1:
		search_directory(ProjectSettings.globalize_path("src"))
		update_translations()


func search_directory(dir: String) -> void:
	for dir_name in DirAccess.get_directories_at(dir):
		search_directory(dir.path_join(dir_name))
	
	for file_name in DirAccess.get_files_at(dir):
		var file_text := FileAccess.get_file_as_string(dir.path_join(file_name))
		for start_delim in delimiters:
			var end_delim := delimiters[start_delim]
			var cursor := 0
			while true:
				cursor = file_text.find(start_delim, cursor)
				if cursor == -1:
					break
				
				var string_start := cursor + start_delim.length()
				cursor = file_text.find(end_delim, cursor)
				
				var msgid := file_text.substr(string_start, cursor - string_start)
				var full_file_name := dir.path_join(file_name)
				
				var already_exists := false
				for msg in messages:
					if msg.msgid == msgid:
						already_exists = true
						msg.files.append(full_file_name)
						break
				if not already_exists:
					messages.append(Message.new(msgid, PackedStringArray([full_file_name])))


func update_translations() -> void:
	var location := ProjectSettings.globalize_path(TRANSLATIONS_DIR + "/GodSVG.pot")
	var fa := FileAccess.open(location, FileAccess.WRITE)
	fa.store_string(HEADER)
	
	for msg in messages:
		fa.store_string(msg.to_string())
	fa = null
	print("Created " + TRANSLATIONS_DIR + "/GodSVG.pot with %d strings" % (messages.size() + 1))
	
	var files := DirAccess.get_files_at(ProjectSettings.globalize_path(TRANSLATIONS_DIR))
	for file in files:
		if not (file.get_extension() == "po" or file == "GodSVG.pot"):
			continue
		
		var args := PackedStringArray(["--update", "--quiet", "--verbose", "--backup=off",
				ProjectSettings.globalize_path(TRANSLATIONS_DIR).path_join(file), location])
		var output: Array = []
		var result := OS.execute("msgmerge", args, output, true)
		if not result == -1:
			if file == "GodSVG.pot":
				continue
			elif not output.is_empty():
				print("Updated " + TRANSLATIONS_DIR + "/%s: %s" % [file, output[0].rstrip("\n")])
			else:
				print("Updated " + TRANSLATIONS_DIR + "%s" % file)
