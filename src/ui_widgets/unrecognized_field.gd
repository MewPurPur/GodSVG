# An editor to be tied to an attribute GodSVG can't recognize, allowing to still edit it.
extends BetterLineEdit

var attribute_name: String  # Assume it doesn't propagate.

func set_value(new_value: String, save := false) -> void:
	State.set_selected_attribute(attribute_name, new_value)
	sync()
	if save:
		State.save_svg()

func _ready() -> void:
	Configs.language_changed.connect(sync_localization)
	sync()
	sync_localization()
	for xid in State.selected_xids:
		var xnode := State.root_element.get_xnode(xid)
		if xnode.is_element():
			xnode.attribute_changed.connect(_on_element_attribute_changed)
	text_submitted.connect(set_value.bind(true))
	text_change_canceled.connect(sync)

func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync()

func sync() -> void:
	if State.selected_xids.is_empty():
		return
	
	var values := PackedStringArray()
	var has_same_values := true
	
	for xid in State.selected_xids:
		var xnode := State.root_element.get_xnode(xid)
		if not xnode.is_element():
			continue
		
		var element: Element = xnode
		var new_value := element.get_attribute_value(attribute_name)
		
		if not values.is_empty():
			if has_same_values and new_value != values[0]:
				has_same_values = false
		
		values.append(new_value)
	
	text = values[0] if has_same_values else ".."
	
	var tooltip_lines := PackedStringArray()
	tooltip_lines.append(Translator.translate("GodSVG doesn't recognize this attribute."))
	tooltip_lines.append("")
	for i in values.size():
		var current_value := values[i] if not values[i].is_empty() else Translator.translate("Unset")
		tooltip_lines.append(current_value)
	tooltip_text = "\n".join(tooltip_lines)

func sync_localization() -> void:
	sync()
