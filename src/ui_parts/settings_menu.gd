extends PanelContainer

const SettingsContentGeneric = preload("res://src/ui_widgets/settings_content_generic.tscn")
const SettingsContentPalettes = preload("res://src/ui_widgets/settings_content_palettes.tscn")
const SettingsContentShortcuts = preload("res://src/ui_widgets/settings_content_shortcuts.tscn")

@onready var lang_button: Button = $VBoxContainer/Language
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var content_container: MarginContainer = %ScrollContainer/ContentContainer
@onready var tabs: VBoxContainer = %Tabs
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var preview_panel: PanelContainer = $VBoxContainer/PreviewPanel

enum TabIndex {FORMATTING, PALETTES, SHORTCUTS, THEMING, TAB_BAR, OTHER}

func get_tab_localized_name(tab_index: TabIndex) -> String:
	match tab_index:
		TabIndex.FORMATTING: return Translator.translate("Formatting")
		TabIndex.PALETTES: return Translator.translate("Palettes")
		TabIndex.SHORTCUTS: return Translator.translate("Shortcuts")
		TabIndex.THEMING: return Translator.translate("Theming")
		TabIndex.TAB_BAR: return Translator.translate("Tab bar")
		TabIndex.OTHER: return Translator.translate("Other")
	return ""

@warning_ignore("int_as_enum_without_match")
var focused_tab_index := -1 as TabIndex

func _ready() -> void:
	close_button.pressed.connect(queue_free)
	scroll_container.get_v_scroll_bar().visibility_changed.connect(adjust_right_margin)
	adjust_right_margin()
	
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	press_tab(0)

func _unhandled_input(event: InputEvent) -> void:
	var tab_count := TabIndex.size()
	if ShortcutUtils.is_action_pressed(event, "select_next_tab"):
		press_tab((focused_tab_index + 1) % tab_count)
	elif ShortcutUtils.is_action_pressed(event, "select_previous_tab"):
		press_tab((focused_tab_index + tab_count - 1) % tab_count)

func press_tab(index: int) -> void:
	tabs.get_child(index).button_pressed = true

func sync_theming() -> void:
	var stylebox := ThemeDB.get_default_theme().get_stylebox("panel", theme_type_variation).duplicate()
	stylebox.content_margin_top += 4.0
	add_theme_stylebox_override("panel", stylebox)

func sync_localization() -> void:
	close_button.text = Translator.translate("Close")
	lang_button.text = Translator.translate("Language") + ": " +\
			TranslationUtils.get_locale_string(TranslationServer.get_locale())
	setup_tabs()

func adjust_right_margin() -> void:
	var scrollbar := scroll_container.get_v_scroll_bar()
	content_container.add_theme_constant_override("margin_right",
			2 if scrollbar.visible else int(2 + scrollbar.size.x))

func setup_tabs() -> void:
	for tab in tabs.get_children():
		tab.queue_free()
	var button_group := ButtonGroup.new()
	for tab_index in TabIndex.size():
		var tab := Button.new()
		tab.text = get_tab_localized_name(tab_index)
		tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tab.toggle_mode = true
		tab.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		tab.focus_mode = Control.FOCUS_NONE
		tab.theme_type_variation = "SideTab"
		tab.toggled.connect(_on_tab_toggled.bind(tab_index))
		tab.button_group = button_group
		tab.button_pressed = (tab_index == focused_tab_index)
		tabs.add_child(tab)


func _on_tab_toggled(toggled_on: bool, tab_index: TabIndex) -> void:
	if toggled_on and focused_tab_index != tab_index:
		focused_tab_index = tab_index
		setup_content()

func setup_content() -> void:
	scroll_container.scroll_vertical = 0
	for child in content_container.get_children():
		child.queue_free()
	
	match focused_tab_index:
		TabIndex.FORMATTING:
			preview_panel.show()
			var current_content := SettingsContentGeneric.instantiate()
			current_content.setup([Configs.savedata.editor_formatter,
					Configs.savedata.export_formatter] as Array[ConfigResource], focused_tab_index)
			content_container.add_child(current_content)
			current_content.preview_changed.connect(set_preview)
		TabIndex.PALETTES:
			preview_panel.hide()
			var current_content := SettingsContentPalettes.instantiate()
			content_container.add_child(current_content)
		TabIndex.SHORTCUTS:
			preview_panel.hide()
			var current_content := SettingsContentShortcuts.instantiate()
			content_container.add_child(current_content)
		TabIndex.THEMING, TabIndex.TAB_BAR, TabIndex.OTHER:
			preview_panel.show()
			var current_content := SettingsContentGeneric.instantiate()
			current_content.setup([Configs.savedata] as Array[ConfigResource], focused_tab_index)
			content_container.add_child(current_content)
			current_content.preview_changed.connect(set_preview)
	# Update hover.
	HandlerGUI.throw_mouse_motion_event()


func set_preview(node: Control) -> void:
	for child in preview_panel.get_children():
		child.queue_free()
	preview_panel.add_child(node)


func _on_language_pressed() -> void:
	var strings_count := TranslationServer.get_translation_object("en").get_message_count()
	
	var btn_arr: Array[Button] = []
	for locale in TranslationServer.get_loaded_locales():
		var is_current_locale := (locale == TranslationServer.get_locale())
		
		# Translation percentages.
		if locale != "en":
			var translation_obj := TranslationServer.get_translation_object(locale)
			var translated_count := translation_obj.get_message_count() -\
					translation_obj.get_translated_message_list().count("")
			
			btn_arr.append(ContextPopup.create_button(
					TranslationUtils.get_locale_display(locale),
					_on_language_chosen.bind(locale), is_current_locale,
					null, Utils.num_simple(translated_count * 100.0 / strings_count, 1) + "%"))
		else:
			btn_arr.append(ContextPopup.create_button(
					TranslationUtils.get_locale_display(locale),
					_on_language_chosen.bind(locale), is_current_locale))
	
	var lang_popup := ContextPopup.new()
	lang_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(lang_popup, lang_button.get_global_rect(), get_viewport())

func _on_language_chosen(locale: String) -> void:
	Configs.savedata.language = locale
