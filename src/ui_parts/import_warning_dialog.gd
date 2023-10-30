extends Dialog

signal imported(text: String)

@onready var warnings_label: RichTextLabel = %WarningsLabel
@onready var texture_preview: TextureRect = %TexturePreview

var imported_text := ""

func _ready() -> void:
	# Convert forward and backward to show any artifacts that might occur after parsing.
	var import_preview_text := SVGParser.svg_to_text(SVGParser.text_to_svg(imported_text))
	var import_preview_svg := SVGParser.text_to_svg(import_preview_text)
	var scaling_factor := 256.0 / maxf(import_preview_svg.attributes.width.get_value(),
			import_preview_svg.attributes.height.get_value())
	var img := Image.new()
	img.load_svg_from_string(import_preview_text, scaling_factor)
	if not img.is_empty():
		texture_preview.texture = ImageTexture.create_from_image(img)
	var warnings := get_svg_errors(imported_text)
	if warnings.is_empty():
		imported.emit(imported_text)
	
	for warning in warnings:
		warnings_label.text += warning + "\n"


func set_svg(text: String) -> void:
	imported_text = text


func get_svg_errors(text: String) -> Array[String]:
	var warnings: Array[String] = []
	var syntax_err_id := SVGParser.get_svg_syntax_error(text)
	if syntax_err_id != &"":
		warnings.append(tr(&"#syntax_error") + ": " + tr(syntax_err_id))
	else:
		var svg_tag := SVGParser.text_to_svg(text)
		var tids := svg_tag.get_all_tids()
		
		for tid in tids:
			var tag := svg_tag.get_by_tid(tid)
			if tag is TagUnknown:
				warnings.append(tr(&"#unknown_tag") + ": " + tag.name)
			else:
				for unknown_attrib in tag.unknown_attributes:
					warnings.append(tr(&"#unknown_attribute") + ": " + unknown_attrib.name)
	return warnings


func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_ok_button_pressed() -> void:
	imported.emit(imported_text)

func _on_imported(_text: String) -> void:
	queue_free()
