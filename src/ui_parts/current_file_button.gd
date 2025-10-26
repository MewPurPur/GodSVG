extends Button

func _ready() -> void:
	Configs.active_tab_status_changed.connect(update_file_button)
	Configs.active_tab_changed.connect(update_file_button)
	pressed.connect(_on_file_button_pressed)
	update_file_button()

func _make_custom_tooltip(_for_text: String) -> Object:
	var file_path := Configs.savedata.get_active_tab().get_presented_svg_file_path()
	if file_path.is_empty():
		return null
	
	var label := Label.new()
	label.add_theme_font_override("font", ThemeUtils.mono_font)
	label.add_theme_font_size_override("font_size", 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = file_path
	Utils.set_max_text_width(label, 192.0, 4.0)
	return label

func _on_file_button_pressed() -> void:
	var btn_array: Array[Button] = []
	btn_array.append(ContextPopup.create_shortcut_button("save"))
	btn_array.append(ContextPopup.create_shortcut_button("save_as", false,
			Translator.translate("Save SVG as…")))
	btn_array.append(ContextPopup.create_shortcut_button("reset_svg",
			FileUtils.compare_svg_to_disk_contents() != FileUtils.FileState.DIFFERENT))
	btn_array.append(ContextPopup.create_shortcut_button("open_externally",
			not FileAccess.file_exists(Configs.savedata.get_active_tab().svg_file_path)))
	btn_array.append(ContextPopup.create_shortcut_button("open_in_folder",
			not FileAccess.file_exists(Configs.savedata.get_active_tab().svg_file_path)))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true, size.x, PackedInt32Array([2]))
	HandlerGUI.popup_under_rect_center(context_popup, get_global_rect(), get_viewport())

func update_file_button() -> void:
	text = Configs.savedata.get_active_tab().presented_name
	Utils.set_max_text_width(self, 140.0, 12.0)
