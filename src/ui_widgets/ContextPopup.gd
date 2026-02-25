## Standard popup for actions with methods for easy setup.
class_name ContextPopup extends PanelContainer

const arrow = preload("res://assets/icons/PopupArrow.svg")
var ci := get_canvas_item()

var focus_index := -1:
	set(new_value):
		if focus_index != new_value:
			focus_index = new_value
			queue_redraw()

var buttons: Array[ContextButton] = []
var align_left := true

func _ready() -> void:
	mouse_exited.connect(_on_mouse_exited)
	for button in buttons:
		button.draw.connect(queue_redraw)
	
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("ui_down", focus_first_below)
	shortcuts.add_shortcut("ui_up", focus_first_above)
	shortcuts.add_shortcut("ui_right", _on_ui_right)
	shortcuts.add_shortcut("ui_left", _on_ui_left)
	shortcuts.add_shortcut("ui_accept", _on_ui_accept)
	HandlerGUI.register_shortcuts(self, shortcuts)

static func create(new_buttons: Array[ContextButton], new_align_left := true, min_width := -1.0, separator_indices := PackedInt32Array()) -> ContextPopup:
	var context_popup := ContextPopup.new()
	context_popup.buttons = new_buttons
	context_popup.align_left = new_align_left
	
	var scroll_container := _common_initial_setup()
	var main_container: VBoxContainer = scroll_container.get_child(0)
	context_popup.add_child(scroll_container)
	
	# Add the buttons.
	for idx in context_popup.buttons.size():
		if idx in separator_indices:
			var separator := HSeparator.new()
			separator.theme_type_variation = "SmallHSeparator"
			main_container.add_child(separator)
		main_container.add_child(context_popup.buttons[idx])
	
	if min_width > 0:
		context_popup.custom_minimum_size.x = min_width
	
	# Without this delay, get_minimum_size().y was returning a value larger than expected.
	main_container.ready.connect(
		func() -> void:
			var content_scale_factor := context_popup.get_tree().root.content_scale_factor
			var max_height := context_popup.get_window().size.y / (content_scale_factor * 2.0) - 16.0 * content_scale_factor
			if context_popup.get_minimum_size().y > max_height:
				context_popup.custom_minimum_size.y = max_height
				scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	)
	
	return context_popup


static func create_with_title(new_buttons: Array[ContextButton], top_title: String, new_align_left := true,
min_width := -1.0, separator_indices := PackedInt32Array()) -> ContextPopup:
	var context_popup := ContextPopup.new()
	context_popup.buttons = new_buttons
	context_popup.align_left = new_align_left
	
	var scroll_container := _common_initial_setup()
	var main_container: VBoxContainer = scroll_container.get_child(0)
	context_popup.add_child(scroll_container)
	
	# Setup the title.
	var title_container := PanelContainer.new()
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = ThemeUtils.flat_button_color_disabled
	stylebox.content_margin_bottom = 3.0
	stylebox.content_margin_left = 8.0
	stylebox.content_margin_right = 8.0
	stylebox.border_width_bottom = 2
	stylebox.border_color = ThemeUtils.basic_panel_border_color
	title_container.add_theme_stylebox_override("panel", stylebox)
	var title_label := Label.new()
	title_label.text = top_title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.theme_type_variation = "TitleLabel"
	title_label.add_theme_font_size_override("font_size", 14)
	title_container.add_child(title_label)
	main_container.add_child(title_container)
	
	# Continue with regular setup logic.
	for idx in context_popup.buttons.size():
		if idx in separator_indices:
			var separator := HSeparator.new()
			separator.theme_type_variation = "SmallHSeparator"
			main_container.add_child(separator)
		main_container.add_child(context_popup.buttons[idx])
	
	if min_width > 0:
		context_popup.custom_minimum_size.x = min_width
	
	# Without this delay, get_minimum_size().y was returning a value larger than expected.
	main_container.ready.connect(
		func() -> void:
			var content_scale_factor := context_popup.get_tree().root.content_scale_factor
			var max_height := context_popup.get_window().size.y / (content_scale_factor * 2.0) - 16.0 * content_scale_factor
			if context_popup.get_minimum_size().y > max_height:
				context_popup.custom_minimum_size.y = max_height
				scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	)
	
	return context_popup


# Helper.
static func _common_initial_setup() -> ScrollContainer:
	# Create a ScrollContainer to allow scrolling.
	var scroll_container := ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# Increase the scrollbar area on Android.
	if OS.get_name() == "Android":
		var scrollbar := scroll_container.get_v_scroll_bar()
		var stylebox := scrollbar.get_theme_stylebox("scroll").duplicate()
		stylebox.content_margin_left = 10.0
		stylebox.content_margin_right = 10.0
		scrollbar.add_theme_stylebox_override("scroll", stylebox)
	
	var main_container := VBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_theme_constant_override("separation", 0)
	
	scroll_container.add_child(main_container)
	return scroll_container


