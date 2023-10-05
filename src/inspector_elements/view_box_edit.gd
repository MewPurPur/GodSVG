extends HBoxContainer

signal view_box_changed(w: int, h: int)

@onready var width_edit: Control = $WidthEdit
@onready var height_edit: Control = $HeightEdit

func emit_view_box_changed(_new_value := -1.0) -> void:
	view_box_changed.emit(width_edit.value, height_edit.value)

func _ready() -> void:
	height_edit.value = 16
	height_edit.value_changed.connect(emit_view_box_changed)
	width_edit.value = 16
	width_edit.value_changed.connect(emit_view_box_changed)
	emit_view_box_changed()
