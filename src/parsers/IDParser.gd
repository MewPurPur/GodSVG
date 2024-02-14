class_name IDParser extends RefCounted

# XML's NameToken specification.
static func is_valid_id(id: String) -> bool:
	if id.is_empty():
		return false
	
	for id_char in id:
		if id_char in ":_-.":
			continue
		var u := id_char.unicode_at(0)
		if (u >= 48 and u <= 57) or (u >= 65 and u <= 90) or (u >= 97 and u <= 122) or\
		(u >= 0xC0 and u <= 0xD6) or (u >= 0xD8 and u <= 0xF6) or\
		(u >= 0xF8 and u <= 0x2FF) or (u >= 0x370 and u <= 0x37D) or\
		(u >= 0x37F and u <= 0x1FFF) or (u >= 0x200C and u <= 0x200D) or\
		(u >= 0x2070 and u <= 0x218F) or (u >= 0x2C00 and u <= 0x2FEF) or\
		(u >= 0x3001 and u <= 0xD7FF) or (u >= 0xF900 and u <= 0xFDCF) or\
		(u >= 0xFDF0 and u <= 0xFFFD) or (u >= 0x10000 and u <= 0xEFFFF):
			continue
		return false
	return true
