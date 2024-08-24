# A resource for the color palettes that are listed in the color picker.
class_name Formatter extends Resource

enum ShorthandTags {ALWAYS, ALL_EXCEPT_CONTAINERS, NEVER}
enum NamedColorUse {ALWAYS, WHEN_SHORTER_OR_EQUAL, WHEN_SHORTER, NEVER}
enum PrimaryColorSyntax {THREE_OR_SIX_DIGIT_HEX, SIX_DIGIT_HEX, RGB}

# Elements that don't make sense without child elements.
const container_elements = ["svg", "g", "linearGradient", "radialGradient"]

static var enum_text := {
	"xml_shorthand_tags": {
		ShorthandTags.ALWAYS: TranslationServer.translate("Always"),
		ShorthandTags.ALL_EXCEPT_CONTAINERS: TranslationServer.translate("All except containers"),
		ShorthandTags.NEVER: TranslationServer.translate("Never"),
	},
	"color_use_named_colors": {
		NamedColorUse.ALWAYS: TranslationServer.translate("Always"),
		NamedColorUse.WHEN_SHORTER_OR_EQUAL: TranslationServer.translate("When shorter or equal"),
		NamedColorUse.WHEN_SHORTER: TranslationServer.translate("When shorter"),
		NamedColorUse.NEVER: TranslationServer.translate("Never"),
	},
	"color_primary_syntax": {
		PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX: TranslationServer.translate("3-digit or 6-digit hex"),
		PrimaryColorSyntax.SIX_DIGIT_HEX: TranslationServer.translate("6-digit hex"),
		PrimaryColorSyntax.RGB: "RGB",
	},
}

func get_enum_texts(property: String) -> PackedStringArray:
	var values := PackedStringArray()
	var enum_dict: Dictionary = enum_text[property]
	for key in enum_dict:
		values.append(enum_dict[key])
	return values

# The title must be unique.
@export var title := "":
	set(new_value):
		if title != new_value:
			title = new_value
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
		number_remove_leading_zero = new_value
		emit_changed()

@export var number_use_exponent_if_shorter := true:
	set(new_value):
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
		color_capital_hex = new_value
		emit_changed()

@export var pathdata_compress_numbers := true:
	set(new_value):
		pathdata_compress_numbers = new_value
		emit_changed()

@export var pathdata_minimize_spacing := true:
	set(new_value):
		pathdata_minimize_spacing = new_value
		emit_changed()

@export var pathdata_remove_spacing_after_flags := true:
	set(new_value):
		pathdata_remove_spacing_after_flags = new_value
		emit_changed()

@export var pathdata_remove_consecutive_commands := true:
	set(new_value):
		pathdata_remove_consecutive_commands = new_value
		emit_changed()

@export var transform_list_compress_numbers := true:
	set(new_value):
		transform_list_compress_numbers = new_value
		emit_changed()

@export var transform_list_minimize_spacing := true:
	set(new_value):
		transform_list_minimize_spacing = new_value
		emit_changed()

@export var transform_list_remove_unnecessary_params := true:
	set(new_value):
		transform_list_remove_unnecessary_params = new_value
		emit_changed()


func _init(new_title := "") -> void:
	title = new_title
	# Connects to the _on_changed function once all initial file loading is done.
	# This way the config is saved only once on launch.
	changed.connect(func(): changed.connect(_on_changed), CONNECT_DEFERRED | CONNECT_ONE_SHOT)

func _on_changed() -> void:
	if self == GlobalSettings.savedata.editor_formatter:
		SVG.sync_elements()
	GlobalSettings.save()
