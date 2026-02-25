extends PanelContainer

const AboutAuthors = preload("res://src/ui_parts/about_authors.tscn")
const AboutDonors = preload("res://src/ui_parts/about_donors.tscn")
const AboutThirdPartyLicenses = preload("res://src/ui_parts/about_third_party_licenses.tscn")

enum TabIndex {AUTHORS, DONORS, LICENSE, THIRD_PARTY_LICENSES}

func get_tab_localized_name(tab_index: TabIndex) -> String:
	match tab_index:
		TabIndex.AUTHORS: return Translator.translate("Authors")
		TabIndex.DONORS: return Translator.translate("Donors")
		TabIndex.LICENSE: return Translator.translate("License")
		TabIndex.THIRD_PARTY_LICENSES: return Translator.translate("Third-party licenses")
	return ""

@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var tab_container: GoodTabContainer = $VBoxContainer/TabContainer

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
	
	for tab_index in TabIndex.size():
		tab_container.add_tab(get_tab_localized_name(tab_index))
	tab_container.get_content_method = get_content
	tab_container.select_tab(0)
	HandlerGUI.register_focus_sequence(self, [tab_container, close_button], true)


func select_next_tab() -> void:
	tab_container.current_tab = (tab_container.current_tab + 1) % tab_container.get_tab_count()

func select_previous_tab() -> void:
	var tab_count := tab_container.get_tab_count()
	tab_container.current_tab = (tab_container.current_tab + tab_count - 1) % tab_count

func get_content(index: int) -> Control:
	match index:
		TabIndex.AUTHORS:
			return AboutAuthors.instantiate()
		TabIndex.DONORS:
			return AboutDonors.instantiate()
		TabIndex.LICENSE:
			# Doesn't need to be translated.
			var license_label := Label.new()
			license_label.text = "MIT License\n\nCopyright (c) 2023 MewPurPur\nCopyright (c) 2023-present GodSVG contributors\n\n" +\
					Engine.get_license_info()["Expat"].strip_edges()
			license_label.add_theme_font_override("font", ThemeUtils.mono_font)
			license_label.add_theme_font_size_override("font_size", 11)
			return license_label
		TabIndex.THIRD_PARTY_LICENSES:
			return AboutThirdPartyLicenses.instantiate()
	return null
