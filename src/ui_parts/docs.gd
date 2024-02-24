extends PanelContainer

@onready var desc: RichTextLabel = %"#kbd_shortcuts_tab"

func _ready() -> void:
	for shortcut in [&"#shortcut_inspector_delete", &"#shortcut_inspector_ctrl_down",
	&"#shortcut_inspector_ctrl_up", &"#shortcut_inspector_ctrl_d"]:
		desc.add_text(tr(shortcut))
		desc.newline()


func _on_close_pressed() -> void:
	queue_free()
