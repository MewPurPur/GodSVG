extends MarginContainer

var advanced_mode := false

@onready var debug_label: Label = $DebugContainer/DebugLabel
@onready var input_debug_label: Label = $DebugContainer/InputDebugLabel
@onready var debug_container: VBoxContainer = $DebugContainer

func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("debug", toggle_debug)
	shortcuts.add_shortcut("advanced_debug", toggle_debug.bind(true))
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	set_debug_visibility(false)
	get_window().window_input.connect(_update_input_debug)

func toggle_debug(advanced := false) -> void:
	if advanced and not advanced_mode:
		advanced_mode = true
		set_debug_visibility(true)
	else:
		if not advanced:
			advanced_mode = false
		set_debug_visibility(not debug_container.visible)

func set_debug_visibility(visibility: bool) -> void:
	debug_container.visible = visibility
	if visible:
		input_debug_label.text = ""
		update_debug()

# The strings here are intentionally not localized.
func update_debug() -> void:
	var debug_text := ""
	debug_text += "FPS: %d\n" % Performance.get_monitor(Performance.TIME_FPS)
	debug_text += "Static Mem: %s\n" % String.humanize_size(int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	
	debug_text += "Objects: %d\n" % Performance.get_monitor(Performance.OBJECT_COUNT)
	debug_text += "Nodes: %d\n" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	debug_text += "Stray nodes: %d\n" % Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	
	if advanced_mode:
		debug_text += "Resources: %d\n" % Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
		debug_text += "Total Objects Drawn: %d\n" % Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		debug_text += "Total Primitives Drawn: %d\n" % Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		debug_text += "Total Draw Calls: %d\n" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		debug_text += "Video Mem: %s\n" % String.humanize_size(int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)))
		debug_text += "Texture Mem: %s\n" % String.humanize_size(int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)))
		debug_text += "Buffer Mem: %s\n" % String.humanize_size(int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)))
	
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
			event_text += " (" + Utils.num_simple(event.position.x, 2) + ", " + Utils.num_simple(event.position.y, 2) + ")"
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
