extends VBoxContainer

@onready var drag_handle: TextureRect = $PanelContainer/HBoxContainer/DragHandle
@onready var shortcut_container: HBoxContainer = $PanelContainer/HBoxContainer/HBoxContainer
@onready var panel_container: PanelContainer = $PanelContainer

const PanelConfig = preload("res://src/ui_parts/shortcut_panel_config.tscn")

var dragging := false
var drag_offset := Vector2.ZERO

func update_theme() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(3)
	stylebox.set_content_margin_all(4)
	stylebox.content_margin_right = 8
	stylebox.bg_color = ThemeUtils.dark_panel_color
	panel_container.add_theme_stylebox_override("panel", stylebox)

func _ready() -> void:
	drag_handle.gui_input.connect(_on_drag_handle_gui_input)
	update_theme()
	update()

func update() -> void:
	for child in shortcut_container.get_children():
		child.queue_free()
	
	for i in range(5):
		var shortcut := Configs.savedata.get_shortcut_panel_presented_shortcut(i)
		if not shortcut.is_empty():
			add_new_shortcut(shortcut)
	panel_container.reset_size()

func add_new_shortcut(shortcut: String) -> void:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.custom_minimum_size = Vector2(30, 30)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.icon = ShortcutUtils.get_shortcut_icon(shortcut)
	shortcut_container.add_child(button)
	button.pressed.connect(simulate_key_press.bind(shortcut))

func _on_drag_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = event.position
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		position += event.relative

func simulate_key_press(action_name: String) -> void:
	var events := InputMap.action_get_events(action_name)
	for event in events:
		if event is InputEventKey:
			event.pressed = true
			Input.parse_input_event(event)
			return

func _on_panel_settings_pressed() -> void:
	HandlerGUI.add_menu(PanelConfig.instantiate())