func _draw() -> void:
	var text_offset := ContextButton.PADDING
	for button in buttons:
		if (is_instance_valid(button.get_icon()) and align_left) or button.type == ContextButton.Type.CHECKBOX:
			text_offset += 16.0 + ContextButton.ICON_SPACING
			break
	
	for button_idx in buttons.size():
		var button := buttons[button_idx]
		var button_rect := Rect2(button.global_position - global_position, button.size)
		if button.disabled:
			button.get_theme_stylebox("disabled").draw(ci, button_rect)
		elif button_idx == focus_index:
			button.get_theme_stylebox("focus").draw(ci, button_rect)
		
		if button.type == ContextButton.Type.ARROW:
			var icon_color := button.get_theme_color("icon_color")
			if button_idx == focus_index:
				icon_color = button.get_theme_color("icon_focus_color")
			arrow.draw(ci, button_rect.end - (ContextButton.PADDING + 16.0) * Vector2(1, 1), icon_color)
		elif button.type == ContextButton.Type.CHECKBOX:
			var checkbox_icon: Texture2D
			if button.toggled_on:
				if button.disabled:
					checkbox_icon = get_theme_icon("checked_disabled", "CheckBox")
				else:
					checkbox_icon = get_theme_icon("checked", "CheckBox")
			else:
				if button.disabled:
					checkbox_icon = get_theme_icon("unchecked_disabled", "CheckBox")
				else:
					checkbox_icon = get_theme_icon("unchecked", "CheckBox")
			checkbox_icon.draw(ci, button_rect.position + ContextButton.PADDING * Vector2(1, 1))
		
		var button_icon := button.get_icon()
		var button_text := button.get_text()
		if is_instance_valid(button_icon) and button.type == ContextButton.Type.NORMAL:
			var icon_color := button.get_theme_color("icon_color")
			if button.disabled:
				icon_color = button.get_theme_color("icon_disabled_color")
			elif button_idx == focus_index:
				icon_color = button.get_theme_color("icon_focus_color")
			
			var icon_size := button_icon.get_size() * 16.0 / maxi(button_icon.get_width(), button_icon.get_height())
			if button_text.is_empty() and not align_left:
				button_icon.draw_rect(ci, Rect2(button_rect.get_center() - icon_size / 2, icon_size), false, icon_color)
			else:
				button_icon.draw_rect(ci, Rect2(button_rect.position + Vector2(1, 1) * ContextButton.PADDING, icon_size), false, icon_color)
		
		if not button_text.is_empty():
			var font := button.get_theme_font("font")
			var font_size := button.get_theme_font_size("font_size")
			var font_color := button.get_theme_color("font_color")
			if button.disabled:
				font_color = button.get_theme_color("font_disabled_color")
			elif button_idx == focus_index:
				font_color = button.get_theme_color("font_focus_color")
			var text_width := button_rect.size.x
			if align_left:
				text_width -= text_offset + ContextButton.PADDING
			else:
				text_width -= text_offset * 2
			
			font.draw_string(ci, button_rect.position + Vector2(text_offset, 16), button_text,
					HORIZONTAL_ALIGNMENT_LEFT if align_left else HORIZONTAL_ALIGNMENT_CENTER, text_width, font_size, font_color)
			
			var button_dim_text := button.get_dim_text()
			if not button_dim_text.is_empty():
				var dim_font_color := ThemeUtils.subtle_text_color
				if button.disabled:
					dim_font_color.a *= 0.6
				font.draw_string(ci, button_rect.position + Vector2(0, 16), button_dim_text,
						HORIZONTAL_ALIGNMENT_RIGHT, button_rect.size.x - ContextButton.PADDING, font_size, dim_font_color)

func _input(event: InputEvent) -> void:
	for button in buttons:
		if not button.action.is_empty() and not button.disabled:
			if ShortcutUtils.is_action_pressed(event, button.action):
				if button.type == ContextButton.Type.NORMAL:
					queue_free()
					tree_exited.connect(HandlerGUI.throw_action_event.bind(button.action))
				elif button.type == ContextButton.Type.CHECKBOX:
					button.toggled_on = not button.toggled_on
					queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			if event.is_pressed():
				set_focus_index_to_button_at_global_position(event.global_position)
			elif event.is_released():
				try_to_call_focused_button()
	elif event is InputEventMouseMotion:
		# We only want to capture real mouse motion for this.
		if not event.relative.is_zero_approx():
			set_focus_index_to_button_at_global_position(event.global_position)

func try_to_call_focused_button() -> void:
	if focus_index != -1:
		var btn := buttons[focus_index]
		if not btn.disabled:
			btn.get_callback().call()
			if btn.type == ContextButton.Type.NORMAL:
				queue_free()

func try_to_open_submenu() -> void:
	if is_instance_valid(HandlerGUI.popup_submenu) and focus_index == -1:
		focus_first_below()
		return
	
	var focus_button := buttons[focus_index]
	if focus_button.type == ContextButton.Type.ARROW:
		var options: Array[ContextButton] = []
		for button_builder in focus_button.submenu_button_builders:
			options.append(button_builder.call())
		var new_popup := ContextPopup.create(options)
		new_popup.focus_first_below()
		HandlerGUI.popup_submenu_to_right_or_left_side(new_popup, focus_button)

func set_focus_index_to_button_at_global_position(pos: Vector2) -> void:
	focus_index = -1
	for button_idx in buttons.size():
		if buttons[button_idx].get_global_rect().has_point(pos):
			focus_index = button_idx
			return

func focus_first_below() -> void:
	for button_idx in (range(focus_index + 1, buttons.size()) + range(0, focus_index)):
		if not buttons[button_idx].disabled:
			focus_index = button_idx
			return

func focus_first_above() -> void:
	var range_start := focus_index if focus_index != -1 else buttons.size()
	for button_idx in range(range_start - 1, -1, -1) + range(buttons.size() - 1, range_start, -1):
		if not buttons[button_idx].disabled:
			focus_index = button_idx
			return


func _on_mouse_exited() -> void:
	focus_index = -1

func _on_ui_right() -> void:
	try_to_open_submenu()

func _on_ui_accept() -> void:
	try_to_call_focused_button()
	try_to_open_submenu()

func _on_ui_left() -> void:
	if is_instance_valid(HandlerGUI.popup_submenu):
		queue_free()
