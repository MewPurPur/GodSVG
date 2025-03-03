extends Control

const PreviewRectScene = preload("res://src/ui_widgets/preview_rect.tscn")

const plus_icon = preload("res://assets/icons/Plus.svg")
const close_icon = preload("res://assets/icons/Close.svg")
const scroll_forwards_icon = preload("res://assets/icons/ScrollForwards.svg")
const scroll_backwards_icon = preload("res://assets/icons/ScrollBackwards.svg")

const DEFAULT_TAB_WIDTH = 120.0
const MIN_TAB_WIDTH = 60.0
const CLOSE_BUTTON_MARGIN = 2

var ci := get_canvas_item()

var current_scroll := 0.0
var scrolling_backwards := false
var scrolling_forwards := false
var active_controls: Array[Control] = []

# Processing is enabled only when dragging.
var proposed_drop_idx := -1:
	set(new_value):
		if proposed_drop_idx != new_value:
			proposed_drop_idx = new_value
			queue_redraw()

func _exit_tree() -> void:
	RenderingServer.free_rid(ci)

func _ready() -> void:
	Configs.active_tab_changed.connect(activate)
	Configs.tabs_changed.connect(activate)
	Configs.active_tab_changed.connect(scroll_to_active)
	Configs.tabs_changed.connect(scroll_to_active)
	resized.connect(scroll_to_active)
	Configs.language_changed.connect(queue_redraw)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	set_process(false)

