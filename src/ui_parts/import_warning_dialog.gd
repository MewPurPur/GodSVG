extends PanelContainer

signal imported

@onready var warnings_label: RichTextLabel = %WarningsLabel
@onready var texture_preview: TextureRect = %TexturePreview
@onready var ok_button: Button = %ButtonContainer/OKButton

var imported_text := ""

func _ready() -> void:
	ok_button.grab_focus()
	# Convert forward and backward to show how GodSVG would display the given SVG.
	var imported_text_parse_result := SVGParser.text_to_svg(imported_text)
	var preview_text := SVGParser.svg_to_text(imported_text_parse_result.svg)
	var preview_parse_result := SVGParser.text_to_svg(preview_text)
	var preview := preview_parse_result.svg
	if preview != null:
		var scaling_factor := texture_preview.size.x * 2 / maxf(preview.width, preview.height)
		var img := Image.new()
		img.load_svg_from_string(SVGParser.svg_to_text(preview), scaling_factor)
		if not img.is_empty():
			img.fix_alpha_edges()
			texture_preview.texture = ImageTexture.create_from_image(img)
	
	var warnings := get_svg_errors(imported_text_parse_result)
	if warnings.is_empty():
		imported.emit()
	for warning in warnings:
		warnings_label.text += warning + "\n"


func set_svg(text: String) -> void:
	imported_text = text


func get_svg_errors(parse_result: SVGParser.ParseResult) -> Array[String]:
	var warnings: Array[String] = []
	if parse_result.error != SVGParser.ParseError.OK:
		warnings = [tr(&"#syntax_error") + ": " +\
				tr(SVGParser.get_error_stringname(parse_result.error))]
	else:
		var svg_tag := parse_result.svg
		var tids := svg_tag.get_all_tids()
		for tid in tids:
			var tag := svg_tag.get_tag(tid)
			if tag is TagUnknown:
				warnings.append(tr(&"#unknown_tag") + ": " + tag.name)
			else:
				for unknown_attrib in tag.unknown_attributes:
					warnings.append(tr(&"#unknown_attribute") + ": " + unknown_attrib.name)
	return warnings


func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_ok_button_pressed() -> void:
	imported.emit()

func _on_imported() -> void:
	queue_free()
