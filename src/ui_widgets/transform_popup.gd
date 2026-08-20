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

var attribute: AttributeTransformList
var undo_redo := UndoRedoRef.new()

var focus_index := -1
var is_rebuilt_focus_hidden := true

@onready var x1_edit: NumberEdit = %FinalMatrix/X1
@onready var x2_edit: NumberEdit = %FinalMatrix/X2
@onready var y1_edit: NumberEdit = %FinalMatrix/Y1
@onready var y2_edit: NumberEdit = %FinalMatrix/Y2
@onready var o1_edit: NumberEdit = %FinalMatrix/O1
@onready var o2_edit: NumberEdit = %FinalMatrix/O2
@onready var transforms_container: VBoxContainer = %TransformList
@onready var add_button: Button = %AddButton
@onready var apply_matrix_button: Button = %ApplyMatrix

func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("ui_undo", undo_redo.undo)
	shortcuts.add_shortcut("ui_redo", undo_redo.redo)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	add_button.pressed.connect(popup_new_transform_context.bind(0, add_button))
	apply_matrix_button.pressed.connect(_on_apply_matrix_pressed)
	sync()

func _exit_tree() -> void:
	State.save_svg()

func sync_localization() -> void:
	apply_matrix_button.tooltip_text = Translator.translate("Apply the matrix")

func sync() -> void:
	var transform_count := attribute.get_transform_count()
	# Sync until the first different transform type is found; then rebuild the rest.
	var last_resync_index := 0
	for transform_editor in transforms_container.get_children():
		if last_resync_index >= transform_count:
			break
		var t := attribute.get_transform(last_resync_index)
		if t.name == transform_editor.transform.name:
			transform_editor.resync(t)
		else:
			break
		last_resync_index += 1
	
	for i in transforms_container.get_child_count():
		if i >= last_resync_index:
			transforms_container.get_child(i).queue_free()
	
	for i in range(last_resync_index, transform_count):
		var t := attribute.get_transform(i)
		var t_editor := TransformEditorScene.instantiate()
		transforms_container.add_child(t_editor)
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
		t_editor.transform_button.icon = _icons_dict[t_editor.transform.name]
		t_editor.transform_button.pressed.connect(popup_transform_actions.bind(i, t_editor.transform_button))
		t_editor.focused.connect(func() -> void: focus_index = i)
	
	if transform_count == 0 or focus_index < 0 or focus_index >= transform_count:
		add_button.grab_focus(is_rebuilt_focus_hidden)
	else:
		transforms_container.get_child(focus_index).grab_focus_override(is_rebuilt_focus_hidden)
	
	# Show the add button if there are no transforms.
	transforms_container.visible = (transform_count != 0)
	add_button.visible = (transform_count == 0)
	# Sync final transform.
	var final_transform := attribute.get_final_precise_transform()
	x1_edit.set_value(final_transform[0])
	x2_edit.set_value(final_transform[1])
	y1_edit.set_value(final_transform[2])
	y2_edit.set_value(final_transform[3])
	o1_edit.set_value(final_transform[4])
	o2_edit.set_value(final_transform[5])
	
	var focus_sequence: Array[Control] = [add_button]
	focus_sequence.append_array(transforms_container.get_children())
	focus_sequence.append(x1_edit)
	focus_sequence.append(x2_edit)
	focus_sequence.append(y1_edit)
	focus_sequence.append(y2_edit)
	focus_sequence.append(o1_edit)
	focus_sequence.append(o2_edit)
	focus_sequence.append(apply_matrix_button)
	HandlerGUI.register_focus_sequence(self, focus_sequence)


func create_mini_number_field(index: int, property: String) -> BetterLineEdit:
	var field := MiniNumberFieldScene.instantiate()
	field.custom_minimum_size.x = 44
	field.tooltip_text = property
	field.value_changed.connect(update_value.bind(index, property))
	return field


func edit(callback: Callable) -> void:
	undo_redo.create_action()
	undo_redo.add_do_method(callback)
	undo_redo.add_do_method(sync)
	undo_redo.add_undo_method(attribute.set_transform_list.bind(attribute.get_transforms()))
	undo_redo.add_undo_method(sync)
	undo_redo.commit_action()

