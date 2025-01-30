extends Control

const plus_icon = preload("res://assets/icons/Plus.svg")
const close_icon = preload("res://assets/icons/Close.svg")

const TAB_WIDTH = 120.0
const CLOSE_BUTTON_MARGIN = 2

var active_controls: Array[Control] = []

var proposed_drop_idx := -1:
	set(new_value):
		if proposed_drop_idx != new_value:
			proposed_drop_idx = new_value
			queue_redraw()

func _ready() -> void:
	Configs.active_tab_file_path_changed.connect(queue_redraw)
	Configs.active_tab_changed.connect(activate)
	Configs.tabs_changed.connect(activate)
	Configs.language_changed.connect(queue_redraw)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _draw() -> void:
	var background_stylebox: StyleBoxFlat =\
			get_theme_stylebox("tab_unselected", "TabContainer").duplicate()
	background_stylebox.corner_radius_top_left += 1
	background_stylebox.corner_radius_top_right += 1
	background_stylebox.bg_color = Color(ThemeUtils.common_panel_inner_color, 0.4)
	draw_style_box(background_stylebox, get_rect())
	
	for tab_index in Configs.savedata.get_tab_count() + 1:
		var has_transient_tab := not State.transient_tab_path.is_empty()
		var drawing_transient_tab := tab_index == Configs.savedata.get_tab_count()
		if drawing_transient_tab and not has_transient_tab:
			break
		
		var current_tab_name := State.transient_tab_path.get_file() if\
				drawing_transient_tab else Configs.savedata.get_tab(tab_index).get_presented_name()
		
		var rect := get_tab_rect(tab_index)
		var text_line := TextLine.new()
		text_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		text_line.add_string(current_tab_name, ThemeUtils.regular_font, 13)
		if (has_transient_tab and drawing_transient_tab) or\
		(not has_transient_tab and tab_index == Configs.savedata.get_active_tab_index()):
			var close_rect := get_close_button_rect()
			text_line.width = TAB_WIDTH - close_rect.size.x - CLOSE_BUTTON_MARGIN * 2 - 4
			draw_style_box(get_theme_stylebox("tab_selected", "TabContainer"), rect)
			text_line.draw(get_canvas_item(), rect.position + Vector2(4, 3))
			var close_icon_size := close_icon.get_size()
			draw_texture_rect(close_icon, Rect2(close_rect.position +\
					(close_rect.size - close_icon_size) / 2.0, close_icon_size), false)
		else:
			text_line.width = TAB_WIDTH - 8
			var is_hovered := rect.has_point(get_local_mouse_position())
			var tab_style := "tab_hovered" if is_hovered else "tab_unselected"
			var text_color := ThemeUtils.common_text_color if is_hovered else\
					(ThemeUtils.common_subtle_text_color + ThemeUtils.common_text_color) / 2
			draw_style_box(get_theme_stylebox(tab_style, "TabContainer"), rect)
			text_line.draw(get_canvas_item(), rect.position + Vector2(4, 3), text_color)
	if Configs.savedata.get_tab_count() < SaveData.MAX_TABS:
		var plus_rect := get_add_button_rect()
		var plus_icon_size := plus_icon.get_size()
		draw_texture_rect(plus_icon, Rect2(plus_rect.position +\
				(plus_rect.size - plus_icon_size) / 2.0, plus_icon_size), false)
	
	if proposed_drop_idx != -1:
		draw_line(Vector2(TAB_WIDTH * proposed_drop_idx, 0),
				Vector2(TAB_WIDTH * proposed_drop_idx, size.y),
				Configs.savedata.basic_color_valid, 4)


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	
	queue_redraw()
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			var hovered_idx := get_hovered_index()
			if hovered_idx != -1:
				Configs.savedata.set_active_tab_index(hovered_idx)
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				return
			
			var btn_arr: Array[Button] = []
			
			if hovered_idx == -1:
				btn_arr.append(ContextPopup.create_button(Translator.translate("Create tab"),
						Configs.savedata.add_empty_tab, false,
						load("res://assets/icons/CreateTab.svg"), "new_tab"))
			else:
				btn_arr.append(ContextPopup.create_button(Translator.translate("Close tab"),
						close_tab.bind(hovered_idx), false, null, "close_tab"))
				# TODO Unify into "Close multiple tabs"
				btn_arr.append(ContextPopup.create_button(
						Translator.translate("Close all other tabs"),
						close_other_tabs.bind(hovered_idx),
						Configs.savedata.get_tab_count() == 1, null))
				btn_arr.append(ContextPopup.create_button(
						Translator.translate("Close tabs to the left"),
						close_tabs_to_left.bind(hovered_idx), hovered_idx == 0, null))
				btn_arr.append(ContextPopup.create_button(
						Translator.translate("Close tabs to the right"),
						close_tabs_to_right.bind(hovered_idx),
						hovered_idx == Configs.savedata.get_tab_count() - 1, null))
				btn_arr.append(ContextPopup.create_button(Translator.translate("Open externally"),
						ShortcutUtils.fn("open_externally"),
						not FileAccess.file_exists(Configs.savedata.get_active_tab().svg_file_path),
						load("res://assets/icons/OpenFile.svg"), "open_externally"))
				btn_arr.append(ContextPopup.create_button(Translator.translate("Show in File Manager"),
						ShortcutUtils.fn("open_in_folder"),
						not FileAccess.file_exists(Configs.savedata.get_active_tab().svg_file_path),
						load("res://assets/icons/OpenFolder.svg"), "open_in_folder"))
			var tab_popup := ContextPopup.new()
			tab_popup.setup(btn_arr, true, -1, -1, PackedInt32Array([4]))
			
			if hovered_idx != -1:
				var tab_global_rect := get_tab_rect(hovered_idx)
				tab_global_rect.position += get_global_rect().position
				HandlerGUI.popup_under_rect(tab_popup, tab_global_rect, get_viewport())
			else:
				HandlerGUI.popup_under_pos(tab_popup, get_global_mouse_position(), get_viewport())


