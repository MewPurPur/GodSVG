# Run with Ctrl+Shift+X.
@tool
extends EditorScript

const COMMENTS_DICT: Dictionary[String, String] = {
	"svg;vector;graphics;draw;design;illustration;image;art;diagram;icon;logo;editor;path;shape;2D;code;blue;fox": "A list of keywords that should remain semicolon-separated regardless of the language. If a keyword has no unique translation, omit it, and if it has multiple sensible translations, you can include all of them.",
	"Viewport": "The viewport is the area where the graphic is displayed. In similar applications, it's often called the canvas.",
	"CDATA color": "CDATA shouldn't be translated. It's a type of XML section.",
	"Editor formatter": "Refers to the formatter used for GodSVG's code editor.",
	"Export formatter": "Refers to the formatter used when exporting.",
	"Handles": "Refers to the draggable gizmos.",
	"Dash length": "Refers to the selection rectangle's animated dashed stroke.",
	"Excluded": "Refers to the zero, one, or multiple UI parts to not be shown in the final layout. It's of plural cardinality.",
	"Update check failed": "When checking for updates.",
	"Project Founder and Manager": "If the language has different gendered versions, prefer the most neutral-sounding one, i.e., the one used when you don't know the person's gender. If that's not possible, use feminine.",
	"V-Sync": "Stands for \"Vertical Synchronization\".",
	"Previews": "Refers to a part of the layout where icons are previewed at various sizes.",
	"Dark": "Refers to a theme preset.",
	"Light": "Refers to a theme preset.",
	"Gray": "Refers to a theme preset.",
	"Black (OLED)": "Refers to a theme preset.",
	"translation-credits": "Translators (comma-separated): Name or alias, optionally followed by an email in angle brackets <email@example.com>.\nUsed for credits. Adding yourself is optional. New entries go at the end. Don't remove or rearrange existing entries.",
	"Evaluate": """Refers to evaluating an expression such as "sin(2*pi/5)".""",
	"Grid tick interval": "Refers to the specially marked grid ticks, which are more distinct and have a coordinate.",
	"No ticks": "Refers to the specially marked grid ticks, which are more distinct and have a coordinate.",
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
			for i in range(2, 10):
				delimiters["Translator." + method + "(\n" + "\t".repeat(i) + quote] = quote + ")"
	
	for method in ["translate_with_object"]:
		for quote in ["'", '"', '"""']:
			delimiters["Translator." + method + "(" + quote] = quote + ","
			for i in range(2, 10):
				delimiters["Translator." + method + "(\n" + "\t".repeat(i) + quote] = quote + ","

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
	if OS.execute("msgmerge", PackedStringArray()) == -1:
		return
	populate_delimiters()
	get_messages_from_directory(ProjectSettings.globalize_path("src"))
	get_messages_from_file(ProjectSettings.globalize_path("godot_only/scripts/update_desktop_file.gd"))
	update_translations()


func get_messages_from_directory(dir: String) -> void:
	for dir_name in DirAccess.get_directories_at(dir):
		get_messages_from_directory(dir.path_join(dir_name))
	for file_name in DirAccess.get_files_at(dir):
		get_messages_from_file(dir.path_join(file_name))

func get_messages_from_file(file_path: String) -> void:
	var file_text := FileAccess.get_file_as_string(file_path)
	for start_delim in delimiters:
		var end_delim := delimiters[start_delim]
		var cursor := 0
		while true:
			cursor = file_text.find(start_delim, cursor)
			if cursor == -1:
				break
			
			var string_start := cursor + start_delim.length()
			cursor = file_text.find(end_delim, cursor)
			if file_text[cursor - end_delim.length()] == "\\":
				continue
			
			var msgid := file_text.substr(string_start, cursor - string_start)
			
			var already_exists := false
			for msg in messages:
				if msg.msgid == msgid:
					already_exists = true
					msg.files.append(file_path)
					break
			if not already_exists:
				messages.append(Message.new(msgid, PackedStringArray([file_path])))


func update_translations() -> void:
	# Update .pot file.
	var used_comments := PackedStringArray()
	var translations_dir_location := ProjectSettings.globalize_path(TRANSLATIONS_DIR)
	var pot_location := translations_dir_location.path_join("GodSVG.pot")
	
	var fa := FileAccess.open(pot_location, FileAccess.WRITE)
	if not is_instance_valid(fa):
		print_rich("[color=#f66]Failed to open %s." % pot_location)
		return
	
	fa.store_string(HEADER)
	for msg in messages:
		if COMMENTS_DICT.has(msg.msgid):
			var comment_lines := COMMENTS_DICT[msg.msgid].split("\n")
			var comment := ""
			for line in comment_lines:
				comment += "#. %s\n" % line
			fa.store_string(comment)
			used_comments.append(msg.msgid)
		fa.store_string(msg.to_string())
	fa = null
	print("Created %s with %d strings" % [TRANSLATIONS_DIR.path_join("GodSVG.pot"), (messages.size() + 1)])
	
	# Update .po files.
	for file in DirAccess.get_files_at(translations_dir_location):
		if not (file.get_extension() == "po" or file == "GodSVG.pot"):
			continue
		
		var args := PackedStringArray(["--update", "--quiet", "--verbose", "--backup=off", translations_dir_location.path_join(file), pot_location])
		var output: Array = []
		var result := OS.execute("msgmerge", args, output, true)
		if not result == -1:
			var po_location := translations_dir_location.path_join(file)
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
