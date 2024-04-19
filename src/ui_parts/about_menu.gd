extends PanelContainer

@onready var project_founder_list: PanelGrid = %ProjectFounder/List
@onready var authors_list: PanelGrid = %Developers/List
@onready var translations_list: PanelGrid = %Translations/List
@onready var donors_list: PanelGrid = %DonorsList
@onready var version_label: Label = %VersionLabel

func _ready() -> void:
	if not ProjectSettings.has_setting("application/config/version"):
		version_label.text = "GodSVG (Version information unavailable)"
	else:
		version_label.text = "GodSVG v" + ProjectSettings.get_setting("application/config/version")
	project_founder_list.items = AppInfo.project_founder_and_manager
	project_founder_list.setup()
	authors_list.items = AppInfo.authors
	authors_list.setup()
	donors_list.items = AppInfo.donors
	donors_list.setup()
	var translation_items: Array[String] = []
	for lang in TranslationServer.get_loaded_locales():
		var credits := TranslationServer.get_translation_object(lang).get_message(
				"translation-credits")
		if not credits.is_empty():
			translation_items.append(lang + ": " + credits)
	translations_list.items = translation_items
	translations_list.setup()

func _on_components_pressed() -> void:
	OS.shell_open("https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt")

func _on_close_pressed() -> void:
	HandlerGUI.remove_overlay()
