## An attribute inside a [Tag], i.e. <tag attribute="value"/>
class_name Attribute extends RefCounted

signal value_changed(new_value: Variant)
signal propagate_value_changed(undo_redo: bool)

enum Type {UNKNOWN, INT, FLOAT, UFLOAT, NFLOAT, COLOR, PATHDATA, ENUM, VIEWBOX}
var type: Type

var default: Variant
var _value: Variant

enum SyncMode {LOUD, INTERMEDIATE, FINAL, NO_PROPAGATION, SILENT}

# LOUD means the attribute will emit value_changed and be noticed everywhere.

# INTERMEDIATE is the same as LOUD, but doesn't create an UndoRedo action.
# Can be used to update an attribute continuously (i.e. dragging a color).

# FINAL is the same as LOUD, but it runs even if the new value is the same.
# This can be used to force an UndoRedo action after some intermediate changes.
# Note that the attribute is not responsible for making sure the new value is
# different from the previous one in the UndoRedo, this must be handled in the widgets.

# NO_PROPAGATION means the tag won't learn about it. This can allow the attribute change
# to be noted by an attribute editor without the SVG text being updated.
# This can be used, for example, to update two attributes corresponding to 2D coordinates
# without the first one causing an update to the SVG text.

# SILENT means the attribute update is ignored fully. It only makes sense
# if there is logic for updating the corresponding attribute editor despite that.

func set_value(new_value: Variant, sync_mode := SyncMode.LOUD) -> void:
	if new_value != _value or sync_mode == SyncMode.FINAL:
		_value = new_value
		if sync_mode != SyncMode.SILENT:
			value_changed.emit(new_value)
			if sync_mode != SyncMode.NO_PROPAGATION:
				propagate_value_changed.emit(sync_mode != SyncMode.INTERMEDIATE)

func get_value() -> Variant:
	return _value

# A new_default of null means it's a required attribute.
func _init(new_type: Type, new_default: Variant = null, new_init: Variant = null) -> void:
	type = new_type
	default = new_default
	set_value(new_init if new_init != null else new_default, SyncMode.SILENT)
