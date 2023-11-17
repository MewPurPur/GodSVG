## An editor to be tied to an [AttributeRect].
extends AttributeEditor

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")

@onready var x_field: NumberEditType = $XField
@onready var y_field: NumberEditType = $YField
@onready var w_field: NumberEditType = $WField
@onready var h_field: NumberEditType = $HField

signal value_changed(new_value: Rect2)
var _value: Rect2  # Must not be updated directly.

func set_value(new_value: Rect2, emit_value_changed := true):
	if _value != new_value:
		_value = new_value
		if emit_value_changed:
			value_changed.emit(new_value)

func get_value() -> Rect2:
	return _value


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		set_value(attribute.get_value())
		# Maybe most attributes should listen for this signal instead of value_changed.
		attribute.value_changed.connect(set_value)


func _on_x_field_value_changed(new_value: float) -> void:
	set_value(Rect2(
			new_value, y_field.current_value, w_field.current_value, h_field.current_value))

func _on_y_field_value_changed(new_value: float) -> void:
	set_value(Rect2(
			x_field.current_value, new_value, w_field.current_value, h_field.current_value))

func _on_w_field_value_changed(new_value: float) -> void:
	set_value(Rect2(
			x_field.current_value, y_field.current_value, new_value, h_field.current_value))

func _on_h_field_value_changed(new_value: float) -> void:
	set_value(Rect2(
			x_field.current_value, y_field.current_value, w_field.current_value, new_value))

func _on_value_changed(new_value: Rect2) -> void:
	x_field.current_value = new_value.position.x
	y_field.current_value = new_value.position.y
	w_field.current_value = new_value.size.x
	h_field.current_value = new_value.size.y
	if attribute != null:
		attribute.set_value(new_value)
