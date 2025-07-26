extends PanelContainer

const PaletteConfigWidgetScene = preload("res://src/ui_widgets/palette_config.tscn")
const ShortcutConfigWidgetScene = preload("res://src/ui_widgets/setting_shortcut.tscn")
const ShortcutShowcaseWidgetScene = preload("res://src/ui_widgets/presented_shortcut.tscn")

const SettingsContentGeneric = preload("res://src/ui_widgets/settings_content_generic.tscn")

const plus_icon = preload("res://assets/icons/Plus.svg")
const import_icon = preload("res://assets/icons/Import.svg")
const reset_icon = preload("res://assets/icons/Reload.svg")

@onready var lang_button: Button = $VBoxContainer/Language
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var content_container: MarginContainer = %ScrollContainer/ContentContainer
@onready var tabs: VBoxContainer = %Tabs
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var preview_panel: PanelContainer = $VBoxContainer/PreviewPanel

enum TabIndex {FORMATTING, PALETTES, SHORTCUTS, THEMING, TAB_BAR, OTHER}

var tab_localized_names: Dictionary[TabIndex, String] = {
	TabIndex.FORMATTING: Translator.translate("Formatting"),
	TabIndex.PALETTES: Translator.translate("Palettes"),
	TabIndex.SHORTCUTS: Translator.translate("Shortcuts"),
	TabIndex.THEMING: Translator.translate("Theming"),
	TabIndex.TAB_BAR: Translator.translate("Tab bar"),
	TabIndex.OTHER: Translator.translate("Other"),
}

@warning_ignore("int_as_enum_without_match")
var focused_tab_index := -1 as TabIndex 

var current_content: Control

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
		tab.text = tab_localized_names[tab_index]
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
			current_content = SettingsContentGeneric.instantiate()
			current_content.setup([Configs.savedata.editor_formatter,
					Configs.savedata.export_formatter] as Array[ConfigResource], focused_tab_index)
			content_container.add_child(current_content)
			current_content.preview_changed.connect(set_preview)
		TabIndex.PALETTES:
			preview_panel.hide()
			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_container.add_child(vbox)
			rebuild_palettes()
		TabIndex.SHORTCUTS:
			preview_panel.hide()
			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.add_theme_constant_override("separation", 6)
			content_container.add_child(vbox)
			var categories := HFlowContainer.new()
			var button_group := ButtonGroup.new()
			for tab_idx in shortcut_tab_names:
				var btn := Button.new()
				btn.toggle_mode = true
				btn.button_group = button_group
				btn.pressed.connect(show_shortcuts.bind(tab_idx))
				btn.text = get_translated_shortcut_tab(tab_idx)
				btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				btn.focus_mode = Control.FOCUS_NONE
				btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
				categories.add_child(btn)
			vbox.add_child(categories)
			var shortcuts := VBoxContainer.new()
			shortcuts.add_theme_constant_override("separation", 3)
			shortcuts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			shortcuts.size_flags_vertical = Control.SIZE_EXPAND_FILL
			vbox.add_child(shortcuts)
			categories.get_child(0).button_pressed = true
			categories.get_child(0).pressed.emit()
		TabIndex.THEMING, TabIndex.TAB_BAR, TabIndex.OTHER:
			preview_panel.show()
			current_content = SettingsContentGeneric.instantiate()
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
	HandlerGUI.popup_under_rect_center(lang_popup, lang_button.get_global_rect(),
			get_viewport())

func _on_language_chosen(locale: String) -> void:
	Configs.savedata.language = locale


# Palette tab helpers.

func _popup_xml_palette_options(palette_xml_button: Button) -> void:
	var btn_arr: Array[Button] = []
	btn_arr.append(ContextPopup.create_button(Translator.translate("Import XML"),
			add_imported_palette, false, load("res://assets/icons/Import.svg")))
	btn_arr.append(ContextPopup.create_button(Translator.translate("Paste XML"),
			add_pasted_palette, !Palette.is_valid_palette(Utils.get_clipboard_web_safe()),
			load("res://assets/icons/Paste.svg")))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(context_popup, palette_xml_button.get_global_rect(),
			get_viewport())


func add_empty_palette() -> void:
	_shared_add_palette_logic(Palette.new())

func add_pasted_palette() -> void:
	_shared_add_palettes_logic(Palette.text_to_palettes(Utils.get_clipboard_web_safe()))

func add_imported_palette() -> void:
	FileUtils.open_xml_import_dialog(_on_import_palette_finished)

func _on_import_palette_finished(file_text: String) -> void:
	_shared_add_palettes_logic(Palette.text_to_palettes(file_text))

func _shared_add_palettes_logic(palettes: Array[Palette]) -> void:
	if not palettes.is_empty():
		_shared_add_palette_logic(palettes[0])

func _shared_add_palette_logic(palette: Palette) -> void:
	Configs.savedata.add_palette(palette)
	rebuild_palettes()


func rebuild_palettes() -> void:
	var palette_container := content_container.get_child(-1)
	for palette_config in palette_container.get_children():
		palette_config.queue_free()
	for palette in Configs.savedata.get_palettes():
		var palette_config := PaletteConfigWidgetScene.instantiate()
		palette_container.add_child(palette_config)
		palette_config.assign_palette(palette)
		palette_config.layout_changed.connect(rebuild_palettes)
	
	# Add the buttons for adding a new palette.
	var spacer := Control.new()
	palette_container.add_child(spacer)
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	palette_container.add_child(hbox)
	
	var add_palette_button := Button.new()
	add_palette_button.theme_type_variation = "TranslucentButton"
	add_palette_button.icon = plus_icon
	add_palette_button.text = Translator.translate("New palette")
	add_palette_button.focus_mode = Control.FOCUS_NONE
	add_palette_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_palette_button.pressed.connect(add_empty_palette)
	hbox.add_child(add_palette_button)
	
	var xml_palette_button := Button.new()
	xml_palette_button.theme_type_variation = "TranslucentButton"
	xml_palette_button.icon = import_icon
	xml_palette_button.text = Translator.translate("New palette from XML")
	xml_palette_button.focus_mode = Control.FOCUS_NONE
	xml_palette_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hbox.add_child(xml_palette_button)
	xml_palette_button.pressed.connect(_popup_xml_palette_options.bind(xml_palette_button))


var shortcut_tab_names := PackedStringArray(["file", "edit", "view", "tool", "help"])

func get_translated_shortcut_tab(tab_idx: String) -> String:
	match tab_idx:
		"file": return Translator.translate("File")
		"edit": return Translator.translate("Edit")
		"view": return Translator.translate("View")
		"tool": return Translator.translate("Tool")
		"help": return Translator.translate("Help")
	return ""


func show_shortcuts(category: String) -> void:
	var shortcuts_container := content_container.get_child(-1).get_child(-1)
	for child in shortcuts_container.get_children():
		child.queue_free()
	
	for action in ShortcutUtils.get_actions(category):
		var shortcut_config := ShortcutConfigWidgetScene.instantiate() if\
				ShortcutUtils.is_action_modifiable(action) else\
				ShortcutShowcaseWidgetScene.instantiate()
		
		shortcuts_container.add_child(shortcut_config)
		shortcut_config.label.text = TranslationUtils.get_action_description(action)
		shortcut_config.setup(action)
