extends VBoxContainer

@onready var project_founder_label: Label = $ProjectFounderLabel
@onready var developers_label: Label = $DevelopersLabel
@onready var developers_list: PanelGrid = $DevelopersList
@onready var translators_label: Label = $TranslatorsLabel
@onready var translators_vbox: VBoxContainer = $TranslatorsVBox

func _ready() -> void:
	var app_info := Utils.get_app_info()
	
	project_founder_label.text = Translator.translate("Project Founder and Manager") + ": " + app_info.project_founder_and_manager
	developers_label.text = Translator.translate("Developers")
	translators_label.text = Translator.translate("Translators")
	
	developers_list.items = app_info.authors
	
	for child in translators_vbox.get_children():
		child.queue_free()
	
	# There can be multiple translators for a single locale.
	for locale in TranslationServer.get_loaded_locales():
		var credits := TranslationServer.find_translations(locale, true)[0].get_message("translation-credits").split(",", false)
		if credits.is_empty():
			continue
		
		for i in credits.size():
			credits[i] = credits[i].strip_edges()
		
		var label := Label.new()
		label.text = " " + TranslationUtils.get_locale_display(locale)
		translators_vbox.add_child(label)
		var list := PanelGrid.new()
		list.columns = 1
		list.items = credits
		translators_vbox.add_child(list)
