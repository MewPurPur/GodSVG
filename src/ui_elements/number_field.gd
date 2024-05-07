# An editor to be tied to a numeric attribute.
extends BetterLineEdit

signal focused
var attribute: AttributeNumeric
var previous_focusable: Control

var min_value := 0.0
var max_value := 1.0
var allow_lower := true
var allow_higher := true

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	if not new_value.is_empty():
		var numeric_value := NumberParser.evaluate(new_value)
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
		
		new_value = NumberParser.num_to_text(numeric_value)
		sync(attribute.format(new_value))
	
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
	set_value(attribute.get_value())
	super()
	attribute.value_changed.connect(set_value)
	tooltip_text = attribute.name
	placeholder_text = attribute.get_default()
	text_submitted.connect(set_value)
	if previous_focusable:
		previous_focusable.focus_next = previous_focusable.get_path_to(self)
		self.focus_previous = get_path_to(previous_focusable)
	previous_focusable = self

func _on_focus_entered() -> void:
	remove_theme_color_override("font_color")
	focused.emit()
	super()

func _on_text_change_canceled() -> void:
	sync(attribute.get_value())

func sync(new_value: String) -> void:
	text = new_value
	remove_theme_color_override("font_color")
	if new_value == attribute.get_default():
		add_theme_color_override("font_color", GlobalSettings.basic_color_warning)

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.BASIC_COLORS_CHANGED:
		sync(text)
