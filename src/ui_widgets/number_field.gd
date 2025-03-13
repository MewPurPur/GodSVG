# An editor to be tied to a numeric attribute.
extends BetterLineEdit

var element: Element
var attribute_name: String:  # May propagate.
	set(new_value):
		attribute_name = new_value
		if DB.attribute_number_range[attribute_name] == DB.NumberRange.ARBITRARY:
			cached_min_value = -INF
			cached_max_value = INF
		else:
			cached_min_value = 0.0
			cached_max_value = INF

var cached_min_value: float
var cached_max_value: float

func set_value(new_value: String, save := false) -> void:
	if not new_value.is_empty():
		if not AttributeNumeric.text_check_percentage(new_value):
			var numeric_value := NumstringParser.evaluate(new_value)
			# Validate the value.
			if !is_finite(numeric_value):
				sync()
				return
			
			numeric_value = clampf(numeric_value, cached_min_value, cached_max_value)
			new_value = element.get_attribute(attribute_name).num_to_text(numeric_value)
	element.set_attribute(attribute_name, new_value)
	sync()
	if save:
		State.queue_svg_save()

func setup_placeholder() -> void:
	placeholder_text = element.get_default(attribute_name)


func _ready() -> void:
	Configs.basic_colors_changed.connect(sync)
	sync()
	element.attribute_changed.connect(_on_element_attribute_changed)
	if attribute_name in DB.propagated_attributes:
		element.ancestor_attribute_changed.connect(_on_element_ancestor_attribute_changed)
	tooltip_text = attribute_name
	text_submitted.connect(set_value.bind(true))
	text_change_canceled.connect(sync)
	focus_entered.connect(_on_focus_entered)
	setup_placeholder()


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		set_value(element.get_attribute_value(attribute_name))

func _on_element_ancestor_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		setup_placeholder()
		sync()

func _on_focus_entered() -> void:
	remove_theme_color_override("font_color")

func sync() -> void:
	var new_value := element.get_attribute_value(attribute_name)
	text = new_value
	remove_theme_color_override("font_color")
	if new_value == element.get_default(attribute_name):
		add_theme_color_override("font_color", Configs.savedata.basic_color_warning)
