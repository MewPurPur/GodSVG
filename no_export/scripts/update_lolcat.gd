# Run with Ctrl+Shift+X.
@tool
extends EditorScript

const CREDITS := "FlooferLand"

func _run() -> void:
	var input := FileAccess.get_file_as_string("res://translations/en.po")
	var output := ""
	var last_id := ""
	var update_count := 0
	for line in input.split("\n"):
		line = line.strip_edges()
		var line_out := line
		if not line.begins_with("#"):
			if line.begins_with("msgid"):
				last_id = line.replace("msgid", "").strip_edges().trim_prefix("\"").trim_suffix("\"")
			elif line.begins_with("msgstr") and not last_id.is_empty():
				var new := _translate_str(last_id)
				line_out = "msgstr \"%s\"" % new
				last_id = ""
				if new != last_id:
					update_count += 1
			else:
				line_out = line_out.replace("Language: en", "Language: lolcat")
		output += "%s\n" % line_out
	
	var file := FileAccess.open("res://translations/lolcat.po", FileAccess.WRITE)
	var file_err := FileAccess.get_open_error()
	if file_err != OK:
		print("Error '%s' saving lolcat translation" % file_err)
	file.store_string(output)
	file.close()
	print("Updated %s translations! =(^w^)=" % update_count)

func _translate_str(input: String) -> String:
	input = input.to_lower()
	
	# Quick replaces (should be careful here)
	input = input\
		.replace("translation-credits", CREDITS)\
		.replace("to compare", "an compare")\
		.replace("no other data is collected or transmitted", "no spywarez.. promis")\
		.replace("do you", "does u")\
		.replace("could not be", "cant b")\
		.replace("can be", "can b")\
		.replace("may be", "maybe")\
		.replace("format", "fomat")\
		.replace("ous ", "us ")\
		.replace("?", "??")\
		.replace("'s", "s")\
		.replace("'t", "t")\
		.replace(", ", " ")
	
	# The smarts
	if input.ends_with("."):
		input = input.trim_suffix(".")
	
	# Quick words (order matters)
	var words := {
		"quit": "kthxbye",
		"want": "wants",
		"when": "wen",
		"this": "dis",
		"the": "da",
		"these": "deez",
		"prettier": "pretty",
		"graphic": "grafic",
		"discarded": "boomed",
		"zoom": "zoomie",
		"ok": "okey",
		"close": "byebye",
		"view": "look",
		"path": "paf",
		"error": "bad",
		"undefined": "undenfied",
		"cancel": "cancelz",
		"elements": "elementz",
		"attributes": "attributez",
		"versions": "versionz",
		"colors": "colorz",
		"exists": "exist",
		"files": "filez",
		"godsvgs": "godsvg",
		"debug": "antibug",
		"bug": "buggy",
		"v-sync": "input lag (vsync)"
	}
	for key in words.keys():
		var word: String = words[key]
		if input == key: # Single-word translations
			input = word
		else:
			input = _replace_word(input, key, word)
		
		# Prevents a bug with trailing S being duplicated
		input = input.replace("ss ", "s ")
	return input

func _replace_word(input: String, what: String, forwhat: String) -> String:
	return input\
		.replace(" %s " % what, " %s " % forwhat)\
		.replace(" %s." % what, " %s." % forwhat)\
		.replace(" %s," % what, " %s," % forwhat)\
		.replace(" %s!" % what, " %s!" % forwhat)\
		.replace(" %s?" % what, " %s?" % forwhat)
