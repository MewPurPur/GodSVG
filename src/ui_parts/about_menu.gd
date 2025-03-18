extends PanelContainer

const app_info_json = preload("res://app_info.json")

@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var translators_vbox: VBoxContainer = %TranslatorsVBox
@onready var developers_list: PanelGrid = %DevelopersList

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
			var app_info: Dictionary = app_info_json.data
			
			%ProjectFounderLabel.text = Translator.translate("Project Founder and Manager") +\
					": " + app_info.project_founder_and_manager
			%DevelopersLabel.text = Translator.translate("Developers")
			%TranslatorsLabel.text = Translator.translate("Translators")
			
			developers_list.items = app_info.authors
			
			# There can be multiple translators for a single locale.
			for locale in TranslationServer.get_loaded_locales():
				var credits := TranslationServer.get_translation_object(locale).get_message(
						"translation-credits").split(",", false)
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
		1:
			%Donors/Label.text = Translator.translate("Donors")
			%GoldenDonors/Label.text = Translator.translate("Golden donors")
			%DiamondDonors/Label.text = Translator.translate("Diamond donors")
			
			var app_info: Dictionary = app_info_json.data
			# Once the past donors lists start filling up, they will never unfill,
			# so no need to bother with logic, we can just unhide it manually.
			if app_info.donors.is_empty() and app_info.anonymous_donors == 0:
				%Donors.hide()
			else:
				donors_list.items = app_info.donors
				if app_info.anonymous_donors != 0:
					donors_list.dim_last_item = true
					donors_list.items.append("%d anonymous" % app_info.anonymous_donors)
			
			if app_info.golden_donors.is_empty() and app_info.anonymous_golden_donors == 0:
				%GoldenDonors.hide()
			else:
				golden_donors_list.items = app_info.golden_donors
				if app_info.anonymous_golden_donors != 0:
					golden_donors_list.dim_last_item = true
					golden_donors_list.items.append("%d anonymous" % app_info.anonymous_golden_donors)
			
			if app_info.diamond_donors.is_empty() and app_info.anonymous_diamond_donors == 0:
				%DiamondDonors.hide()
			else:
				diamond_donors_list.items = app_info.diamond_donors
				if app_info.anonymous_diamond_donors != 0:
					diamond_donors_list.dim_last_item = true
					diamond_donors_list.items.append("%d anonymous" % app_info.anonymous_diamond_donors)
			
			past_donors_list.items = app_info.past_donors
			if app_info.past_anonymous_donors != 0:
				past_donors_list.dim_last_item = true
				past_donors_list.items.append("%d anonymous" % app_info.past_anonymous_donors)
			
			past_golden_donors_list.items = app_info.past_golden_donors
			if app_info.past_anonymous_golden_donors != 0:
				past_golden_donors_list.dim_last_item = true
				past_golden_donors_list.items.append("%d anonymous" % app_info.past_anonymous_golden_donors)
			
			past_donors_list.items = app_info.past_diamond_donors
			if app_info.past_anonymous_diamond_donors != 0:
				past_diamond_donors_list.dim_last_item = true
				past_diamond_donors_list.items.append("%d anonymous" % app_info.past_anonymous_diamond_donors)
		2:
			# This part doesn't need to be translated.
			%LicenseLabel.text = "MIT License\n\nCopyright (c) 2023 MewPurPur\n" +\
					"Copyright (c) 2023-present GodSVG contributors\n\n" +\
					Engine.get_license_info()["Expat"]
		3:
			for child in %GodSVGParts.get_children():
				child.queue_free()
			for child in %GodotParts.get_children():
				child.queue_free()
			for child in %LicenseTexts.get_children():
				child.queue_free()
			
			# This part doesn't need to be translated.
			var godsvg_parts_label := Label.new()
			godsvg_parts_label.text = "GodSVG components"
			var godot_parts_label := Label.new()
			godot_parts_label.text = "Godot components"
			var license_texts_label := Label.new()
			license_texts_label.text = "Licenses"
			for label: Label in [godsvg_parts_label, godot_parts_label, license_texts_label]:
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.add_theme_font_size_override("font_size", 16)
			%GodSVGParts.add_child(godsvg_parts_label)
			%GodotParts.add_child(godot_parts_label)
			%LicenseTexts.add_child(license_texts_label)
			
			var godot_copyright_info := Engine.get_copyright_info()
			var godot_engine_copyright: Dictionary
			for dict in godot_copyright_info:
				if dict.name == "Godot Engine":
					dict.parts[0].erase("files")
					godot_engine_copyright = dict
					break
			
			var godsvg_copyright_info: Array[Dictionary] = [
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
				var label := Label.new()
				label.add_theme_font_size_override("font_size", 11)
				for part in copyright_info["parts"]:
					if part.has("files"):
						label.text += "Files:\n- %s\n" % "\n- ".join(part["files"])
					label.text += "© %s\nLicense: %s" % ["\n© ".join(
							part["copyright"]), part["license"]]
				var vbox := VBoxContainer.new()
				var name_label := Label.new()
				name_label.add_theme_font_size_override("font_size", 14)
				name_label.text = copyright_info["name"]
				vbox.add_child(name_label)
				vbox.add_child(label)
				%GodSVGParts.add_child(vbox)
			
			# Clean up Godot's copyright info from some stripped modules
			# to show more relevant components and load the UI faster.
			var used_licenses: PackedStringArray
			const unused_module_paths: PackedStringArray = ["modules/betsy",
					"modules/godot_physics_2d", "modules/godot_physics_3d",
					"modules/jolt_physics", "modules/lightmapper_rd", "thirdparty/brotli",
					"thirdparty/cvtt", "thirdparty/basis_universal", "thirdparty/d3d12",
					"thirdparty/etcpak", "thirdparty/graphite", "thirdparty/meshoptimizer",
					"thirdparty/minimp3", "thirdparty/minizip", "thirdparty/openxr",
					"thirdparty/tinyexr", "thirdparty/vhacd", "thirdparty/volk",
					"thirdparty/vulkan", "thirdparty/xatlas"]
			for copyright_info_idx in range(godot_copyright_info.size() - 1, -1, -1):
				var copyright_info: Dictionary = godot_copyright_info[copyright_info_idx]
				for part_idx in range(copyright_info["parts"].size() -1, -1, -1):
					var part: Dictionary = copyright_info["parts"][part_idx]
					if part.has("files"):
						for i in range(part["files"].size() - 1, -1, -1):
							for module_path in unused_module_paths:
								if module_path in part["files"][i]:
									part["files"].remove_at(i)
									break
						if part["files"].is_empty():
							godot_copyright_info.erase(copyright_info)
						else:
							var used_license: String = part["license"]
							if not used_license in used_licenses:
								used_licenses.append(used_license)
			
			for copyright_info in godot_copyright_info:
				var label := Label.new()
				label.add_theme_font_size_override("font_size", 11)
				for part in copyright_info["parts"]:
					if part.has("files"):
						label.text += "Files:\n- %s\n" % "\n- ".join(part["files"])
					label.text += "© %s\nLicense: %s" % ["\n© ".join(
							part["copyright"]), part["license"]]
				var vbox := VBoxContainer.new()
				var name_label := Label.new()
				name_label.add_theme_font_size_override("font_size", 14)
				name_label.text = copyright_info["name"]
				vbox.add_child(name_label)
				vbox.add_child(label)
				%GodotParts.add_child(vbox)
			
			var licenses_dict := Engine.get_license_info()
			for license_name in licenses_dict:
				if not license_name in used_licenses:
					continue
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
