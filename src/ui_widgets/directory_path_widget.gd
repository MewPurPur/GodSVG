extends Control

const SLASH_SPACING = 8.0
const ICON_SPACING = 3.0
const MAX_BUTTON_WIDTH = 180.0
const BUTTON_SIDE_MARGIN := 2.0
const DROPDOWN_BUTTON_SIDE_MARGIN := 5.0

const home_icon = preload("res://assets/icons/Home.svg")
const computer_icon = preload("res://assets/icons/Computer.svg")

var ci := get_canvas_item()

signal directory_selected(path: String)

class ButtonData extends RefCounted:
	var rect: Rect2
	var path: String
	var display_text: String
	var icon: Texture2D
	
	func _init(new_rect: Rect2, new_path: String, new_display_text: String, new_icon: Texture2D = null) -> void:
		rect = new_rect
		path = new_path
		display_text = new_display_text
		icon = new_icon

var buttons: Array[ButtonData] = []  # The last button isn't clickable.
var dropdown_button: ButtonData = null  # Uses collapsed paths
var collapsed_paths := PackedStringArray()
var hovered_button: ButtonData = null
var pressed_button: ButtonData = null

var path := ""

func _ready() -> void:
	mouse_exited.connect(_on_mouse_exited)

func set_path(new_path: String) -> void:
	path = new_path
	sync_buttons.call_deferred()
	queue_redraw()

func sync_buttons() -> void:
	buttons.clear()
	collapsed_paths.clear()
	dropdown_button = null
	
	var font := ThemeUtils.regular_font
	var font_size := get_theme_font_size("font_size", "FlatButton")
	
	var available_width := size.x - 20.0
	var processed_path := path
	var offset := 0.0
	
	while true:
		var processed_path_component := processed_path.get_file()
		var button_content_width: float
		
		if processed_path_component.is_empty():
			button_content_width = font.get_string_size("Computer", HORIZONTAL_ALIGNMENT_CENTER, MAX_BUTTON_WIDTH, font_size).x + ICON_SPACING + computer_icon.get_width()
			if is_instance_valid(dropdown_button):
				collapsed_paths.append(processed_path)
			else:
				buttons.append(ButtonData.new(Rect2(0, 1, button_content_width + BUTTON_SIDE_MARGIN * 2, size.y - 2), processed_path, "Computer", computer_icon))
			offset += button_content_width + SLASH_SPACING + BUTTON_SIDE_MARGIN * 2
			break
		elif processed_path == Utils.get_home_dir():
			button_content_width = font.get_string_size("Home", HORIZONTAL_ALIGNMENT_CENTER, MAX_BUTTON_WIDTH, font_size).x + ICON_SPACING + home_icon.get_width()
			if is_instance_valid(dropdown_button):
				collapsed_paths.append(processed_path)
			else:
				buttons.append(ButtonData.new(Rect2(0, 1, button_content_width + BUTTON_SIDE_MARGIN * 2, size.y - 2), processed_path, "Home", home_icon))
			offset += button_content_width + SLASH_SPACING + BUTTON_SIDE_MARGIN * 2
			if path != processed_path:
				break
		else:
			if is_instance_valid(dropdown_button):
				collapsed_paths.append(processed_path)
			else:
				button_content_width = font.get_string_size(processed_path_component, HORIZONTAL_ALIGNMENT_CENTER, MAX_BUTTON_WIDTH, font_size).x
				if offset + button_content_width + BUTTON_SIDE_MARGIN * 2 + SLASH_SPACING > available_width:
					button_content_width = font.get_string_size("…", HORIZONTAL_ALIGNMENT_CENTER, MAX_BUTTON_WIDTH, font_size).x
					dropdown_button = ButtonData.new(Rect2(0, 1, button_content_width + DROPDOWN_BUTTON_SIDE_MARGIN * 2, size.y - 2), "", "…")
				else:
					buttons.append(ButtonData.new(Rect2(0, 1, button_content_width + BUTTON_SIDE_MARGIN * 2, size.y - 2), processed_path, processed_path_component))
					offset += button_content_width + SLASH_SPACING + BUTTON_SIDE_MARGIN * 2
		
		if processed_path == processed_path.get_base_dir():
			break
		processed_path = processed_path.get_base_dir()
	
	buttons.reverse()
	
	var buttons_to_reposition: Array[ButtonData] = buttons.duplicate()
	if is_instance_valid(dropdown_button):
		buttons_to_reposition.push_front(dropdown_button)
	
	offset = 0.0
	for i in buttons_to_reposition.size():
		var button := buttons_to_reposition[i]
		
		button.rect.position.x = offset
		
		var side_margin := DROPDOWN_BUTTON_SIDE_MARGIN if button == dropdown_button else BUTTON_SIDE_MARGIN
		var content_width := font.get_string_size(button.display_text, HORIZONTAL_ALIGNMENT_CENTER, MAX_BUTTON_WIDTH, font_size).x
		if is_instance_valid(button.icon):
			content_width += button.icon.get_width() + ICON_SPACING
		offset += content_width + side_margin * 2
		
		if i != buttons_to_reposition.size() - 1:
			offset += SLASH_SPACING
	
	HandlerGUI.throw_mouse_motion_event()
	queue_redraw()