func _draw() -> void:
	var background_stylebox: StyleBoxFlat =\
			get_theme_stylebox("tab_unselected", "TabContainer").duplicate()
	background_stylebox.corner_radius_top_left += 1
	background_stylebox.corner_radius_top_right += 1
	background_stylebox.bg_color = Color(ThemeUtils.common_panel_inner_color, 0.4)
	draw_style_box(background_stylebox, get_rect())
	
	var has_transient_tab := not State.transient_tab_path.is_empty()
	var mouse_pos := get_local_mouse_position()
	
	for tab_index in Configs.savedata.get_tab_count() + 1:
		var drawing_transient_tab := (tab_index == Configs.savedata.get_tab_count())
		if drawing_transient_tab and not has_transient_tab:
			break
		
		var rect := get_tab_rect(tab_index)
		if not rect.has_area():
			continue
		
		var current_tab_name := State.transient_tab_path.get_file() if\
				drawing_transient_tab else Configs.savedata.get_tab(tab_index).presented_name
		if Configs.savedata.get_tab(tab_index).marked_unsaved:
			current_tab_name = "* " + current_tab_name
		
		if (has_transient_tab and drawing_transient_tab) or\
		(not has_transient_tab and tab_index == Configs.savedata.get_active_tab_index()):
			draw_style_box(get_theme_stylebox("tab_selected", "TabContainer"), rect)
			var text_line_width := rect.size.x - size.y
			if text_line_width > 0:
				var text_line := TextLine.new()
				text_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				text_line.add_string(current_tab_name, ThemeUtils.regular_font, 13)
				text_line.width = text_line_width
				text_line.draw(ci, rect.position + Vector2(4, 3),
						get_theme_color("font_selected_color", "TabContainer"))
			var close_rect := get_close_button_rect()
			if close_rect.has_area():
				var close_icon_size := close_icon.get_size()
				draw_texture_rect(close_icon, Rect2(close_rect.position +\
						(close_rect.size - close_icon_size) / 2.0, close_icon_size), false)
		else:
			var is_hovered := rect.has_point(mouse_pos)
			var tab_style := "tab_hovered" if is_hovered else "tab_unselected"
			draw_style_box(get_theme_stylebox(tab_style, "TabContainer"), rect)
			
			var text_line_width := rect.size.x - 8
			if text_line_width > 0:
				var text_color := get_theme_color("font_hovered_color" if is_hovered else\
						"font_unselected_color", "TabContainer")
				
				var text_line := TextLine.new()
				text_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				text_line.add_string(current_tab_name, ThemeUtils.regular_font, 13)
				text_line.width = text_line_width
				text_line.draw(ci, rect.position + Vector2(4, 3), text_color)
	
	var add_button_rect := get_add_button_rect()
	if add_button_rect.has_area():
		var plus_icon_size := plus_icon.get_size()
		draw_texture_rect(plus_icon, Rect2(add_button_rect.position +\
				(add_button_rect.size - plus_icon_size) / 2.0, plus_icon_size), false)
	
	var scroll_backwards_rect := get_scroll_backwards_area_rect()
	if scroll_backwards_rect.has_area():
		var scroll_backwards_icon_size := scroll_backwards_icon.get_size()
		var icon_modulate := Color.WHITE
		if is_scroll_backwards_disabled():
			icon_modulate = get_theme_color("icon_disabled_color", "Button")
		else:
			var line_x := scroll_backwards_rect.end.x + 1
			draw_line(Vector2(line_x, 0), Vector2(line_x, size.y),
					ThemeUtils.common_panel_border_color)
			if scroll_backwards_rect.has_point(mouse_pos):
				var stylebox_theme := "pressed" if\
						Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else "hover"
				get_theme_stylebox(stylebox_theme, "FlatButton").draw(ci,
						scroll_backwards_rect)
		draw_texture_rect(scroll_backwards_icon, Rect2(scroll_backwards_rect.position +\
				(scroll_backwards_rect.size - scroll_backwards_icon_size) / 2.0,
				scroll_backwards_icon_size), false, icon_modulate)
	
	var scroll_forwards_rect := get_scroll_forwards_area_rect()
	if scroll_forwards_rect.has_area():
		var scroll_forwards_icon_size := scroll_forwards_icon.get_size()
		var icon_modulate := Color.WHITE
		if is_scroll_forwards_disabled():
			icon_modulate = get_theme_color("icon_disabled_color", "Button")
		else:
			var line_x := scroll_forwards_rect.position.x
			draw_line(Vector2(line_x, 0), Vector2(line_x, size.y),
					ThemeUtils.common_panel_border_color)
			if scroll_forwards_rect.has_point(mouse_pos):
				var stylebox_theme := "pressed" if\
						Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else "hover"
				get_theme_stylebox(stylebox_theme, "FlatButton").draw(ci, scroll_forwards_rect)
		draw_texture_rect(scroll_forwards_icon, Rect2(scroll_forwards_rect.position +\
				(scroll_forwards_rect.size - scroll_forwards_icon_size) / 2.0,
				scroll_forwards_icon_size), false, icon_modulate)
	
	if proposed_drop_idx != -1:
		var prev_tab_rect := get_tab_rect(proposed_drop_idx - 1)
		var x_pos: float
		if prev_tab_rect.has_area():
			x_pos = prev_tab_rect.end.x
		else:
			x_pos = get_tab_rect(proposed_drop_idx).position.x
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, size.y),
				Configs.savedata.basic_color_valid, 4)


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	
	queue_redraw()
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]:
				scroll_backwards()
			if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT]:
				scroll_forwards()
			elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
				var hovered_idx := get_hovered_index()
				if hovered_idx != -1:
					if hovered_idx == Configs.savedata.get_active_tab_index():
						scroll_to_active()
					else:
						# Give time for deferred callbacks that might change the active SVG.
						Configs.savedata.set_active_tab_index.call_deferred(hovered_idx)
				if event.button_index == MOUSE_BUTTON_LEFT:
					var scroll_backwards_area_rect := get_scroll_backwards_area_rect()
					if scroll_backwards_area_rect.has_area() and\
					scroll_backwards_area_rect.has_point(event.position) and\
					not is_scroll_backwards_disabled():
						scrolling_backwards = true
						return
					
					var scroll_forwards_area_rect := get_scroll_forwards_area_rect()
					if scroll_forwards_area_rect.has_area() and\
					scroll_forwards_area_rect.has_point(event.position) and\
					not is_scroll_forwards_disabled():
						scrolling_forwards = true
					return
				
				var btn_arr: Array[Button] = []
				
				if hovered_idx == -1:
					btn_arr.append(ContextPopup.create_button(
							Translator.translate("Create tab"), Configs.savedata.add_empty_tab,
							false, load("res://assets/icons/CreateTab.svg"), "new_tab"))
				else:
					var new_active_tab := Configs.savedata.get_tab(hovered_idx)
					
					btn_arr.append(ContextPopup.create_button(
							Translator.translate("Close tab"),
							FileUtils.close_tabs.bind(hovered_idx), false, null, "close_tab"))
					# TODO Unify into "Close multiple tabs"
					btn_arr.append(ContextPopup.create_button(
							Translator.translate("Close all other tabs"),
							FileUtils.close_tabs.bind(hovered_idx,
							FileUtils.TabCloseMode.ALL_OTHERS),
							Configs.savedata.get_tab_count() < 2))
					btn_arr.append(ContextPopup.create_button(
							Translator.translate("Close tabs to the left"),
							FileUtils.close_tabs.bind(hovered_idx,
							FileUtils.TabCloseMode.TO_LEFT), hovered_idx == 0))
					btn_arr.append(ContextPopup.create_button(
							Translator.translate("Close tabs to the right"),
							FileUtils.close_tabs.bind(hovered_idx,
							FileUtils.TabCloseMode.TO_RIGHT),
							hovered_idx == Configs.savedata.get_tab_count() - 1))
					btn_arr.append(ContextPopup.create_button(
							Translator.translate("Open externally"),
							ShortcutUtils.fn("open_externally"),
							not FileAccess.file_exists(new_active_tab.svg_file_path),
							load("res://assets/icons/OpenFile.svg"), "open_externally"))
					btn_arr.append(ContextPopup.create_button(
							Translator.translate("Show in File Manager"),
							ShortcutUtils.fn("open_in_folder"),
							not FileAccess.file_exists(new_active_tab.svg_file_path),
							load("res://assets/icons/OpenFolder.svg"), "open_in_folder"))
				var tab_popup := ContextPopup.new()
				tab_popup.setup(btn_arr, true, -1, -1, PackedInt32Array([4]))
				
				if hovered_idx != -1:
					var tab_global_rect := get_tab_rect(hovered_idx)
					tab_global_rect.position += get_global_rect().position
					HandlerGUI.popup_under_rect(tab_popup, tab_global_rect, get_viewport())
				else:
					HandlerGUI.popup_under_pos(tab_popup, get_global_mouse_position(),
							get_viewport())
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			scrolling_backwards = false
			scrolling_forwards = false