func update_value(new_value: float, index: int, property: String) -> void:
	undo_redo.create_action()
	undo_redo.add_do_method(attribute.set_transform_property.bind(index, property, new_value))
	undo_redo.add_do_method(sync)
	undo_redo.add_undo_method(attribute.set_transform_property.bind(index, property, attribute.get_transform(index).get(property)))
	undo_redo.add_undo_method(sync)
	undo_redo.commit_action()

func insert_transform(index: int, transform_type: String) -> void:
	edit(attribute.insert_transform.bind(index, transform_type))

func delete_transform(index: int) -> void:
	edit(attribute.delete_transform.bind(index))

func replace_matrix(index: int, new_transform: Transform) -> void:
	var new_transforms := attribute.get_transforms()
	new_transforms[index] = new_transform
	edit(attribute.set_transform_list.bind(new_transforms))

func _on_apply_matrix_pressed() -> void:
	var final_transform := attribute.get_final_precise_transform()
	edit(attribute.set_transform_list.bind([Transform.TransformMatrix.new(
			final_transform[0], final_transform[1], final_transform[2], final_transform[3],
			final_transform[4], final_transform[5])] as Array[Transform]))


func popup_transform_actions(index: int, control: Control) -> void:
	var transform := attribute.get_transform(index)
	
	var btn_arr: Array[ContextButton] = []
	btn_arr.append(ContextButton.create_custom(Translator.translate("Insert after"),
			popup_new_transform_context.bind(index + 1, control), preload("res://assets/icons/InsertAfter.svg")))
	btn_arr.append(ContextButton.create_custom(Translator.translate("Insert before"),
			popup_new_transform_context.bind(index, control), preload("res://assets/icons/InsertBefore.svg")))
	
	# Convert basic transforms to matrices, and matrices to basic transforms if possible.
	if transform is Transform.TransformMatrix:
		var basic_transform: Transform = transform.get_equivalent_basic_transform()
		if is_instance_valid(basic_transform):
			var text_line := TextLine.new()
			text_line.add_string(Translator.translate("Convert to") + ": ", ThemeUtils.main_font, get_theme_font_size("font_size", "Button"))
			text_line.add_string(basic_transform.name, ThemeUtils.mono_font, get_theme_font_size("font_size", "Button"))
			
			btn_arr.append(ContextButton.create_custom("", replace_matrix.bind(index, basic_transform),
					_icons_dict[basic_transform.name]).add_custom_text_line(text_line))
	else:
		var t := transform.compute_precise_transform()
		var matrix_transform := Transform.TransformMatrix.new(t[0], t[1], t[2], t[3], t[4], t[5])
		var text_line := TextLine.new()
		text_line.add_string(Translator.translate("Convert to") + ": ", ThemeUtils.main_font, get_theme_font_size("font_size", "Button"))
		text_line.add_string("matrix", ThemeUtils.mono_font, get_theme_font_size("font_size", "Button"))
		
		btn_arr.append(ContextButton.create_custom("", replace_matrix.bind(index, matrix_transform),
				_icons_dict["matrix"]).add_custom_text_line(text_line))
	
	btn_arr.append(ContextButton.create_custom(Translator.translate("Delete"),
			delete_transform.bind(index), preload("res://assets/icons/Delete.svg")))
	
	HandlerGUI.popup_under_rect_center(ContextPopup.create(btn_arr), control.get_global_rect(), get_viewport())

func popup_new_transform_context(index: int, control: Control) -> void:
	var btn_arr: Array[ContextButton] = []
	const CONST_ARR: PackedStringArray = ["matrix", "translate", "rotate", "scale", "skewX", "skewY"]
	for transform_type in CONST_ARR:
		var btn := ContextButton.create_custom(transform_type, insert_transform.bind(index, transform_type), _icons_dict[transform_type])
		btn.add_theme_font_override("font", ThemeUtils.mono_font)
		btn_arr.append(btn)
	HandlerGUI.popup_under_rect_center(ContextPopup.create_with_title(btn_arr, Translator.translate("New transform")), control.get_global_rect(), get_viewport())
