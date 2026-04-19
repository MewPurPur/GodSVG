extends Control

# TODO look into why load() is needed to not get a warning that leads to errors later on.
# "Parse Error: [ext_resource] referenced non-existent resource at: res://src/ui_widgets/color_edit.tscn"
var ColorConfigurationPopupScene = load("res://src/ui_widgets/color_configuration_popup.tscn")
const ColorConfigurationPopup = preload("res://src/ui_widgets/color_configuration_popup.gd")

const checkerboard = preload("res://assets/icons/Checkerboard.svg")
const gear_icon = preload("res://assets/icons/GearOutlined.svg")
const plus_icon = preload("res://assets/icons/Plus.svg")

const SWATCH_SIZE = 22.0
const SEPARATION = 3.0

signal swatch_selected(index: int)
signal visible_focus_changed

var ci := get_canvas_item()
var surfaces: Array[RID] = []

@export var configuration_mode := false
var palette: Palette  # If it's a mock palette, the variables below are used.
var fake_color_names: PackedStringArray
var fake_colors: PackedStringArray
var fake_reserved_paints: Dictionary[int, Color]
var fake_reserved_textures: Dictionary[int, DPITexture]

var hover_index := -1:
	set(new_value):
		if hover_index != new_value:
			hover_index = new_value
			queue_redraw()
var pressed_index := -1
var focus_index := -1:
	set(new_value):
		if focus_index != new_value:
			focus_index = new_value
			queue_redraw()
var current_value := "":
	set(new_value):
		if current_value != new_value:
			current_value = new_value
			queue_redraw()

func setup(new_palette: Palette, new_current_value := "") -> void:
	palette = new_palette
	palette.layout_changed.connect(unfocus)
	palette.changed_deferred.connect(queue_redraw)
	current_value = new_current_value

func setup_fake(new_color_names: PackedStringArray, new_colors: PackedStringArray,
new_reserved_paints: Dictionary[int, Color], new_reserved_textures: Dictionary[int, DPITexture], new_current_value := "") -> void:
	fake_color_names = new_color_names
	fake_colors = new_colors
	fake_reserved_paints = new_reserved_paints
	fake_reserved_textures = new_reserved_textures
	current_value = new_current_value

func _ready() -> void:
	mouse_exited.connect(_on_mouse_exited)
	focus_exited.connect(unfocus)
	focus_entered.connect(_on_focus_entered)
	swatch_selected.connect(_on_swatch_selected)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var index := get_index_at_pos(event.position)
			if event.is_pressed() and index != -1 and index < get_color_count():
				pressed_index = index
				focus_index = index
				grab_focus(true)
			elif event.is_pressed() and configuration_mode and get_index_rect(get_color_count()).has_point(event.position):
				pressed_index = get_color_count()
				focus_index = get_color_count()
				grab_focus(true)
			elif event.is_released() and pressed_index == get_color_count():
				popup_add_color()
				pressed_index = -1
			elif event.is_released() and pressed_index != -1 and (configuration_mode or not (current_value.is_empty() or\
			ColorParser.are_colors_same(ColorParser.add_hash_if_hex(get_color(index)), current_value))):
				if index == pressed_index:
					swatch_selected.emit(index)
				pressed_index = -1
	
	# TODO 4.7 Use _get_cursor_shape().
	if event is InputEventMouseButton or (event is InputEventMouseMotion and event.button_mask == 0):
		if event.button_mask == 0:
			var index := get_index_at_pos(event.position)
			if (get_index_at_pos(event.position) == -1 and not (configuration_mode and get_index_rect(get_color_count()).has_point(event.position))) or\
			(not current_value.is_empty() and ColorParser.are_colors_same(ColorParser.add_hash_if_hex(get_color(index)), current_value)):
				mouse_default_cursor_shape = Control.CURSOR_ARROW
			else:
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	if event is InputEventMouse:
		hover_index = get_index_at_pos(event.position)
		queue_redraw()
	
	if ShortcutUtils.is_action_pressed(event, "ui_left", true):
		if has_focus(true) and focus_index > 0:
			focus_index -= 1
		grab_focus()
		visible_focus_changed.emit()
		accept_event()
	elif ShortcutUtils.is_action_pressed(event, "ui_right", true):
		if has_focus(true) and (focus_index < get_color_count() - 1 or\
		(configuration_mode and focus_index < get_color_count())):
			focus_index += 1
		grab_focus()
		visible_focus_changed.emit()
		accept_event()
	elif ShortcutUtils.is_action_pressed(event, "ui_up", true):
		var column_count := get_column_count()
		if has_focus(true) and focus_index >= column_count:
			focus_index -= column_count
		grab_focus()
		visible_focus_changed.emit()
		accept_event()
	elif ShortcutUtils.is_action_pressed(event, "ui_down", true):
		var column_count := get_column_count()
		if has_focus(true) and (focus_index < get_color_count() - column_count or\
		(configuration_mode and focus_index < get_color_count() - column_count + 1)):
			focus_index += column_count
		grab_focus()
		visible_focus_changed.emit()
		accept_event()
	elif ShortcutUtils.is_action_pressed(event, "ui_accept", true):
		if has_focus(true):
			if focus_index == get_color_count():
				popup_add_color()
			else:
				swatch_selected.emit(focus_index)
		accept_event()

