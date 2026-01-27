# An editor to be tied to a transform list attribute.
extends LineEditButton

var attribute_name: String  # Never propagates.

const TransformPopupScene = preload("res://src/ui_widgets/transform_popup.tscn")

func set_value(new_value: String, save := false) -> void:
	State.set_selected_attribute(attribute_name, new_value)
	sync()
	if save:
		State.save_svg()


func _ready() -> void:
	Configs.language_changed.connect(sync_localization)
	Configs.basic_colors_changed.connect(sync)
	sync_localization()
	sync()
	for xid in State.selected_xids:
		var xnode := State.root_element.get_xnode(xid)
		if xnode.is_element():
			xnode.attribute_changed.connect(_on_element_attribute_changed)
	text_submitted.connect(set_value.bind(true))
	text_changed.connect(setup_font)
	setup_font(text)
	text_change_canceled.connect(sync)
	button_gui_input.connect(_on_button_gui_input)
	pressed.connect(_on_pressed)
	focus_entered.connect(_on_focus_entered)


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync()

func _on_focus_entered() -> void:
	remove_theme_color_override("font_color")

func sync_localization() -> void:
	placeholder_text = Translator.translate("No transforms")

func setup_font(new_text: String) -> void:
	use_mono_font = not new_text.is_empty()

func sync() -> void:
	remove_theme_color_override("font_color")
	
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
			if has_same_values and not new_value in values:
				has_same_values = false
		
		values.append(new_value)
	
	text = values[0] if has_same_values else ".."
	setup_font(text)
	
	if has_same_values and values[0].is_empty():
		add_theme_color_override("font_color", Configs.savedata.basic_color_warning)
	
	var tooltip_lines := PackedStringArray()
	for i in values.size():
		tooltip_lines.append(values[i] if not values[i].is_empty() else Translator.translate("Unset"))
	tooltip_text = "\n".join(tooltip_lines)

func _on_pressed() -> void:
	if State.selected_xids.is_empty():
		return
	
	var values := PackedStringArray()
	var has_same_values := true
	
	for xid in State.selected_xids:
		var xnode := State.root_element.get_xnode(xid)
		if xnode.is_element():
			var element: Element = xnode
			var new_value := element.get_attribute_value(attribute_name)
			
			if not values.is_empty() and not new_value in values:
				has_same_values = false
				break
			
			values.append(new_value)
	
	if not has_same_values:
		return
	
	var first_element: Element = State.root_element.get_xnode(State.selected_xids[0])
	var transform_popup := TransformPopupScene.instantiate()
	transform_popup.attribute_ref = first_element.get_attribute(attribute_name)
	HandlerGUI.popup_under_rect(transform_popup, get_global_rect(), get_viewport())


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		accept_event()
		HandlerGUI.throw_mouse_motion_event()
	else:
		if is_instance_valid(temp_button):
			temp_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