func _draw() -> void:
	var font := ThemeUtils.regular_font
	var font_size := get_theme_font_size("font_size", "FlatButton")
	
	var buttons_to_draw: Array[ButtonData] = buttons.duplicate()
	if is_instance_valid(dropdown_button):
		buttons_to_draw.push_front(dropdown_button)
	
	for i in buttons_to_draw.size():
		var button := buttons_to_draw[i]
		
		var component_modulate := ThemeUtils.dimmer_text_color
		if button == pressed_button and button == hovered_button:
			component_modulate = ThemeUtils.highlighted_text_color
		elif i == buttons_to_draw.size() - 1 or button == hovered_button:
			component_modulate = ThemeUtils.text_color
		
		if button == pressed_button and button == hovered_button:
			get_theme_stylebox("pressed", "FlatButton").draw(ci, button.rect)
		elif button == hovered_button:
			get_theme_stylebox("hover", "FlatButton").draw(ci, button.rect)
		
		if is_instance_valid(button.icon):
			var text_x := button.rect.position.x + BUTTON_SIDE_MARGIN
			button.icon.draw(ci, Vector2(text_x, (size.y - button.icon.get_height()) / 2.0), component_modulate)
			text_x += button.icon.get_width() + ICON_SPACING
			font.draw_string(ci, Vector2(text_x, 16), button.display_text, HORIZONTAL_ALIGNMENT_LEFT, MAX_BUTTON_WIDTH, font_size, component_modulate)
		else:
			var text_line := TextLine.new()
			text_line.add_string(button.display_text, font, font_size)
			text_line.width = button.rect.size.x
			text_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			var side_margin := DROPDOWN_BUTTON_SIDE_MARGIN if button == dropdown_button else BUTTON_SIDE_MARGIN
			text_line.draw(ci, Vector2(button.rect.position.x + side_margin, 2), component_modulate)
		
		if i < buttons_to_draw.size() - 1:
			font.draw_string(ci, Vector2(button.rect.end.x + 0.5, 16), "/", HORIZONTAL_ALIGNMENT_CENTER, SLASH_SPACING, font_size, ThemeUtils.dimmer_text_color)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask == 0:
			var found_hovered := false
			for button_idx in buttons.size() - 1:
				var button := buttons[button_idx]
				if button.rect.has_point(event.position):
					if hovered_button != button:
						hovered_button = button
						queue_redraw()
					found_hovered = true
					break
			
			if not found_hovered and is_instance_valid(dropdown_button) and dropdown_button.rect.has_point(event.position):
				if hovered_button != dropdown_button:
					hovered_button = dropdown_button
					queue_redraw()
				found_hovered = true
			
			if not found_hovered and hovered_button != null:
				hovered_button = null
				queue_redraw()
		else:
			var found_hovered := false
			for button_idx in buttons.size() - 1:
				var button := buttons[button_idx]
				if button.rect.has_point(event.position):
					if hovered_button != button and button == pressed_button:
						hovered_button = button
						queue_redraw()
					found_hovered = true
					break
			
			if not found_hovered and is_instance_valid(dropdown_button) and dropdown_button.rect.has_point(event.position):
				if hovered_button != dropdown_button:
					hovered_button = dropdown_button
					queue_redraw()
				found_hovered = true
			
			if not found_hovered and hovered_button != null:
				hovered_button = null
				queue_redraw()
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			pressed_button = hovered_button
			queue_redraw()
		elif event.is_released():
			if is_instance_valid(pressed_button) and pressed_button == hovered_button:
				if pressed_button == dropdown_button:
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
				else:
					directory_selected.emit(pressed_button.path)
			pressed_button = null

func _on_mouse_exited() -> void:
	hovered_button = null
	queue_redraw()
