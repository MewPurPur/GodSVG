class_name Attribute extends RefCounted

signal value_changed(new_value: Variant)

enum Type {INT, FLOAT, UFLOAT, NFLOAT, COLOR, PATHDATA, ENUM, RECT}

var type: Type
var default: Variant

var value: Variant:
	set(new_value):
		if new_value != value:
			value = new_value
			value_changed.emit(new_value)

# A default of null means it's a required attribute.
func _init(new_type: Type, new_default: Variant = null, new_init: Variant = null) -> void:
	type = new_type
	default = new_default
	value = new_init if new_init != null else new_default

func duplicate() -> Attribute:
	return Attribute.new(type,default,value)
