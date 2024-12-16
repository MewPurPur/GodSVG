extends PanelContainer

@onready var add_empty_button: Button = $VBoxContainer/AddEmpty
@onready var import_button: Button = $VBoxContainer/Import

func _ready() -> void:
	Configs.language_changed.connect(update_translations)
	update_translations()
	add_empty_button.connect(Configs.savedata.add_empty_tab)
	import_button.connect(ShortcutUtils.fn("import"))

func update_translations() -> void:
	add_empty_button.text = Translator.translate("New empty SVG")
	import_button.text = Translator.translate("Import SVG")
