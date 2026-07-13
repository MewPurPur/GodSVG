# A popup for picking a path command in insertion context.
extends PanelContainer

const PathCommandButton = preload("res://src/ui_widgets/path_command_button.tscn")

signal path_command_picked(new_command: String)

var path_attribute: AttributePathdata

@onready var command_container: VBoxContainer = %CommandContainer
@onready var toggles_container: HBoxContainer = %TogglesContainer
@onready var relative_toggle: CheckButton = %TogglesContainer/RelativeToggle
@onready var keep_open_toggle: CheckButton = %TogglesContainer/KeepOpenToggle
@onready var margin_container: MarginContainer = $VBoxContainer/MarginContainer

func _ready() -> void:
	path_command_picked.connect(_on_path_command_picked.unbind(1), CONNECT_DEFERRED)
	relative_toggle.text = Translator.translate("Relative")
	relative_toggle.toggled.connect(_on_relative_toggle_toggled)
	relative_toggle.button_pressed = Configs.savedata.path_command_insert_relative
	sync_to_path_command_insert_relative()
	keep_open_toggle.text = Translator.translate("Keep open")
	keep_open_toggle.tooltip_text = Translator.translate("If toggled off, you must hold {keys} when selecting a path command to keep the popup open.").format(
			{"keys": "Shift/Ctrl"})
	keep_open_toggle.toggled.connect(_on_keep_open_toggle_toggled)
	keep_open_toggle.button_pressed = Configs.savedata.path_command_insert_keep_open


func setup(new_path_attribute: AttributePathdata) -> void:
	path_attribute = new_path_attribute
	if not is_node_ready():
		await ready
	reset()

func reset() -> void:
	for child in command_container.get_children():
		command_container.remove_child(child)
		child.queue_free()
	
	var index: int = State.inner_selections.max()
	var prev_command_char := path_attribute.get_command(index).command_char
	# Warn against invalid commands. Z can be syntactically invalid, so completely disallow it.
	# S commands are deliberately warned against in most cases, even though there is some sense in using them without a C or S command before them.
	# Same for T commands in most cases, even though there is a notion of letting them determine the next shorthand quadratic curve.
	# And M or Z commands after M commands are warned, there's no useful notion of using those.
	add_path_command_button("M", false, prev_command_char in "Mm" or (path_attribute.get_command_count() > index + 1 and\
			path_attribute.get_command(index + 1).command_char in "Zz"))
	add_path_command_button("L")
	add_path_command_button("H")
	add_path_command_button("V")
	add_path_command_button("Z", prev_command_char in "Zz" or (path_attribute.get_command_count() > index + 1 and\
			path_attribute.get_command(index + 1).command_char in "Zz"), prev_command_char in "Mm")
	add_path_command_button("A")
	add_path_command_button("Q")
	add_path_command_button("T", false, not prev_command_char in "QqTt")
	add_path_command_button("C")
	add_path_command_button("S", false, not prev_command_char in "CcSs")
	sync_to_path_command_insert_relative()
	
	var focus_sequence: Array[Control] = [relative_toggle]
	focus_sequence.append_array(command_container.get_children())
	HandlerGUI.register_focus_sequence(self, focus_sequence, true)

func add_path_command_button(command_char: String, is_disabled := false, is_warned := false) -> void:
	var path_command_button := PathCommandButton.instantiate()
	path_command_button.setup(command_char, is_disabled, is_warned)
	if not is_disabled:
		path_command_button.pressed_custom.connect(path_command_picked.emit)
	command_container.add_child(path_command_button)

func _on_relative_toggle_toggled(toggled_on: bool) -> void:
	Configs.savedata.path_command_insert_relative = toggled_on
	sync_to_path_command_insert_relative()

func _on_keep_open_toggle_toggled(toggled_on: bool) -> void:
	Configs.savedata.path_command_insert_keep_open = toggled_on


func sync_to_path_command_insert_relative() -> void:
	if command_container.get_child_count() > 0:
		for command_button in command_container.get_children():
			command_button.command_char = command_button.command_char.to_lower() if\
					Configs.savedata.path_command_insert_relative else command_button.command_char.to_upper()
			command_button.queue_redraw()
		# After the command button draws, we can make the toggles visible and ensure they aren't wider.
		keep_open_toggle.show.call_deferred()
		relative_toggle.show.call_deferred()
		sync_toggles_size.call_deferred()

func sync_toggles_size() -> void:
	margin_container.begin_bulk_theme_override()
	margin_container.add_theme_constant_override("margin_left", 4)
	margin_container.add_theme_constant_override("margin_right", 4)
	margin_container.end_bulk_theme_override()
	toggles_container.add_theme_constant_override("separation", 4)
	for toggle: CheckButton in [keep_open_toggle, relative_toggle]:
		toggle.begin_bulk_theme_override()
		toggle.remove_theme_font_size_override("font_size")
		toggle.remove_theme_constant_override("h_separation")
		toggle.end_bulk_theme_override()
	reset_size()
	
	var last_size := INF
	while size.x < last_size:
		last_size = size.x
		_resize_toggles(keep_open_toggle.get_theme_font_size("font_size") - 1)
	_resize_toggles(keep_open_toggle.get_theme_font_size("font_size") + 1)

func _resize_toggles(font_size: int) -> void:
	var base_font_size := ThemeDB.get_default_theme().get_font_size("font_size", "CheckButton")
	var base_h_separation := ThemeDB.get_default_theme().get_constant("h_separation", "CheckButton")
	var new_scale := float(font_size) / base_font_size
	var buffer_size := roundi(new_scale * 4)
	margin_container.begin_bulk_theme_override()
	margin_container.add_theme_constant_override("margin_left", buffer_size)
	margin_container.add_theme_constant_override("margin_right", buffer_size)
	margin_container.end_bulk_theme_override()
	toggles_container.add_theme_constant_override("separation", buffer_size)
	for toggle: CheckButton in [keep_open_toggle, relative_toggle]:
		toggle.begin_bulk_theme_override()
		toggle.add_theme_font_size_override("font_size", font_size)
		toggle.add_theme_constant_override("h_separation", roundi(base_h_separation * new_scale))
		toggle.end_bulk_theme_override()
	reset_size()


func _on_path_command_picked() -> void:
	if Configs.savedata.path_command_insert_keep_open or Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_SHIFT):
		reset()
	else:
		queue_free()
