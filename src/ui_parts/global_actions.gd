extends HBoxContainer

@onready var import_button: Button = $RightSide/ImportButton
@onready var export_button: Button = $RightSide/ExportButton
@onready var more_options: Button = $LeftSide/MoreOptions
@onready var settings_button: Button = $LeftSide/SettingsButton

func update_translations() -> void:
	import_button.tooltip_text = Translator.translate("Import")
	export_button.tooltip_text = Translator.translate("Export")
	settings_button.tooltip_text = Translator.translate("Settings")

func _ready() -> void:
	Configs.language_changed.connect(update_translations)
	update_translations()
	import_button.pressed.connect(ShortcutUtils.fn("import"))
	export_button.pressed.connect(ShortcutUtils.fn("export"))
	more_options.pressed.connect(_on_more_options_pressed)
	settings_button.pressed.connect(ShortcutUtils.fn_call.bind("open_settings"))


func _on_more_options_pressed() -> void:
	var can_show_savedata_folder := DisplayServer.has_feature(
				DisplayServer.FEATURE_NATIVE_DIALOG_FILE)
	var buttons_arr: Array[Button] = []
	buttons_arr.append(ContextPopup.create_button(Translator.translate(
			"Check for updates"), ShortcutUtils.fn("check_updates"), false,
			load("res://assets/icons/Reload.svg"), "check_updates"))
	
	if can_show_savedata_folder:
		buttons_arr.append(ContextPopup.create_button(Translator.translate(
				"View savedata"), open_savedata_folder , false,
				load("res://assets/icons/OpenFolder.svg")))
	
	var about_btn := ContextPopup.create_button(Translator.translate("About…"),
			ShortcutUtils.fn("about_info"), false, load("res://assets/logos/icon.png"),
			"about_info")
	about_btn.expand_icon = true
	buttons_arr.append(about_btn)
	buttons_arr.append(ContextPopup.create_button(Translator.translate(
			"Donate…"), ShortcutUtils.fn("about_donate"), false,
			load("res://assets/icons/Heart.svg"), "about_donate"))
	buttons_arr.append(ContextPopup.create_button(Translator.translate(
			"GodSVG repository"), ShortcutUtils.fn("about_repo"), false,
			load("res://assets/icons/Link.svg"), "about_repo"))
	buttons_arr.append(ContextPopup.create_button(Translator.translate(
			"GodSVG website"), ShortcutUtils.fn("about_website"), false,
			load("res://assets/icons/Link.svg"), "about_website"))
	var separator_indices := PackedInt32Array([1, 3])
	if can_show_savedata_folder:
		separator_indices = PackedInt32Array([2, 4])
	
	var more_popup := ContextPopup.new()
	more_popup.setup(buttons_arr, true, -1, -1, separator_indices)
	HandlerGUI.popup_under_rect_center(more_popup, more_options.get_global_rect(),
			get_viewport())


func open_savedata_folder() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"))
