extends AttributeEditor

@onready var line_edit: BetterLineEdit = $LineEdit

signal value_changed(new_value: String)
var _value: String  # Must not be updated directly.

func set_value(new_value: String, emit_value_changed := true):
	if _value != new_value:
		_value = new_value
		if emit_value_changed:
			value_changed.emit(new_value)

func get_value() -> String:
	return _value


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		set_value(attribute.get_value())
	line_edit.text = get_value()
	line_edit.tooltip_text = attribute_name + "\n(" + tr(&"#unknown_tooltip") + ")"

func _on_value_changed(new_value: String) -> void:
	line_edit.text = new_value
	if attribute != null:
		attribute.set_value(new_value)


func _on_text_submitted(new_text: String) -> void:
	line_edit.release_focus()
	set_value(new_text)