# Autoscroll when the dragged tab is hovered beyond the tabs area.
func _process(_delta: float) -> void:
	var mouse_pos := get_local_mouse_position()
	var scroll_forwards_area_rect := get_scroll_forwards_area_rect()
	if ((scrolling_forwards and scroll_forwards_area_rect.has_point(mouse_pos)) or\
	(mouse_pos.x > size.x - get_add_button_rect().size.x -\
	scroll_forwards_area_rect.size.x)) and scroll_forwards_area_rect.has_area():
		scroll_forwards()
		return
	
	var scroll_backwards_area_rect := get_scroll_backwards_area_rect()
	if ((scrolling_backwards and scroll_backwards_area_rect.has_point(mouse_pos)) or\
	(mouse_pos.x < scroll_backwards_area_rect.size.x)) and\
	scroll_backwards_area_rect.has_area():
		scroll_backwards()
		return


func _on_mouse_entered() -> void:
	activate()

func _on_mouse_exited() -> void:
	cleanup()

func cleanup() -> void:
	for control in active_controls:
		control.queue_free()
	active_controls = []
	queue_redraw()


func scroll_backwards() -> void:
	set_scroll(current_scroll - 5.0)

func scroll_forwards() -> void:
	set_scroll(current_scroll + 5.0)

func scroll_to_active() -> void:
	var idx := Configs.savedata.get_active_tab_index()
	set_scroll(clampf(current_scroll, MIN_TAB_WIDTH * (idx + 1) -\
			size.x + get_add_button_rect().size.x + get_scroll_forwards_area_rect().size.x +\
			get_scroll_backwards_area_rect().size.x, MIN_TAB_WIDTH * idx))

