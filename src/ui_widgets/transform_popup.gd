# A popup for editing a transform list.
extends PanelContainer

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

const MiniNumberFieldScene = preload("res://src/ui_widgets/mini_number_field.tscn")
const TransformEditorScene = preload("res://src/ui_widgets/transform_editor.tscn")

const _icons_dict: Dictionary[String, Texture2D] = {
	"matrix": preload("res://assets/icons/Matrix.svg"),
	"translate": preload("res://assets/icons/Translate.svg"),
	"rotate": preload("res://assets/icons/Rotate.svg"),
	"scale": preload("res://assets/icons/Scale.svg"),
	"skewX": preload("res://assets/icons/SkewX.svg"),
	"skewY": preload("res://assets/icons/SkewY.svg"),
}

var attribute_ref: AttributeTransformList
var undo_redo := UndoRedoRef.new()

@onready var x1_edit: NumberEdit = %FinalMatrix/X1
@onready var x2_edit: NumberEdit = %FinalMatrix/X2
@onready var y1_edit: NumberEdit = %FinalMatrix/Y1
@onready var y2_edit: NumberEdit = %FinalMatrix/Y2
@onready var o1_edit: NumberEdit = %FinalMatrix/O1
@onready var o2_edit: NumberEdit = %FinalMatrix/O2
@onready var transform_list: VBoxContainer = %TransformList
@onready var add_button: Button = %AddButton
@onready var apply_matrix: Button = %ApplyMatrix

func _ready() -> void:
	Configs.language_changed.connect(sync_localization)
	add_button.pressed.connect(popup_new_transform_context.bind(0, add_button))
	apply_matrix.pressed.connect(_on_apply_matrix_pressed)
	rebuild()
	sync_localization()

func _exit_tree() -> void:
	State.queue_svg_save()

func sync_localization() -> void:
	apply_matrix.tooltip_text = Translator.translate("Apply the matrix")

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
		var t_editor := TransformEditorScene.instantiate()
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
		t_editor.transform_button.icon = _icons_dict[t_editor.type]
		t_editor.transform_button.pressed.connect(
				popup_transform_actions.bind(i, t_editor.transform_button))
		i += 1
	# Show the add button if there are no transforms.
	transform_list.visible = (transform_count != 0)
	add_button.visible = (transform_count == 0)
	update_final_transform()


func create_mini_number_field(idx: int, property: String) -> BetterLineEdit:
	var field := MiniNumberFieldScene.instantiate()
	field.custom_minimum_size.x = 44
	field.tooltip_text = property
	field.value_changed.connect(update_value.bind(idx, property))
	return field


func update_value(new_value: float, idx: int, property: String) -> void:
	undo_redo.create_action()
	undo_redo.add_do_method(attribute_ref.set_transform_property.bind(idx, property, new_value))
	undo_redo.add_do_method(rebuild)
	undo_redo.add_undo_method(attribute_ref.set_transform_list.bind(get_transform_list()))
	undo_redo.add_undo_method(rebuild)
	undo_redo.commit_action()

func insert_transform(idx: int, transform_type: String) -> void:
	undo_redo.create_action()
	undo_redo.add_do_method(attribute_ref.insert_transform.bind(idx, transform_type))
	undo_redo.add_do_method(rebuild)
	undo_redo.add_undo_method(attribute_ref.set_transform_list.bind(get_transform_list()))
	undo_redo.add_undo_method(rebuild)
	undo_redo.commit_action()

func delete_transform(idx: int) -> void:
	undo_redo.create_action()
	undo_redo.add_do_method(attribute_ref.delete_transform.bind(idx))
	undo_redo.add_do_method(rebuild)
	undo_redo.add_undo_method(attribute_ref.set_transform_list.bind(get_transform_list()))
	undo_redo.add_undo_method(rebuild)
	undo_redo.commit_action()

func _on_apply_matrix_pressed() -> void:
	var final_transform := attribute_ref.get_final_precise_transform()
	undo_redo.create_action()
	undo_redo.add_do_method(attribute_ref.set_transform_list.bind([
			Transform.TransformMatrix.new(final_transform[0], final_transform[1],
			final_transform[2], final_transform[3], final_transform[4],
			final_transform[5])] as Array[Transform]))
	undo_redo.add_do_method(rebuild)
	undo_redo.add_undo_method(attribute_ref.set_transform_list.bind(get_transform_list()))
	undo_redo.add_undo_method(rebuild)
	undo_redo.commit_action()

func update_final_transform() -> void:
	var final_transform := attribute_ref.get_final_precise_transform()
	x1_edit.set_value(final_transform[0])
	x2_edit.set_value(final_transform[1])
	y1_edit.set_value(final_transform[2])
	y2_edit.set_value(final_transform[3])
	o1_edit.set_value(final_transform[4])
	o2_edit.set_value(final_transform[5])


func popup_transform_actions(idx: int, control: Control) -> void:
	var btn_array: Array[Button] = []
	btn_array.append(ContextPopup.create_button(Translator.translate("Insert After"),
			popup_new_transform_context.bind(idx + 1, control), false,
			load("res://assets/icons/InsertAfter.svg")))
	btn_array.append(ContextPopup.create_button(Translator.translate("Insert Before"),
			popup_new_transform_context.bind(idx, control), false,
			load("res://assets/icons/InsertBefore.svg")))
	btn_array.append(ContextPopup.create_button(Translator.translate("Delete"),
			delete_transform.bind(idx), false, load("res://assets/icons/Delete.svg")))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true)
	HandlerGUI.popup_under_rect_center(context_popup, control.get_global_rect(), get_viewport())

func popup_new_transform_context(idx: int, control: Control) -> void:
	var btn_array: Array[Button] = []
	const CONST_ARR: PackedStringArray = ["matrix", "translate", "rotate", "scale", "skewX", "skewY"]
	for transform_type in CONST_ARR:
		var btn := ContextPopup.create_button(transform_type,
				insert_transform.bind(idx, transform_type), false,
				_icons_dict[transform_type])
		btn.add_theme_font_override("font", ThemeUtils.mono_font)
		btn_array.append(btn)
	
	var transform_context := ContextPopup.new()
	transform_context.setup_with_title(btn_array, Translator.translate("New transform"), true)
	HandlerGUI.popup_under_rect_center(transform_context, control.get_global_rect(), get_viewport())


func _unhandled_input(event: InputEvent) -> void:
	if ShortcutUtils.is_action_pressed(event, "ui_undo"):
		undo_redo.undo()
		accept_event()
	elif ShortcutUtils.is_action_pressed(event, "ui_redo"):
		undo_redo.redo()
		accept_event()


# So I have to rebuild this in its entirety to keep the references safe or something...
func get_transform_list() -> Array[Transform]:
	var t_list: Array[Transform] = []
	for t in attribute_ref.get_transform_list():
		if t is Transform.TransformMatrix:
			t_list.append(Transform.TransformMatrix.new(t.x1, t.x2, t.y1, t.y2, t.o1, t.o2))
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
