# A resource used to determine how to structure the XML and represent attributes.
class_name Formatter extends ConfigResource

enum Preset {COMPACT, PRETTY}
enum ShorthandTags {ALWAYS, ALL_EXCEPT_CONTAINERS, NEVER}
enum NamedColorUse {ALWAYS, WHEN_SHORTER_OR_EQUAL, WHEN_SHORTER, NEVER}
enum PrimaryColorSyntax {THREE_OR_SIX_DIGIT_HEX, SIX_DIGIT_HEX, RGB}

# Elements that don't make sense without child elements.
const container_elements: Array[String] = ["svg", "g", "linearGradient", "radialGradient"]

# TODO Typed Dictionary wonkiness  Dictionary[Preset, String]
static func get_preset_value_text_map() -> Dictionary:
	return {
		Preset.COMPACT: Translator.translate("Compact"),
		Preset.PRETTY: Translator.translate("Pretty"),
	}

# TODO Typed Dictionary wonkiness  Dictionary[ShorthandTags, String]
static func get_shorthand_tags_value_text_map() -> Dictionary:
	return {
		ShorthandTags.ALWAYS: Translator.translate("Always"),
		ShorthandTags.ALL_EXCEPT_CONTAINERS: Translator.translate("All except containers"),
		ShorthandTags.NEVER: Translator.translate("Never"),
	}

# TODO Typed Dictionary wonkiness  Dictionary[NamedColorUse, String]
static func get_named_color_use_value_text_map() -> Dictionary:
	return {
		NamedColorUse.ALWAYS: Translator.translate("Always"),
		NamedColorUse.WHEN_SHORTER_OR_EQUAL: Translator.translate("When shorter or equal"),
		NamedColorUse.WHEN_SHORTER: Translator.translate("When shorter"),
		NamedColorUse.NEVER: Translator.translate("Never"),
	}

# TODO Typed Dictionary wonkiness  Dictionary[PrimaryColorSyntax, String]
static func get_primary_color_syntax_value_text_map() -> Dictionary:
	return {
		PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX: Translator.translate("3-digit or 6-digit hex"),
		PrimaryColorSyntax.SIX_DIGIT_HEX: Translator.translate("6-digit hex"),
		PrimaryColorSyntax.RGB: "RGB",
	}

# TODO Typed Dictionary wonkiness  Dictionary[Variant, String]
static func get_enum_value_text_map(property: String) -> Dictionary:
	match property:
		"preset": return get_preset_value_text_map()
		"xml_shorthand_tags": return get_shorthand_tags_value_text_map()
		"color_use_named_colors": return get_named_color_use_value_text_map()
		"color_primary_syntax": return get_primary_color_syntax_value_text_map()
	return {}


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

func reset_to_default() -> void:
	for setting in _get_setting_names():
		set(setting, get_setting_default(setting))

func is_everything_default() -> bool:
	for setting in _get_setting_names():
		if get(setting) != get_setting_default(setting):
			return false
	return true

func _get_setting_names() -> PackedStringArray:
	var arr := PackedStringArray()
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_STORAGE:
			if get_setting_default(p.name) != null:
				arr.append(p.name)
	return arr

func _init(new_preset := Preset.COMPACT) -> void:
	preset = new_preset
	reset_to_default()
	super()


@export var preset := Preset.COMPACT:
	set(new_value):
		if preset != new_value:
			preset = new_value
			emit_changed()


@export var xml_keep_comments := false:
	set(new_value):
		if xml_keep_comments != new_value:
			xml_keep_comments = new_value
			emit_changed()

@export var xml_keep_unrecognized := false:
	set(new_value):
		if xml_keep_unrecognized != new_value:
			xml_keep_unrecognized = new_value
			emit_changed()

@export var xml_add_trailing_newline := false:
	set(new_value):
		if xml_add_trailing_newline != new_value:
			xml_add_trailing_newline = new_value
			emit_changed()

