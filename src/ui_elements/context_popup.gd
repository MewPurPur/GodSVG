## The standard context menu popup.
extends Popup

@onready var panel: PanelContainer = $PanelContainer
@onready var main_container: VBoxContainer = $PanelContainer/MainContainer

func add_button(btn: Button, align_left: bool, should_reset_size := true) -> void:
	if not btn is CheckBox:
		btn.theme_type_variation = &"FlatButton"
		btn.pressed.connect(queue_free)
	btn.focus_mode = Control.FOCUS_NONE
	main_container.add_child(btn)
	if align_left:
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if should_reset_size:
		reset_size()

func set_button_array(buttons: Array[Button], align_left := false,
min_width := -1) -> void:
	for button in main_container.get_children():
		button.free()
	if buttons.is_empty():
		return
	else:
		var last_button_idx := buttons.size() - 1
		for i in last_button_idx:
			add_button(buttons[i], align_left, false)
		add_button(buttons[last_button_idx], align_left)
		if min_width > 0:
			min_size.x = ceili(min_width)
			panel.custom_minimum_size.x = min_width


func get_button_count() -> int:
	return main_container.get_child_count()


func _on_popup_hide() -> void:
	queue_free()
