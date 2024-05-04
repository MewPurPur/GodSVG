# A popup for editing a transform list.
extends PanelContainer

const DEFAULT_VALUE_OPACITY = 2/3.0

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")

const MiniNumberField = preload("res://src/ui_elements/mini_number_field.tscn")
const TransformEditor = preload("res://src/ui_elements/transform_editor.tscn")
const code_font = preload("res://visual/fonts/FontMono.ttf")

const icons_dict := {
	"matrix": preload("res://visual/icons/Matrix.svg"),
	"translate": preload("res://visual/icons/Translate.svg"),
	"rotate": preload("res://visual/icons/Rotate.svg"),
	"scale": preload("res://visual/icons/Scale.svg"),
	"skewX": preload("res://visual/icons/SkewX.svg"),
	"skewY": preload("res://visual/icons/SkewY.svg"),
}

var attribute_ref: AttributeTransform
var UR := UndoRedo.new()

@onready var x1_edit: NumberEditType = %FinalMatrix/X1
@onready var x2_edit: NumberEditType = %FinalMatrix/X2
@onready var y1_edit: NumberEditType = %FinalMatrix/Y1
@onready var y2_edit: NumberEditType = %FinalMatrix/Y2
@onready var o1_edit: NumberEditType = %FinalMatrix/O1
@onready var o2_edit: NumberEditType = %FinalMatrix/O2
@onready var transform_list: VBoxContainer = %TransformList
@onready var add_button: Button = %AddButton
@onready var apply_matrix: Button = %ApplyMatrix

func _ready() -> void:
	add_button.pressed.connect(popup_new_transform_context.bind(0, add_button))
	apply_matrix.pressed.connect(_on_apply_matrix_pressed)
	rebuild()