func _draw() -> void:
	var normal_sb := get_theme_stylebox("swatch_normal", "PalettePreview")
	var mouse_pos := get_local_mouse_position()
	
	if has_focus(true):
		get_theme_stylebox("focus", "PalettePreview").draw(ci, Rect2(Vector2.ZERO, size))
	
	for index in get_color_count():
		var rect := get_index_rect(index)
		var color := get_color(index)
		
		if not has_focus(true):
			if not current_value.is_empty() and ColorParser.are_colors_same(ColorParser.add_hash_if_hex(color), current_value):
				get_theme_stylebox("swatch_selected", "PalettePreview").draw(ci, rect)
			elif hover_index == index:
				if index == pressed_index:
					get_theme_stylebox("swatch_selected", "PalettePreview").draw(ci, rect)
				else:
					get_theme_stylebox("swatch_hover", "PalettePreview").draw(ci, rect)
			else:
				normal_sb.draw(ci, rect)
		
		if has_focus(true) and index == focus_index or (is_instance_valid(proposed_drop_data) and index == proposed_drop_data.index):
			get_theme_stylebox("swatch_focus", "PalettePreview").draw(ci, rect)
		
		var inner_rect := rect.grow(-2)
		if fake_reserved_textures.has(index):
			fake_reserved_textures[index].draw_rect(ci, inner_rect, false)
		else:
			var parsed_color: Color
			if fake_reserved_paints.has(index):
				parsed_color = fake_reserved_paints[index]
			else:
				parsed_color = ColorParser.text_to_color(color, Color.BLACK, true)
			
			if parsed_color.a != 1:
				draw_texture_rect(checkerboard, inner_rect, false)
			if parsed_color.a != 0:
				draw_rect(inner_rect, parsed_color)
		
		if configuration_mode and Rect2(Vector2.ZERO, size).has_point(mouse_pos):
			# Draw the gear icon. Configuration mode will always have a real palette, so it's safe.
			if not is_instance_valid(proposed_drop_data) or proposed_drop_data.palette != palette:
				if hover_index == index:
					gear_icon.draw(ci, rect.position + (rect.size - gear_icon.get_size()) / 2)
				continue
			
			if is_instance_valid(proposed_drop_data) and not proposed_drop_data.index in [proposed_drop_index - 1, proposed_drop_index]:
				# Draw the drag-and-drop indicator.
				var drop_sb: StyleBoxFlat
				if proposed_drop_index == index:
					drop_sb = StyleBoxFlat.new()
					drop_sb.border_width_left = 2
				elif proposed_drop_index == index + 1:
					drop_sb = StyleBoxFlat.new()
					drop_sb.border_width_right = 2
				if is_instance_valid(drop_sb):
					drop_sb.draw_center = false
					drop_sb.border_color = Configs.savedata.basic_color_valid
					drop_sb.set_corner_radius_all(3)
					drop_sb.draw(ci, rect)
	
	if configuration_mode:
		var rect := get_index_rect(palette.get_color_count())
		var icon_theming := "icon_normal_color"
		if hover_index == palette.get_color_count():
			if pressed_index == palette.get_color_count():
				get_theme_stylebox("swatch_selected", "PalettePreview").draw(ci, rect)
				icon_theming = "icon_pressed_color"
			else:
				get_theme_stylebox("swatch_hover", "PalettePreview").draw(ci, rect)
				icon_theming = "icon_hover_color"
		else:
			normal_sb.draw(ci, rect)
		plus_icon.draw(ci, rect.position + (rect.size - plus_icon.get_size()) / 2, get_theme_color(icon_theming, "Button"))
		if has_focus(true) and focus_index == palette.get_color_count():
			get_theme_stylebox("swatch_focus", "PalettePreview").draw(ci, rect)
	
	custom_minimum_size.y = get_index_rect(get_color_count() - 1).end.y

func _get_tooltip(at_position: Vector2) -> String:
	var index := get_index_at_pos(at_position)
	if index == -1:
		return ""
	return String.num_int64(index)

func _make_custom_tooltip(for_text: String) -> Object:
	if for_text.is_empty():
		return null
	var index := for_text.to_int()
	
	var rtl := RichTextLabel.new()
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	rtl.fit_content = true
	rtl.bbcode_enabled = true
	rtl.add_theme_font_override("mono_font", ThemeUtils.mono_font)
	# Set up the text.
	var color_name := get_color_name(index)
	if not color_name.is_empty():
		rtl.add_text(color_name)
		rtl.newline()
	rtl.push_mono()
	rtl.add_text(get_color(index))
	return rtl

