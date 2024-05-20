extends PanelContainer

@onready var label: Label = %MainContainer/Label
@onready var shortcut_container: HBoxContainer = %ShortcutContainer

func setup(new_action: String) -> void:
	var events := InputMap.action_get_events(new_action)
	# Clear the existing buttons.
	for button in shortcut_container.get_children():
		button.queue_free()
	# Create new ones.
	for i in events.size():
		var new_btn := Button.new()
		new_btn.auto_translate = false
		shortcut_container.add_child.call_deferred(new_btn)
		new_btn.custom_minimum_size.x = 144.0
		new_btn.size_flags_horizontal = Control.SIZE_FILL
		new_btn.theme_type_variation = "TranslucentButton"
		new_btn.focus_mode = Control.FOCUS_NONE
		new_btn.disabled = true
		new_btn.text = events[i].as_text_keycode()
