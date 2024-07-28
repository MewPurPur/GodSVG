extends PanelContainer

# Very reliant on the transform popup.
# But that's fine, this isn't intended to be used elsewhere.

var type: String
var transform: Transform

@onready var transform_list: VBoxContainer = $TransformList
@onready var transform_button: Button = $TransformList/TopButton

var _fields: Array[BetterLineEdit]

func setup(new_transform: Transform, new_fields: Array[BetterLineEdit]) -> void:
	transform = new_transform
	if transform is Transform.TransformMatrix:
		type = "matrix"
	elif transform is Transform.TransformTranslate:
		type = "translate"
	elif transform is Transform.TransformRotate:
		type = "rotate"
	elif transform is Transform.TransformScale:
		type = "scale"
	elif transform is Transform.TransformSkewX:
		type = "skewX"
	elif transform is Transform.TransformSkewY:
		type = "skewY"
	transform_button.text = type
	
	_fields = new_fields
	match type:
		"matrix":
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
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
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(_fields[0])
			transform_fields.add_child(_fields[1])
			transform_list.add_child(transform_fields)
		"rotate":
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(_fields[0])
			transform_fields.add_child(_fields[1])
			transform_fields.add_child(_fields[2])
			transform_list.add_child(transform_fields)
		"scale":
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(_fields[0])
			transform_fields.add_child(_fields[1])
			transform_list.add_child(transform_fields)
		"skewX":
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(_fields[0])
			transform_list.add_child(transform_fields)
		"skewY":
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(_fields[0])
			transform_list.add_child(transform_fields)
	
	for field in _fields:
		field.set_value(transform.get(field.tooltip_text), true)  # "Clean code" is a sham.
		field.focus_entered.connect(reset_field_color.bind(field))
		field.focus_exited.connect(setup_field_colors)
	setup_field_colors()

func resync(new_transform: Transform) -> void:
	transform = new_transform
	for field in _fields:
		field.set_value(transform.get(field.tooltip_text), true)
	setup_field_colors()

func setup_field_colors() -> void:
	match type:
		"translate":
			determine_field_font_color(_fields[1], transform.y == 0)
		"rotate":
			determine_field_font_color(_fields[1], transform.x == 0 and transform.y == 0)
			determine_field_font_color(_fields[2], transform.x == 0 and transform.y == 0)
		"scale":
			determine_field_font_color(_fields[1], transform.x == transform.y)

func determine_field_font_color(field: BetterLineEdit, omit: bool) -> void:
	if omit:
		field.add_theme_color_override("font_color",
				Color(field.get_theme_color("font_color"), 2/3.0))
	else:
		reset_field_color(field)

func reset_field_color(field: BetterLineEdit) -> void:
	field.remove_theme_color_override("font_color")
