class_name ColorParser extends RefCounted

# The passed text should already be a valid color string.
static func format_text(text: String) -> String:
	text = text.strip_edges()
	
	if AttributeColor.is_valid_url(text):
		return "url(" + text.substr(4, text.length() - 5).strip_edges() + ")"
	
	if GlobalSettings.color_convert_rgb_to_hex and AttributeColor.is_valid_rgb(text):
		var inside_brackets := text.substr(4, text.length() - 5)
		var args := inside_brackets.split(",", false)
		text = "#" +\
				Color8(args[0].to_int(), args[1].to_int(), args[2].to_int()).to_html(false)
	
	if GlobalSettings.color_convert_named_to_hex and\
	AttributeColor.is_valid_named(text) and not text in AttributeColor.other_named_colors:
		text = AttributeColor.named_colors[text]
	
	if GlobalSettings.color_use_shorthand_hex_code and text.length() == 7 and\
	text[0] == "#" and text[1] == text[2] and text[3] == text[4] and text[5] == text[6]:
		text = "#" + text[1] + text[3] + text[5]
	
	if GlobalSettings.color_use_short_named_colors:
		var big_hex := text
		if AttributeColor.is_valid_hex(big_hex) and big_hex.length() == 4:
			big_hex = "#" + text[1] + text[1] + text[2] + text[2] + text[3] + text[3]
		if big_hex in AttributeColor.named_colors.values():
			var text_key: String = AttributeColor.named_colors.find_key(big_hex)
			if text_key.length() < text.length():
				text = text_key
	
	return text
