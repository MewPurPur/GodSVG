## This singleton handles the two representations of the SVG:
## The SVG text, and the native [TagSVG] representation.
extends Node

var text := ""
var root_tag := TagSVG.new()

var UR := UndoRedo.new()

signal parsing_finished(error_id: StringName) 

func _ready() -> void:
	SVG.root_tag.changed_unknown.connect(update_text)
	SVG.root_tag.attribute_changed.connect(update_text)
	SVG.root_tag.child_attribute_changed.connect(update_text)
	SVG.root_tag.tag_layout_changed.connect(update_text)
	
	if GlobalSettings.save_data.svg_text.is_empty():
		root_tag.attributes.width.set_value(16.0)
		root_tag.attributes.height.set_value(16.0)
		update_text()
	else:
		text = GlobalSettings.save_data.svg_text
		sync_data()


func sync_data() -> void:
	var err_id := SVGParser.get_svg_syntax_error(text)
	parsing_finished.emit(err_id)
	if err_id == &"":
		update_tags()

func update_text() -> void:
	text = SVGParser.svg_to_text(root_tag)

func update_tags() -> void:
	root_tag.replace_self(SVGParser.text_to_svg(text))
