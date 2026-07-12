extends PanelContainer

signal point_count_chosen(count: int)

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

@onready var label: Label = %Label
@onready var number_edit: NumberEdit = %NumberEdit

func _ready() -> void:
	label.text = Translator.translate("Points to insert") + ":"
	number_edit.editing_toggled.connect(_on_editing_toggled)
	tree_exited.connect(_on_tree_exited)
	number_edit.grab_focus()

func _on_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		queue_free()

func _on_tree_exited() -> void:
	point_count_chosen.emit(number_edit.get_value())
