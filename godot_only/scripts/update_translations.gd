# Run with Ctrl+Shift+X.
@tool
extends EditorScript

const COMMENTS_DICT = {
	"Viewport": "The viewport is the area where the graphic is displayed. In similar applications, it's often called the canvas.",
	"CDATA color": "CDATA shouldn't be translated. It's a type of XML section.",
	"Editor formatter": "Refers to the formatter used for GodSVG's code editor.",
	"Export formatter": "Refers to the formatter used when exporting.",
	"Handles": "Refers to the draggable gizmos.",
	"Dash length": "Refers to the selection rectangle's animated dashed stroke",
	"Excluded": "Refers to the zero, one, or multiple UI parts to not be shown in the final layout. It's of plural cardinality.",
	"Update check failed": "When checking for updates.",
	"Project Founder and Manager": "If the language has different gendered versions, prefer the most neutral-sounding one, i.e., the one used when you don't know the person's gender. If that's not possible, use feminine.",
	"V-Sync": "Stands for \"Vertical Synchronization\".",
}

const TRANSLATIONS_DIR = "translations"

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
	var msgid := ""
	
	func _init(p_msgid: String, p_files: PackedStringArray):
		msgid = p_msgid
		files = p_files.duplicate()
	
	func _to_string() -> String:
		return "\n#: " + "\n#: ".join(files) + '\nmsgid "%s"\nmsgstr ""\n' % msgid


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
						msg.files.append(full_file_name + ":")
						break
				if not already_exists:
					messages.append(Message.new(msgid, PackedStringArray([full_file_name + ":"])))


func update_translations() -> void:
	var used_comments := PackedStringArray()
	var folder_location := ProjectSettings.globalize_path(TRANSLATIONS_DIR)
	var pot_location := folder_location.path_join("GodSVG.pot")
	
	var fa := FileAccess.open(pot_location, FileAccess.WRITE)
	fa.store_string(HEADER)
	for msg in messages:
		if COMMENTS_DICT.has(msg.msgid):
			fa.store_string("#. %s\n" % COMMENTS_DICT[msg.msgid])
			used_comments.append(msg.msgid)
		fa.store_string(msg.to_string())
	fa = null
	print("Created %s with %d strings" % [TRANSLATIONS_DIR.path_join("/GodSVG.pot"),
			(messages.size() + 1)])
	
	for file in DirAccess.get_files_at(folder_location):
		if not (file.get_extension() == "po" or file == "GodSVG.pot"):
			continue
		
		var args := PackedStringArray(["--update", "--quiet", "--verbose", "--backup=off",
				folder_location.path_join(file), pot_location])
		var output: Array = []
		var result := OS.execute("msgmerge", args, output, true)
		if not result == -1:
			var po_location = folder_location.path_join(file)
			args = PackedStringArray(["--no-wrap", po_location, "-o", po_location])
			OS.execute("msgcat", args)
			if file == "GodSVG.pot":
				continue
			elif not output.is_empty():
				print("Updated " + TRANSLATIONS_DIR + "/%s: %s" % [file, output[0].rstrip("\n")])
			else:
				print("Updated " + TRANSLATIONS_DIR + "%s" % file)
	
	for id in COMMENTS_DICT:
		if not used_comments.has(id):
			print_rich("[color=#f66]The \"%s\" string, which has a comment defined for it, wasn't encountered." % id)
