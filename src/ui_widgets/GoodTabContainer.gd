## A class similar to TabContainer, but more adapted to GodSVG's needs.
## It's less configurable, but has the ability to have tabs on the side.
class_name GoodTabContainer extends Control

signal tab_selected(index: int)

var ci := get_canvas_item()
var _content_container: MarginContainer
var _scroll_container: ScrollContainer

@export var side_tabs := false
@export var sidebar_width := 160.0
@export var current_tab_index := -1

var _tab_names: PackedStringArray
var _tab_rects: Array[Rect2]
var get_content_method := Callable()

func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_exited.connect(_on_base_class_mouse_exited)

func _on_base_class_mouse_exited() -> void:
	queue_redraw()

func _draw() -> void:
	if side_tabs:
		var test_text_line := TextLine.new()
		test_text_line.add_string("W", get_theme_font("font", "TabContainer"), get_theme_font_size("font_size", "TabContainer"))
		var max_top_bottom_margin := 0.0
		const CONST_ARR: PackedStringArray = ["side_tab_unselected", "side_tab_selected", "side_tab_hovered"]
		for tab_type in CONST_ARR:
			var stylebox := get_theme_stylebox(tab_type, "TabContainer")
			max_top_bottom_margin = maxf(max_top_bottom_margin, stylebox.content_margin_bottom + stylebox.content_margin_top)
		var tab_height := test_text_line.get_size().y + max_top_bottom_margin
		
		var side_tabbar_background := get_theme_stylebox("tabbar_background", "TabContainer").duplicate()
		Utils.rotate_flat_stylebox_90_left(side_tabbar_background)
		side_tabbar_background.draw(ci, Rect2(0, 0, sidebar_width, size.y))
		var side_panel := get_theme_stylebox("panel", "TabContainer").duplicate()
		Utils.rotate_flat_stylebox_90_left(side_panel)
		side_panel.draw(ci, Rect2(sidebar_width, 0, size.x - sidebar_width, size.y))
		
		_tab_rects.clear()
		for tab_idx in get_tab_count():
			var tab_rect := Rect2(0, tab_height * tab_idx, sidebar_width, tab_height)
			_tab_rects.append(tab_rect)
			
			var theme_type := "side_tab_unselected"
			var theme_color := "font_unselected_color"
			if current_tab_index == tab_idx:
				theme_type = "side_tab_selected"
				theme_color = "font_selected_color"
			elif tab_rect.has_point(get_local_mouse_position()):
				theme_type = "side_tab_hovered"
				theme_color = "font_hovered_color"
			var tab_stylebox := get_theme_stylebox(theme_type, "TabContainer")
			tab_stylebox.draw(ci, tab_rect)
			if has_focus(true) and current_tab_index == tab_idx:
				get_theme_stylebox("tab_focus", "TabContainer").draw(ci, tab_rect)
			
			var text_line := TextLine.new()
			text_line.add_string(_tab_names[tab_idx], get_theme_font("font", "TabContainer"), get_theme_font_size("font_size", "TabContainer"))
			text_line.width = sidebar_width - tab_stylebox.content_margin_left - tab_stylebox.content_margin_right
			text_line.draw(ci, tab_rect.position + Vector2(tab_stylebox.content_margin_left, tab_stylebox.content_margin_top),
					get_theme_color(theme_color, "TabContainer"))
	else:
		var test_text_line := TextLine.new()
		test_text_line.add_string("W", get_theme_font("font", "TabContainer"), get_theme_font_size("font_size", "TabContainer"))
		var max_top_bottom_margin := 0.0
		var max_left_right_margin := 0.0
		const CONST_ARR: PackedStringArray = ["tab_unselected", "tab_selected", "tab_hovered"]
		for tab_type in CONST_ARR:
			var stylebox := get_theme_stylebox(tab_type, "TabContainer")
			max_top_bottom_margin = maxf(max_top_bottom_margin, stylebox.content_margin_bottom + stylebox.content_margin_top)
			max_left_right_margin = maxf(max_left_right_margin, stylebox.content_margin_left + stylebox.content_margin_right)
		var tab_height := test_text_line.get_size().y + max_top_bottom_margin
		
		get_theme_stylebox("tabbar_background", "TabContainer").draw(ci, Rect2(0, 0, size.x, tab_height))
		get_theme_stylebox("panel", "TabContainer").draw(ci, Rect2(0, tab_height, size.x, size.y - tab_height))
		
		var tab_offset := 0.0
		_tab_rects.clear()
		for tab_idx in get_tab_count():
			var string_width := get_theme_font("font", "TabContainer").get_string_size(_tab_names[tab_idx],
					HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size", "TabContainer")).x
			var tab_width := string_width + max_left_right_margin
			
			var tab_rect := Rect2(tab_offset, 0, tab_width, tab_height)
			_tab_rects.append(tab_rect)
			tab_offset += tab_width
			
			var theme_type := "tab_unselected"
			var theme_color := "font_unselected_color"
			if current_tab_index == tab_idx:
				theme_type = "tab_selected"
				theme_color = "font_selected_color"
			elif tab_rect.has_point(get_local_mouse_position()):
				theme_type = "tab_hovered"
				theme_color = "font_hovered_color"
			var tab_stylebox := get_theme_stylebox(theme_type, "TabContainer")
			
			tab_stylebox.draw(ci, tab_rect)
			if has_focus(true) and current_tab_index == tab_idx:
				get_theme_stylebox("tab_focus", "TabContainer").draw(ci, tab_rect)
			
			var text_line := TextLine.new()
			text_line.add_string(_tab_names[tab_idx], get_theme_font("font", "TabContainer"), get_theme_font_size("font_size", "TabContainer"))
			text_line.draw(ci, tab_rect.position + Vector2(tab_stylebox.content_margin_left, tab_stylebox.content_margin_top),
					get_theme_color(theme_color, "TabContainer"))

func _ready() -> void:
	_content_container = MarginContainer.new()
	_content_container.add_theme_constant_override("margin_left", 8)
	_content_container.add_theme_constant_override("margin_right", 8)
	_content_container.add_theme_constant_override("margin_top", 8)
	_content_container.add_theme_constant_override("margin_bottom", 8)
	_scroll_container = ScrollContainer.new()
	add_child(_scroll_container)
	_scroll_container.add_child(_content_container)
	_content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	resized.connect(_on_base_class_resized)
	
	tab_selected.connect(_on_base_class_tab_selected)
	
	if current_tab_index != -1:
		select_tab(current_tab_index)

func _on_base_class_resized() -> void:
	var panel_stylebox := get_theme_stylebox("panel", "TabContainer")
	if side_tabs:
		panel_stylebox = panel_stylebox.duplicate()
		Utils.rotate_flat_stylebox_90_left(panel_stylebox)
		_scroll_container.position = Vector2(sidebar_width, panel_stylebox.border_width_top)
		_scroll_container.size = Vector2(size.x - sidebar_width - panel_stylebox.border_width_right,
				size.y - panel_stylebox.border_width_top - panel_stylebox.border_width_bottom)
		# FIXME The scrollbar can get all wrong without this.
		await get_tree().process_frame
		_scroll_container.scroll_vertical += 1
		_scroll_container.scroll_vertical -= 1
	else:
		var test_text_line := TextLine.new()
		test_text_line.add_string("W", get_theme_font("font", "TabContainer"), get_theme_font_size("font_size", "TabContainer"))
		var max_top_bottom_margin := 0.0
		var max_left_right_margin := 0.0
		const CONST_ARR: PackedStringArray = ["tab_unselected", "tab_selected", "tab_hovered"]
		for tab_type in CONST_ARR:
			var stylebox := get_theme_stylebox(tab_type, "TabContainer")
			max_top_bottom_margin = maxf(max_top_bottom_margin, stylebox.content_margin_bottom + stylebox.content_margin_top)
			max_left_right_margin = maxf(max_left_right_margin, stylebox.content_margin_left + stylebox.content_margin_right)
		var tab_height := test_text_line.get_size().y + max_top_bottom_margin
		
		panel_stylebox = panel_stylebox.duplicate()
		_scroll_container.position = Vector2(0, tab_height)
		_scroll_container.size = Vector2(size.x - panel_stylebox.border_width_right,
				size.y - tab_height - panel_stylebox.border_width_top - panel_stylebox.border_width_bottom)
		# FIXME The scrollbar can get all wrong without this.
		await get_tree().process_frame
		_scroll_container.scroll_vertical += 1
		_scroll_container.scroll_vertical -= 1


func select_tab(tab_index: int) -> void:
	if tab_index != current_tab_index:
		current_tab_index = tab_index
		for child in _content_container.get_children():
			child.queue_free()
		if tab_index != -1:
			tab_selected.emit(tab_index)
			_scroll_container.scroll_vertical = 0
		queue_redraw()

func add_tab(new_name: String) -> void:
	_tab_names.append(new_name)
	queue_redraw()

func clear_all_tabs() -> void:
	_tab_names.clear()
	queue_redraw()

func get_tab_count() -> int:
	return _tab_names.size()


func _on_base_class_tab_selected(index: int) -> void:
	for child in _content_container.get_children():
		child.queue_free()
	if get_content_method.is_valid():
		_content_container.add_child(get_content_method.call(index))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		queue_redraw()
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			for tab_idx in get_tab_count():
				if _tab_rects[tab_idx].has_point(event.position):
					select_tab(tab_idx)
	elif ShortcutUtils.is_action_pressed(event, "ui_down" if side_tabs else "ui_right", true):
		grab_focus()
		select_tab(mini(current_tab_index + 1, get_tab_count() - 1))
		accept_event()
	elif ShortcutUtils.is_action_pressed(event, "ui_up" if side_tabs else "ui_left", true):
		grab_focus()
		select_tab(maxi(current_tab_index - 1, 0))
		accept_event()
