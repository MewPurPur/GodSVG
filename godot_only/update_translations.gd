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

var messages: Array[Message] = [Message.new("translation-credits")]


class Message:
	var refs: Array[MsgRef]
	var msgid := String()
	
	func _init(p_msgid: String, ref := MsgRef.new("", 0)):
		msgid = p_msgid
		if not ref.is_empty():
			refs.append(ref)
	
	func _to_string() -> String:
		var ret := "\n"
		for ref in refs:
			ret += "#: %s\n" % ref
		return ret + 'msgid "%s"\nmsgstr ""\n' % msgid


class MsgRef:
	var path := String()
	var line := 0
	
	func _init(p_path: String, p_line: int):
		path = p_path
		line = p_line
	
	func is_empty():
		return path.is_empty()
	
	func _to_string():
		return path + ":%d" % line


func _run() -> void:
	if not OS.execute("msgmerge", PackedStringArray()) == -1:
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
				var line := file_text.count("\n", 0, string_start) + 1
				cursor = file_text.find(end_delim, cursor)
				
				var msgid := file_text.substr(string_start, cursor - string_start)
				var ref := MsgRef.new(dir.path_join(file_name), line)
				
				var already_exists := false
				for msg in messages:
					if msg.msgid == msgid:
						already_exists = true
						msg.refs.append(ref)
						break
				if not already_exists:
					messages.append(Message.new(msgid, ref))


func update_translations() -> void:
	var location := ProjectSettings.globalize_path("translations/GodSVG.pot")
	var fa := FileAccess.open(location, FileAccess.WRITE)
	fa.store_string(HEADER)
	
	for msg in messages:
		fa.store_string(msg.to_string())
	fa = null
	print("Created translations/GodSVG.pot with %d strings" % (messages.size() + 1))
	
	var files := DirAccess.get_files_at(ProjectSettings.globalize_path("translations"))
	for file in files:
		if not file.get_extension() == "po" and file != "GodSVG.pot":
			continue
		
		var args := PackedStringArray([
			"--update",
			"--quiet",
			"--verbose",
			"--backup=off",
			ProjectSettings.globalize_path("translations").path_join(file),
			location
		])
		var output := []
		var result := OS.execute("msgmerge", args, output, true)
		if not result == -1:
			if file == "GodSVG.pot":
				continue
			elif not output.is_empty():
				print("Updated translations/%s: %s" % [file, output[0].rstrip("\n")])
			else:
				print("Updated translations%s" % file)
