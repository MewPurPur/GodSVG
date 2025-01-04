# A resource for the color palettes that are listed in the color picker.
class_name Formatter extends ConfigResource

enum Preset {COMPACT, PRETTY}
enum ShorthandTags {ALWAYS, ALL_EXCEPT_CONTAINERS, NEVER}
enum NamedColorUse {ALWAYS, WHEN_SHORTER_OR_EQUAL, WHEN_SHORTER, NEVER}
enum PrimaryColorSyntax {THREE_OR_SIX_DIGIT_HEX, SIX_DIGIT_HEX, RGB}

# Elements that don't make sense without child elements.
const container_elements = ["svg", "g", "linearGradient", "radialGradient"]


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

@export var xml_indentation_spaces := 2:
	set(new_value):
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
		if color_use_named_colors != new_value:
			color_use_named_colors = new_value
			emit_changed()

@export var color_primary_syntax := PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX:
	set(new_value):
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
