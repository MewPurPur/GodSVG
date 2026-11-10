## A resource used to determine how to structure the XML and format attribute values.
## The various configs are described interactively in the GodSVG settings menu.
class_name Formatter extends ConfigResource

enum Preset {COMPACT, PRETTY}
enum ShorthandTags {ALWAYS, ALL_EXCEPT_CONTAINERS, NEVER}
enum FormattingStyle {COMPACT, PRETTY, VERBOSE}
enum NamedColorUse {ALWAYS, WHEN_SHORTER_OR_EQUAL, WHEN_SHORTER, NEVER}
enum PrimaryColorSyntax {THREE_OR_SIX_DIGIT_HEX, SIX_DIGIT_HEX, RGB}

# Elements that don't make sense without child elements.
const CONTAINER_ELEMENTS: PackedStringArray = ["svg", "g", "linearGradient", "radialGradient"]

static func get_preset_value_text_map() -> Dictionary[Preset, String]:
	return {
		Preset.COMPACT: Translator.translate("Compact"),
		Preset.PRETTY: Translator.translate("Pretty"),
	}

static func get_shorthand_tags_value_text_map() -> Dictionary[ShorthandTags, String]:
	return {
		ShorthandTags.ALWAYS: Translator.translate("Always"),
		ShorthandTags.ALL_EXCEPT_CONTAINERS: Translator.translate("All except containers"),
		ShorthandTags.NEVER: Translator.translate("Never"),
	}

static func get_formatting_style_value_text_map() -> Dictionary[FormattingStyle, String]:
	return {
		FormattingStyle.COMPACT: Translator.translate("Compact"),
		FormattingStyle.PRETTY: Translator.translate("Pretty"),
		FormattingStyle.VERBOSE: Translator.translate("Verbose"),
	}

static func get_named_color_use_value_text_map() -> Dictionary[NamedColorUse, String]:
	return {
		NamedColorUse.ALWAYS: Translator.translate("Always"),
		NamedColorUse.WHEN_SHORTER_OR_EQUAL: Translator.translate("When shorter or equal"),
		NamedColorUse.WHEN_SHORTER: Translator.translate("When shorter"),
		NamedColorUse.NEVER: Translator.translate("Never"),
	}

static func get_primary_color_syntax_value_text_map() -> Dictionary[PrimaryColorSyntax, String]:
	return {
		PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX: Translator.translate("3-digit or 6-digit hex"),
		PrimaryColorSyntax.SIX_DIGIT_HEX: Translator.translate("6-digit hex"),
		PrimaryColorSyntax.RGB: "RGB",
	}

## Returns the default of a settings based on the preset.
func get_setting_default(setting: String) -> Variant:
	match setting:
		"xml_add_trailing_newline": return false
		"xml_indentation_use_spaces": return false
		"xml_indentation_spaces": return 2
		"pathdata_compress_numbers": return true
		"pathdata_minimize_spacing": return true
		"pathdata_remove_consecutive_commands": return true
		"color_primary_syntax": return PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX
		"color_capital_hex": return false
		
		"xml_shorthand_tags": return ShorthandTags.ALWAYS if preset == Preset.COMPACT else ShorthandTags.ALL_EXCEPT_CONTAINERS
		"xml_shorthand_tags_space_out_slash": return preset == Preset.PRETTY
		"xml_formatting_style": return FormattingStyle.COMPACT if preset == Preset.COMPACT else FormattingStyle.PRETTY
		"number_remove_leading_zero": return preset == Preset.COMPACT
		"number_use_exponent_if_shorter": return preset == Preset.COMPACT
		"color_use_named_colors": return NamedColorUse.WHEN_SHORTER if preset == Preset.COMPACT else NamedColorUse.ALWAYS
		"pathdata_remove_spacing_after_flags": return preset == Preset.COMPACT
		"transform_list_compress_numbers": return preset == Preset.COMPACT
		"transform_list_minimize_spacing": return preset == Preset.COMPACT
		"transform_list_remove_unnecessary_params": return preset == Preset.COMPACT
	return null

## Resets all settings to their defaults based on the preset.
func reset_to_default() -> void:
	for setting in _get_setting_names():
		set(setting, get_setting_default(setting))

