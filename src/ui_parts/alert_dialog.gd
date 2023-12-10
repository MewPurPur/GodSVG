extends Dialog

@onready var title: Label = %MainContainer/TextContainer/Title
@onready var label: RichTextLabel = %MainContainer/TextContainer/Label
@onready var ok_button: Button = $PanelContainer/MarginContainer/MainContainer/OKButton

func _ready() -> void:
	ok_button.grab_focus()

func setup(message: String, title_text := "#alert", min_width := 180.0) -> void:
	label.text = tr(message)
	title.text = tr(title_text)
	label.custom_minimum_size.x = min_width

func _on_ok_button_pressed() -> void:
	queue_free()
