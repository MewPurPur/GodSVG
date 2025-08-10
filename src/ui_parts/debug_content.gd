extends VBoxContainer

@onready var debug_label: Label = $DebugLabel
@onready var input_debug_label: Label = $InputDebugLabel

func _ready() -> void:
	State.show_debug_changed.connect(_on_show_debug_changed)
	_on_show_debug_changed()
	get_window().window_input.connect(_update_input_debug)

func _on_show_debug_changed() -> void:
	if State.show_debug:
		show()
		update_debug()
		input_debug_label.text = ""
	else:
		hide()

# The strings here are intentionally not localized.
func update_debug() -> void:
	var debug_text := ""
	debug_text += "FPS: %d\n" % Performance.get_monitor(Performance.TIME_FPS)
	debug_text += "Static Mem: %s\n" % String.humanize_size(int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	debug_text += "Nodes: %d\n" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	debug_text += "Stray nodes: %d\n" % Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	debug_text += "Objects: %d\n" % Performance.get_monitor(Performance.OBJECT_COUNT)
	debug_label.text = debug_text
	# Set up the next update if the container is still visible.
	if visible:
		get_tree().create_timer(1.0).timeout.connect(update_debug)

var last_event_text := ""
var last_event_repeat_count := 1

func _update_input_debug(event: InputEvent) -> void:
	if visible and event.is_pressed():
		var new_text := input_debug_label.text
		var event_text := event.as_text()
		if event is InputEventMouse:
			event_text += " (" + String.num(event.position.x, 2) + ", " + String.num(event.position.y, 2) + ")"
		if event_text == last_event_text:
			last_event_repeat_count += 1
			new_text = new_text.left(new_text.rfind("\n", new_text.length() - 2) + 1)
			event_text += " (%d)" % last_event_repeat_count
		else:
			last_event_text = event_text
			last_event_repeat_count = 1
		if new_text.count("\n") >= 5:
			new_text = new_text.right(-new_text.find("\n") - 1)
		new_text += event_text + "\n"
		input_debug_label.text = new_text
