extends PanelContainer

@onready var version_label: Label = %VersionLabel
@onready var close_button: Button = $VBoxContainer/CloseButton

@onready var project_founder_list: PanelGrid = %ProjectFounder/List
@onready var authors_list: PanelGrid = %Developers/List
@onready var translations_list: PanelGrid = %Translations/List

@onready var donors_list: PanelGrid = %Donors/List
@onready var golden_donors_list: PanelGrid = %GoldenDonors/List
@onready var diamond_donors_list: PanelGrid = %DiamondDonors/List

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.LANGUAGE_CHANGED:
		update_translation()

func update_translation() -> void:
	%ProjectFounder/Label.text = TranslationServer.translate("Project Founder and Manager")
	%Developers/Label.text = TranslationServer.translate("Developers")
	%Translations/Label.text = TranslationServer.translate("Translators")
	%Donors/Label.text = TranslationServer.translate("Donors")
	%GoldenDonors/Label.text = TranslationServer.translate("Golden donors")
	%DiamondDonors/Label.text = TranslationServer.translate("Diamond donors")
	$VBoxContainer/TabContainer.set_tab_title(0, TranslationServer.translate("Authors"))
	$VBoxContainer/TabContainer.set_tab_title(1, TranslationServer.translate("Donors"))
	$VBoxContainer/TabContainer.set_tab_title(2, TranslationServer.translate("License"))
	$VBoxContainer/TabContainer.set_tab_title(3, TranslationServer.translate(
			"Third-party licenses"))
	%Components.text = TranslationServer.translate("Godot third-party components")

func _ready() -> void:
	version_label.text = "GodSVG v" + ProjectSettings.get_setting("application/config/version")
	project_founder_list.items = AppInfo.project_founder_and_manager
	project_founder_list.setup()
	authors_list.items = AppInfo.authors
	authors_list.setup()
	donors_list.items = AppInfo.donors
	donors_list.setup()
	golden_donors_list.items = AppInfo.golden_donors
	golden_donors_list.setup()
	diamond_donors_list.items = AppInfo.diamond_donors
	diamond_donors_list.setup()
	var translation_items: Array[String] = []
	for lang in TranslationServer.get_loaded_locales():
		var credits := TranslationServer.get_translation_object(lang).get_message(
				"translation-credits")
		if not credits.is_empty():
			translation_items.append(lang + ": " + credits)
	translations_list.items = translation_items
	translations_list.setup()
	close_button.pressed.connect(queue_free)
	update_translation()

func _on_components_pressed() -> void:
	OS.shell_open("https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt")