func rebuild() -> void:
	var transform_count := attribute_ref.get_transform_count()
	# Sync until the first different transform type is found; then rebuild the rest.
	var i := 0
	for transform_editor in transform_list.get_children():
		if i >= transform_count:
			break
		var t := attribute_ref.get_transform(i)
		if t is AttributeTransform.TransformMatrix and transform_editor.type == "matrix":
			transform_editor.fields[0].set_value(t.x1, true)
			transform_editor.fields[1].set_value(t.x2, true)
			transform_editor.fields[2].set_value(t.y1, true)
			transform_editor.fields[3].set_value(t.y2, true)
			transform_editor.fields[4].set_value(t.o1, true)
			transform_editor.fields[5].set_value(t.o2, true)
		elif t is AttributeTransform.TransformTranslate and\
		transform_editor.type == "translate":
			transform_editor.fields[0].set_value(t.x, true)
			transform_editor.fields[1].set_value(t.y, true)
			if t.y == 0:
				transform_editor.fields[1].add_theme_color_override("font_color", Color(
						transform_editor.fields[1].get_theme_color("font_color"),
						DEFAULT_VALUE_OPACITY))
			else:
				transform_editor.fields[1].remove_theme_color_override("font_color")
		elif t is AttributeTransform.TransformRotate and transform_editor.type == "rotate":
			transform_editor.fields[0].set_value(t.deg, true)
			transform_editor.fields[1].set_value(t.x, true)
			transform_editor.fields[2].set_value(t.y, true)
			if t.x == 0 and t.y == 0:
				transform_editor.fields[1].add_theme_color_override("font_color", Color(
						transform_editor.fields[1].get_theme_color("font_color"),
						DEFAULT_VALUE_OPACITY))
				transform_editor.fields[2].add_theme_color_override("font_color", Color(
						transform_editor.fields[2].get_theme_color("font_color"),
						DEFAULT_VALUE_OPACITY))
			else:
				transform_editor.fields[1].remove_theme_color_override("font_color")
				transform_editor.fields[2].remove_theme_color_override("font_color")
		elif t is AttributeTransform.TransformScale and transform_editor.type == "scale":
			transform_editor.fields[0].set_value(t.x, true)
			transform_editor.fields[1].set_value(t.y, true)
			if t.x == t.y:
				transform_editor.fields[1].add_theme_color_override("font_color", Color(
						transform_editor.fields[1].get_theme_color("font_color"),
						DEFAULT_VALUE_OPACITY))
			else:
				transform_editor.fields[1].remove_theme_color_override("font_color")
		elif t is AttributeTransform.TransformSkewX and transform_editor.type == "skewX":
			transform_editor.fields[0].set_value(t.x, true)
		elif t is AttributeTransform.TransformSkewY and transform_editor.type == "skewY":
			transform_editor.fields[0].set_value(t.y, true)
		else:
			break
		i += 1
	
	for child in transform_list.get_children():
		if child.get_index() >= i:
			child.queue_free()
	while i < transform_count:
		var t := attribute_ref.get_transform(i)
		var t_editor := TransformEditor.instantiate()
		transform_list.add_child(t_editor)
		# Setup top panel
		if t is AttributeTransform.TransformMatrix:
			t_editor.type = "matrix"
		elif t is AttributeTransform.TransformTranslate:
			t_editor.type = "translate"
		elif t is AttributeTransform.TransformRotate:
			t_editor.type = "rotate"
		elif t is AttributeTransform.TransformScale:
			t_editor.type = "scale"
		elif t is AttributeTransform.TransformSkewX:
			t_editor.type = "skewX"
		elif t is AttributeTransform.TransformSkewY:
			t_editor.type = "skewY"
		t_editor.transform_label.text = t_editor.type
		t_editor.transform_icon.texture = icons_dict[t_editor.type]
		t_editor.more_button.pressed.connect(
				popup_transform_actions.bind(i, t_editor.more_button))
		# Setup fields.
		if t is AttributeTransform.TransformMatrix:
			var field_x1 := create_mini_number_field(t, i, "x1")
			var field_x2 := create_mini_number_field(t, i, "x2")
			var field_y1 := create_mini_number_field(t, i, "y1")
			var field_y2 := create_mini_number_field(t, i, "y2")
			var field_o1 := create_mini_number_field(t, i, "o1")
			var field_o2 := create_mini_number_field(t, i, "o2")
			t_editor.fields = [field_x1, field_x2, field_y1, field_y2, field_o1, field_o1]\
					as Array[BetterLineEdit]
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_x1)
			transform_fields.add_child(field_y1)
			transform_fields.add_child(field_o1)
			var transform_fields_additional := HBoxContainer.new()
			transform_fields_additional.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields_additional.add_child(field_x2)
			transform_fields_additional.add_child(field_y2)
			transform_fields_additional.add_child(field_o2)
			t_editor.transform_list.add_child(transform_fields)
			t_editor.transform_list.add_child(transform_fields_additional)
		elif t is AttributeTransform.TransformTranslate:
			var field_x := create_mini_number_field(t, i, "x")
			var field_y := create_mini_number_field(t, i, "y")
			t_editor.fields = [field_x, field_y] as Array[BetterLineEdit]
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_x)
			transform_fields.add_child(field_y)
			t_editor.transform_list.add_child(transform_fields)
		elif t is AttributeTransform.TransformRotate:
			var field_deg := create_mini_number_field(t, i, "deg")
			field_deg.mode = field_deg.Mode.ANGLE
			var field_x := create_mini_number_field(t, i, "x")
			var field_y := create_mini_number_field(t, i, "y")
			t_editor.fields = [field_deg, field_x, field_y] as Array[BetterLineEdit]
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_deg)
			transform_fields.add_child(field_x)
			transform_fields.add_child(field_y)
			t_editor.transform_list.add_child(transform_fields)
		elif t is AttributeTransform.TransformScale:
			var field_x := create_mini_number_field(t, i, "x")
			var field_y := create_mini_number_field(t, i, "y")
			t_editor.fields = [field_x, field_y] as Array[BetterLineEdit]
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_x)
			transform_fields.add_child(field_y)
			t_editor.transform_list.add_child(transform_fields)
		elif t is AttributeTransform.TransformSkewX:
			var field_x := create_mini_number_field(t, i, "x")
			t_editor.fields = [field_x] as Array[BetterLineEdit]
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_x)
			t_editor.transform_list.add_child(transform_fields)
		elif t is AttributeTransform.TransformSkewY:
			var field_y := create_mini_number_field(t, i, "y")
			t_editor.fields = [field_y] as Array[BetterLineEdit]
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_y)
			t_editor.transform_list.add_child(transform_fields)
		i += 1
	# Show the add button if there are no transforms.
	transform_list.visible = (transform_count != 0)
	add_button.visible = (transform_count == 0)
	update_final_transform()

func create_mini_number_field(transform: AttributeTransform.Transform, idx: int,
property: String) -> BetterLineEdit:
	var field := MiniNumberField.instantiate()
	field.custom_minimum_size.x = 44
	field.set_value(transform.get(property))
	if (transform is AttributeTransform.TransformTranslate and transform.y == 0 and\
	property == "y") or (transform is AttributeTransform.TransformRotate and\
	transform.x == 0 and transform.y == 0 and (property == "x" or property == "y")) or\
	(transform is AttributeTransform.TransformScale and transform.x == transform.y and\
	property == "y"):
		field.add_theme_color_override("font_color", Color(
				field.get_theme_color("font_color"), DEFAULT_VALUE_OPACITY))
	field.tooltip_text = property
	field.value_changed.connect(update_value.bind(idx, property))
	return field