func close_tab(idx: int) -> void:
	Configs.savedata.remove_tabs(PackedInt32Array([idx]))

func close_other_tabs(idx: int) -> void:
	Configs.savedata.remove_tabs(PackedInt32Array(range(0, idx) +\
			range(idx + 1, Configs.savedata.get_tab_count())))

func close_tabs_to_left(idx: int) -> void:
	Configs.savedata.remove_tabs(PackedInt32Array(range(0, idx)))

func close_tabs_to_right(idx: int) -> void:
	Configs.savedata.remove_tabs(PackedInt32Array(
			range(idx + 1, Configs.savedata.get_tab_count())))


func _on_mouse_entered() -> void:
	activate()

func _on_mouse_exited() -> void:
	cleanup()

func cleanup() -> void:
	for control in active_controls:
		control.queue_free()
	active_controls = []
	queue_redraw()


func get_tab_rect(idx: int) -> Rect2:
	return Rect2(TAB_WIDTH * idx, 0, TAB_WIDTH, size.y)

func get_close_button_rect() -> Rect2:
	var active_index := Configs.savedata.get_active_tab_index() if\
			State.transient_tab_path.is_empty() else Configs.savedata.get_tab_count()
	var side := size.y - CLOSE_BUTTON_MARGIN * 2
	return Rect2(TAB_WIDTH * (active_index + 1) - CLOSE_BUTTON_MARGIN - side,
			CLOSE_BUTTON_MARGIN, side, side)

func get_add_button_rect() -> Rect2:
	var tab_count := Configs.savedata.get_tab_count()
	if not State.transient_tab_path.is_empty():
		tab_count += 1
	return Rect2(TAB_WIDTH * tab_count, 0, size.y, size.y)

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
	var close_button := Button.new()
	close_button.theme_type_variation = "FlatButton"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.position = close_rect.position
	close_button.size = close_rect.size
	close_button.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(close_button)
	active_controls.append(close_button)
	close_button.pressed.connect(Configs.savedata.remove_active_tab)
	
	if Configs.savedata.get_tab_count() >= SaveData.MAX_TABS:
		return
	
	var add_rect := get_add_button_rect()
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
		return ""
	
	var current_tab := Configs.savedata.get_tab(hovered_tab_idx)
	if current_tab.svg_file_path.is_empty():
		return Translator.translate(
				"This SVG is not bound to a location on the computer yet.")
	return current_tab.svg_file_path


func get_tab_index_at(pos: Vector2) -> int:
	if not get_close_button_rect().has_point(pos):
		for tab_index in Configs.savedata.get_tab_count():
			if get_tab_rect(tab_index).has_point(pos):
				return tab_index
	return -1


class TabDropData extends RefCounted:
	var index := -1
	func _init(new_index: int) -> void:
		index = new_index

func get_drop_index_at(pos: Vector2) -> int:
	for idx in Configs.savedata.get_tab_count():
		if get_tab_rect(idx).get_center().x > pos.x:
			return idx
	return Configs.savedata.get_tab_count()

func _get_drag_data(at_position: Vector2) -> Variant:
	var tab_index_at_position := get_tab_index_at(at_position)
	if tab_index_at_position == -1:
		return
	# Roughly mimics the tab drawing.
	var preview := Panel.new()
	preview.modulate = Color(1, 1, 1, 0.85)
	preview.custom_minimum_size = Vector2(TAB_WIDTH, size.y)
	preview.add_theme_stylebox_override("panel",
			get_theme_stylebox("tab_selected", "TabContainer"))
	var label := Label.new()
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 13)
	label.text = Configs.savedata.get_active_tab().get_presented_name()
	preview.add_child(label)
	label.position = Vector2(4, 3)
	label.size.x = TAB_WIDTH - 8
	
	set_drag_preview(preview)
	return TabDropData.new(tab_index_at_position)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is TabDropData:
		proposed_drop_idx = -1
		return false
	var current_drop_idx = get_drop_index_at(at_position)
	if current_drop_idx in [data.index, data.index + 1]:
		proposed_drop_idx = -1
		return false
	else:
		proposed_drop_idx = current_drop_idx
		return true

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not data is TabDropData:
		return
	Configs.savedata.move_tab(data.index, get_drop_index_at(at_position))

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		proposed_drop_idx = -1
