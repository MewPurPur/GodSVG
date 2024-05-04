extends PanelContainer

signal imported

@onready var warnings_label: RichTextLabel = %WarningsLabel
@onready var texture_preview: CenterContainer = %TexturePreview
@onready var ok_button: Button = %ButtonContainer/OKButton
@onready var margin_container: MarginContainer = %MarginContainer
@onready var cancel_button: Button = $VBoxContainer/ButtonContainer/CancelButton

var imported_text := ""

func _ready() -> void:
	imported.connect(queue_free)
	# Convert forward and backward to show how GodSVG would display the given SVG.
	var imported_text_parse_result := SVGParser.text_to_svg(imported_text)
	var preview_text := SVGParser.svg_to_text(imported_text_parse_result.svg)
	var preview_parse_result := SVGParser.text_to_svg(preview_text)
	var preview := preview_parse_result.svg
	if preview != null:
		texture_preview.setup(SVGParser.svg_to_text(preview), preview.get_size())
	
	if imported_text_parse_result.error != SVGParser.ParseError.OK:
		texture_preview.hide()
		margin_container.custom_minimum_size.y = 48
		size.y = 0
		warnings_label.add_theme_color_override("default_color",
				GlobalSettings.basic_color_error)
		warnings_label.text = "[center]%s: %s" % [TranslationServer.translate(
				"Syntax error"), TranslationServer.translate(SVGParser.get_error_string(
				imported_text_parse_result.error))]
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


func set_svg(text: String) -> void:
	imported_text = text


func get_svg_warnings(svg_tag: TagSVG) -> Array[String]:
	var warnings: Array[String] = []
	var tids := svg_tag.get_all_tids()
	for tid in tids:
		var tag := svg_tag.get_tag(tid)
		if tag is TagUnknown:
			warnings.append("%s: %s" % [TranslationServer.translate("Unknown tag"),
					tag.name])
		else:
			for unknown_attrib in tag.unknown_attributes:
				warnings.append("%s: %s" % [TranslationServer.translate("Unknown attribute"),
						unknown_attrib.name])
	return warnings


func _on_ok_button_pressed() -> void:
	imported.emit()
