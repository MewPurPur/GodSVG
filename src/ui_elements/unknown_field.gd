## An editor to be tied to an AttributeUnknown.
## Allows attributes to be edited even if they aren't recognized by GodSVG.
extends AttributeEditor

@onready var line_edit: BetterLineEdit = $LineEdit

signal value_changed(new_value: String, update_type: UpdateType)
var _value: String  # Must not be updated directly.

func set_value(new_value: String, update_type := UpdateType.REGULAR):
	if _value != new_value or update_type == UpdateType.FINAL:
		_value = new_value
		if update_type != UpdateType.NO_SIGNAL:
			value_changed.emit(new_value, update_type)

func get_value() -> String:
	return _value


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	set_value(attribute.get_value())
	line_edit.text = get_value()
	line_edit.tooltip_text = attribute_name + "\n(" + tr(&"#unknown_tooltip") + ")"

func _on_value_changed(new_value: String, update_type: UpdateType) -> void:
	line_edit.text = new_value
	match update_type:
		UpdateType.INTERMEDIATE:
			attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
		UpdateType.FINAL:
			attribute.set_value(new_value, Attribute.SyncMode.FINAL)
		_:
			attribute.set_value(new_value)


func _on_text_submitted(new_text: String) -> void:
	line_edit.release_focus()
	set_value(new_text)
