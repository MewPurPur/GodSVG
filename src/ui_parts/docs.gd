extends ColorRect

@onready var desc: RichTextLabel = %Desc

func _ready() -> void:
	desc.add_text(tr(&"#shortcut_inspector_delete"))
	desc.newline()
	desc.add_text(tr(&"#shortcut_inspector_alt_down"))
	desc.newline()
	desc.add_text(tr(&"#shortcut_inspector_alt_up"))


func _on_close_pressed() -> void:
	queue_free()
