# A resource for the color palettes that are listed in the color picker.
class_name Formatter extends Resource

var _config_signal_queued := false
signal config_settings_changed

enum Preset {COMPACT, PRETTY}
enum ShorthandTags {ALWAYS, ALL_EXCEPT_CONTAINERS, NEVER}
enum NamedColorUse {ALWAYS, WHEN_SHORTER_OR_EQUAL, WHEN_SHORTER, NEVER}
enum PrimaryColorSyntax {THREE_OR_SIX_DIGIT_HEX, SIX_DIGIT_HEX, RGB}


static func get_preset_enum_text(enum_value: Preset) -> String:
	match enum_value:
		Preset.COMPACT: return Translator.translate("Compact")
		Preset.PRETTY: return Translator.translate("Pretty")
	return ""

static func get_shorthand_tags_enum_text(enum_value: ShorthandTags) -> String:
	match enum_value:
		ShorthandTags.ALWAYS: return Translator.translate("Always")
		ShorthandTags.ALL_EXCEPT_CONTAINERS:
			return Translator.translate("All except containers")
		ShorthandTags.NEVER: return Translator.translate("Never")
	return ""

static func get_named_color_use_enum_text(enum_value: NamedColorUse) -> String:
	match enum_value:
		NamedColorUse.ALWAYS: return Translator.translate("Always")
		NamedColorUse.WHEN_SHORTER_OR_EQUAL:
			return Translator.translate("When shorter or equal")
		NamedColorUse.WHEN_SHORTER: return Translator.translate("When shorter")
		NamedColorUse.NEVER: return Translator.translate("Never")
	return ""

static func get_primary_color_syntax_enum_text(enum_value: PrimaryColorSyntax) -> String:
	match enum_value:
		PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX:
			return Translator.translate("3-digit or 6-digit hex")
		PrimaryColorSyntax.SIX_DIGIT_HEX: return Translator.translate("6-digit hex")
		PrimaryColorSyntax.RGB: return "RGB"
	return ""

static func get_enum_texts(property: String) -> PackedStringArray:
	var values := PackedStringArray()
	match property:
		"preset":
			for key in Preset.keys():
				values.append(get_preset_enum_text(Preset[key]))
		"xml_shorthand_tags":
			for key in ShorthandTags.keys():
				values.append(get_shorthand_tags_enum_text(ShorthandTags[key]))
		"color_use_named_colors":
			for key in NamedColorUse.keys():
				values.append(get_named_color_use_enum_text(NamedColorUse[key]))
		"color_primary_syntax":
			for key in PrimaryColorSyntax.keys():
				values.append(get_primary_color_syntax_enum_text(PrimaryColorSyntax[key]))
	return values


func get_setting_default(setting: String) -> Variant:
	match setting:
		"xml_keep_unrecognized": return false
		"xml_add_trailing_newline": return false
		"xml_indentation_use_spaces": return false
		"xml_indentation_spaces": return 2
		"pathdata_compress_numbers": return true
		"pathdata_minimize_spacing": return true
		"pathdata_remove_consecutive_commands": return true
		"color_primary_syntax": return PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX
		"color_capital_hex": return false
		
		"xml_keep_comments": return preset == Preset.PRETTY
		"xml_shorthand_tags": return ShorthandTags.ALWAYS if\
				preset == Preset.COMPACT else ShorthandTags.ALL_EXCEPT_CONTAINERS
		"xml_shorthand_tags_space_out_slash": return preset == Preset.PRETTY
		"xml_pretty_formatting": return preset == Preset.PRETTY
		"number_remove_leading_zero": return preset == Preset.COMPACT
		"number_use_exponent_if_shorter": return preset == Preset.COMPACT
		"color_use_named_colors": return NamedColorUse.WHEN_SHORTER if\
				preset == Preset.COMPACT else NamedColorUse.ALWAYS
		"pathdata_remove_spacing_after_flags": return preset == Preset.COMPACT
		"transform_list_compress_numbers": return preset == Preset.COMPACT
		"transform_list_minimize_spacing": return preset == Preset.COMPACT
		"transform_list_remove_unnecessary_params": return preset == Preset.COMPACT
	return null

func _set(property: StringName, value: Variant) -> bool:
	if get(property) == value:
		return true
	emit_changed()
	if property != &"preset":
		_queue_emit_config_settings_changed()
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


@export var preset := Preset.COMPACT

@export var xml_keep_comments := false
@export var xml_keep_unrecognized := false
@export var xml_add_trailing_newline := false
@export var xml_shorthand_tags := ShorthandTags.ALWAYS
@export var xml_shorthand_tags_space_out_slash := false
@export var xml_pretty_formatting := false
@export var xml_indentation_use_spaces := false
@export var xml_indentation_spaces := 2
@export var number_remove_leading_zero := true
@export var number_use_exponent_if_shorter := true
@export var color_use_named_colors := NamedColorUse.WHEN_SHORTER
@export var color_primary_syntax := PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX
@export var color_capital_hex := false
@export var pathdata_compress_numbers := true
@export var pathdata_minimize_spacing := true
@export var pathdata_remove_spacing_after_flags := true
@export var pathdata_remove_consecutive_commands := true
@export var transform_list_compress_numbers := true
@export var transform_list_minimize_spacing := true
@export var transform_list_remove_unnecessary_params := true


func _init(new_preset := Preset.COMPACT) -> void:
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
