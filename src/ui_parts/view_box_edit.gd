extends HBoxContainer

signal viewbox_changed(w: float, h: float)

@onready var width_edit: Control = $WidthEdit
@onready var height_edit: Control = $HeightEdit

func emit_viewbox_changed() -> void:
	viewbox_changed.emit(width_edit.get_value(), height_edit.get_value())

func _ready() -> void:
	height_edit.value_changed.connect(emit_viewbox_changed.unbind(1))
	width_edit.value_changed.connect(emit_viewbox_changed.unbind(1))
	update_viewbox()

func update_viewbox():
	width_edit.set_value(SVG.data.width, false)
	height_edit.set_value(SVG.data.height)
