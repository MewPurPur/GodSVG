# A popup for picking a color.
extends PanelContainer

const go_back_icon = preload("res://assets/icons/GoBack.svg")
const config_icon = preload("res://assets/icons/Config.svg")

const GoodColorPickerScene = preload("res://src/ui_widgets/good_color_picker.tscn")
const ColorUtilitiesAreaScene = preload("res://src/ui_widgets/color_utilities_area.tscn")

# If the currentColor keyword is available, but uninteresting, don't show it.
enum CurrentColorAvailability {UNAVAILABLE, UNINTERESTING, INTERESTING}

signal color_picked(new_color: String, final: bool)
var current_value: String
var initial_value: String
var effective_color: Color

var alpha_enabled := false
var is_none_keyword_available := false
var show_url: bool
var current_color := Color.BLACK
var current_color_availability := CurrentColorAvailability.UNAVAILABLE

var color_picker_shown := true

@onready var content: MarginContainer = %Content
@onready var navigation_panel: PanelContainer = %NavigationPanel
@onready var switch_mode_button: Button = %NavigationPanel/SwitchModeButton

func setup(new_current_value: String, new_effective_color: Color) -> void:
	current_value = new_current_value
	initial_value = new_current_value
	effective_color = new_effective_color

func _ready() -> void:
	switch_mode_button.pressed.connect(_on_switch_mode_button_pressed)
	setup_content()
	theme_changed.connect(sync_theming)
	sync_theming()

func sync_theming() -> void:
	var panel_sb := get_theme_stylebox("disabled", "ContextButton").duplicate()
	panel_sb.content_margin_top = 2
	panel_sb.content_margin_bottom = 2
	navigation_panel.add_theme_stylebox_override("panel", panel_sb)
	
	var CONST_ARR: PackedStringArray = ["normal", "hover", "pressed"]
	for theme_item in CONST_ARR:
		var sb := switch_mode_button.get_theme_stylebox(theme_item).duplicate()
		sb.content_margin_top -= 2
		sb.content_margin_bottom -= 2
		sb.content_margin_left -= 2
		switch_mode_button.add_theme_stylebox_override(theme_item, sb)


# Switching between palette mode and color picker mode.
func _on_switch_mode_button_pressed() -> void:
	color_picker_shown = not color_picker_shown
	setup_content()

func setup_content() -> void:
	for child in content.get_children():
		child.queue_free()
	
	if color_picker_shown:
		switch_mode_button.text = Translator.translate("Color utilities")
		switch_mode_button.icon = config_icon
		var color_picker := GoodColorPickerScene.instantiate()
		color_picker.alpha_enabled = alpha_enabled
		color_picker.is_none_keyword_available = is_none_keyword_available
		color_picker.is_current_color_keyword_available = (current_color_availability != CurrentColorAvailability.UNAVAILABLE)
		content.add_child(color_picker)
		color_picker.setup_color(current_value, initial_value, effective_color)
		color_picker.color_changed.connect(_on_color_changed)
		#HandlerGUI.register_focus_sequence(color_picker, [color_picker, switch_mode_button])
	else:
		switch_mode_button.text = Translator.translate("Back to color picker")
		switch_mode_button.icon = go_back_icon
		var color_utils := ColorUtilitiesAreaScene.instantiate()
		color_utils.is_none_keyword_available = is_none_keyword_available
		color_utils.show_current_color = (current_color_availability == CurrentColorAvailability.INTERESTING)
		color_utils.show_url = show_url
		content.add_child(color_utils)
		color_utils.setup_color(current_value)
		color_utils.color_changed.connect(_on_color_changed)

func _on_color_changed(new_color: String) -> void:
	current_value = new_color
	color_picked.emit(current_value, false)

func _exit_tree() -> void:
	color_picked.emit(current_value, true)
