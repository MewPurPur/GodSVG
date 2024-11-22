extends PanelContainer

@onready var title: Label = $MainContainer/TextContainer/Title
@onready var label: RichTextLabel = $MainContainer/TextContainer/Label
@onready var ok_button: Button = $MainContainer/OKButton

func _ready() -> void:
	ok_button.pressed.connect(queue_free)
	ok_button.grab_focus()

func setup(message: String) -> void:
	label.text = message
	title.text = Translator.translate("Alert!")
	ok_button.text = Translator.translate("OK")
	label.custom_minimum_size.x = 280.0
