extends PanelContainer

const app_info_json = preload("res://app_info.json")

@onready var version_label: Label = %VersionLabel
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var translations_list: VBoxContainer = %Translations/List

@onready var project_founder_list: PanelGrid = %ProjectFounder/List
@onready var authors_list: PanelGrid = %Developers/List

@onready var donors_vbox: VBoxContainer = %Donors
@onready var golden_donors_vbox: VBoxContainer = %GoldenDonors
@onready var diamond_donors_vbox: VBoxContainer = %DiamondDonors
@onready var donors_list: PanelGrid = %Donors/List
@onready var golden_donors_list: PanelGrid = %GoldenDonors/List
@onready var diamond_donors_list: PanelGrid = %DiamondDonors/List
@onready var past_donors_list: PanelGrid = %PastDonors/List
@onready var past_golden_donors_list: PanelGrid = %PastGoldenDonors/List
@onready var past_diamond_donors_list: PanelGrid = %PastDiamondDonors/List

func _ready() -> void:
	var app_info: Dictionary = app_info_json.data
	version_label.text = "GodSVG v" + ProjectSettings.get_setting("application/config/version")
	project_founder_list.items = app_info.project_founder_and_manager
	project_founder_list.setup()
	authors_list.items = app_info.authors
	authors_list.setup()
	# Once the past donors lists start filling up, they will never unfill, so no need to
	# bother with logic, we can just unhide it manually.
	if app_info.donors.is_empty() and app_info.anonymous_donors == 0:
		donors_vbox.hide()
	else:
		donors_list.items = app_info.donors
		if app_info.anonymous_donors != 0:
			donors_list.dim_last_item = true
			donors_list.items.append("%d anonymous" % app_info.anonymous_donors)
		donors_list.setup()
	
	if app_info.golden_donors.is_empty() and app_info.anonymous_golden_donors == 0:
		golden_donors_vbox.hide()
	else:
		golden_donors_list.items = app_info.golden_donors
		if app_info.anonymous_golden_donors != 0:
			golden_donors_list.dim_last_item = true
			golden_donors_list.items.append("%d anonymous" % app_info.anonymous_golden_donors)
		golden_donors_list.setup()
	
	if app_info.diamond_donors.is_empty() and app_info.anonymous_diamond_donors == 0:
		diamond_donors_vbox.hide()
	else:
		diamond_donors_list.items = app_info.diamond_donors
		if app_info.anonymous_diamond_donors != 0:
			diamond_donors_list.dim_last_item = true
			diamond_donors_list.items.append("%d anonymous" % app_info.anonymous_diamond_donors)
		diamond_donors_list.setup()
	
	past_donors_list.items = app_info.past_donors
	if app_info.past_anonymous_donors != 0:
		past_donors_list.dim_last_item = true
		past_donors_list.items.append("%d anonymous" % app_info.past_anonymous_donors)
	past_donors_list.setup()
	
	past_golden_donors_list.items = app_info.past_golden_donors
	if app_info.past_anonymous_golden_donors != 0:
		past_golden_donors_list.dim_last_item = true
		past_golden_donors_list.items.append("%d anonymous" % app_info.past_anonymous_golden_donors)
	past_golden_donors_list.setup()
	
	past_donors_list.items = app_info.past_diamond_donors
	if app_info.past_anonymous_diamond_donors != 0:
		past_diamond_donors_list.dim_last_item = true
		past_diamond_donors_list.items.append("%d anonymous" % app_info.past_anonymous_diamond_donors)
	past_diamond_donors_list.setup()
	# There can be multiple translators for a single locale.
	for lang in TranslationServer.get_loaded_locales():
		var credits := TranslationServer.get_translation_object(lang).get_message(
				"translation-credits").split(",", false)
		if credits.is_empty():
			continue
		
		for i in credits.size():
			credits[i] = credits[i].strip_edges()
		
		var label := Label.new()
		label.text = TranslationServer.get_locale_name(lang) + " (%s):" % lang
		translations_list.add_child(label)
		var list := PanelGrid.new()
		list.stylebox = authors_list.stylebox
		list.add_theme_constant_override("h_separation", -1)
		list.add_theme_constant_override("v_separation", -1)
		list.items = credits
		list.setup()
		translations_list.add_child(list)
	
	close_button.pressed.connect(queue_free)
	
	%ProjectFounder/Label.text = Translator.translate("Project Founder and Manager")
	%Developers/Label.text = Translator.translate("Developers")
	%Translations/Label.text = Translator.translate("Translators")
	%Donors/Label.text = Translator.translate("Donors")
	%GoldenDonors/Label.text = Translator.translate("Golden donors")
	%DiamondDonors/Label.text = Translator.translate("Diamond donors")
	$VBoxContainer/TabContainer.set_tab_title(0, Translator.translate("Authors"))
	$VBoxContainer/TabContainer.set_tab_title(1, Translator.translate("Donors"))
	$VBoxContainer/TabContainer.set_tab_title(2, Translator.translate("License"))
	$VBoxContainer/TabContainer.set_tab_title(3, Translator.translate(
			"Third-party licenses"))
	%Components.text = Translator.translate("Godot third-party components")

func _on_components_pressed() -> void:
	OS.shell_open("https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt")
