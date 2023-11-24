## An attribute inside a [Tag], i.e. <tag attribute="value"/>
class_name Attribute extends RefCounted

signal value_changed(new_value: Variant)
signal propagate_value_changed(complete: bool)

enum Type {UNKNOWN, INT, FLOAT, UFLOAT, NFLOAT, COLOR, PATHDATA, ENUM, VIEWBOX}
var type: Type

var default: Variant
var _value: Variant

enum SyncMode {LOUD, INTERMEDIATE, FINAL, NO_PROPAGATION, SILENT}

# LOUD means the attribute will emit value_changed and be noticed everywhere.

# INTERMEDIATE is the same as LOUD, but it won't create an UndoRedo action.

# FINAL is the same as LOUD, but it works even if the value didn't change.
# This can be used to force an UndoRedo action after some intermediate changes.
# Note that the attribute is not responsible for making sure the new value is
# different from the previous one in the UndoRedo, so handle this in the widgets. 

# NO_PROPAGATION means the tag won't learn about it. This can allow the attribute change
# to be noted by an attribute editor without the SVG text being updated.
# This can be used, for example, to update two attributes corresponding to 2D coordinates
# without the first one causing an update to the SVG text.

# SILENT means the attribute update is ignored fully. It only makes sense
# if there is logic for updating the corresponding attribute editor despite that.

func set_value(new_value: Variant, propagation := SyncMode.LOUD) -> void:
	if new_value != _value or propagation == SyncMode.FINAL:
		_value = new_value
		if propagation != SyncMode.SILENT:
			value_changed.emit(new_value)
			if propagation == SyncMode.LOUD or propagation == SyncMode.FINAL:
				print("Save UndoRedo")
				propagate_value_changed.emit(true)
			elif propagation == SyncMode.INTERMEDIATE:
				print("Intermediate")
				propagate_value_changed.emit(false)

func get_value() -> Variant:
	return _value

# A new_default of null means it's a required attribute.
func _init(new_type: Type, new_default: Variant = null, new_init: Variant = null) -> void:
	type = new_type
	default = new_default
	set_value(new_init if new_init != null else new_default, SyncMode.SILENT)
