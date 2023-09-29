extends HBoxContainer

@onready var code_edit: CodeEdit = $CodeEdit

func _ready() -> void:
	auto_update_text()
	SVG.data.resized.connect(auto_update_text)
	SVG.data.attribute_changed.connect(auto_update_text)
	SVG.data.tag_added.connect(auto_update_text)
	SVG.data.tag_deleted.connect(auto_update_text)
	SVG.data.tag_moved.connect(auto_update_text)
	SVG.data.changed_unknown.connect(auto_update_text)

func auto_update_text() -> void:
	if not has_focus():
		code_edit.text = SVG.string


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(code_edit.text)

func _on_code_edit_text_changed() -> void:
	SVG.string = code_edit.text
	SVG.sync_data()
