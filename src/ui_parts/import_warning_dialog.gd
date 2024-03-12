extends PanelContainer

signal imported

@onready var warnings_label: RichTextLabel = %WarningsLabel
@onready var texture_preview: TextureRect = %TexturePreview
@onready var checkerboard = $MarginContainer/VBoxContainer/TextureContainer/Checkerboard
@onready var ok_button: Button = %ButtonContainer/OKButton
@onready var margin_container = %MarginContainer

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
	
	if imported_text_parse_result.error != SVGParser.ParseError.OK:
		checkerboard.hide()
		margin_container.custom_minimum_size.y = 48
		size.y = 0
		warnings_label.add_theme_color_override("default_color",
				GlobalSettings.basic_color_error)
		warnings_label.text = "[center]" + tr("Syntax error") + ": " +\
				tr(SVGParser.get_error_string(imported_text_parse_result.error))
	else:
		var svg_warnings := get_svg_warnings(imported_text_parse_result.svg)
		if svg_warnings.is_empty():
			imported.emit()
		else:
			warnings_label.add_theme_color_override("default_color",
					GlobalSettings.basic_color_warning)
			for warning in svg_warnings:
				warnings_label.text += warning + "\n"


func set_svg(text: String) -> void:
	imported_text = text


func get_svg_warnings(svg_tag: TagSVG) -> Array[String]:
	var warnings: Array[String] = []
	var tids := svg_tag.get_all_tids()
	for tid in tids:
		var tag := svg_tag.get_tag(tid)
		if tag is TagUnknown:
			warnings.append(tr("Unknown Tag") + ": " + tag.name)
		else:
			for unknown_attrib in tag.unknown_attributes:
				warnings.append(tr("Unknown Attribute") + ": " + unknown_attrib.name)
	return warnings


func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_ok_button_pressed() -> void:
	imported.emit()

func _on_imported() -> void:
	queue_free()
