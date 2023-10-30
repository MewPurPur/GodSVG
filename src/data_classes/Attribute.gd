## An attribute inside a [Tag], i.e. <tag attribute="value"/>
class_name Attribute extends RefCounted

signal value_changed(new_value: Variant)
signal propagate_value_changed()

enum Type {UNKNOWN, INT, FLOAT, UFLOAT, NFLOAT, COLOR, PATHDATA, ENUM, RECT}

var type: Type
var default: Variant

var _value: Variant

# Sometimes, value changes will be "quiet" and won't propagate - for example, if
# the attributes corresponding to 2D position get updated at the same time,
# we would want both changes to be noted by their input fields,
# but we also want only the second change to update the whole SVG and the code.
func set_value(new_value: Variant, propagate := true) -> void:
	if new_value != _value:
		_value = new_value
		value_changed.emit(new_value)
		if propagate:
			propagate_value_changed.emit()

func get_value() -> Variant:
	return _value

# A new_default of null means it's a required attribute.
func _init(new_type: Type, new_default: Variant = null, new_init: Variant = null) -> void:
	type = new_type
	default = new_default
	set_value(new_init if new_init != null else new_default, false)