func set_scroll(new_value: float) -> void:
	if get_scroll_limit() < 0:
		new_value = 0.0
	else:
		new_value = clampf(new_value, 0, get_scroll_limit())
	if current_scroll != new_value:
		current_scroll = new_value
		queue_redraw()
		activate()


func get_proper_tab_count() -> int:
	if State.transient_tab_path.is_empty():
		return Configs.savedata.get_tab_count()
	return Configs.savedata.get_tab_count() + 1

func get_tab_rect(idx: int) -> Rect2:
	# Things that can take space.
	var add_button_width := get_add_button_rect().size.x
	var scroll_backwards_button_width := get_scroll_backwards_area_rect().size.x
	var scroll_forwards_button_width := get_scroll_forwards_area_rect().size.x
	
	var left_limit := scroll_backwards_button_width
	var right_limit := size.x - add_button_width - scroll_forwards_button_width
	
	var tab_width := clampf((size.x - add_button_width - scroll_backwards_button_width -\
			scroll_forwards_button_width) / get_proper_tab_count(),
			MIN_TAB_WIDTH, DEFAULT_TAB_WIDTH)
	var unclamped_tab_start := tab_width * idx - current_scroll + left_limit
	var tab_start := clampf(unclamped_tab_start, left_limit, right_limit)
	var tab_end := clampf(unclamped_tab_start + tab_width, left_limit, right_limit)
	
	if tab_end <= tab_start:
		return Rect2()
	return Rect2(tab_start, 0, tab_end - tab_start, size.y)

func get_close_button_rect() -> Rect2:
	var tab_rect := get_tab_rect(Configs.savedata.get_active_tab_index() if\
			State.transient_tab_path.is_empty() else Configs.savedata.get_tab_count())
	var side := size.y - CLOSE_BUTTON_MARGIN * 2
	var left_coords := tab_rect.position.x + tab_rect.size.x - CLOSE_BUTTON_MARGIN - side
	if left_coords < get_scroll_backwards_area_rect().size.x or\
	tab_rect.size.x < size.y - CLOSE_BUTTON_MARGIN:
		return Rect2()
	return Rect2(left_coords, CLOSE_BUTTON_MARGIN, side, side)

func get_add_button_rect() -> Rect2:
	var tab_count := get_proper_tab_count()
	if tab_count >= SaveData.MAX_TABS:
		return Rect2()
	return Rect2(minf(DEFAULT_TAB_WIDTH * tab_count, size.x - size.y), 0, size.y, size.y)

func get_scroll_forwards_area_rect() -> Rect2:
	var add_button_width := get_add_button_rect().size.x
	if size.x - add_button_width > get_proper_tab_count() * MIN_TAB_WIDTH:
		return Rect2()
	var width := size.y / 1.5
	return Rect2(size.x - add_button_width - width, 0, width, size.y)

func is_scroll_forwards_disabled() -> bool:
	return current_scroll >= get_scroll_limit()

func get_scroll_backwards_area_rect() -> Rect2:
	if size.x - get_add_button_rect().size.x > get_proper_tab_count() * MIN_TAB_WIDTH:
		return Rect2()
	return Rect2(0, 0, size.y / 1.5, size.y)

func is_scroll_backwards_disabled() -> bool:
	return current_scroll <= 0.0

