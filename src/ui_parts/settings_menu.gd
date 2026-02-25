extends PanelContainer

const SettingsContentGeneric = preload("res://src/ui_widgets/settings_content_generic.tscn")
const SettingsContentPalettes = preload("res://src/ui_widgets/settings_content_palettes.tscn")
const SettingsContentShortcuts = preload("res://src/ui_widgets/settings_content_shortcuts.tscn")

@onready var language_button: Button = %LanguageButton
@onready var settings_tab_container: GoodTabContainer = %SettingsTabContainer
@onready var preview_panel: PanelContainer = %PreviewPanel
@onready var close_button: Button = %CloseButton

enum TabIndex {FORMATTING, OPTIMIZER, PALETTES, SHORTCUTS, THEMING, TAB_BAR, OTHER}

func get_tab_localized_name(tab_index: TabIndex) -> String:
	match tab_index:
		TabIndex.FORMATTING: return Translator.translate("Formatting")
		TabIndex.OPTIMIZER: return Translator.translate("Optimizer")
		TabIndex.PALETTES: return Translator.translate("Palettes")
		TabIndex.SHORTCUTS: return Translator.translate("Shortcuts")
		TabIndex.THEMING: return Translator.translate("Theming")
		TabIndex.TAB_BAR: return Translator.translate("Tab bar")
		TabIndex.OTHER: return Translator.translate("Other")
	return ""

func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("select_next_tab", select_next_tab)
	shortcuts.add_shortcut("select_previous_tab", select_previous_tab)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	close_button.pressed.connect(queue_free)
	language_button.pressed.connect(_on_language_pressed)
	
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	
	settings_tab_container.get_content_method = get_content
	settings_tab_container.select_tab(0)
	HandlerGUI.register_focus_sequence(self, [language_button, settings_tab_container, close_button], true)

func select_next_tab() -> void:
	settings_tab_container.select_tab((settings_tab_container.current_tab_index + 1) % TabIndex.size())

func select_previous_tab() -> void:
	var tab_count := TabIndex.size()
	settings_tab_container.select_tab((settings_tab_container.current_tab_index + tab_count - 1) % tab_count)

func sync_theming() -> void:
	var stylebox := ThemeDB.get_default_theme().get_stylebox("panel", theme_type_variation).duplicate()
	stylebox.content_margin_top += 4.0
	add_theme_stylebox_override("panel", stylebox)
	setup_tabs()

func sync_localization() -> void:
	close_button.text = Translator.translate("Close")
	language_button.text = Translator.translate("Language") + ": " + TranslationUtils.get_locale_string(TranslationServer.get_locale())
	setup_tabs()

func setup_tabs() -> void:
	settings_tab_container.clear_all_tabs()
	for tab_index in TabIndex.size():
		settings_tab_container.add_tab(get_tab_localized_name(tab_index))

func get_content(index: TabIndex) -> Control:
	var current_content: Control = null
	preview_panel.visible = index in [TabIndex.FORMATTING, TabIndex.THEMING, TabIndex.TAB_BAR, TabIndex.OTHER]
	match index:
		TabIndex.FORMATTING:
			current_content = SettingsContentGeneric.instantiate()
			current_content.setup([Configs.savedata.editor_formatter,
					Configs.savedata.export_formatter] as Array[ConfigResource], current_content.setup_formatting_content)
			current_content.preview_changed.connect(set_preview)
		TabIndex.OPTIMIZER:
			current_content = SettingsContentGeneric.instantiate()
			current_content.setup([Configs.savedata.default_optimizer] as Array[ConfigResource], current_content.setup_optimizer_content)
		TabIndex.PALETTES:
			current_content = SettingsContentPalettes.instantiate()
		TabIndex.SHORTCUTS:
			current_content = SettingsContentShortcuts.instantiate()
		TabIndex.THEMING, TabIndex.TAB_BAR, TabIndex.OTHER:
			current_content = SettingsContentGeneric.instantiate()
			var callback := Callable()
			match index:
				TabIndex.THEMING: callback = current_content.setup_theming_content
				TabIndex.TAB_BAR: callback = current_content.setup_tab_bar_content
				TabIndex.OTHER: callback = current_content.setup_other_content
			current_content.setup([Configs.savedata] as Array[ConfigResource], callback)
			current_content.preview_changed.connect(set_preview)
	# Update hover.
	HandlerGUI.throw_mouse_motion_event()
	return current_content


func set_preview(node: Control) -> void:
	for child in preview_panel.get_children():
		child.queue_free()
	if is_instance_valid(node):
		preview_panel.add_child(node)


func _on_language_pressed() -> void:
	var strings_count := TranslationServer.find_translations("en", true)[0].get_message_count()
	
	var btn_arr: Array[ContextButton] = []
	for locale in TranslationServer.get_loaded_locales():
		var is_current_locale := (locale == TranslationServer.get_locale())
		
		var btn := ContextButton.create_custom(TranslationUtils.get_locale_display(locale),
				_on_language_chosen.bind(locale), null, is_current_locale)
		
		if locale != "en":
			var translation_obj := TranslationServer.find_translations(locale, true)[0]
			var translated_count := translation_obj.get_message_count() - translation_obj.get_translated_message_list().count("")
			btn.add_custom_dim_text(Utils.num_simple(translated_count * 100.0 / strings_count, 1) + "%")
		btn_arr.append(btn)
	
	HandlerGUI.popup_under_rect_center(ContextPopup.create(btn_arr), language_button.get_global_rect(), get_viewport())

func _on_language_chosen(locale: String) -> void:
	Configs.savedata.language = locale
