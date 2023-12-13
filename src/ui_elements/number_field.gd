## An editor to be tied to a numeric attribute.
extends BetterLineEdit

var attribute: AttributeNumeric
var attribute_name: String

var min_value := 0.0
var max_value := 1.0
var allow_lower := true
var allow_higher := true

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	var numeric_value := AttributeNumeric.evaluate_expr(new_value)
	# Validate the value.
	if !is_finite(numeric_value):
		sync(attribute.get_value())
		return
	
	if not allow_higher and numeric_value > max_value:
		numeric_value = max_value
		new_value = NumberParser.num_to_text(numeric_value)
	elif not allow_lower and numeric_value < min_value:
		numeric_value = min_value
		new_value = NumberParser.num_to_text(numeric_value)
	
	# Just because the value passed was +1 or 1.0 instead of the default 1,
	# shouldn't cause the attribute to be added to the SVG text.
	if NumberParser.text_to_num(attribute.default) == numeric_value:
		new_value = attribute.default
	elif NumberParser.text_to_num(new_value) != AttributeNumeric.evaluate_expr(new_value):
		new_value = NumberParser.num_to_text(numeric_value)
	
	sync(attribute.autoformat(new_value))
	# Update the attribute.
	if new_value != attribute.get_value() or update_type == Utils.UpdateType.FINAL:
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
	super()

func _on_text_submitted(submitted_text: String) -> void:
	set_value(submitted_text)

func sync(new_value: String) -> void:
	text = new_value
	if new_value == attribute.default:
		add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
	else:
		remove_theme_color_override(&"font_color")
