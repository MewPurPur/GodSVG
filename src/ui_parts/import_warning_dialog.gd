extends PanelContainer

signal imported

@onready var warnings_label: RichTextLabel = %WarningsLabel
@onready var texture_preview: TextureRect = %TexturePreview
@onready var ok_button: Button = %ButtonContainer/OKButton

var imported_text := ""

func _ready() -> void:
	ok_button.grab_focus()
	# Convert forward and backward to show any artifacts that might occur after parsing.
	var preview_text := SVGParser.svg_to_text(SVGParser.text_to_svg(imported_text))
	var preview_svg: Variant = SVGParser.text_to_svg(preview_text)
	if typeof(preview_svg) == TYPE_STRING_NAME:
		return  # Error in parsing.
	
	var scaling_factor := texture_preview.size.x * 2.0 /\
			maxf(preview_svg.width, preview_svg.height)
	var img := Image.new()
	img.load_svg_from_string(preview_text, scaling_factor)
	if not img.is_empty():
		img.fix_alpha_edges()
		texture_preview.texture = ImageTexture.create_from_image(img)
	var warnings := get_svg_errors(imported_text)
	if warnings.is_empty():
		imported.emit()
	
	for warning in warnings:
		warnings_label.text += warning + "\n"


func set_svg(text: String) -> void:
	imported_text = text


func get_svg_errors(text: String) -> Array[String]:
	var warnings: Array[String] = []
	var svg_parse_result: Variant = SVGParser.text_to_svg(text)
	if typeof(svg_parse_result) == TYPE_STRING_NAME:
		warnings.append(tr(&"#syntax_error") + ": " + tr(svg_parse_result))
	else:
		var svg_tag: TagSVG = svg_parse_result
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
