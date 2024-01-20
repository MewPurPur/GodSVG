## A popup for editing a transform matrix.
extends Popup

@onready var x1_edit: LineEdit = $PanelContainer/GridContainer/X1
@onready var y1_edit: LineEdit = $PanelContainer/GridContainer/Y1
@onready var o1_edit: LineEdit = $PanelContainer/GridContainer/O1

@onready var x2_edit: LineEdit = $PanelContainer/GridContainer/X2
@onready var y2_edit: LineEdit = $PanelContainer/GridContainer/Y2
@onready var o2_edit: LineEdit = $PanelContainer/GridContainer/O2

signal matrix_edited(new_matrix: String)

var transform: Transform2D

func initialize() -> void:
	x1_edit.text = String.num(transform[0].x, 4)
	y1_edit.text = String.num(transform[1].x, 4)
	o1_edit.text = String.num(transform[2].x, 4)
	x2_edit.text = String.num(transform[0].y, 4)
	y2_edit.text = String.num(transform[1].y, 4)
	o2_edit.text = String.num(transform[2].y, 4)

func text_submitted(_new_text: String) -> void:
	var new_transform := "matrix(%s %s %s %s %s %s)" % [x1_edit.text, x2_edit.text,
			y1_edit.text, y2_edit.text, o1_edit.text, o2_edit.text]
	matrix_edited.emit(new_transform)

func focus_exited() -> void:
	var new_transform := "matrix(%s %s %s %s %s %s)" % [x1_edit.text, x2_edit.text,
			y1_edit.text, y2_edit.text, o1_edit.text, o2_edit.text]
	matrix_edited.emit(new_transform)

func _on_popup_hide() -> void:
	queue_free()
