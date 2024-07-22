extends PanelContainer

signal imported

@onready var warnings_label: RichTextLabel = %WarningsLabel
@onready var texture_preview: CenterContainer = %TexturePreview
@onready var ok_button: Button = %ButtonContainer/OKButton
@onready var margin_container: MarginContainer = %MarginContainer
@onready var cancel_button: Button = $VBoxContainer/ButtonContainer/CancelButton

var imported_text := ""

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.LANGUAGE_CHANGED:
		setup()

func _ready() -> void:
	imported.connect(queue_free)
	ok_button.pressed.connect(imported.emit)
	setup()


func setup() -> void:
	# Convert forward and backward to show how GodSVG would display the given SVG.
	var imported_text_parse_result := SVGParser.text_to_root(imported_text)
	var preview_text := SVGParser.root_to_text(imported_text_parse_result.svg)
	var preview_parse_result := SVGParser.text_to_root(preview_text)
	var preview := preview_parse_result.svg
	if is_instance_valid(preview):
		texture_preview.setup(SVGParser.root_to_text(preview), preview.get_size())
	
	if imported_text_parse_result.error != SVGParser.ParseError.OK:
		texture_preview.hide()
		margin_container.custom_minimum_size.y = 48
		size.y = 0
		warnings_label.add_theme_color_override("default_color",
				GlobalSettings.basic_color_error)
		warnings_label.text = "[center]%s: %s" % [TranslationServer.translate(
				"Syntax error"), SVGParser.get_error_string(imported_text_parse_result.error)]
	else:
		var svg_warnings := get_svg_warnings(imported_text_parse_result.svg)
		if svg_warnings.is_empty():
			imported.emit()
		else:
			warnings_label.add_theme_color_override("default_color",
					GlobalSettings.basic_color_warning)
			for warning in svg_warnings:
				warnings_label.text += warning + "\n"
	ok_button.grab_focus()
	cancel_button.pressed.connect(queue_free)
	$VBoxContainer/Title.text = TranslationServer.translate("Import Problems")


func set_svg(text: String) -> void:
	imported_text = text


func get_svg_warnings(root_element: ElementRoot) -> PackedStringArray:
	var unrecognized_elements := PackedStringArray()
	var unrecognized_attributes := PackedStringArray()
	for element in root_element.get_all_elements():
		if element is ElementUnrecognized:
			if not element.name in unrecognized_elements:
				unrecognized_elements.append(element.name)
		else:
			for attribute in element.get_all_attributes():
				if not DB.is_attribute_recognized(element.name, attribute.name) and\
				not attribute.name in unrecognized_attributes:
					unrecognized_attributes.append(attribute.name)
	var warnings := PackedStringArray()
	for element in unrecognized_elements:
		warnings.append("%s: %s" % [TranslationServer.translate("Unrecognized element"),
				element])
	for attribute in unrecognized_attributes:
		warnings.append("%s: %s" % [TranslationServer.translate("Unrecognized attribute"),
				attribute])
	return warnings
