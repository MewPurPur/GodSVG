extends AttributeEditor

@onready var x_field: HBoxContainer = $XField
@onready var y_field: HBoxContainer = $YField
@onready var w_field: HBoxContainer = $WField
@onready var h_field: HBoxContainer = $HField

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
	w_field.allow_lower = false
	h_field.allow_lower = false
	# FIXME Lift these limitations.
	x_field.num_edit.editable = false
	y_field.num_edit.editable = false
	w_field.num_edit.editable = false
	h_field.num_edit.editable = false
	
	x_field.min_value = -1024.0
	y_field.min_value = -1024.0
	value_changed.connect(_on_value_changed)
	if attribute != null:
		set_value(attribute.value)
		attribute.value_changed.connect(set_value)


func _on_x_field_value_changed(new_value: float) -> void:
	set_value(Rect2(
			new_value, y_field.get_value(), w_field.get_value(), h_field.get_value()))

func _on_y_field_value_changed(new_value: float) -> void:
	set_value(Rect2(
			x_field.get_value(), new_value, w_field.get_value(), h_field.get_value()))

func _on_w_field_value_changed(new_value: float) -> void:
	set_value(Rect2(
			x_field.get_value(), y_field.get_value(), new_value, h_field.get_value()))

func _on_h_field_value_changed(new_value: float) -> void:
	set_value(Rect2(
			x_field.get_value(), y_field.get_value(), w_field.get_value(), new_value))

func _on_value_changed(new_value: Rect2) -> void:
	x_field.num_edit.text = str(new_value.position.x)
	y_field.num_edit.text = str(new_value.position.y)
	w_field.num_edit.text = str(new_value.size.x)
	h_field.num_edit.text = str(new_value.size.y)
	if attribute != null:
		attribute.value = new_value
