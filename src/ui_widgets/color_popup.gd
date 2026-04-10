# A popup for picking a color.
extends PanelContainer

const go_back_icon = preload("res://assets/icons/GoBack.svg")
const config_icon = preload("res://assets/icons/Config.svg")

const GoodColorPickerScene = preload("res://src/ui_widgets/good_color_picker.tscn")
const ColorUtilitiesAreaScene = preload("res://src/ui_widgets/color_utilities_area.tscn")

# If the currentColor keyword is available, but uninteresting, don't show it.
enum CurrentColorAvailability {UNAVAILABLE, UNINTERESTING, INTERESTING}

signal color_picked(new_color: String, final: bool)
var color_config: ColorPickerUtils.ColorConfig

var alpha_enabled := false
var is_none_keyword_available := false
var show_url: bool
var current_color := Color.BLACK
var current_color_availability := CurrentColorAvailability.UNAVAILABLE

@onready var content: Control = %Content
@onready var navigation_panel: PanelContainer = %NavigationPanel
@onready var switch_mode_button: Button = %NavigationPanel/SwitchModeButton

func setup(new_current_value: String, new_effective_color: Color) -> void:
	color_config = ColorPickerUtils.ColorConfig.new()
	color_config.color = ColorPickerUtils.PreciseColor.from_color(ColorParser.text_to_color(new_current_value, new_effective_color, alpha_enabled))
	color_config.color.shift_hsv()
	if not alpha_enabled:
		color_config.color.a = 1.0
	color_config.color.paint = new_current_value
	color_config.initial_color = color_config.color.duplicate()
	color_config.backup_color = color_config.color.duplicate()
	color_config.color_changed.connect(_on_color_changed)

func _ready() -> void:
	switch_mode_button.pressed.connect(_on_switch_mode_button_pressed)
	if not State.color_popup_on_picker_page:
		# Use the size from the color picker page.
		State.color_popup_on_picker_page = true
		setup_content()
		State.color_popup_on_picker_page = false
	setup_content()
	theme_changed.connect(sync_theming)
	sync_theming()
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("ui_undo", color_config.undo_redo.undo)
	shortcuts.add_shortcut("ui_redo", color_config.undo_redo.redo)
	HandlerGUI.register_shortcuts(self, shortcuts)

func sync_theming() -> void:
	var panel_sb := get_theme_stylebox("disabled", "ContextButton").duplicate()
	panel_sb.content_margin_top = 2
	panel_sb.content_margin_bottom = 2
	navigation_panel.add_theme_stylebox_override("panel", panel_sb)


# Switching between palette mode and color picker mode.
func _on_switch_mode_button_pressed() -> void:
	State.color_popup_on_picker_page = not State.color_popup_on_picker_page
	setup_content()

func setup_content() -> void:
	for child in content.get_children():
		child.queue_free()
	
	if State.color_popup_on_picker_page:
		set_swatch_mode_button_text_and_icon(Translator.translate("Color utilities"), config_icon)
		var color_picker := GoodColorPickerScene.instantiate()
		color_picker.setup_color(color_config)
		color_picker.alpha_enabled = alpha_enabled
		color_picker.is_none_keyword_available = is_none_keyword_available
		color_picker.is_current_color_keyword_available = (current_color_availability != CurrentColorAvailability.UNAVAILABLE)
		content.add_child(color_picker)
		#HandlerGUI.register_focus_sequence(color_picker, [color_picker, switch_mode_button])
	else:
		set_swatch_mode_button_text_and_icon(Translator.translate("Back to color picker"), go_back_icon)
		var color_utils := ColorUtilitiesAreaScene.instantiate()
		color_utils.is_none_keyword_available = is_none_keyword_available
		color_utils.show_current_color = (current_color_availability == CurrentColorAvailability.INTERESTING)
		color_utils.show_url = show_url
		color_utils.current_color = current_color
		content.add_child(color_utils)
		color_utils.setup_color(color_config)

func set_swatch_mode_button_text_and_icon(new_text: String, new_icon: DPITexture) -> void:
	var font := switch_mode_button.get_theme_font("font")
	var font_size := ThemeDB.get_default_theme().get_font_size("font_size", "TranslucentButton")
	var sb := switch_mode_button.get_theme_stylebox("normal")
	switch_mode_button.custom_minimum_size.y = font.get_height(font_size) + sb.content_margin_top + sb.content_margin_bottom
	
	switch_mode_button.remove_theme_font_size_override("font_size")
	while font.get_string_size(new_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x > 180:
		font_size -= 1
	switch_mode_button.add_theme_font_size_override("font_size", font_size)
	
	switch_mode_button.text = new_text
	switch_mode_button.icon = new_icon

func _on_color_changed() -> void:
	color_picked.emit(color_config.color.paint, false)

func _exit_tree() -> void:
	color_picked.emit(color_config.color.paint, true)
