## The standard context menu popup.
extends Popup

@onready var panel: PanelContainer = $PanelContainer
@onready var main_container: VBoxContainer = $PanelContainer/MainContainer

func add_button(butt: Button, should_reset_size := true) -> void:
	if not butt is CheckBox:
		butt.theme_type_variation = &"FlatButton"
		butt.pressed.connect(queue_free)
	if not butt.disabled:
		butt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	butt.focus_mode = Control.FOCUS_NONE
	main_container.add_child(butt)
	if should_reset_size:
		reset_size()

func set_btn_array(buttons: Array[Button]) -> void:
	for button in main_container.get_children():
		button.free()
	if buttons.is_empty():
		return
	else:
		var last_button_idx := buttons.size() - 1
		for i in last_button_idx:
			add_button(buttons[i], false)
		add_button(buttons[last_button_idx])

func set_min_width(w: float) -> void:
	min_size.x = ceili(w)
	panel.custom_minimum_size.x = w


func get_button_count() -> int:
	return main_container.get_child_count()


func _on_popup_hide() -> void:
	queue_free()
