extends PanelContainer

const UNUSED_MODULE_PATHS: PackedStringArray = ["modules/betsy", "modules/godot_physics_2d",
	"modules/godot_physics_3d", "modules/jolt_physics", "modules/lightmapper_rd", "thirdparty/brotli",
	"thirdparty/cvtt", "thirdparty/basis_universal", "thirdparty/d3d12", "thirdparty/etcpak",
	"thirdparty/graphite", "thirdparty/meshoptimizer", "thirdparty/minimp3", "thirdparty/minizip",
	"thirdparty/openxr", "thirdparty/tinyexr", "thirdparty/vhacd", "thirdparty/volk",
	"thirdparty/vulkan", "thirdparty/xatlas"
]

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
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("select_next_tab", select_next_tab)
	shortcuts.add_shortcut("select_previous_tab", select_previous_tab)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
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


func select_next_tab() -> void:
	tab_container.current_tab = (tab_container.current_tab + 1) % tab_container.get_tab_count()

func select_previous_tab() -> void:
	var tab_count := tab_container.get_tab_count()
	tab_container.current_tab = (tab_container.current_tab + tab_count - 1) % tab_count

func _on_tab_changed(idx: int) -> void:
	match idx:
		0:
			var app_info := get_app_info()
			
			%ProjectFounderLabel.text = Translator.translate("Project Founder and Manager") + ": " + app_info.project_founder_and_manager
			%DevelopersLabel.text = Translator.translate("Developers")
			%TranslatorsLabel.text = Translator.translate("Translators")
			
			developers_list.items = app_info.authors
			
			for child in translators_vbox.get_children():
				child.queue_free()
			
			# There can be multiple translators for a single locale.
			for locale in TranslationServer.get_loaded_locales():
				var credits := TranslationServer.get_translation_object(locale).get_message("translation-credits").split(",", false)
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
			var app_info := get_app_info()
			
			%Donors/Label.text = Translator.translate("Donors")
			%GoldenDonors/Label.text = Translator.translate("Golden donors")
			%DiamondDonors/Label.text = Translator.translate("Diamond donors")
			
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
			%LicenseLabel.text = "MIT License\n\nCopyright (c) 2023 MewPurPur\nCopyright (c) 2023-present GodSVG contributors\n\n" +\
					Engine.get_license_info()["Expat"]
		3:
			for control: Control in [%GodSVGParts, %GodotParts, %LicenseTexts]:
				for child in control.get_children():
					child.queue_free()
			
			# This part doesn't need to be translated.
			var godsvg_parts_label := Label.new()
			godsvg_parts_label.text = "GodSVG components"
			var godot_parts_label := Label.new()
			godot_parts_label.text = "Godot Engine components"
			var license_texts_label := Label.new()
			license_texts_label.text = "Licenses"
			for label: Label in [godsvg_parts_label, godot_parts_label, license_texts_label]:
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.theme_type_variation = "TitleLabel"
				label.add_theme_font_size_override("font_size", 17)
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
							"files": ["res://visual/fonts/original/NotoSans-SemiBold.woff2", "res://visual/fonts/original/NotoSans-ExtraBold.woff2"]
						}
					]
				},
				{
					"name": "Droid Sans font",
					"parts": [
						{
							"copyright": ["2008, The Android Open Source Project"],
							"license": "Apache-2.0",
							"files": ["res://visual/fonts/original/DroidSansFallback.woff2"]
						}
					]
				},
				{
					"name": "JetBrains Mono font",
					"parts": [
						{
							"copyright": ["2020, JetBrains s.r.o."],
							"license": "OFL-1.1",
							"files": ["res://visual/fonts/original/JetBrainsMono-Medium.woff2"]
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
					label.text += "© %s\nLicense: %s" % ["\n© ".join(part["copyright"]), part["license"]]
				var vbox := VBoxContainer.new()
				var name_label := Label.new()
				name_label.add_theme_font_size_override("font_size", 14)
				name_label.text = copyright_info["name"]
				vbox.add_child(name_label)
				vbox.add_child(label)
				%GodSVGParts.add_child(vbox)
			
			# Clean up Godot's copyright info from some stripped modules to show more relevant components and load the UI faster.
			var used_licenses: PackedStringArray
			for copyright_info_idx in range(godot_copyright_info.size() - 1, -1, -1):
				var copyright_info: Dictionary = godot_copyright_info[copyright_info_idx]
				for part_idx in range(copyright_info["parts"].size() -1, -1, -1):
					var part: Dictionary = copyright_info["parts"][part_idx]
					if part.has("files"):
						for i in range(part["files"].size() - 1, -1, -1):
							for module_path in UNUSED_MODULE_PATHS:
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
					label.text += "© %s\nLicense: %s" % ["\n© ".join(part["copyright"]), part["license"]]
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
				license_title.add_theme_font_size_override("font_size", 14)
				license_title.text = license_name
				license_vbox.add_child(license_title)
				var license_text := Label.new()
				license_text.add_theme_font_override("font", ThemeUtils.mono_font)
				license_text.add_theme_font_size_override("font_size", 11)
				license_text.text = licenses_dict[license_name]
				license_vbox.add_child(license_text)
				%LicenseTexts.add_child(license_vbox)


# Just enough of a parser to handle app_data.toml
func get_app_info() -> Dictionary[String, Variant]:
	var toml_text := FileAccess.get_file_as_string("res://app_info.toml")
	var lines := toml_text.split("\n", false)
	var result: Dictionary[String, Variant]
	var i := 0
	
	while i < lines.size():
		var line := lines[i].get_slice("#", 0).strip_edges()
		if line.is_empty():
			i += 1
			continue
		
		var parts := line.split("=", false, 2)
		if parts.size() != 2:
			i += 1
			continue
		
		var key := parts[0].strip_edges()
		var raw_value := parts[1].strip_edges()
		
		if raw_value.begins_with("["):
			var array_text := ""
			if raw_value.ends_with("]"):
				array_text = raw_value.substr(1, raw_value.length() - 2)
			else:
				array_text = raw_value.right(-1)
				while true:
					i += 1
					if i >= lines.size():
						break
					var next_line := lines[i].get_slice("#", 0).strip_edges()
					if next_line.ends_with("]"):
						array_text += " " + next_line.substr(0, next_line.length() - 1)
						break
					else:
						array_text += " " + next_line
			
			var elements := array_text.split(",", false)
			var arr := []
			for elem in elements:
				var v := elem.strip_edges()
				if (v.begins_with('"') and v.ends_with('"')) or (v.begins_with("'") and v.ends_with("'")):
					arr.append(v.substr(1, v.length() - 2))
				elif v.is_valid_int():
					arr.append(v.to_int())
				elif v.is_valid_float():
					arr.append(v.to_float())
			result[key] = arr
		
		else:
			if (raw_value.begins_with('"') and raw_value.ends_with('"')) or (raw_value.begins_with("'") and raw_value.ends_with("'")):
				result[key] = raw_value.substr(1, raw_value.length() - 2)
			elif raw_value.is_valid_int():
				result[key] = raw_value.to_int()
			elif raw_value.is_valid_float():
				result[key] = raw_value.to_float()
		
		i += 1
	
	return result