func get_scroll_limit() -> float:
	var add_button_width := get_add_button_rect().size.x
	var scroll_backwards_button_width := get_scroll_backwards_area_rect().size.x
	var scroll_forwards_button_width := get_scroll_forwards_area_rect().size.x
	
	var available_area := size.x - add_button_width - scroll_backwards_button_width -\
			scroll_forwards_button_width
	return clampf(available_area / get_proper_tab_count(),
			MIN_TAB_WIDTH, DEFAULT_TAB_WIDTH) * get_proper_tab_count() - available_area

func get_hovered_index() -> int:
	var mouse_pos := get_local_mouse_position()
	if get_close_button_rect().has_point(mouse_pos):
		return -1
	
	for idx in Configs.savedata.get_tab_count():
		if get_tab_rect(idx).has_point(mouse_pos):
			return idx
	return -1


func activate() -> void:
	cleanup()
	
	var close_rect := get_close_button_rect()
	if close_rect.has_area():
		var close_button := Button.new()
		close_button.theme_type_variation = "FlatButton"
		close_button.focus_mode = Control.FOCUS_NONE
		close_button.position = close_rect.position
		close_button.size = close_rect.size
		close_button.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(close_button)
		active_controls.append(close_button)
		close_button.pressed.connect(func() -> void:
				FileUtils.close_tabs(Configs.savedata.get_active_tab_index())
		)
	
	var add_rect := get_add_button_rect()
	if add_rect.has_area():
		var add_button := Button.new()
		add_button.theme_type_variation = "FlatButton"
		add_button.focus_mode = Control.FOCUS_NONE
		add_button.position = add_rect.position
		add_button.size = add_rect.size
		add_button.mouse_filter = Control.MOUSE_FILTER_PASS
		add_button.tooltip_text = Translator.translate("Create a new tab")
		add_child(add_button)
		active_controls.append(add_button)
		add_button.pressed.connect(Configs.savedata.add_empty_tab)


func _get_tooltip(at_position: Vector2) -> String:
	var hovered_tab_idx := get_tab_index_at(at_position)
	if hovered_tab_idx == -1:
		var backwards_area_rect := get_scroll_backwards_area_rect()
		if backwards_area_rect.has_area() and backwards_area_rect.has_point(at_position):
			return Translator.translate("Scroll backwards")
		
		var forwards_area_rect := get_scroll_forwards_area_rect()
		if forwards_area_rect.has_area() and forwards_area_rect.has_point(at_position):
			return Translator.translate("Scroll forwards")
		
		return ""
	
	var current_tab := Configs.savedata.get_tab(hovered_tab_idx)
	if current_tab.svg_file_path.is_empty():
		return Translator.translate("This SVG is not bound to a file location yet.")
	# We have to pass some metadata to the tooltip.
	# Since "*" isn't valid in filepaths, we use it as a delimiter.
	elif hovered_tab_idx == Configs.savedata.get_active_tab_index():
		return "%s*hovered" % current_tab.get_presented_svg_file_path()
	
	return "%s*%d" % [current_tab.get_presented_svg_file_path(), current_tab.id]

