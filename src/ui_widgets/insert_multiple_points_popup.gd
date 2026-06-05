extends PanelContainer

signal point_count_chosen(count: int)

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

@onready var label: Label = %Label
@onready var number_edit: NumberEdit = %NumberEdit

func _ready() -> void:
	label.text = Translator.translate("Points to insert") + ":"
	number_edit.value_changed.connect(_on_point_count_chosen)
	number_edit.text_change_canceled.connect(queue_free)
	number_edit.grab_focus()

func _on_point_count_chosen(count: int) -> void:
	point_count_chosen.emit(count)
	queue_free()
