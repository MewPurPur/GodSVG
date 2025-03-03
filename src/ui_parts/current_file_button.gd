extends Button

func _ready() -> void:
	Configs.active_tab_status_changed.connect(update_file_button)
	Configs.active_tab_changed.connect(update_file_button)
	pressed.connect(_on_file_button_pressed)
	update_file_button()

func _make_custom_tooltip(_for_text: String) -> Object:
	var label := Label.new()
	label.add_theme_font_override("font", ThemeUtils.mono_font)
	label.add_theme_font_size_override("font_size", 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = Configs.savedata.get_active_tab().get_presented_svg_file_path()
	Utils.set_max_text_width(label, 192.0, 4.0)
	return label

func _on_file_button_pressed() -> void:
	var btn_array: Array[Button] = []
	btn_array.append(ContextPopup.create_button(Translator.translate("Save SVG"),
			FileUtils.save_svg, false, load("res://assets/icons/Save.svg"), "save"))
	btn_array.append(ContextPopup.create_button(Translator.translate("Save SVG as…"),
			FileUtils.save_svg_as, false, load("res://assets/icons/Save.svg"), "save_as"))
	btn_array.append(ContextPopup.create_button(Translator.translate("Reset SVG"),
			ShortcutUtils.fn("reset_svg"),
			FileUtils.compare_svg_to_disk_contents() != FileUtils.FileState.DIFFERENT,
			load("res://assets/icons/Reload.svg"), "reset_svg"))
	btn_array.append(ContextPopup.create_button(Translator.translate("Open externally"),
			ShortcutUtils.fn("open_externally"),
			not FileAccess.file_exists(Configs.savedata.get_active_tab().svg_file_path),
			load("res://assets/icons/OpenFile.svg"), "open_externally"))
	btn_array.append(ContextPopup.create_button(Translator.translate("Show in File Manager"),
			ShortcutUtils.fn("open_in_folder"),
			not FileAccess.file_exists(Configs.savedata.get_active_tab().svg_file_path),
			load("res://assets/icons/OpenFolder.svg"), "open_in_folder"))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true, size.x, -1, PackedInt32Array([2]))
	HandlerGUI.popup_under_rect_center(context_popup, get_global_rect(), get_viewport())

func update_file_button() -> void:
	var file_name := State.transient_tab_path.get_file() if\
			not State.transient_tab_path.is_empty() else\
			Configs.savedata.get_active_tab().presented_name
	text = file_name
	tooltip_text = file_name
	Utils.set_max_text_width(self, 140.0, 12.0)
