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

func setup(buttons: Array[Button], align_left := false, min_width := -1,
separator_indices: Array[int] = []) -> void:
	for control in main_container.get_children():
		control.free()
	if buttons.is_empty():
		return
	else:
		for idx in buttons.size():
			if idx in separator_indices:
				var separator := HSeparator.new()
				separator.theme_type_variation = "SmallHSeparator"
				main_container.add_child(separator)
			add_button(buttons[idx], align_left)
		if min_width > 0:
			min_size.x = ceili(min_width)
			panel.custom_minimum_size.x = min_width

func setup_with_title(buttons: Array[Button], top_title: String, align_left := false,
min_width := -1, separator_indices: Array[int] = []) -> void:
	for control in main_container.get_children():
		control.free()
	if buttons.is_empty():
		return
	else:
		# Setup the title.
		var title_container := PanelContainer.new()
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = Color("#0003")
		stylebox.content_margin_bottom = 3
		stylebox.content_margin_left = 8
		stylebox.content_margin_right = 8
		stylebox.border_width_bottom = 2
		stylebox.border_color = ThemeGenerator.common_separator_color
		title_container.add_theme_stylebox_override("panel", stylebox)
		var title_label := Label.new()
		title_label.text = top_title
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.begin_bulk_theme_override()
		title_label.add_theme_color_override("font_color", Color("def"))
		title_label.add_theme_font_size_override("font_size", 14)
		title_label.end_bulk_theme_override()
		title_container.add_child(title_label)
		main_container.add_child(title_container)
		# Continueu with regular setup logic.
		for idx in buttons.size():
			if idx in separator_indices:
				var separator := HSeparator.new()
				separator.theme_type_variation = "SmallHSeparator"
				main_container.add_child(separator)
			add_button(buttons[idx], align_left)
		if min_width > 0:
			min_size.x = ceili(min_width)
			panel.custom_minimum_size.x = min_width


func get_button_count() -> int:
	return main_container.get_child_count()