func update_value(new_value: float, idx: int, property: String) -> void:
	UR.create_action("")
	UR.add_do_method(attribute_ref.set_transform_property.bind(idx, property, new_value))
	UR.add_do_method(rebuild)
	UR.add_undo_method(attribute_ref.set_transform_list.bind(get_transform_list()))
	UR.add_undo_method(rebuild)
	UR.commit_action()

func insert_transform(idx: int, transform_type: String) -> void:
	UR.create_action("")
	UR.add_do_method(attribute_ref.insert_transform.bind(idx, transform_type))
	UR.add_do_method(rebuild)
	UR.add_undo_method(attribute_ref.set_transform_list.bind(get_transform_list()))
	UR.add_undo_method(rebuild)
	UR.commit_action()

func delete_transform(idx: int) -> void:
	UR.create_action("")
	UR.add_do_method(attribute_ref.delete_transform.bind(idx))
	UR.add_do_method(rebuild)
	UR.add_undo_method(attribute_ref.set_transform_list.bind(get_transform_list()))
	UR.add_undo_method(rebuild)
	UR.commit_action()

func _on_apply_matrix_pressed() -> void:
	var final_transform := attribute_ref.get_final_transform()
	UR.create_action("")
	UR.add_do_method(attribute_ref.set_transform_list.bind([
			AttributeTransform.TransformMatrix.new(final_transform.x.x, final_transform.x.y,
			final_transform.y.x, final_transform.y.y, final_transform.origin.x,
			final_transform.origin.y)] as Array[AttributeTransform.Transform]))
	UR.add_do_method(rebuild)
	UR.add_undo_method(attribute_ref.set_transform_list.bind(get_transform_list()))
	UR.add_undo_method(rebuild)
	UR.commit_action()

func update_final_transform() -> void:
	var final_transform := attribute_ref.get_final_transform()
	x1_edit.set_value(final_transform[0].x)
	x2_edit.set_value(final_transform[0].y)
	y1_edit.set_value(final_transform[1].x)
	y2_edit.set_value(final_transform[1].y)
	o1_edit.set_value(final_transform[2].x)
	o2_edit.set_value(final_transform[2].y)


func popup_transform_actions(idx: int, control: Control) -> void:
	var btn_array: Array[Button] = []
	btn_array.append(Utils.create_btn(TranslationServer.translate("Insert After"),
			popup_new_transform_context.bind(idx + 1, control), false,
			load("res://visual/icons/InsertAfter.svg")))
	btn_array.append(Utils.create_btn(TranslationServer.translate("Insert Before"),
			popup_new_transform_context.bind(idx, control), false,
			load("res://visual/icons/InsertBefore.svg")))
	btn_array.append(Utils.create_btn(TranslationServer.translate("Delete"),
			delete_transform.bind(idx), false, load("res://visual/icons/Delete.svg")))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true)
	HandlerGUI.popup_under_rect_center(context_popup, control.get_global_rect(),
			get_viewport())

func popup_new_transform_context(idx: int, control: Control) -> void:
	var btn_array: Array[Button] = []
	for transform in ["matrix", "translate", "rotate", "scale", "skewX", "skewY"]:
		var btn := Utils.create_btn(transform, insert_transform.bind(idx, transform),
				false, icons_dict[transform])
		btn.add_theme_font_override("font", code_font)
		btn_array.append(btn)
	
	var transform_context := ContextPopup.new()
	transform_context.setup_with_title(btn_array,
			TranslationServer.translate("New transform"), true)
	HandlerGUI.popup_under_rect_center(transform_context, control.get_global_rect(),
			get_viewport())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("redo"):
		if UR.has_redo():
			UR.redo()
	elif event.is_action_pressed("undo"):
		if UR.has_undo():
			UR.undo()


# So I have to rebuild this in its entirety to keep the references safe or something...
func get_transform_list() -> Array[AttributeTransform.Transform]:
	var t_list: Array[AttributeTransform.Transform] = []
	for t in attribute_ref.get_transform_list():
		if t is AttributeTransform.TransformMatrix:
			t_list.append(AttributeTransform.TransformMatrix.new(
					t.x1, t.x2, t.y1, t.y2, t.o1, t.o2))
		elif t is AttributeTransform.TransformTranslate:
			t_list.append(AttributeTransform.TransformTranslate.new(t.x, t.y))
		elif t is AttributeTransform.TransformRotate:
			t_list.append(AttributeTransform.TransformRotate.new(t.deg, t.x, t.y))
		elif t is AttributeTransform.TransformScale:
			t_list.append(AttributeTransform.TransformScale.new(t.x, t.y))
		elif t is AttributeTransform.TransformSkewX:
			t_list.append(AttributeTransform.TransformSkewX.new(t.x))
		elif t is AttributeTransform.TransformSkewY:
			t_list.append(AttributeTransform.TransformSkewY.new(t.y))
	return t_list
