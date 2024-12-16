extends HBoxContainer

@onready var layout_button: Button = $LayoutButton
@onready var size_button: Button = $SizeButton
@onready var file_button: Button = $FileButton
@onready var import_button: Button = $ImportButton
@onready var export_button: Button = $ExportButton
@onready var more_button: Button = $MoreButton

enum Layout {CODE_EDITOR_TOP_INSPECTOR_BOTTOM, INSPECTOR_TOP_CODE_EDITOR_BOTTOM,
		ONLY_CODE_EDITOR, ONLY_INSPECTOR}

func set_layout(new_layout: Layout) -> void:
	Configs.savedata.layout = new_layout


func update_translation() -> void:
	import_button.tooltip_text = Translator.translate("Import")
	export_button.tooltip_text = Translator.translate("Export")
	layout_button.tooltip_text = Translator.translate("Choose layout")
	more_button.tooltip_text = Translator.translate("Other actions")

func _ready() -> void:
	# Fix the size button sizing.
	size_button.begin_bulk_theme_override()
	for theming in ["normal", "hover", "pressed", "disabled"]:
		var stylebox := size_button.get_theme_stylebox(theming).duplicate()
		stylebox.content_margin_bottom = 0
		stylebox.content_margin_top = 0
		size_button.add_theme_stylebox_override(theming, stylebox)
	size_button.end_bulk_theme_override()
	# Connect buttons to methods.
	import_button.pressed.connect(ShortcutUtils.fn("import"))
	export_button.pressed.connect(ShortcutUtils.fn("export"))
	file_button.pressed.connect(_on_file_button_pressed)
	size_button.pressed.connect(_on_size_button_pressed)
	layout_button.pressed.connect(_on_layout_button_pressed)
	more_button.pressed.connect(_on_action_button_pressed)
	Configs.basic_colors_changed.connect(update_size_button_colors)
	SVG.changed.connect(update_size_button)
	Configs.language_changed.connect(update_translation)
	update_size_button()
	update_file_button()
	update_translation()


func update_size_button() -> void:
	var svg_text_size := SVG.text.length()
	size_button.text = String.humanize_size(svg_text_size)
	size_button.tooltip_text = String.num_uint64(svg_text_size) + " B"
	if SVG.root_element.optimize(true):
		size_button.disabled = false
		size_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		update_size_button_colors()
	else:
		size_button.disabled = true
		size_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		size_button.remove_theme_color_override("font_color")

func update_size_button_colors() -> void:
	size_button.begin_bulk_theme_override()
	for theming in ["font_color", "font_hover_color", "font_pressed_color"]:
		size_button.add_theme_color_override(theming,
				Configs.savedata.theme_config.basic_color_warning.lerp(
				Configs.savedata.theme_config.common_text_color, 0.5))
	size_button.end_bulk_theme_override()

func update_file_button() -> void:
	var tab := Configs.savedata.get_current_tab()
	if tab != null:
		var file_path := tab.svg_file_path
		file_button.visible = !file_path.is_empty()
		file_button.text = file_path.get_file()
		file_button.tooltip_text = file_path.get_file()
		Utils.set_max_text_width(file_button, 140.0, 12.0)


func _on_file_button_pressed() -> void:
	var btn_array: Array[Button] = []
	btn_array.append(ContextPopup.create_button(Translator.translate("Save SVG"),
			FileUtils.save_svg, false, load("res://visual/icons/Save.svg"), "save"))
	btn_array.append(ContextPopup.create_button(Translator.translate("Open file"),
			ShortcutUtils.fn("open_svg"),
			not FileAccess.file_exists(Configs.get_current_tab().svg_file_path),
			load("res://visual/icons/OpenFile.svg"), "open_svg"))
	btn_array.append(ContextPopup.create_button(Translator.translate("Reset SVG"),
			ShortcutUtils.fn("reset_svg"),
			FileUtils.compare_svg_to_disk_contents() != FileUtils.FileState.DIFFERENT,
			load("res://visual/icons/Reload.svg"), "reset_svg"))
	btn_array.append(ContextPopup.create_button(
			Translator.translate("Clear saving path"),
			ShortcutUtils.fn("clear_file_path"), false, load("res://visual/icons/Clear.svg"),
			"clear_file_path"))
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true, file_button.size.x)
	HandlerGUI.popup_under_rect_center(context_popup, file_button.get_global_rect(),
			get_viewport())

func _on_size_button_pressed() -> void:
	var btn_array: Array[Button] = [
		ContextPopup.create_button(Translator.translate("Optimize"),
				ShortcutUtils.fn("optimize"), false, load("res://visual/icons/Compress.svg"),
				"optimize")]
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true)
	HandlerGUI.popup_under_rect_center(context_popup, size_button.get_global_rect(),
			get_viewport())

func _on_layout_button_pressed() -> void:
	var btn_array: Array[Button] = [
		ContextPopup.create_button(Translator.translate("Default"),
				set_layout.bind(Layout.CODE_EDITOR_TOP_INSPECTOR_BOTTOM),
				Configs.savedata.layout == Layout.CODE_EDITOR_TOP_INSPECTOR_BOTTOM),
		ContextPopup.create_button(Translator.translate("Only inspector"),
				set_layout.bind(Layout.ONLY_INSPECTOR),
				Configs.savedata.layout == Layout.ONLY_INSPECTOR),
		ContextPopup.create_button(Translator.translate("Only code editor"),
				set_layout.bind(Layout.ONLY_CODE_EDITOR),
				Configs.savedata.layout == Layout.ONLY_CODE_EDITOR)]
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true)
	HandlerGUI.popup_under_rect_center(context_popup, layout_button.get_global_rect(),
			get_viewport())

func _on_action_button_pressed() -> void:
	var btn_array: Array[Button] = [
		ContextPopup.create_button(Translator.translate("Clear SVG"),
				ShortcutUtils.fn("clear_svg"), SVG.text == SVG.DEFAULT,
				load("res://visual/icons/Clear.svg"), "clear_svg")]
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true)
	HandlerGUI.popup_under_rect_center(context_popup, more_button.get_global_rect(),
			get_viewport())
