extends PanelContainer

@onready var desc: RichTextLabel = %"Shortcuts"

func _ready() -> void:
	for shortcut in [&"Delete: Deletes the selected tags", &"Ctrl+Down: Moves the selected tags down",
	&"Ctrl+Up: Moves the selected tags up", &"Ctrl+D: Duplicates the selected tags"]:
		desc.add_text(tr(shortcut))
		desc.newline()


func _on_close_pressed() -> void:
	queue_free()
