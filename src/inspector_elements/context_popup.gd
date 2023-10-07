extends Popup

@onready var main_container: VBoxContainer = $PanelContainer/MainContainer

func add_button(butt: Button, top_corners := false, bottom_corners := false) -> void:
	var normal_stylebox := StyleBoxEmpty.new()
	normal_stylebox.set_content_margin_all(2)
	butt.add_theme_stylebox_override(&"normal", normal_stylebox)
	var hover_stylebox := StyleBoxFlat.new()
	hover_stylebox.bg_color = Color("#def1")
	var pressed_stylebox := StyleBoxFlat.new()
	pressed_stylebox.bg_color = Color("#def2")
	for stylebox: StyleBoxFlat in [hover_stylebox, pressed_stylebox]:
		stylebox.set_content_margin_all(2)
		if top_corners:
			stylebox.corner_radius_top_left = 5
			stylebox.corner_radius_top_right = 5
		if bottom_corners:
			stylebox.corner_radius_bottom_left = 5
			stylebox.corner_radius_bottom_right = 5
	butt.add_theme_stylebox_override(&"hover", hover_stylebox)
	butt.add_theme_stylebox_override(&"pressed", pressed_stylebox)
	main_container.add_child(butt)
	reset_size()
	

func get_button_count() -> int:
	return main_container.get_child_count()
