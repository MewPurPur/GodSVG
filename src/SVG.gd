## This singleton handles the two representations of the SVG:
## The SVG text, and the native [TagSVG] representation.
extends Node

var string := ""
var root_tag := TagSVG.new()

signal parsing_finished(error_id: StringName)

func _ready() -> void:
	SVG.root_tag.changed_unknown.connect(update_string)
	SVG.root_tag.attribute_changed.connect(update_string)
	SVG.root_tag.child_attribute_changed.connect(update_string)
	SVG.root_tag.tag_layout_changed.connect(update_string)
	
	if GlobalSettings.save_data.svg.is_empty():
		update_string()
	else:
		string = GlobalSettings.save_data.svg
		sync_data()


func sync_data() -> void:
	var err_id := SVGParser.get_svg_syntax_error(string)
	parsing_finished.emit(err_id)
	if err_id == &"":
		update_tags()

func update_string() -> void:
	string = SVGParser.svg_to_text(root_tag)

func update_tags() -> void:
	root_tag.replace_self(SVGParser.text_to_svg(string))
