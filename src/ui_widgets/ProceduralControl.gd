## A control meant to be fully drawn. Such controls often need flat-like buttons, so this control providing a common implementation.
class_name ProceduralControl extends Control

var ci := get_canvas_item()

class ButtonData extends RefCounted:
	var rect: Rect2
	var callable: Callable
	var text_line: TextLine
	var icon: DPITexture
	var disabled: bool
	
	var theme_variation := "FlatButton"
	var theme_color_overrides: Dictionary[String, Color]
	var theme_stylebox_overrides: Dictionary[String, StyleBox]
	var theme_h_separation_override := -1
	var use_arrow_cursor := false
	
	static func create_from_icon(new_rect: Rect2, new_callable: Callable, new_icon: DPITexture) -> ButtonData:
		var new_button_data := ButtonData.new()
		new_button_data.rect = new_rect
		new_button_data.callable = new_callable
		new_button_data.icon = new_icon
		return new_button_data
	
	static func create_from_textline(new_rect: Rect2, new_callable: Callable, new_text_line: TextLine) -> ButtonData:
		var new_button_data := ButtonData.new()
		new_button_data.rect = new_rect
		new_button_data.callable = new_callable
		new_button_data.text_line = new_text_line
		return new_button_data
	
	static func create_from_icon_and_textline(new_rect: Rect2, new_callable: Callable, new_icon: DPITexture, new_text_line: TextLine) -> ButtonData:
		var new_button_data := ButtonData.new()
		new_button_data.rect = new_rect
		new_button_data.callable = new_callable
		new_button_data.icon = new_icon
		new_button_data.text_line = new_text_line
		return new_button_data

var buttons: Array[ButtonData] = []
var hovered_button: ButtonData = null
var pressed_button: ButtonData = null

func _ready() -> void:
	mouse_exited.connect(_on_base_class_mouse_exited)

func _on_base_class_mouse_exited() -> void:
	hovered_button = null
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	queue_redraw()

