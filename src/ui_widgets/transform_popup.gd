# A popup for editing a transform list.
extends PanelContainer

const NumberEditType = preload("res://src/ui_widgets/number_edit.gd")

const MiniNumberField = preload("res://src/ui_widgets/mini_number_field.tscn")
const TransformEditor = preload("res://src/ui_widgets/transform_editor.tscn")
const code_font = preload("res://visual/fonts/FontMono.ttf")

const icons_dict := {
	"matrix": preload("res://visual/icons/Matrix.svg"),
	"translate": preload("res://visual/icons/Translate.svg"),
	"rotate": preload("res://visual/icons/Rotate.svg"),
	"scale": preload("res://visual/icons/Scale.svg"),
	"skewX": preload("res://visual/icons/SkewX.svg"),
	"skewY": preload("res://visual/icons/SkewY.svg"),
}

var attribute_ref: AttributeTransformList
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
	GlobalSettings.language_changed.connect(update_translation)
	add_button.pressed.connect(popup_new_transform_context.bind(0, add_button))
	apply_matrix.pressed.connect(_on_apply_matrix_pressed)
	rebuild()
	update_translation()

func _exit_tree() -> void:
	SVG.queue_save()
	UR.free()

func update_translation() -> void:
	apply_matrix.tooltip_text = TranslationServer.translate("Apply the matrix")

func rebuild() -> void:
	var transform_count := attribute_ref.get_transform_count()
	# Sync until the first different transform type is found; then rebuild the rest.
	var i := 0
	for transform_editor in transform_list.get_children():
		if i >= transform_count:
			break
		var t := attribute_ref.get_transform(i)
		if t is Transform.TransformMatrix and transform_editor.type == "matrix" or\
		t is Transform.TransformTranslate and transform_editor.type == "translate" or\
		t is Transform.TransformRotate and transform_editor.type == "rotate" or\
		t is Transform.TransformScale and transform_editor.type == "scale" or\
		t is Transform.TransformSkewX and transform_editor.type == "skewX" or\
		t is Transform.TransformSkewY and transform_editor.type == "skewY":
			transform_editor.resync(t)
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
		var fields: Array[BetterLineEdit]
		# Setup fields.
		if t is Transform.TransformMatrix:
			fields = [create_mini_number_field(i, "x1"), create_mini_number_field(i, "x2"),
					create_mini_number_field(i, "y1"), create_mini_number_field(i, "y2"),
					create_mini_number_field(i, "o1"), create_mini_number_field(i, "o2")]
		elif t is Transform.TransformTranslate:
			fields = [create_mini_number_field(i, "x"), create_mini_number_field(i, "y")]
		elif t is Transform.TransformRotate:
			fields = [create_mini_number_field(i, "deg"),
					create_mini_number_field(i, "x"), create_mini_number_field(i, "y")]
		elif t is Transform.TransformScale:
			fields = [create_mini_number_field(i, "x"), create_mini_number_field(i, "y")]
		elif t is Transform.TransformSkewX:
			fields = [create_mini_number_field(i, "x")]
		elif t is Transform.TransformSkewY:
			fields = [create_mini_number_field(i, "y")]
		t_editor.setup(t, fields)
		t_editor.transform_button.icon = icons_dict[t_editor.type]
		t_editor.transform_button.pressed.connect(
				popup_transform_actions.bind(i, t_editor.transform_button))
		i += 1
	# Show the add button if there are no transforms.
	transform_list.visible = (transform_count != 0)
	add_button.visible = (transform_count == 0)
	update_final_transform()


func create_mini_number_field(idx: int, property: String) -> BetterLineEdit:
	var field := MiniNumberField.instantiate()
	field.custom_minimum_size.x = 44
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
			Transform.TransformMatrix.new(final_transform.x.x, final_transform.x.y,
			final_transform.y.x, final_transform.y.y, final_transform.origin.x,
			final_transform.origin.y)] as Array[Transform]))
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
	btn_array.append(ContextPopup.create_button(TranslationServer.translate("Insert After"),
			popup_new_transform_context.bind(idx + 1, control), false,
			load("res://visual/icons/InsertAfter.svg")))
	btn_array.append(ContextPopup.create_button(TranslationServer.translate("Insert Before"),
			popup_new_transform_context.bind(idx, control), false,
			load("res://visual/icons/InsertBefore.svg")))
	btn_array.append(ContextPopup.create_button(TranslationServer.translate("Delete"),
			delete_transform.bind(idx), false, load("res://visual/icons/Delete.svg")))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true)
	HandlerGUI.popup_under_rect_center(context_popup, control.get_global_rect(),
			get_viewport())

func popup_new_transform_context(idx: int, control: Control) -> void:
	var btn_array: Array[Button] = []
	for transform in ["matrix", "translate", "rotate", "scale", "skewX", "skewY"]:
		var btn := ContextPopup.create_button(transform,
				insert_transform.bind(idx, transform), false, icons_dict[transform])
		btn.add_theme_font_override("font", code_font)
		btn_array.append(btn)
	
	var transform_context := ContextPopup.new()
	transform_context.setup_with_title(btn_array,
			TranslationServer.translate("New transform"), true)
	HandlerGUI.popup_under_rect_center(transform_context, control.get_global_rect(),
			get_viewport())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("redo"):
		if UR.has_redo():
			UR.redo()
	elif event.is_action_pressed("undo"):
		if UR.has_undo():
			UR.undo()


# So I have to rebuild this in its entirety to keep the references safe or something...
func get_transform_list() -> Array[Transform]:
	var t_list: Array[Transform] = []
	for t in attribute_ref.get_transform_list():
		if t is Transform.TransformMatrix:
			t_list.append(Transform.TransformMatrix.new(
					t.x1, t.x2, t.y1, t.y2, t.o1, t.o2))
		elif t is Transform.TransformTranslate:
			t_list.append(Transform.TransformTranslate.new(t.x, t.y))
		elif t is Transform.TransformRotate:
			t_list.append(Transform.TransformRotate.new(t.deg, t.x, t.y))
		elif t is Transform.TransformScale:
			t_list.append(Transform.TransformScale.new(t.x, t.y))
		elif t is Transform.TransformSkewX:
			t_list.append(Transform.TransformSkewX.new(t.x))
		elif t is Transform.TransformSkewY:
			t_list.append(Transform.TransformSkewY.new(t.y))
	return t_list