func _make_custom_tooltip(for_text: String) -> Object:
	var asterisk_pos := for_text.find("*")
	if asterisk_pos == -1:
		return null
	
	var path := for_text.left(asterisk_pos)
	var label := Label.new()
	label.add_theme_font_override("font", ThemeUtils.mono_font)
	label.add_theme_font_size_override("font_size", 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = path
	Utils.set_max_text_width(label, 192.0, 4.0)
	
	var metadata := for_text.right(-asterisk_pos - 1)
	if metadata == "hovered":
		return label
	
	var id := metadata.to_int()
	var margin_container := MarginContainer.new()
	var tooltip_panel_stylebox := get_theme_stylebox("panel", "TooltipPanel")
	margin_container.begin_bulk_theme_override()
	margin_container.add_theme_constant_override("margin_top",
			int(8 - tooltip_panel_stylebox.content_margin_top))
	margin_container.add_theme_constant_override("margin_bottom",
			int(8 - tooltip_panel_stylebox.content_margin_bottom))
	margin_container.add_theme_constant_override("margin_left",
			int(8 - tooltip_panel_stylebox.content_margin_left))
	margin_container.end_bulk_theme_override()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	var preview_rect := PreviewRectScene.instantiate()
	hbox.add_child(preview_rect)
	preview_rect.custom_minimum_size = Vector2(96, 96)
	preview_rect.size = Vector2.ZERO
	preview_rect.setup_svg_without_dimensions(FileAccess.get_file_as_string(
			TabData.get_edited_file_path_for_id(id)))
	preview_rect.shrink_to_fit(16, 16)
	hbox.add_child(label)
	margin_container.add_child(hbox)
	return margin_container


func get_tab_index_at(pos: Vector2) -> int:
	if not get_close_button_rect().has_point(pos):
		for tab_index in Configs.savedata.get_tab_count():
			var tab_rect := get_tab_rect(tab_index)
			if tab_rect.has_area() and tab_rect.has_point(pos):
				return tab_index
	return -1


class TabDropData extends RefCounted:
	var index := -1
	func _init(new_index: int) -> void:
		index = new_index

func get_drop_index_at(pos: Vector2) -> int:
	var add_button_width := get_add_button_rect().size.x
	var scroll_backwards_button_width := get_scroll_backwards_area_rect().size.x
	var scroll_forwards_button_width := get_scroll_forwards_area_rect().size.x
	
	if pos.x < scroll_backwards_button_width or\
	pos.x > size.x - scroll_forwards_button_width - add_button_width:
		return -1
	
	var first_tab_with_area := 0
	for idx in Configs.savedata.get_tab_count():
		if get_tab_rect(idx).has_area():
			first_tab_with_area = idx
			break
	
	var tab_width := clampf((size.x - add_button_width - scroll_backwards_button_width -\
			scroll_forwards_button_width) / get_proper_tab_count(),
			MIN_TAB_WIDTH, DEFAULT_TAB_WIDTH)
	
	for idx in range(first_tab_with_area, Configs.savedata.get_tab_count()):
		var tab_rect := get_tab_rect(idx)
		if not tab_rect.has_area() or tab_width * (idx + 0.5) - current_scroll +\
		scroll_backwards_button_width > pos.x:
			return idx
	return Configs.savedata.get_tab_count()

func _get_drag_data(at_position: Vector2) -> Variant:
	var tab_index_at_position := get_tab_index_at(at_position)
	if tab_index_at_position == -1:
		return
	
	var tab_width := get_tab_rect(tab_index_at_position).size.x
	# Roughly mimics the tab drawing.
	var preview := Panel.new()
	preview.modulate = Color(1, 1, 1, 0.85)
	preview.custom_minimum_size = Vector2(tab_width, size.y)
	preview.add_theme_stylebox_override("panel",
			get_theme_stylebox("tab_selected", "TabContainer"))
	var label := Label.new()
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = Configs.savedata.get_active_tab().presented_name
	preview.add_child(label)
	label.position = Vector2(4, 3)
	label.size.x = tab_width - 8
	
	set_drag_preview(preview)
	set_process(true)
	return TabDropData.new(tab_index_at_position)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is TabDropData:
		proposed_drop_idx = -1
		return false
	var current_drop_idx := get_drop_index_at(at_position)
	if current_drop_idx in [data.index, data.index + 1]:
		proposed_drop_idx = -1
		return false
	else:
		proposed_drop_idx = current_drop_idx
		return true

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not data is TabDropData:
		return
	set_process(false)
	Configs.savedata.move_tab(data.index, get_drop_index_at(at_position))

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		set_process(false)
		proposed_drop_idx = -1
