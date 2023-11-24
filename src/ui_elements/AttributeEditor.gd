## Base class for controls that bind to an [Attribute].
class_name AttributeEditor extends Control

# TODO Godot doesn't quite allow for this right now,
# but ideally, there would be more unified aspects here.

# NORMAL = Emits value_changed signal.
# NO_SIGNAL = Doesn't emit value_changed signal.
# INTERMEDIATE = Emits and asks the attribute to use Attribute.SyncMode.INTERMEDIATE
# FINAL = Emits and asks the attribute to use Attribute.SyncMode.FINAL
enum UpdateMode {NORMAL, NO_SIGNAL, INTERMEDIATE, FINAL}

var attribute: Attribute
var attribute_name: String


func _on_value_changed(new_value: Variant, update_mode: UpdateMode) -> void:
	if attribute != null:
		match update_mode:
			UpdateMode.NORMAL:
				attribute.set_value(new_value)
			UpdateMode.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			UpdateMode.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
