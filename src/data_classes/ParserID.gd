## Parser for IDs, URLs, and HREFs.
@abstract class_name ParserID

enum NameValidityLevel {VALID, INVALID_XML_NAMETOKEN, INVALID}

## Returns a NameValidityLevel value based on whether the id is valid. If it's not a valid nametoken,
## it should be treated as a warning. Nmtoken syntax source: https://www.w3.org/TR/REC-xml/#NT-Nmtoken
static func _basic_get_id_validity(id: String) -> NameValidityLevel:
	var validity_level := NameValidityLevel.VALID
	for id_char in id:
		if id_char in ":_-.":
			continue
		var u := ord(id_char)
		if (u >= 48 and u <= 57) or (u >= 65 and u <= 90) or (u >= 97 and u <= 122) or u == 0xB7 or (u >= 0xC0 and u <= 0xD6) or (u >= 0xD8 and u <= 0xF6) or\
		(u >= 0xF8 and u <= 0x37D) or (u >= 0x37F and u <= 0x1FFF) or (u >= 0x200C and u <= 0x200D) or (u >= 0x203F and u <= 0x2040) or\
		(u >= 0x2070 and u <= 0x218F) or (u >= 0x2C00 and u <= 0x2FEF) or (u >= 0x3001 and u <= 0xD7FF) or (u >= 0xF900 and u <= 0xFDCF) or\
		(u >= 0xFDF0 and u <= 0xFFFD) or (u >= 0x10000 and u <= 0xEFFFF):
			continue
		
		if id_char in " \n\t\r":
			return NameValidityLevel.INVALID
		else:
			validity_level = NameValidityLevel.INVALID_XML_NAMETOKEN
	return validity_level


static func get_id_validity(id: String) -> NameValidityLevel:
	if id.is_empty() or id[0] == "#":
		return NameValidityLevel.INVALID
	return _basic_get_id_validity(id)

static func get_href_validity(id: String) -> NameValidityLevel:
	if id.is_empty():
		return NameValidityLevel.INVALID
	return _basic_get_id_validity(id.trim_prefix("#"))

static func is_url_valid(url: String) -> bool:
	url = url.strip_edges()
	if not url.begins_with("url(") or not url.ends_with(")"):
		return false
	return _basic_get_id_validity(get_url_id(url)) != NameValidityLevel.INVALID

static func get_url_id(url: String) -> String:
	return url.substr(4, url.length() - 5).strip_edges().right(-1)
