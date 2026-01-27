# An editor to be tied to a numeric attribute.
extends BetterLineEdit

var attribute_name: String:  # May propagate.
	set(new_value):
		attribute_name = new_value
		cached_min_value = -INF if DB.ATTRIBUTE_NUMBER_RANGE[attribute_name] == DB.NumberRange.ARBITRARY else 0.0

var cached_min_value: float

func set_value(new_value: String, save := false) -> void:
	if not new_value.is_empty():
		if not AttributeNumeric.text_check_percentage(new_value):
			var numeric_value := NumstringParser.evaluate(new_value)
			# Validate the value.
			if not is_finite(numeric_value):
				sync()
				return
			
			numeric_value = maxf(numeric_value, cached_min_value)
			new_value = NumberParser.num_to_text(numeric_value, Configs.savedata.editor_formatter)
	State.set_selected_attribute(attribute_name, new_value)
	sync()
	if save:
		State.save_svg()


func _ready() -> void:
	Configs.basic_colors_changed.connect(sync)
	sync()
	for xid in State.selected_xids:
		var xnode := State.root_element.get_xnode(xid)
		if xnode.is_element():
			xnode.attribute_changed.connect(_on_element_attribute_changed)
	text_submitted.connect(set_value.bind(true))
	text_change_canceled.connect(sync)
	focus_entered.connect(_on_focus_entered)
	sync()

func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync()

func _on_focus_entered() -> void:
	remove_theme_color_override("font_color")

func sync() -> void:
	remove_theme_color_override("font_color")
	
	if State.selected_xids.is_empty():
		return
	
	var values := PackedStringArray()
	var defaults := PackedStringArray()
	var has_same_values := true
	var has_same_defaults := true
	
	for xid in State.selected_xids:
		var xnode := State.root_element.get_xnode(xid)
		if not xnode.is_element():
			continue
		
		var element: Element = xnode
		var new_value := element.get_attribute_value(attribute_name)
		var new_default := element.get_default(attribute_name)
		
		if not values.is_empty():
			if has_same_values and not new_value in values:
				has_same_values = false
			if has_same_defaults and not new_default in defaults:
				has_same_defaults = false
		
		values.append(new_value)
		defaults.append(new_default)
	
	text = values[0] if has_same_values else ".."
	placeholder_text = defaults[0] if has_same_defaults else ".."
	if values == defaults:
		add_theme_color_override("font_color", Configs.savedata.basic_color_warning)
	
	var tooltip_lines := PackedStringArray()
	for i in values.size():
		var current_value := values[i] if not values[i].is_empty() else Translator.translate("Unset")
		tooltip_lines.append(current_value + " (" + Translator.translate("Default") + ": " + defaults[i] + ")")
	tooltip_text = "\n".join(tooltip_lines)
