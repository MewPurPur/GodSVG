extends Popup

signal color_deletion_requested

@onready var color_label: Label = %ConfigureContainer/TopContainer/ColorLabel
@onready var color_name_edit: BetterLineEdit = %ConfigureContainer/TopContainer/NameEdit
@onready var color_name_edit_button: Button = %ConfigureContainer/TopContainer/EditButton
@onready var color_edit: HBoxContainer = %ConfigureContainer/BottomContainer/ColorEdit
@onready var delete_button: Button = %ConfigureContainer/BottomContainer/DeleteButton

var named_color: NamedColor

func _ready() -> void:
	set_label_text(named_color.name)
	color_edit.value = named_color.color


func _on_edit_button_pressed() -> void:
	color_name_edit.text = named_color.name
	color_name_edit.show()
	color_name_edit.grab_focus()
	color_name_edit.caret_column = color_name_edit.text.length()
	color_label.hide()
	color_name_edit_button.hide()


func _on_name_edit_focus_exited() -> void:
	change_color_name(color_name_edit.text)

func change_color_name(new_text: String) -> void:
	var new_name := new_text.strip_edges()
	set_label_text(new_name)
	hide_name_edit()


func hide_name_edit() -> void:
	color_name_edit.hide()
	color_name_edit_button.show()
	color_label.show()

func set_label_text(new_text: String) -> void:
	if new_text.is_empty():
		color_label.text = tr(&"#unnamed")
		color_label.add_theme_color_override(&"font_color", Color(0.5, 0.5, 0.5))
	else:
		color_label.text = new_text
		color_label.remove_theme_color_override(&"font_color")


func _on_delete_button_pressed() -> void:
	color_deletion_requested.emit()
	queue_free()


func _on_popup_hide() -> void:
	queue_free()
