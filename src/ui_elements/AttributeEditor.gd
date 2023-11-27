## Base class for controls that bind to an [Attribute].
class_name AttributeEditor extends Control

# TODO Godot doesn't quite allow for this right now,
# but ideally, there would be more unified aspects here.

var attribute: Attribute
var attribute_name: String

# Values to be used for set_value().
# REGULAR means that value_changed will emit if the new value is different.
# NO_SIGNAL means value_changed won't emit.
# INTERMEDIATE and FINAL cause the attribute update to have the corresponding sync mode.
# Note that FINAL causes the equivalence check to be skipped.
enum UpdateType {REGULAR, NO_SIGNAL, INTERMEDIATE, FINAL}
