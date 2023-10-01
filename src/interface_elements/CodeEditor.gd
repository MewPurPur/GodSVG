extends HBoxContainer

@onready var code_edit: CodeEdit = $CodeEdit
@onready var error_bar: PanelContainer = $CodeEdit/ErrorContainer
@onready var error_label: RichTextLabel = $CodeEdit/ErrorContainer/Padding/ErrorLabel

func _ready() -> void:
	SVG.parsing_finished.connect(update_error)
	auto_update_text()
	SVG.data.resized.connect(auto_update_text)
	SVG.data.attribute_changed.connect(auto_update_text)
	SVG.data.tag_added.connect(auto_update_text)
	SVG.data.tag_deleted.connect(auto_update_text)
	SVG.data.tag_moved.connect(auto_update_text)
	SVG.data.changed_unknown.connect(auto_update_text)

func auto_update_text() -> void:
	if not code_edit.has_focus():
		code_edit.text = SVG.string

func update_error(err: String) -> void:
	if err.is_empty():
		error_bar.hide()
	else:
		error_bar.show()
		error_label.text = err


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(code_edit.text)

func _on_code_edit_text_changed() -> void:
	SVG.string = code_edit.text
	SVG.sync_data()
