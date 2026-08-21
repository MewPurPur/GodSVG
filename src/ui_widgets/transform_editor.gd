extends PanelContainer

# Very reliant on the transform popup. But that's fine, this isn't intended to be used elsewhere.

signal focused

var transform: Transform

@onready var transform_list: VBoxContainer = $TransformList
@onready var transform_button: Button = $TransformList/TopButton

var _fields: Array[BetterLineEdit]

func setup(new_transform: Transform, new_fields: Array[BetterLineEdit]) -> void:
	transform = new_transform
	transform_button.text = transform.name
	_fields = new_fields
	var transform_fields := HBoxContainer.new()
	transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
	match transform.name:
		"matrix":
			transform_fields.add_child(_fields[0])
			transform_fields.add_child(_fields[2])
			transform_fields.add_child(_fields[4])
			var transform_fields_additional := HBoxContainer.new()
			transform_fields_additional.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields_additional.add_child(_fields[1])
			transform_fields_additional.add_child(_fields[3])
			transform_fields_additional.add_child(_fields[5])
			transform_list.add_child(transform_fields)
			transform_list.add_child(transform_fields_additional)
		"translate":
			transform_fields.add_child(_fields[0])
			transform_fields.add_child(_fields[1])
			transform_list.add_child(transform_fields)
		"rotate":
			transform_fields.add_child(_fields[0])
			transform_fields.add_child(_fields[1])
			transform_fields.add_child(_fields[2])
			transform_list.add_child(transform_fields)
		"scale":
			transform_fields.add_child(_fields[0])
			transform_fields.add_child(_fields[1])
			transform_list.add_child(transform_fields)
		"skewX":
			transform_fields.add_child(_fields[0])
			transform_list.add_child(transform_fields)
		"skewY":
			transform_fields.add_child(_fields[0])
			transform_list.add_child(transform_fields)
	
	for field in _fields:
		field.set_value(transform.get(field.tooltip_text), true)  # "Clean code" is a sham.
		field.focus_entered.connect(reset_field_color.bind(field))
		field.focus_entered.connect(focused.emit)
		field.focus_exited.connect(setup_field_defaults_and_colors)
	setup_field_defaults_and_colors()
	
	transform_button.focus_entered.connect(focused.emit)
	
	var focus_sequence: Array[Control] = [transform_button]
	focus_sequence.append_array(_fields)
	HandlerGUI.register_focus_sequence(self, focus_sequence)

func resync(new_transform: Transform) -> void:
	transform = new_transform
	for field in _fields:
		field.set_value(transform.get(field.tooltip_text), true)
	setup_field_defaults_and_colors()

func grab_focus_override(hide_focus := true) -> void:
	transform_button.grab_focus(hide_focus)

func has_focus_override(ignore_hidden_focus := false) -> void:
	transform_button.has_focus(ignore_hidden_focus)

func setup_field_defaults_and_colors() -> void:
	update_title_font_color()
	match transform.name:
		"translate":
			_fields[1].default = 0
			determine_field_font_color(_fields[1], transform.y == 0)
		"rotate":
			determine_field_font_color(_fields[1], transform.x == 0 and transform.y == 0)
			determine_field_font_color(_fields[2], transform.x == 0 and transform.y == 0)
		"scale":
			_fields[1].default = transform.x
			determine_field_font_color(_fields[1], transform.x == transform.y)

func determine_field_font_color(field: BetterLineEdit, omit: bool) -> void:
	if omit:
		field.add_theme_color_override("font_color", Color(field.get_theme_color("font_color"), 2/3.0))
	else:
		reset_field_color(field)

func reset_field_color(field: BetterLineEdit) -> void:
	field.remove_theme_color_override("font_color")

func update_title_font_color() -> void:
	if transform.is_redundant():
		transform_button.add_theme_color_override("font_color", Color(transform_button.get_theme_color("font_color"), 2/3.0))
	else:
		transform_button.remove_theme_color_override("font_color")
