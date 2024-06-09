# An editor to be tied to a numeric attribute.
extends BetterLineEdit

var element: Element
var attribute_name: String  # May propagate.

var min_value := 0.0
var max_value := 1.0
var allow_lower := true
var allow_higher := true

func set_value(new_value: String, save := false) -> void:
	if not new_value.is_empty():
		new_value = new_value.strip_edges()
		if not new_value.ends_with("%"):
			var numeric_value := NumberParser.evaluate(new_value)
			# Validate the value.
			if !is_finite(numeric_value):
				sync(element.get_attribute_value(attribute_name))
				return
			
			if not allow_higher and numeric_value > max_value:
				numeric_value = max_value
				new_value = NumberParser.num_to_text(numeric_value)
			elif not allow_lower and numeric_value < min_value:
				numeric_value = min_value
				new_value = NumberParser.num_to_text(numeric_value)
			
			new_value = NumberParser.num_to_text(numeric_value)
		sync(element.get_attribute(attribute_name).format(new_value))
	element.set_attribute(attribute_name, new_value)
	if save:
		SVG.queue_save()

func setup_placeholder() -> void:
	placeholder_text = element.get_default(attribute_name)


func _ready() -> void:
	set_value(element.get_attribute_value(attribute_name, true))
	element.attribute_changed.connect(_on_element_attribute_changed)
	if attribute_name in DB.propagated_attributes:
		element.ancestor_attribute_changed.connect(_on_element_ancestor_attribute_changed)
	tooltip_text = attribute_name
	text_submitted.connect(set_value.bind(true))
	text_change_canceled.connect(_on_text_change_canceled)
	focus_entered.connect(_on_focus_entered)
	setup_placeholder()


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		set_value(element.get_attribute_value(attribute_name, true))

func _on_element_ancestor_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		setup_placeholder()

func _on_focus_entered() -> void:
	remove_theme_color_override("font_color")

func _on_text_change_canceled() -> void:
	sync(element.get_attribute_value(attribute_name))

func sync(new_value: String) -> void:
	text = new_value
	remove_theme_color_override("font_color")
	if new_value == element.get_default(attribute_name):
		add_theme_color_override("font_color", GlobalSettings.basic_color_warning)

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.BASIC_COLORS_CHANGED:
		sync(text)