@export var xml_shorthand_tags := ShorthandTags.ALWAYS:
	set(new_value):
		# Validation
		if new_value < 0 || new_value >= ShorthandTags.size():
			new_value = get_setting_default("xml_shorthand_tags")
		# Main part
		if xml_shorthand_tags != new_value:
			xml_shorthand_tags = new_value
			emit_changed()

@export var xml_shorthand_tags_space_out_slash := false:
	set(new_value):
		if xml_shorthand_tags_space_out_slash != new_value:
			xml_shorthand_tags_space_out_slash = new_value
			emit_changed()

@export var xml_pretty_formatting := false:
	set(new_value):
		if xml_pretty_formatting != new_value:
			xml_pretty_formatting = new_value
			emit_changed()

@export var xml_indentation_use_spaces := false:
	set(new_value):
		if xml_indentation_use_spaces != new_value:
			xml_indentation_use_spaces = new_value
			emit_changed()

const INDENTS_MIN = 0
const INDENTS_MAX = 16
@export var xml_indentation_spaces := 2:
	set(new_value):
		new_value = clampi(new_value, INDENTS_MIN, INDENTS_MAX)
		if is_nan(new_value):
			new_value = get_setting_default("xml_indentation_spaces")
		if xml_indentation_spaces != new_value:
			xml_indentation_spaces = new_value
			emit_changed()

@export var number_remove_leading_zero := true:
	set(new_value):
		if number_remove_leading_zero != new_value:
			number_remove_leading_zero = new_value
			emit_changed()

@export var number_use_exponent_if_shorter := true:
	set(new_value):
		if number_use_exponent_if_shorter != new_value:
			number_use_exponent_if_shorter = new_value
			emit_changed()

@export var color_use_named_colors := NamedColorUse.WHEN_SHORTER:
	set(new_value):
		# Validation
		if new_value < 0 || new_value >= NamedColorUse.size():
			new_value = get_setting_default("color_use_named_colors")
		# Main part
		if color_use_named_colors != new_value:
			color_use_named_colors = new_value
			emit_changed()

@export var color_primary_syntax := PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX:
	set(new_value):
		# Validation
		if new_value < 0 || new_value >= PrimaryColorSyntax.size():
			new_value = get_setting_default("color_primary_syntax")
		# Main part
		if color_primary_syntax != new_value:
			color_primary_syntax = new_value
			emit_changed()

@export var color_capital_hex := false:
	set(new_value):
		if color_capital_hex != new_value:
			color_capital_hex = new_value
			emit_changed()

@export var pathdata_compress_numbers := true:
	set(new_value):
		if pathdata_compress_numbers != new_value:
			pathdata_compress_numbers = new_value
			emit_changed()

@export var pathdata_minimize_spacing := true:
	set(new_value):
		if pathdata_minimize_spacing != new_value:
			pathdata_minimize_spacing = new_value
			emit_changed()

@export var pathdata_remove_spacing_after_flags := true:
	set(new_value):
		if pathdata_remove_spacing_after_flags != new_value:
			pathdata_remove_spacing_after_flags = new_value
			emit_changed()

@export var pathdata_remove_consecutive_commands := true:
	set(new_value):
		if pathdata_remove_consecutive_commands != new_value:
			pathdata_remove_consecutive_commands = new_value
			emit_changed()

@export var transform_list_compress_numbers := true:
	set(new_value):
		if transform_list_compress_numbers != new_value:
			transform_list_compress_numbers = new_value
			emit_changed()

@export var transform_list_minimize_spacing := true:
	set(new_value):
		if transform_list_minimize_spacing != new_value:
			transform_list_minimize_spacing = new_value
			emit_changed()

@export var transform_list_remove_unnecessary_params := true:
	set(new_value):
		if transform_list_remove_unnecessary_params != new_value:
			transform_list_remove_unnecessary_params = new_value
			emit_changed()
