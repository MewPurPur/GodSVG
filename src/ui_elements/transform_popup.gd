## A popup for editing a transform matrix.
extends Popup

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")
const ContextPopupType = preload("res://src/ui_elements/context_popup.gd")

const MiniNumberField = preload("res://src/ui_elements/mini_number_field.tscn")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const code_font = preload("res://visual/fonts/FontMono.ttf")
const more_icon = preload("res://visual/icons/SmallMore.svg")
const plus_icon = preload("res://visual/icons/Plus.svg")

const icons_dict := {
	"matrix": preload("res://visual/icons/Matrix.svg"),
	"translate": preload("res://visual/icons/Translate.svg"),
	"rotate": preload("res://visual/icons/Rotate.svg"),
	"scale": preload("res://visual/icons/Scale.svg"),
	"skewX": preload("res://visual/icons/SkewX.svg"),
	"skewY": preload("res://visual/icons/SkewY.svg"),
}

@onready var x1_edit: NumberEditType = %FinalMatrix/X1
@onready var x2_edit: NumberEditType = %FinalMatrix/X2
@onready var y1_edit: NumberEditType = %FinalMatrix/Y1
@onready var y2_edit: NumberEditType = %FinalMatrix/Y2
@onready var o1_edit: NumberEditType = %FinalMatrix/O1
@onready var o2_edit: NumberEditType = %FinalMatrix/O2
@onready var transform_list: VBoxContainer = %TransformList

var attribute_ref: AttributeTransform

func _ready() -> void:
	rebuild()

func rebuild() -> void:
	for child in transform_list.get_children():
		child.queue_free()
	var transform_count := attribute_ref.get_transform_count()
	for i in transform_count:
		var t := attribute_ref.get_transform(i)
		# Basic transform editor setup.
		var transform_editor := PanelContainer.new()
		var stylebox := StyleBoxFlat.new()
		stylebox.content_margin_top = 2
		stylebox.content_margin_top = 2
		stylebox.content_margin_top = 2
		stylebox.content_margin_bottom = 4
		stylebox.set_corner_radius_all(4)
		stylebox.bg_color = Color("#def1")
		transform_editor.add_theme_stylebox_override(&"panel", stylebox)
		var transform_list_editor := VBoxContainer.new()
		# Setup top panel
		var top_panel := HBoxContainer.new()
		top_panel.alignment = BoxContainer.ALIGNMENT_CENTER
		var transform_label := Label.new()
		transform_label.add_theme_font_override(&"font", code_font)
		transform_label.add_theme_color_override(&"font_color", Color("#defe"))
		transform_label.add_theme_font_size_override(&"font_size", 13)
		if t is AttributeTransform.TransformMatrix:
			transform_label.text = "matrix"
		elif t is AttributeTransform.TransformTranslate:
			transform_label.text = "translate"
		elif t is AttributeTransform.TransformRotate:
			transform_label.text = "rotate"
		elif t is AttributeTransform.TransformScale:
			transform_label.text = "scale"
		elif t is AttributeTransform.TransformSkewX:
			transform_label.text = "skewX"
		elif t is AttributeTransform.TransformSkewY:
			transform_label.text = "skewY"
		var transform_icon := TextureRect.new()
		transform_icon.texture = icons_dict[transform_label.text]
		transform_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		transform_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var more_button := Button.new()
		more_button.icon = more_icon
		more_button.theme_type_variation = &"FlatButton"
		more_button.focus_mode = Control.FOCUS_NONE
		more_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		more_button.pressed.connect(popup_transform_actions.bind(i, more_button))
		top_panel.add_child(transform_icon)
		top_panel.add_child(transform_label)
		top_panel.add_child(more_button)
		transform_list_editor.add_child(top_panel)
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
			transform_list_editor.add_child(transform_fields)
			transform_list_editor.add_child(transform_fields_additional)
		elif t is AttributeTransform.TransformTranslate:
			var field_x := MiniNumberField.instantiate()
			var field_y := MiniNumberField.instantiate()
			field_x.set_value(t.x)
			field_y.set_value(t.y)
			field_x.tooltip_text = "x"
			field_y.tooltip_text = "y"
			field_x.value_changed.connect(update_value.bind(i, &"x"))
			field_y.value_changed.connect(update_value.bind(i, &"y"))
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_x)
			transform_fields.add_child(field_y)
			transform_list_editor.add_child(transform_fields)
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
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_deg)
			transform_fields.add_child(field_x)
			transform_fields.add_child(field_y)
			transform_list_editor.add_child(transform_fields)
		elif t is AttributeTransform.TransformScale:
			var field_x := MiniNumberField.instantiate()
			var field_y := MiniNumberField.instantiate()
			field_x.set_value(t.x)
			field_y.set_value(t.y)
			field_x.tooltip_text = "x"
			field_y.tooltip_text = "y"
			field_x.value_changed.connect(update_value.bind(i, &"x"))
			field_y.value_changed.connect(update_value.bind(i, &"y"))
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_x)
			transform_fields.add_child(field_y)
			transform_list_editor.add_child(transform_fields)
		elif t is AttributeTransform.TransformSkewX:
			var field_x := MiniNumberField.instantiate()
			field_x.set_value(t.x)
			field_x.tooltip_text = "x"
			field_x.value_changed.connect(update_value.bind(i, &"x"))
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_x)
			transform_list_editor.add_child(transform_fields)
		elif t is AttributeTransform.TransformSkewY:
			var field_y := MiniNumberField.instantiate()
			field_y.set_value(t.y)
			field_y.tooltip_text = "y"
			field_y.value_changed.connect(update_value.bind(i, &"y"))
			var transform_fields := HBoxContainer.new()
			transform_fields.alignment = BoxContainer.ALIGNMENT_CENTER
			transform_fields.add_child(field_y)
			transform_list_editor.add_child(transform_fields)
		transform_editor.add_child(transform_list_editor)
		transform_list.add_child(transform_editor)
		
	# Add the add button.
	if transform_count == 0:
		var add_button := Button.new()
		add_button.icon = plus_icon
		add_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		add_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_button.focus_mode = Control.FOCUS_NONE
		add_button.theme_type_variation = &"TranslucentButton"
		transform_list.add_child(add_button)
		add_button.pressed.connect(popup_new_transform_context.bind(0, add_button))
	
	update_final_transform()

func update_value(new_value: float, idx: int, property: StringName) -> void:
	attribute_ref.set_transform_property(idx, property, new_value)
	update_final_transform()

func insert_transform(idx: int, transform_type: String) -> void:
	attribute_ref.insert_transform(idx, transform_type)
	rebuild()

func delete_transform(idx: int) -> void:
	attribute_ref.delete_transform(idx)
	rebuild()

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

func _on_apply_matrix_pressed() -> void:
	var final_transform := attribute_ref.get_final_transform()
	attribute_ref.set_transform_list([AttributeTransform.TransformMatrix.new(
			final_transform.x.x, final_transform.x.y, final_transform.y.x,
			final_transform.y.y, final_transform.origin.x, final_transform.origin.y)])
	rebuild()


func _on_popup_hide() -> void:
	queue_free()
