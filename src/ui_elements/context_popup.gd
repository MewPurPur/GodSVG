## The standard context menu popup.
extends Popup

@onready var panel: PanelContainer = $PanelContainer
@onready var main_container: VBoxContainer = $PanelContainer/MainContainer

func add_button(butt: Button, should_reset_size := true) -> void:
	if not butt is CheckBox:
		var normal_stylebox := StyleBoxEmpty.new()
		normal_stylebox.set_content_margin_all(3)
		butt.add_theme_stylebox_override(&"normal", normal_stylebox)
		var hover_stylebox := StyleBoxFlat.new()
		hover_stylebox.bg_color = Color("#def1")
		hover_stylebox.set_content_margin_all(3)
		hover_stylebox.set_corner_radius_all(4)
		var pressed_stylebox := StyleBoxFlat.new()
		pressed_stylebox.bg_color = Color("#def2")
		pressed_stylebox.set_content_margin_all(3)
		pressed_stylebox.set_corner_radius_all(4)
		var disabled_stylebox := StyleBoxFlat.new()
		disabled_stylebox.bg_color = Color("#05060766")
		disabled_stylebox.set_content_margin_all(3)
		disabled_stylebox.set_corner_radius_all(4)
		butt.add_theme_stylebox_override(&"hover", hover_stylebox)
		butt.add_theme_stylebox_override(&"disabled", disabled_stylebox)
		butt.add_theme_stylebox_override(&"pressed", pressed_stylebox)
		butt.pressed.connect(queue_free)
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
