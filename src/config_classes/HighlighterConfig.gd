class_name HighlighterConfig extends Resource

var _config_signal_queued := false
signal config_settings_changed

enum Preset {DEFAULT_DARK, DEFAULT_LIGHT}

static func get_preset_enum_text(enum_value: Preset) -> String:
	match enum_value:
		Preset.DEFAULT_DARK: return Translator.translate("Default dark")
		Preset.DEFAULT_LIGHT: return Translator.translate("Default light")
	return ""


func get_setting_default(setting: String) -> Variant:
	match preset:
		Preset.DEFAULT_DARK:
			match setting:
				"highlighting_symbol_color": return Color("abc9ff")
				"highlighting_element_color": return Color("ff8ccc")
				"highlighting_attribute_color": return Color("bce0ff")
				"highlighting_string_color": return Color("a1ffe0")
				"highlighting_comment_color": return Color("cdcfd280")
				"highlighting_text_color": return Color("cdcfeaac")
				"highlighting_cdata_color": return Color("ffeda1ac")
				"highlighting_error_color": return Color("ff866b")
		Preset.DEFAULT_LIGHT:
			match setting:
				"highlighting_symbol_color": return Color.BLACK
				"highlighting_element_color": return Color.BLACK
				"highlighting_attribute_color": return Color.BLACK
				"highlighting_string_color": return Color.BLACK
				"highlighting_comment_color": return Color.BLACK
				"highlighting_text_color": return Color.BLACK
				"highlighting_cdata_color": return Color.BLACK
				"highlighting_error_color": return Color.BLACK
	return null

func _set(property: StringName, value: Variant) -> bool:
	if get(property) == value:
		return true
	emit_changed()
	if property != &"preset":
		_queue_emit_config_settings_changed()
		Configs.highlighting_colors_changed.emit()
	return true

func reset_to_default() -> void:
	for dict in get_property_list():
		if dict.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and dict.name != "preset":
			set(dict.name, get_setting_default(dict.name))

func is_everything_default() -> bool:
	for setting_dict in get_property_list():
		var setting: String = setting_dict.name
		if not setting in Resource and setting != "preset" and\
		get(setting) != get_setting_default(setting):
			return false
	return true


@export var preset := Preset.DEFAULT_DARK:
	set(new_value):
		if preset != new_value:
			preset = new_value
			emit_changed()
			_config_signal_queued = false  # Changing the preset doesn't affect the config.

@export var highlighting_symbol_color := Color("abc9ff")
@export var highlighting_element_color := Color("ff8ccc")
@export var highlighting_attribute_color := Color("bce0ff")
@export var highlighting_string_color := Color("a1ffe0")
@export var highlighting_comment_color := Color("cdcfd280")
@export var highlighting_text_color := Color("cdcfeaac")
@export var highlighting_cdata_color := Color("ffeda1ac")
@export var highlighting_error_color := Color("ff866b")

func _init(new_preset := Preset.DEFAULT_DARK) -> void:
	preset = new_preset
	reset_to_default()
	changed.connect(_queue_emit_config_settings_changed)

func _queue_emit_config_settings_changed() -> void:
	_config_signal_queued = true
	_emit_config_settings_changed.call_deferred()

func _emit_config_settings_changed() -> void:
	if _config_signal_queued:
		_config_signal_queued = false
		config_settings_changed.emit()


func generate_highlighter() -> SVGHighlighter:
	var new_highlighter := SVGHighlighter.new()
	new_highlighter.symbol_color = highlighting_symbol_color
	new_highlighter.element_color = highlighting_element_color
	new_highlighter.attribute_color = highlighting_attribute_color
	new_highlighter.string_color = highlighting_string_color
	new_highlighter.comment_color = highlighting_comment_color
	new_highlighter.text_color = highlighting_text_color
	new_highlighter.cdata_color = highlighting_cdata_color
	new_highlighter.error_color = highlighting_error_color
	return new_highlighter
