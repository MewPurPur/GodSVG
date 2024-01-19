## The standard context menu popup.
extends Popup

@onready var x1_edit: LineEdit = $PanelContainer/VBox/FirstRow/X1
@onready var y1_edit: LineEdit = $PanelContainer/VBox/FirstRow/Y1
@onready var z1_edit: LineEdit = $PanelContainer/VBox/FirstRow/Z1

@onready var x2_edit: LineEdit = $PanelContainer/VBox/SecondRow/X2
@onready var y2_edit: LineEdit = $PanelContainer/VBox/SecondRow/Y2
@onready var z2_edit: LineEdit = $PanelContainer/VBox/SecondRow/Z2

signal matrix_edited(new_matrix: String)

var transform : Transform2D

func initialize() -> void:
	x1_edit.tooltip_text = "X1"
	y1_edit.tooltip_text = "Y1"
	z1_edit.tooltip_text = "O1"
	x2_edit.tooltip_text = "X2"
	y2_edit.tooltip_text = "Y2"
	z2_edit.tooltip_text = "O2"
	
	x1_edit.text = String.num(transform[0].x, 4)
	y1_edit.text = String.num(transform[1].x, 4)
	z1_edit.text = String.num(transform[2].x, 4)
	x2_edit.text = String.num(transform[0].y, 4)
	y2_edit.text = String.num(transform[1].y, 4)
	z2_edit.text = String.num(transform[2].y, 4)
	

func text_submitted(_new_text: String) -> void:
	var new_transform := "matrix(%s, %s, %s, %s, %s, %s)"%[x1_edit.text, x2_edit.text, y1_edit.text, y2_edit.text, z1_edit.text, z2_edit.text]
	matrix_edited.emit(new_transform)

func focus_exited() -> void:
	var new_transform := "matrix(%s, %s, %s, %s, %s, %s)"%[x1_edit.text, x2_edit.text, y1_edit.text, y2_edit.text, z1_edit.text, z2_edit.text]
	matrix_edited.emit(new_transform)

func _on_popup_hide() -> void:
	queue_free()
