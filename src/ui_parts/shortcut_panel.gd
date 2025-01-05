extends PanelContainer

enum Layout {HORIZONTAL_STRIP, HORIZONTAL_TWO_ROWS, VERTICAL_STRIP}

const ShortcutPanelConfig = preload("res://src/ui_parts/shortcut_panel_config.tscn")

const dot_pattern = preload("res://visual/icons/DotPatternSegment.svg")
const config_icon = preload("res://visual/icons/Config.svg")

# Where on the dotted pattern the dragging started.
var drag_offset := Vector2.ZERO

# This property is used to ensure that the panel stays in roughly the same position
# on the window when it resizes.
var position_window_relative: Vector2

func update_theme() -> void:
	var stylebox := get_theme_stylebox("panel", "DarkPanel").duplicate()
	stylebox.set_content_margin_all(0)
	add_theme_stylebox_override("panel", stylebox)

func set_position_absolute(new_position: Vector2) -> void:
	var usable_area_size := get_usable_area_size()
	position = new_position.clamp(Vector2.ZERO, usable_area_size)
	position_window_relative = position / usable_area_size

func set_position_relative(new_position: Vector2) -> void:
	var usable_area_size := get_usable_area_size()
	position_window_relative = new_position.clamp(Vector2.ZERO, usable_area_size)
	position = usable_area_size * position_window_relative

func _ready() -> void:
	Configs.theme_changed.connect(update_theme)
	Configs.shortcut_panel_changed.connect(update_layout)
	update_theme()
	update_layout()
	# Positioning callbacks and logic.
	get_window().size_changed.connect(sync_relative_position)
	resized.connect(sync_relative_position)
	match Configs.savedata.shortcut_panel_layout:
		Layout.HORIZONTAL_STRIP, Layout.HORIZONTAL_TWO_ROWS:
			set_position_relative(Vector2(0.5, 0.9))
		Layout.VERTICAL_STRIP:
			set_position_relative(Vector2(0.95, 0.9))

func update_layout() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	var main_container: BoxContainer
	match Configs.savedata.shortcut_panel_layout:
		Layout.HORIZONTAL_STRIP, Layout.HORIZONTAL_TWO_ROWS:
			main_container = HBoxContainer.new()
		Layout.VERTICAL_STRIP:
			main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 6)
	add_child(main_container)
	
	var drag_texture := TextureRect.new()
	drag_texture.stretch_mode = TextureRect.STRETCH_TILE
	drag_texture.texture = dot_pattern
	match Configs.savedata.shortcut_panel_layout:
		Layout.HORIZONTAL_STRIP:
			drag_texture.custom_minimum_size = Vector2(16, 24)
		Layout.HORIZONTAL_TWO_ROWS:
			drag_texture.custom_minimum_size = Vector2(16, 56)
		Layout.VERTICAL_STRIP:
			drag_texture.custom_minimum_size = Vector2(24, 16)
	
	var drag_handle := CenterContainer.new()
	drag_handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	match Configs.savedata.shortcut_panel_layout:
		Layout.HORIZONTAL_STRIP, Layout.HORIZONTAL_TWO_ROWS:
			drag_handle.custom_minimum_size.x = 30
		Layout.VERTICAL_STRIP:
			drag_handle.custom_minimum_size.y = 30
	drag_handle.gui_input.connect(_on_drag_handle_gui_input)
	drag_handle.add_child(drag_texture)
	main_container.add_child(drag_handle)
	
	var config_button := Button.new()
	config_button.theme_type_variation = "TranslucentButton"
	config_button.icon = config_icon
	config_button.focus_mode = Control.FOCUS_NONE
	config_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	config_button.mouse_filter = Control.MOUSE_FILTER_PASS
	config_button.custom_minimum_size = Vector2(30, 30)
	config_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	config_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	config_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	config_button.pressed.connect(_on_config_button_pressed)
	main_container.add_child(config_button)
	
	var margin_container := MarginContainer.new()
	margin_container.begin_bulk_theme_override()
	for margin in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin_container.add_theme_constant_override(margin, 4)
	margin_container.begin_bulk_theme_override()
	main_container.add_child(margin_container)
	
	if not Configs.savedata.get_shortcut_panel_slots().is_empty():
		var buttons_container: Container
		match Configs.savedata.shortcut_panel_layout:
			Layout.HORIZONTAL_STRIP:
				buttons_container = HBoxContainer.new()
			Layout.VERTICAL_STRIP:
				buttons_container = VBoxContainer.new()
			Layout.HORIZONTAL_TWO_ROWS:
				buttons_container = GridContainer.new()
				buttons_container.columns = ceili(SaveData.SHORTCUT_PANEL_MAX_SLOTS / 2.0)
		
		for i in range(SaveData.SHORTCUT_PANEL_MAX_SLOTS):
			var shortcut := Configs.savedata.get_shortcut_panel_slot(i)
			if not shortcut.is_empty():
				var button := Button.new()
				button.focus_mode = Control.FOCUS_NONE
				button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				button.mouse_filter = Control.MOUSE_FILTER_PASS
				button.custom_minimum_size = Vector2(30, 30)
				button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				button.icon = ShortcutUtils.get_shortcut_icon(shortcut)
				button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				buttons_container.add_child(button)
				button.pressed.connect(simulate_key_press.bind(shortcut))
		margin_container.add_child(buttons_container)
	reset_size()

func _on_drag_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.button_mask == MOUSE_BUTTON_LEFT:
		if event is InputEventMouseButton:
			drag_offset = event.position if event.is_pressed() else Vector2.ZERO
		elif event is InputEventMouseMotion:
			set_position_absolute(event.global_position - drag_offset)

func simulate_key_press(action_name: String) -> void:
	var events := InputMap.action_get_events(action_name)
	for event in events:
		if event is InputEventKey:
			event.pressed = true
			Input.parse_input_event(event)
			return

func _on_config_button_pressed() -> void:
	HandlerGUI.add_menu(ShortcutPanelConfig.instantiate())

func sync_relative_position() -> void:
	set_position_relative(position_window_relative)


func get_usable_area_size() -> Vector2:
	var window := get_window()
	return Vector2(window.size) * window.get_final_transform().affine_inverse() - size
