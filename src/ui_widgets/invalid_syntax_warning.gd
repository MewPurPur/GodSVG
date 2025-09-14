extends MarginContainer

@onready var invalid_syntax_label: Label = $InvalidSyntaxLabel

func _ready() -> void:
	Configs.basic_colors_changed.connect(sync_invalid_syntax_label_color)
	sync_invalid_syntax_label_color()
	Configs.language_changed.connect(sync_localization)
	sync_localization()

func sync_invalid_syntax_label_color() -> void:
	invalid_syntax_label.add_theme_color_override("font_color", Configs.savedata.basic_color_error)

func sync_localization() -> void:
	invalid_syntax_label.text = Translator.translate("The SVG has invalid syntax. Any edit not made through the code editor will reset it.")
