extends Popup

@onready var main_container: VBoxContainer = $PanelContainer/MainContainer

func add_button(butt: Button, top_corners := false, bottom_corners := false,\
should_reset_size := true) -> void:
	if not butt is CheckBox:
		var normal_stylebox := StyleBoxEmpty.new()
		normal_stylebox.set_content_margin_all(3)
		butt.add_theme_stylebox_override(&"normal", normal_stylebox)
		var hover_stylebox := StyleBoxFlat.new()
		hover_stylebox.bg_color = Color("#def1")
		var pressed_stylebox := StyleBoxFlat.new()
		pressed_stylebox.bg_color = Color("#def2")
		for stylebox: StyleBoxFlat in [hover_stylebox, pressed_stylebox]:
			stylebox.set_content_margin_all(3)
			if top_corners:
				stylebox.corner_radius_top_left = 5
				stylebox.corner_radius_top_right = 5
			if bottom_corners:
				stylebox.corner_radius_bottom_left = 5
				stylebox.corner_radius_bottom_right = 5
		butt.add_theme_stylebox_override(&"hover", hover_stylebox)
		butt.add_theme_stylebox_override(&"pressed", pressed_stylebox)
	main_container.add_child(butt)
	if should_reset_size:
		reset_size()

func set_btn_array(buttons: Array[Button]) -> void:
	for button in main_container.get_children():
		button.queue_free()
	if buttons.is_empty():
		return
	elif buttons.size() == 1:
		add_button(buttons[0], true, true)
		return
	else:
		add_button(buttons.pop_front(), true, false)
		for i in buttons.size() - 1:
			add_button(buttons.pop_front(), false, false, false)
		add_button(buttons[0], false, true)


func get_button_count() -> int:
	return main_container.get_child_count()
