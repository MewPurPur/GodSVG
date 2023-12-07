## An editor to be tied to a numeric attribute.
extends BetterLineEdit

var attribute: AttributeNumeric
var attribute_name: String

var min_value := 0.0
var max_value := 1.0
var allow_lower := true
var allow_higher := true

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	var numeric_value := AttributeNumeric.evaluate_numeric_expression(new_value)
	# Validate the value.
	if !is_finite(numeric_value):
		sync(attribute.get_value())
		return
	if allow_lower:
		if not allow_higher:
			numeric_value = minf(numeric_value, max_value)
	else:
		if allow_higher:
			numeric_value = maxf(numeric_value, min_value)
		else:
			numeric_value = clampf(numeric_value, min_value, max_value)
	
	var old_value := attribute.get_value()
	new_value = AttributeNumeric.num_to_text(numeric_value)
	sync(new_value)
	# Update the attribute.
	if new_value != old_value or update_type == Utils.UpdateType.FINAL:
		match update_type:
			Utils.UpdateType.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			Utils.UpdateType.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
			_:
				attribute.set_value(new_value)


func _ready() -> void:
	super()
	set_value(attribute.get_value())
	attribute.value_changed.connect(set_value)
	tooltip_text = attribute_name

func _on_focus_exited() -> void:
	set_value(text)

func _on_text_submitted(submitted_text: String) -> void:
	set_value(submitted_text)

func sync(new_value: String) -> void:
	text = new_value
	if new_value == attribute.default:
		add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
	else:
		remove_theme_color_override(&"font_color")
