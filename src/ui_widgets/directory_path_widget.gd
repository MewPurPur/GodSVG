extends ProceduralControl

const BUTTON_SIDE_MARGIN := 2.0
const DROPDOWN_BUTTON_SIDE_MARGIN := 4.0
const ICON_SPACING = 2
const SLASH_SPACING = 8.0
const MAX_BUTTON_WIDTH = 180.0

const home_icon = preload("res://assets/icons/Home.svg")
const computer_icon = preload("res://assets/icons/Computer.svg")

signal directory_selected(path: String)

var dropdown_button: ButtonData
var collapsed_paths := PackedStringArray()

var path := ""

func set_path(new_path: String) -> void:
	path = new_path
	sync_buttons.call_deferred()
	queue_redraw()

func sync_buttons() -> void:
	dropdown_button = null
	buttons.clear()
	collapsed_paths.clear()
	
	var font := ThemeUtils.main_font
	var font_size := get_theme_font_size("font_size", "FlatButton")
	
	var available_width := size.x - 20.0
	var processed_path := path
	var offset := 0.0
	
	while true:
		var processed_path_component := processed_path.get_file()
		var button_content_width: float
		
		var special_button_text := ""
		var special_button_icon: DPITexture
		var is_first_dir := false
		if processed_path_component.is_empty():
			special_button_text = "Computer"
			special_button_icon = computer_icon
			is_first_dir = true
		elif processed_path == Utils.get_home_dir():
			special_button_text = "Home"
			special_button_icon = home_icon
			if path != processed_path:
				is_first_dir = true
		
		if not special_button_text.is_empty():
			if is_instance_valid(dropdown_button):
				collapsed_paths.append(processed_path)
			else:
				var text_line := TextLine.new()
				text_line.width = MAX_BUTTON_WIDTH
				text_line.add_string(special_button_text, font, font_size)
				button_content_width = text_line.get_line_width() + ICON_SPACING + special_button_icon.get_width()
				if offset + button_content_width + BUTTON_SIDE_MARGIN * 2 + SLASH_SPACING > size.x:
					text_line.clear()
					text_line.add_string("…", font, font_size)
					dropdown_button = ButtonData.create_from_textline(
							Rect2(0, 1, text_line.get_line_width() + DROPDOWN_BUTTON_SIDE_MARGIN * 2, size.y - 2), _popup_dropdown, text_line)
					dropdown_button.use_arrow_cursor = true
					buttons.append(dropdown_button)
					collapsed_paths.append(processed_path)
				else:
					var new_button := ButtonData.create_from_icon_and_textline(Rect2(0, 1, button_content_width + BUTTON_SIDE_MARGIN * 2, size.y - 2),
							directory_selected.emit.bind(processed_path), special_button_icon, text_line)
					new_button.use_arrow_cursor = true
					new_button.theme_h_separation_override = ICON_SPACING
					new_button.theme_color_overrides = {
						"icon_normal_color": ThemeUtils.dimmer_text_color,
						"font_color": ThemeUtils.dimmer_text_color,
						"icon_hover_color": ThemeUtils.text_color,
						"font_hover_color": ThemeUtils.text_color,
						"icon_pressed_color": ThemeUtils.highlighted_text_color,
						"font_pressed_color": ThemeUtils.highlighted_text_color,
						"icon_disabled_color": ThemeUtils.text_color,
						"font_disabled_color": ThemeUtils.text_color,
					}
					new_button.theme_stylebox_overrides = {"disabled": StyleBoxEmpty.new()}
					buttons.append(new_button)
			offset += button_content_width + SLASH_SPACING + BUTTON_SIDE_MARGIN * 2
			if is_first_dir:
				break
		else:
			if is_instance_valid(dropdown_button):
				collapsed_paths.append(processed_path)
			else:
				var text_line := TextLine.new()
				text_line.width = MAX_BUTTON_WIDTH
				text_line.add_string(processed_path_component, font, font_size)
				button_content_width = text_line.get_line_width()
				# Check against available width since space for the dropdown button is still needed.
				if offset + button_content_width + BUTTON_SIDE_MARGIN * 2 + SLASH_SPACING > available_width:
					text_line.clear()
					text_line.add_string("…", font, font_size)
					dropdown_button = ButtonData.create_from_textline(
							Rect2(0, 1, text_line.get_line_width() + DROPDOWN_BUTTON_SIDE_MARGIN * 2, size.y - 2), _popup_dropdown, text_line)
					dropdown_button.use_arrow_cursor = true
					buttons.append(dropdown_button)
					collapsed_paths.append(processed_path)
				else:
					var new_button := ButtonData.create_from_textline(Rect2(0, 1, button_content_width + BUTTON_SIDE_MARGIN * 2, size.y - 2),
							directory_selected.emit.bind(processed_path), text_line)
					new_button.use_arrow_cursor = true
					new_button.theme_h_separation_override = ICON_SPACING
					new_button.theme_color_overrides = {
						"icon_normal_color": ThemeUtils.dimmer_text_color,
						"font_color": ThemeUtils.dimmer_text_color,
						"icon_hover_color": ThemeUtils.text_color,
						"font_hover_color": ThemeUtils.text_color,
						"icon_pressed_color": ThemeUtils.highlighted_text_color,
						"font_pressed_color": ThemeUtils.highlighted_text_color,
						"icon_disabled_color": ThemeUtils.text_color,
						"font_disabled_color": ThemeUtils.text_color,
					}
					new_button.theme_stylebox_overrides = {"disabled": StyleBoxEmpty.new()}
					buttons.append(new_button)
					offset += button_content_width + SLASH_SPACING + BUTTON_SIDE_MARGIN * 2
		
		processed_path = processed_path.get_base_dir()
	
	buttons[0].disabled = true
	buttons.reverse()
	
	# Reorder buttons.
	offset = 0.0
	for i in buttons.size():
		var button := buttons[i]
		button.rect.position.x = offset
		offset += button.rect.size.x
		if i != buttons.size() - 1:
			offset += SLASH_SPACING
	
	HandlerGUI.throw_mouse_motion_event()
	queue_redraw()

func _draw() -> void:
	super()
	var font := ThemeUtils.main_font
	var font_size := get_theme_font_size("font_size", "FlatButton")
	for i in buttons.size() - 1:
		font.draw_string(ci, Vector2(buttons[i].rect.end.x + 0.5, 16), "/", HORIZONTAL_ALIGNMENT_CENTER, SLASH_SPACING, font_size, ThemeUtils.dimmer_text_color)


func _popup_dropdown() -> void:
	var btn_array: Array[Button] = []
	for collapsed_path in collapsed_paths:
		var display_name := collapsed_path.get_file()
		if display_name.is_empty():
			btn_array.append(ContextPopup.create_button("Computer", directory_selected.emit.bind(collapsed_path), false, computer_icon))
		elif collapsed_path == Utils.get_home_dir():
			btn_array.append(ContextPopup.create_button("Home", directory_selected.emit.bind(collapsed_path), false, home_icon))
		else:
			btn_array.append(ContextPopup.create_button(display_name, directory_selected.emit.bind(collapsed_path)))
	
	var dropdown_popup := ContextPopup.new()
	dropdown_popup.setup(btn_array, true, dropdown_button.rect.size.x, -1)
	HandlerGUI.popup_under_rect_center(dropdown_popup, Rect2(dropdown_button.rect.position + global_position, dropdown_button.rect.size), get_viewport())
