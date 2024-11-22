extends PanelContainer

@onready var title_label: Label = $MainContainer/TextContainer/Title
@onready var label: RichTextLabel = $MainContainer/TextContainer/Label
@onready var cancel_button: Button = $MainContainer/ButtonContainer/CancelButton
@onready var action_button: Button = $MainContainer/ButtonContainer/ActionButton

func _ready() -> void:
	cancel_button.pressed.connect(queue_free)
	action_button.pressed.connect(queue_free)
	action_button.grab_focus()

func setup(title: String, message: String, action_text: String, action: Callable) -> void:
	label.text = message
	title_label.text = title
	cancel_button.text = Translator.translate("Cancel")
	action_button.text = action_text
	action_button.pressed.connect(action)
	action_button.grab_focus()
	label.custom_minimum_size.x = 300.0