## Returns true if all settings are set to their default value based on the preset.
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


## A preset that determines the default values of the formatter configs.
@export var preset := Preset.COMPACT:
	set(new_value):
		if preset != new_value:
			preset = new_value
			emit_changed()


@export var xml_add_trailing_newline := false:
	set(new_value):
		if xml_add_trailing_newline != new_value:
			xml_add_trailing_newline = new_value
			emit_changed()

@export var xml_shorthand_tags := ShorthandTags.ALWAYS:
	set(new_value):
		# Validation
		if new_value < 0 or new_value >= ShorthandTags.size():
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

@export var xml_formatting_style := FormattingStyle.COMPACT:
	set(new_value):
		if xml_formatting_style != new_value:
			xml_formatting_style = new_value
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
		if new_value < 0 or new_value >= NamedColorUse.size():
			new_value = get_setting_default("color_use_named_colors")
		# Main part
		if color_use_named_colors != new_value:
			color_use_named_colors = new_value
			emit_changed()

@export var color_primary_syntax := PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX:
	set(new_value):
		# Validation
		if new_value < 0 or new_value >= PrimaryColorSyntax.size():
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


# Formatting

func get_indent_string() -> String:
	if xml_indentation_use_spaces:
		return " ".repeat(xml_indentation_spaces)
	else:
		return "\t"

## Returns an array consisting of a string for the new value and a AttributeSyntax.
func format_attribute(attribute_name: String, value: String, helpful_meta: Variant = null) -> Array:
	value = value.strip_edges()
	
	for syntax in DB.get_attribute_syntaxes(attribute_name):
		match syntax:
			DB.AttributeSyntax.URL:
				if ParserID.is_valid_url(value):
					return ["url(" + value.substr(4, value.length() - 5).strip_edges() + ")", syntax]
			
			DB.AttributeSyntax.COLOR:
				value = value.strip_edges()
				if ParserID.is_valid_url(value):
					return ["url(" + value.substr(4, value.length() - 5).strip_edges() + ")", syntax]
				
				var named_colors_usage := color_use_named_colors
				
				# First make sure we have a 6-digit hex.
				if ParserColor.is_valid_rgb(value):
					var args_start_pos := value.find("(") + 1
					var inside_brackets := value.substr(args_start_pos, value.length() - args_start_pos - 1)
					var args := inside_brackets.split(",", false)
					var r := String.num_uint64(args[0].strip_edges(false, true).to_int(), 16)
					var g := String.num_uint64(args[1].strip_edges(false, true).to_int(), 16)
					var b := String.num_uint64(args[2].strip_edges(false, true).to_int(), 16)
					value = "#" + (r if r.length() == 2 else "0" + r) + (g if g.length() == 2 else "0" + g) + (b if b.length() == 2 else "0" + b)
				elif ParserColor.is_valid_hsl(value):
					var args_start_pos := value.find("(") + 1
					var inside_brackets := value.substr(args_start_pos, value.length() - args_start_pos - 1)
					var args := inside_brackets.split(",", false)
					var h := posmod(args[0].to_int(), 360)
					var s := clampf(int(args[1].strip_edges(false, true).left(-1).to_float()) * 0.01, 0.0, 1.0)
					var l := clampf(int(args[2].strip_edges(false, true).left(-1).to_float()) * 0.01, 0.0, 1.0)
					var r := String.num_uint64(ParserColor.hsl_get_r(h, s, l), 16)
					var g := String.num_uint64(ParserColor.hsl_get_g(h, s, l), 16)
					var b := String.num_uint64(ParserColor.hsl_get_b(h, s, l), 16)
					value = "#" + (r if r.length() == 2 else "0" + r) + (g if g.length() == 2 else "0" + g) + (b if b.length() == 2 else "0" + b)
				if value in ParserColor.NAMED_COLORS:
					value = ParserColor.NAMED_COLORS[value]
				if ParserColor.is_valid_hex(value) and value.length() == 4:
					value = "#" + value[1] + value[1] + value[2] + value[2] + value[3] + value[3]
				
				value = value.to_upper() if color_capital_hex else value.to_lower()
				match color_primary_syntax:
					Formatter.PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX:
						if value.length() == 7 and value[0] == "#" and value[1] == value[2] and value[3] == value[4] and value[5] == value[6]:
							value = "#" + value[1] + value[3] + value[5]
					Formatter.PrimaryColorSyntax.RGB:
						value = "rgb(" + String.num_uint64(value.substr(1, 2).hex_to_int()) + ", " +\
								String.num_uint64(value.substr(3, 2).hex_to_int()) + ", " +\
								String.num_uint64(value.substr(5, 2).hex_to_int()) + ")"
				
				if named_colors_usage != Formatter.NamedColorUse.NEVER:
					var hex := value.to_lower()
					if ParserColor.is_valid_hex(hex) and hex.length() == 4:
						hex = "#" + hex[1] + hex[1] + hex[2] + hex[2] + hex[3] + hex[3]
					
					if hex in ParserColor.NAMED_COLORS.values():
						if named_colors_usage == Formatter.NamedColorUse.ALWAYS:
							value = ParserColor.NAMED_COLORS.find_key(hex)
						else:
							var named_color_text: String = ParserColor.NAMED_COLORS.find_key(hex)
							if named_color_text.length() < value.length() or\
							(named_colors_usage == Formatter.NamedColorUse.WHEN_SHORTER_OR_EQUAL and named_color_text.length() == value.length()):
								value = named_color_text
				return [value, syntax]
			
			DB.AttributeSyntax.LIST:
				if helpful_meta != null and typeof(helpful_meta) == TYPE_PACKED_FLOAT64_ARRAY:
					helpful_meta = AttributeMetaList.text_to_list(value)
				return AttributeMetaList.list_to_text(helpful_meta, self)
			
			DB.AttributeSyntax.ARBITRARY_FRACTION, DB.AttributeSyntax.ARBITRARY_NUMERIC, DB.AttributeSyntax.POSITIVE_NUMERIC:
				if helpful_meta != null and typeof(helpful_meta) in [TYPE_INT, TYPE_FLOAT]:
					return
	
	return ["", DB.AttributeSyntax.INVALID]