func _draw() -> void:
	for i in buttons.size():
		var button := buttons[i]
		
		# Stylebox drawing.
		if button.disabled:
			if "disabled" in button.theme_stylebox_overrides:
				button.theme_stylebox_overrides["disabled"].draw(ci, button.rect)
			else:
				get_theme_stylebox("disabled", button.theme_variation).draw(ci, button.rect)
		else:
			if button == pressed_button and button == hovered_button:
				if "pressed" in button.theme_stylebox_overrides:
					button.theme_stylebox_overrides["pressed"].draw(ci, button.rect)
				else:
					get_theme_stylebox("pressed", button.theme_variation).draw(ci, button.rect)
			elif button == hovered_button:
				if "hover" in button.theme_stylebox_overrides:
					button.theme_stylebox_overrides["hover"].draw(ci, button.rect)
				else:
					get_theme_stylebox("hover", button.theme_variation).draw(ci, button.rect)
		
		# Text and icon drawing
		var has_text := is_instance_valid(button.text_line)
		var has_icon := is_instance_valid(button.icon)
		
		if has_text and has_icon:
			var h_separation: int
			if button.theme_h_separation_override >= 0:
				h_separation = button.theme_h_separation_override
			else:
				h_separation = get_theme_constant("h_separation", button.theme_variation)
			
			var font_color: Color
			var icon_color: Color
			if button.disabled:
				if "icon_disabled_color" in button.theme_color_overrides:
					icon_color = button.theme_color_overrides["icon_disabled_color"]
				else:
					icon_color = get_theme_color("icon_disabled_color", button.theme_variation)
				
				if "font_disabled_color" in button.theme_color_overrides:
					font_color = button.theme_color_overrides["font_disabled_color"]
				else:
					font_color = get_theme_color("font_disabled_color", button.theme_variation)
			else:
				if button == pressed_button and button == hovered_button:
					if "icon_pressed_color" in button.theme_color_overrides:
						icon_color = button.theme_color_overrides["icon_pressed_color"]
					else:
						icon_color = get_theme_color("icon_pressed_color", button.theme_variation)
					
					if "font_pressed_color" in button.theme_color_overrides:
						font_color = button.theme_color_overrides["font_pressed_color"]
					else:
						font_color = get_theme_color("font_pressed_color", button.theme_variation)
				elif button == hovered_button:
					if "icon_hover_color" in button.theme_color_overrides:
						icon_color = button.theme_color_overrides["icon_hover_color"]
					else:
						icon_color = get_theme_color("icon_hover_color", button.theme_variation)
					
					if "font_hover_color" in button.theme_color_overrides:
						font_color = button.theme_color_overrides["font_hover_color"]
					else:
						font_color = get_theme_color("font_hover_color", button.theme_variation)
				else:
					if "icon_normal_color" in button.theme_color_overrides:
						icon_color = button.theme_color_overrides["icon_normal_color"]
					else:
						icon_color = get_theme_color("icon_normal_color", button.theme_variation)
					
					if "font_color" in button.theme_color_overrides:
						font_color = button.theme_color_overrides["font_color"]
					else:
						font_color = get_theme_color("font_color", button.theme_variation)
			
			var text_size := button.text_line.get_size()
			var icon_size := button.icon.get_size()
			var icon_pos := button.rect.position + (Vector2(button.rect.size.x - text_size.x - icon_size.x - h_separation,
					button.rect.size.y - icon_size.y - 2) / 2.0).round() + Vector2(0, 1)
			button.icon.draw(ci, icon_pos, icon_color)
			button.text_line.draw(ci, Vector2(icon_pos.x + icon_size.x + h_separation, (button.rect.size.y - text_size.y + 1) / 2.0).round(), font_color)
		elif has_text:
			var font_color: Color
			if button.disabled:
				if "font_disabled_color" in button.theme_color_overrides:
					font_color = button.theme_color_overrides["font_disabled_color"]
				else:
					font_color = get_theme_color("font_disabled_color", button.theme_variation)
			else:
				if button == pressed_button and button == hovered_button:
					if "font_pressed_color" in button.theme_color_overrides:
						font_color = button.theme_color_overrides["font_pressed_color"]
					else:
						font_color = get_theme_color("font_pressed_color", button.theme_variation)
				elif button == hovered_button:
					if "font_hover_color" in button.theme_color_overrides:
						font_color = button.theme_color_overrides["font_hover_color"]
					else:
						font_color = get_theme_color("font_hover_color", button.theme_variation)
				else:
					if "font_color" in button.theme_color_overrides:
						font_color = button.theme_color_overrides["font_color"]
					else:
						font_color = get_theme_color("font_color", button.theme_variation)
			
			button.text_line.draw(ci, button.rect.position + (button.rect.size - button.text_line.get_size()) / 2.0, font_color)
		elif has_icon:
			var icon_color: Color
			if button.disabled:
				if "icon_disabled_color" in button.theme_color_overrides:
					icon_color = button.theme_color_overrides["icon_disabled_color"]
				else:
					icon_color = get_theme_color("icon_disabled_color", button.theme_variation)
			else:
				if button == pressed_button and button == hovered_button:
					if "icon_pressed_color" in button.theme_color_overrides:
						icon_color = button.theme_color_overrides["icon_pressed_color"]
					else:
						icon_color = get_theme_color("icon_pressed_color", button.theme_variation)
				elif button == hovered_button:
					if "icon_hover_color" in button.theme_color_overrides:
						icon_color = button.theme_color_overrides["icon_hover_color"]
					else:
						icon_color = get_theme_color("icon_hover_color", button.theme_variation)
				else:
					if "icon_normal_color" in button.theme_color_overrides:
						icon_color = button.theme_color_overrides["icon_normal_color"]
					else:
						icon_color = get_theme_color("icon_normal_color", button.theme_variation)
			
			button.icon.draw(ci, button.rect.position + (button.rect.size - button.icon.get_size()) / 2.0, icon_color)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var mouse_event: InputEventMouse = event
		var event_pos := mouse_event.position
		var should_update_hover := (event is InputEventMouse)
		
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					pressed_button = hovered_button
					queue_redraw()
				elif event.is_released():
					if is_instance_valid(pressed_button) and pressed_button == hovered_button and not pressed_button.disabled:
						pressed_button.callable.call()
					pressed_button = null
					should_update_hover = true
		
		if should_update_hover:
			if event.button_mask == 0 and not (event is InputEventMouseButton and event.is_released() and event.button_index != MOUSE_BUTTON_NONE):
				var found_hovered := false
				for button in buttons:
					if button.disabled:
						continue
					if button.rect.has_point(event_pos):
						if hovered_button != button:
							hovered_button = button
							if not button.use_arrow_cursor:
								mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
							queue_redraw()
						found_hovered = true
						break
				
				if not found_hovered and hovered_button != null:
					hovered_button = null
					mouse_default_cursor_shape = Control.CURSOR_ARROW
					queue_redraw()
			else:
				var found_hovered := false
				for button in buttons:
					if button.disabled:
						continue
					if button.rect.has_point(event_pos):
						if hovered_button != button and button == pressed_button:
							hovered_button = button
							if not button.use_arrow_cursor:
								mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
							queue_redraw()
						found_hovered = true
						break
				
				if not found_hovered and hovered_button != null:
					hovered_button = null
					mouse_default_cursor_shape = Control.CURSOR_ARROW
					queue_redraw()
