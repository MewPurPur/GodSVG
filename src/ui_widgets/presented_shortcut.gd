extends PanelContainer

@onready var label: Label = %MainContainer/Label
@onready var shortcut_container: HBoxContainer = %ShortcutContainer

var action: String

func setup(new_action: String) -> void:
	action = new_action
	var events := InputMap.action_get_events(new_action)
	# Clear the existing buttons.
	for button in shortcut_container.get_children():
		button.queue_free()
	# Create new ones.
	for i in events.size():
		var new_btn := Button.new()
		new_btn.custom_minimum_size = Vector2(160, 24)
		new_btn.size_flags_horizontal = Control.SIZE_FILL
		new_btn.theme_type_variation = "TranslucentButton"
		var shortcut_stylebox := get_theme_stylebox("disabled", "TranslucentButton").duplicate()
		shortcut_stylebox.content_margin_top = 0
		shortcut_stylebox.content_margin_bottom = 0
		new_btn.add_theme_stylebox_override("disabled", shortcut_stylebox)
		
		new_btn.focus_mode = Control.FOCUS_NONE
		new_btn.disabled = true
		new_btn.text = events[i].as_text_keycode()
		shortcut_container.add_child(new_btn)
	Configs.shortcuts_changed.connect(check_shortcuts_validity)
	check_shortcuts_validity()

func check_shortcuts_validity() -> void:
	var events := InputMap.action_get_events(action)
	for i in events.size():
		var shortcut_btn := shortcut_container.get_child(i)
		if not Configs.savedata.is_shortcut_valid(events[i]):
			var warning_color := Color(Configs.savedata.basic_color_warning, 0.8)
			shortcut_btn.add_theme_color_override("font_disabled_color", warning_color)
			var conflicts := Configs.savedata.get_actions_with_shortcut(events[i])
			var action_pos := conflicts.find(action)
			if action_pos != -1:
				conflicts.remove_at(action_pos)
			for ii in conflicts.size():
				conflicts[ii] = TranslationUtils.get_shortcut_description(conflicts[ii])
			if conflicts.size() > 8:
				conflicts.resize(8)
				conflicts.append("...")
			shortcut_btn.tooltip_text = Translator.translate("Also used by") +\
					":\n" + "\n".join(conflicts)
		else:
			shortcut_btn.remove_theme_color_override("font_disabled_color")
