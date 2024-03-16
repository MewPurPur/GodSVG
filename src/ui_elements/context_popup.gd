## The standard context menu popup.
extends BetterPopup

@onready var panel: PanelContainer = $PanelContainer
@onready var main_container: VBoxContainer = $PanelContainer/MainContainer

func add_button(btn: Button, align_left: bool) -> void:
	if not btn is CheckBox:
		btn.theme_type_variation = "ContextButton"
		btn.pressed.connect(queue_free)
	btn.focus_mode = Control.FOCUS_NONE
	main_container.add_child(btn)
	if align_left:
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

func set_button_array(buttons: Array[Button], align_left := false,
min_width := -1) -> void:
	for button in main_container.get_children():
		button.free()
	if buttons.is_empty():
		return
	else:
		for i in buttons.size():
			add_button(buttons[i], align_left)
		if min_width > 0:
			min_size.x = ceili(min_width)
			panel.custom_minimum_size.x = min_width


func get_button_count() -> int:
	return main_container.get_child_count()
