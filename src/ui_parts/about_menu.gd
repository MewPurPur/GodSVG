extends PanelContainer

const app_info_json = preload("res://app_info.json")

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
@onready var tab_container: TabContainer = $VBoxContainer/TabContainer

func _ready() -> void:
	var stylebox := get_theme_stylebox("panel").duplicate()
	stylebox.content_margin_top += 2.0
	add_theme_stylebox_override("panel", stylebox)
	
	%VersionLabel.text = "GodSVG v" + ProjectSettings.get_setting("application/config/version")
	
	close_button.pressed.connect(queue_free)
	close_button.text = Translator.translate("Close")
	
	tab_container.set_tab_title(0, Translator.translate("Authors"))
	tab_container.set_tab_title(1, Translator.translate("Donors"))
	tab_container.set_tab_title(2, Translator.translate("License"))
	tab_container.set_tab_title(3, Translator.translate("Third-party licenses"))
	tab_container.tab_changed.connect(_on_tab_changed)
	_on_tab_changed(0)

func _on_tab_changed(idx: int) -> void:
	match idx:
		0:
			%ProjectFounder/Label.text = Translator.translate("Project Founder and Manager")
			%Developers/Label.text = Translator.translate("Developers")
			%Translations/Label.text = Translator.translate("Translators")
			
			var app_info: Dictionary = app_info_json.data
			project_founder_list.items = app_info.project_founder_and_manager
			project_founder_list.setup()
			authors_list.items = app_info.authors
			authors_list.setup()
			
			# There can be multiple translators for a single locale.
			for lang in TranslationServer.get_loaded_locales():
				var credits := TranslationServer.get_translation_object(lang).get_message(
						"translation-credits").split(",", false)
				if credits.is_empty():
					continue
				
				for i in credits.size():
					credits[i] = credits[i].strip_edges()
				
				var label := Label.new()
				label.text = TranslationServer.get_locale_name(lang) + " (%s):" % lang.to_upper()
				translations_list.add_child(label)
				var list := PanelGrid.new()
				list.stylebox = authors_list.stylebox
				list.add_theme_constant_override("h_separation", -1)
				list.add_theme_constant_override("v_separation", -1)
				list.items = credits
				list.setup()
				translations_list.add_child(list)
		1:
			%Donors/Label.text = Translator.translate("Donors")
			%GoldenDonors/Label.text = Translator.translate("Golden donors")
			%DiamondDonors/Label.text = Translator.translate("Diamond donors")
			
			var app_info: Dictionary = app_info_json.data
			# Once the past donors lists start filling up, they will never unfill,
			# so no need to bother with logic, we can just unhide it manually.
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
		2:
			# This part doesn't need to be translated.
			var licenses_dict := Engine.get_license_info()
			
			%LicenseLabel.text = "MIT License\n\nCopyright (c) 2023 MewPurPur\n" +\
			"Copyright (c) 2023-present GodSVG contributors\n\n" + licenses_dict["Expat"]
		3:
			# This part doesn't need to be translated.
			var licenses_dict := Engine.get_license_info()
			var godot_copyright_info := Engine.get_copyright_info()
			var godot_engine_copyright: Dictionary
			for dict in godot_copyright_info:
				if dict.name == "Godot Engine":
					dict.parts[0].erase("files")
					godot_engine_copyright = dict
					break
			
			var godsvg_copyright_info := [
				godot_engine_copyright,
				{
					"name": "Noto Sans font",
					"parts": [
						{
							"copyright": ["2012, Google Inc."],
							"license": "OFL-1.1",
							"files": ["res://visual/fonts/Font.ttf", "res://visual/fonts/FontBold.ttf"]
						}
					]
				},
				{
					"name": "JetBrains Mono font",
					"parts": [
						{
							"copyright": ["2020, JetBrains s.r.o."],
							"license": "OFL-1.1",
							"files": ["res://visual/fonts/FontMono.ttf"]
						}
					]
				}
			]
			
			for copyright_info in godsvg_copyright_info:
				var vbox := VBoxContainer.new()
				var name_label := Label.new()
				name_label.add_theme_font_size_override("font_size", 14)
				name_label.text = copyright_info["name"]
				vbox.add_child(name_label)
				
				var label := Label.new()
				label.add_theme_font_size_override("font_size", 11)
				for part in copyright_info["parts"]:
					if part.has("files"):
						label.text += "Files:\n- %s\n" % "\n- ".join(part["files"])
					label.text += "© %s\nLicense: %s" % ["\n© ".join(part["copyright"]), part["license"]]
				vbox.add_child(label)
				%GodSVGParts.add_child(vbox)
			
			for copyright_info in godot_copyright_info:
				var vbox := VBoxContainer.new()
				var name_label := Label.new()
				name_label.add_theme_font_size_override("font_size", 14)
				name_label.text = copyright_info["name"]
				vbox.add_child(name_label)
				
				var label := Label.new()
				label.add_theme_font_size_override("font_size", 11)
				for part in copyright_info["parts"]:
					if part.has("files"):
						label.text += "Files:\n- %s\n" % "\n- ".join(part["files"])
					label.text += "© %s\nLicense: %s" % ["\n© ".join(part["copyright"]), part["license"]]
				vbox.add_child(label)
				%GodotParts.add_child(vbox)
			
			for license_name in licenses_dict:
				var license_vbox := VBoxContainer.new()
				var license_title := Label.new()
				license_title.text = license_name
				license_vbox.add_child(license_title)
				var license_text := Label.new()
				license_text.add_theme_font_override("font", ThemeUtils.mono_font)
				license_text.add_theme_font_size_override("font_size", 11)
				license_text.text = licenses_dict[license_name]
				license_vbox.add_child(license_text)
				%LicenseTexts.add_child(license_vbox)
