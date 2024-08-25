class_name SaveData extends Resource

const GoodColorPicker = preload("res://src/ui_widgets/good_color_picker.gd")

@export var language := ""

# Theming
@export var highlighting_symbol_color := Color("abc9ff")
@export var highlighting_element_color := Color("ff8ccc")
@export var highlighting_attribute_color := Color("bce0ff")
@export var highlighting_string_color := Color("a1ffe0")
@export var highlighting_comment_color := Color("cdcfd280")
@export var highlighting_text_color := Color("cdcfeaac")
@export var highlighting_cdata_color := Color("ffeda1ac")
@export var highlighting_error_color := Color("ff866b")
@export var handle_inside_color := Color("fff")
@export var handle_color := Color("#111")
@export var handle_hovered_color := Color("#aaa")
@export var handle_selected_color := Color("#46f")
@export var handle_hovered_selected_color := Color("#f44")
@export var background_color := Color(0.12, 0.132, 0.2, 1)
@export var basic_color_valid := Color("9f9")
@export var basic_color_error := Color("f99")
@export var basic_color_warning := Color("ee5")

# Other
@export var invert_zoom := false
@export var wrap_mouse := false
@export var use_ctrl_for_zoom := true
@export var use_native_file_dialog := true
@export var use_filename_for_window_title := true
@export var handle_size := 1.0
@export var ui_scale := 1.0
@export var auto_ui_scale := true

# Session
@export var snap := -0.5  # Negative when disabled.
@export var color_picker_slider_mode := GoodColorPicker.SliderMode.RGB
@export var path_command_relative := false
@export var last_used_dir := ""
@export var file_dialog_show_hidden := false
@export var current_file_path := ""

@export var keybinds := {}
@export var palettes: Array[ColorPalette] = []
@export var formatters: Array[Formatter] = []
@export var editor_formatter: Formatter = null
@export var export_formatter: Formatter = null
