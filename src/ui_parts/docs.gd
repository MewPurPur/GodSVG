extends ColorRect

@onready var desc: RichTextLabel = %Desc

func _ready() -> void:
	desc.add_text(tr(&"#shortcut_inspector_delete"))
	desc.newline()
	desc.add_text(tr(&"#shortcut_inspector_ctrl_down"))
	desc.newline()
	desc.add_text(tr(&"#shortcut_inspector_ctrl_up"))
	desc.newline()
	desc.add_text(tr(&"#shortcut_inspector_ctrl_d"))


func _on_close_pressed() -> void:
	queue_free()
