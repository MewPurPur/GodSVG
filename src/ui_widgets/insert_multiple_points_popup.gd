extends PanelContainer

signal point_count_chosen(count: int)

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

@onready var label: Label = %Label
@onready var number_edit: NumberEdit = %NumberEdit

func _ready() -> void:
	label.text = Translator.translate("Points to insert") + ":"
	number_edit.value_changed.connect(_on_point_count_chosen)
	number_edit.editing_toggled.connect(_on_editing_toggled)
	number_edit.grab_focus()

func _on_point_count_chosen(count: int) -> void:
	point_count_chosen.emit(count)
	queue_free()

func _on_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		point_count_chosen.emit(number_edit.get_value())
		queue_free()
