extends VBoxContainer

@onready var drag_handle: TextureRect = $PanelContainer/HBoxContainer/DragHandle
@onready var undo_button: Button = $PanelContainer/HBoxContainer/Undo
@onready var redo_button: Button = $PanelContainer/HBoxContainer/Redo
@onready var delete_button: Button = $PanelContainer/HBoxContainer/Delete
@onready var save_button: Button = $PanelContainer/HBoxContainer/Save

var dragging := false
var drag_offset := Vector2.ZERO

func _ready() -> void:
	drag_handle.gui_input.connect(_on_drag_handle_gui_input)
	undo_button.pressed.connect(simulate_action.bind("undo"))
	redo_button.pressed.connect(simulate_action.bind("redo"))
	delete_button.pressed.connect(simulate_action.bind("delete"))
	save_button.pressed.connect(simulate_action.bind("save"))

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

func simulate_action(action_name: String) -> void:
	var events := InputMap.action_get_events(action_name)
	for event in events:
		if event is InputEventKey:
			simulate_key_press(event.keycode, event.ctrl_pressed, event.shift_pressed, event.alt_pressed)
			return

func simulate_key_press(keycode: Key, ctrl := false, shift := false, alt := false) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.shift_pressed = shift
	event.alt_pressed = alt
	event.ctrl_pressed = ctrl
	Input.parse_input_event(event)
