extends PanelContainer

const SettingCheckBox = preload("res://src/ui_elements/setting_check_box.gd")

@onready var number_vbox: VBoxContainer = %NumberVBox
@onready var color_vbox: VBoxContainer = %ColorVBox
@onready var path_vbox: VBoxContainer = %PathVBox

func _ready() -> void:
	disable_checkboxes()

func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_autoformat_settings_changed() -> void:
	SVG.root_tag.replace_self(SVG.root_tag.create_duplicate())
	disable_checkboxes()

func disable_checkboxes() -> void:
	for checkbox in number_vbox.get_children():
		if checkbox is SettingCheckBox:
			if checkbox.setting_name != "number_enable_autoformatting":
				set_checkbox_enabled(checkbox, GlobalSettings.number_enable_autoformatting)
	for checkbox in color_vbox.get_children():
		if checkbox is SettingCheckBox:
			if checkbox.setting_name != "color_enable_autoformatting":
				set_checkbox_enabled(checkbox, GlobalSettings.color_enable_autoformatting)
	for checkbox in path_vbox.get_children():
		if checkbox is SettingCheckBox:
			if checkbox.setting_name != "path_enable_autoformatting":
				set_checkbox_enabled(checkbox, GlobalSettings.path_enable_autoformatting)

func set_checkbox_enabled(checkbox: SettingCheckBox, enabled: bool) -> void:
	checkbox.disabled = not enabled
	checkbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else\
			Control.CURSOR_ARROW
