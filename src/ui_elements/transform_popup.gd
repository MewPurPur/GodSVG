## A popup for editing a transform matrix.
extends Popup

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")
const ContextPopupType = preload("res://src/ui_elements/context_popup.gd")

const MiniNumberField = preload("res://src/ui_elements/mini_number_field.tscn")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
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

func _ready() -> void:
	add_button.pressed.connect(popup_new_transform_context.bind(0, add_button))
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
		elif t is AttributeTransform.TransformRotate and transform_editor.type == "rotate":
			transform_editor.fields[0].set_value(t.deg, true)
			transform_editor.fields[1].set_value(t.x, true)
			transform_editor.fields[2].set_value(t.y, true)
		elif t is AttributeTransform.TransformScale and transform_editor.type == "scale":
			transform_editor.fields[0].set_value(t.x, true)
			transform_editor.fields[1].set_value(t.y, true)
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
		var transform_type: String
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
			var field_x1 := MiniNumberField.instantiate()
			var field_x2 := MiniNumberField.instantiate()
			var field_y1 := MiniNumberField.instantiate()
			var field_y2 := MiniNumberField.instantiate()
			var field_o1 := MiniNumberField.instantiate()
			var field_o2 := MiniNumberField.instantiate()
			field_x1.set_value(t.x1)
			field_x2.set_value(t.x2)
			field_y1.set_value(t.y1)
			field_y2.set_value(t.y2)
			field_o1.set_value(t.o1)
			field_o2.set_value(t.o2)
			field_x1.tooltip_text = "x1"
			field_x2.tooltip_text = "x2"
			field_y1.tooltip_text = "y1"
			field_y2.tooltip_text = "y2"
			field_o1.tooltip_text = "o1"
			field_o2.tooltip_text = "o2"
			field_x1.value_changed.connect(update_value.bind(i, &"x1"))
			field_x2.value_changed.connect(update_value.bind(i, &"x2"))
			field_y1.value_changed.connect(update_value.bind(i, &"y1"))
			field_y2.value_changed.connect(update_value.bind(i, &"y2"))
			field_o1.value_changed.connect(update_value.bind(i, &"o1"))
			field_o2.value_changed.connect(update_value.bind(i, &"o2"))
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
			var field_x := MiniNumberField.instantiate()
			var field_y := MiniNumberField.instantiate()
			field_x.set_value(t.x)
			field_y.set_value(t.y)
			field_x.tooltip_text = "x"
			field_y.tooltip_text = "y"
			field_x.value_changed.connect(update_value.bind(i, &"x"))
			field_y.value_changed.connect(update_value.bind(i, &"y"))
			t_editor.fields = [field_x, field_y] as Array[BetterLineEdit]
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_x)
			transform_fields.add_child(field_y)
			t_editor.transform_list.add_child(transform_fields)
		elif t is AttributeTransform.TransformRotate:
			var field_deg := MiniNumberField.instantiate()
			var field_x := MiniNumberField.instantiate()
			var field_y := MiniNumberField.instantiate()
			field_deg.set_value(t.deg)
			field_deg.mode = field_deg.Mode.ANGLE
			field_x.set_value(t.x)
			field_y.set_value(t.y)
			field_deg.tooltip_text = "deg"
			field_x.tooltip_text = "x"
			field_y.tooltip_text = "y"
			field_deg.value_changed.connect(update_value.bind(i, &"deg"))
			field_x.value_changed.connect(update_value.bind(i, &"x"))
			field_y.value_changed.connect(update_value.bind(i, &"y"))
			t_editor.fields = [field_deg, field_x, field_y] as Array[BetterLineEdit]
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_deg)
			transform_fields.add_child(field_x)
			transform_fields.add_child(field_y)
			t_editor.transform_list.add_child(transform_fields)
		elif t is AttributeTransform.TransformScale:
			var field_x := MiniNumberField.instantiate()
			var field_y := MiniNumberField.instantiate()
			field_x.set_value(t.x)
			field_y.set_value(t.y)
			field_x.tooltip_text = "x"
			field_y.tooltip_text = "y"
			field_x.value_changed.connect(update_value.bind(i, &"x"))
			field_y.value_changed.connect(update_value.bind(i, &"y"))
			t_editor.fields = [field_x, field_y] as Array[BetterLineEdit]
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_x)
			transform_fields.add_child(field_y)
			t_editor.transform_list.add_child(transform_fields)
		elif t is AttributeTransform.TransformSkewX:
			var field_x := MiniNumberField.instantiate()
			field_x.set_value(t.x)
			field_x.tooltip_text = "x"
			field_x.value_changed.connect(update_value.bind(i, &"x"))
			t_editor.fields = [field_x] as Array[BetterLineEdit]
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_x)
			t_editor.transform_list.add_child(transform_fields)
		elif t is AttributeTransform.TransformSkewY:
			var field_y := MiniNumberField.instantiate()
			field_y.set_value(t.y)
			field_y.tooltip_text = "y"
			field_y.value_changed.connect(update_value.bind(i, &"y"))
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


func update_value(new_value: float, idx: int, property: StringName) -> void:
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
	btn_array.append(Utils.create_btn(tr(&"#insert_after"),
			popup_new_transform_context.bind(idx + 1, control), false,
			load("res://visual/icons/InsertAfter.svg")))
	btn_array.append(Utils.create_btn(tr(&"#insert_before"),
			popup_new_transform_context.bind(idx, control), false,
			load("res://visual/icons/InsertBefore.svg")))
	btn_array.append(Utils.create_btn(tr(&"#delete"), delete_transform.bind(idx), false,
			load("res://visual/icons/Delete.svg")))
	
	var context_popup := ContextPopup.instantiate()
	add_child(context_popup)
	context_popup.set_button_array(btn_array, true)
	Utils.popup_under_control_centered(context_popup, control)

func popup_new_transform_context(idx: int, control: Control) -> void:
	Utils.popup_under_control_centered(add_new_transform_context(idx), control)

func add_new_transform_context(idx: int) -> ContextPopupType:
	var btn_array: Array[Button] = []
	for transform in ["matrix", "translate", "rotate", "scale", "skewX", "skewY"]:
		var btn := Utils.create_btn(transform, insert_transform.bind(idx, transform),
				false, icons_dict[transform])
		btn.add_theme_font_override(&"font", code_font)
		btn_array.append(btn)
	
	var transform_context := ContextPopup.instantiate()
	add_child(transform_context)
	transform_context.set_button_array(btn_array, true)
	return transform_context

func _on_popup_hide() -> void:
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"redo"):
		if UR.has_redo():
			UR.redo()
	elif event.is_action_pressed(&"undo"):
		if UR.has_undo():
			UR.undo()


# So I have to rebuild this in its entirety to keep the references safe or something...
func get_transform_list() -> Array[AttributeTransform.Transform]:
	var t_list: Array[AttributeTransform.Transform]
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