func _on_mouse_exited() -> void:
	hover_index = -1
	queue_redraw()

func _get_minimum_size() -> Vector2:
	return Vector2(SWATCH_SIZE, SWATCH_SIZE)


func get_column_count() -> int:
	return floori((size.x + SEPARATION) / (SWATCH_SIZE + SEPARATION))

func get_index_rect(index: int) -> Rect2:
	var column_count := get_column_count()
	if column_count <= 0:
		return Rect2()
	return Rect2((SWATCH_SIZE + SEPARATION) * (index % column_count), (SWATCH_SIZE + SEPARATION) * (index / column_count), SWATCH_SIZE, SWATCH_SIZE)

func get_index_at_pos(pos: Vector2) -> int:
	var posmod_vec := pos.posmod(SWATCH_SIZE + SEPARATION)
	if posmod_vec.x > SWATCH_SIZE or posmod_vec.y > SWATCH_SIZE:
		return -1
	var index := floori(pos.y / (SWATCH_SIZE + SEPARATION)) * get_column_count() + floori(pos.x / (SWATCH_SIZE + SEPARATION))
	if index >= get_color_count():
		return -1
	return index


# Drag and drop logic.

var proposed_drop_index := -1
var proposed_drop_data: DragData

class DragData:
	var palette: Palette
	var index: int
	
	func _init(new_palette: Palette, new_index: int) -> void:
		palette = new_palette
		index = new_index

func _get_drag_data(at_position: Vector2) -> Variant:
	if not configuration_mode:
		return null
	var index := get_index_at_pos(at_position)
	if index == -1:
		return null
	
	var data := DragData.new(palette, index)
	proposed_drop_data = data
	# Set up a preview.
	var preview := Button.new()
	preview.add_theme_stylebox_override("normal", get_theme_stylebox("swatch_normal", "PalettePreview"))
	preview.custom_minimum_size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
	var color_rect := ColorRect.new()
	color_rect.color = palette.get_color(index)
	color_rect.position = Vector2(2, 2)
	color_rect.size = Vector2(SWATCH_SIZE - 4, SWATCH_SIZE - 4)
	preview.add_child(color_rect)
	preview.custom_minimum_size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)
	queue_redraw()
	return data

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		proposed_drop_data = null
		queue_redraw()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not (data is DragData and Rect2(Vector2.ZERO, size).has_point(at_position)):
		proposed_drop_index = -1
		proposed_drop_data = null
		queue_redraw()
		return false
	proposed_drop_index = get_drop_index_at(at_position)
	return data.palette == palette

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	pressed_index = -1
	if proposed_drop_index == -1:
		return
	
	if data.palette == palette:
		focus_index = proposed_drop_index
		palette.move_color(data.index, proposed_drop_index)
	else:
		focus_index = -1
		palette.insert_color(proposed_drop_index, data.palette.get_color(data.index), data.palette.get_color_name(data.index))
		data.palette.remove_color(data.index)

func get_drop_index_at(pos: Vector2) -> int:
	var drop_coordinate := (pos + Vector2(SWATCH_SIZE / 2 + SEPARATION / 2, SEPARATION / 2)) / (SWATCH_SIZE + SEPARATION)
	return floori(drop_coordinate.y) * get_column_count() + floori(drop_coordinate.x)


func _on_swatch_selected(index: int) -> void:
	if configuration_mode:
		var rect := get_index_rect(index)
		var configure_popup: ColorConfigurationPopup = ColorConfigurationPopupScene.instantiate()
		configure_popup.palette = palette
		configure_popup.index = index
		HandlerGUI.popup_under_rect_center(configure_popup, Rect2(global_position + rect.position, rect.size), get_viewport())

func popup_add_color() -> void:
	var new_index := palette.get_color_count()
	var rect := get_index_rect(new_index)
	palette.add_new_color()
	focus_index = new_index
	var configure_popup: ColorConfigurationPopup = ColorConfigurationPopupScene.instantiate()
	configure_popup.palette = palette
	configure_popup.index = new_index
	HandlerGUI.popup_under_rect_center(configure_popup, Rect2(global_position + rect.position, rect.size), get_viewport())

func unfocus() -> void:
	focus_index = -1

func _on_focus_entered() -> void:
	focus_index = 0
	visible_focus_changed.emit()


func get_color(index: int) -> String:
	if is_instance_valid(palette):
		return palette.get_color(index)
	return fake_colors[index]

func get_color_name(index: int) -> String:
	if is_instance_valid(palette):
		return palette.get_color_name(index)
	return fake_color_names[index]

func get_color_count() -> int:
	if is_instance_valid(palette):
		return palette.get_color_count()
	return fake_colors.size()