func number_to_text(number: float) -> String:
	if not is_finite(number):
		return ""
	
	if number == -0.0:
		number = absf(number)
	
	var numstr := Utils.num_simple(number, Utils.MAX_NUMERIC_PRECISION)
	
	if number_use_exponent_if_shorter:
		if numstr.ends_with("000"):
			var e := 3
			while numstr[-e - 1] == "0":
				e += 1
			return numstr.left(-e) + "e" + String.num_uint64(e)
		else:
			var numstr_abs := numstr.trim_prefix("-")
			# Leading zeros aren't removed yet.
			if numstr_abs.begins_with("0.00") and (not number_remove_leading_zero or numstr_abs.begins_with("0.000")):
				var is_num_negative := numstr.begins_with("-")
				var e := 3
				while e + 1 < numstr.length() and numstr_abs[e + 1] == "0":
					e += 1
				
				var output := "-" if is_num_negative else ""
				return output + numstr_abs.right(-e - 1) + "e-" + String.num_uint64(e)
	
	if number_remove_leading_zero and not is_zero_approx(fmod(number, 1)):
		if numstr.begins_with("0"):
			numstr = numstr.right(-1)
		elif numstr.begins_with("-0"):
			numstr = numstr.erase(1)
	
	return numstr

## Converts a number into text based on the parser configuration.
func numstring_number_to_text(num: float, is_angle := false) -> String:
	var text := Utils.num_simple(num, Utils.MAX_ANGLE_PRECISION if is_angle else Utils.MAX_NUMERIC_PRECISION)
	if compress_numbers:
		if text.begins_with("0."):
			text = text.right(-1)
		elif text.begins_with("-0."):
			text = text.erase(1)
	if text == "-0":
		text = "0"
	return text

## Combines an array of numeric strings based on the parser configuration.
func numstr_arr_to_text(numstr_arr: PackedStringArray) -> String:
	var output := ""
	for i in numstr_arr.size() - 1:
		var current_numstr := numstr_arr[i]
		var next_char := numstr_arr[i + 1][0]
		output += current_numstr
		if not minimize_spacing or not (("." in current_numstr and next_char == ".") or next_char in "-+"):
			output += " "
	return output + numstr_arr[-1]
