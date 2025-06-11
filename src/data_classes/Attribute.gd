# Represents an attribute inside an element, i.e. <element attribute="value"/>.
# If the Attribute's data type is known, one of the inheriting classes should be used.
class_name Attribute

signal value_changed

enum NameValidityLevel {VALID, INVALID_XML_NAMETOKEN, INVALID}

var name: String
var _value: String

func set_value(new_value: String) -> void:
	# Formatting can be expensive, so do this cheap check first.
	if new_value == _value:
		return
	var proposed_new_value := format(new_value)
	if proposed_new_value != _value:
		_value = proposed_new_value
		_sync()
		value_changed.emit()

func get_value() -> String:
	return _value

func _sync() -> void:
	pass

func format(text: String) -> String:
	return _format(text, Configs.savedata.editor_formatter)

func get_export_value() -> String:
	return _format(_value, Configs.savedata.export_formatter)

func _format(text: String, _formatter: Formatter) -> String:
	return text

func _init(new_name: String, init_value := "") -> void:
	name = new_name
	set_value(init_value)
	
static func get_name_validity(id: String) -> NameValidityLevel:
	var validity_level := NameValidityLevel.VALID
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
		
		if id_char in " \n\r\t\r":
			return NameValidityLevel.INVALID
		else:
			validity_level = NameValidityLevel.INVALID_XML_NAMETOKEN
	return validity_level
