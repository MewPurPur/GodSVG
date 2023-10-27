extends Node

var string := ""
var root_tag := TagSVG.new()

signal parsing_finished(error_id: StringName)

func _ready() -> void:
	SVG.root_tag.changed_unknown.connect(update_string)
	SVG.root_tag.attribute_changed.connect(update_string)
	SVG.root_tag.child_tag_attribute_changed.connect(update_string)
	SVG.root_tag.tag_added.connect(update_string)
	SVG.root_tag.tag_deleted.connect(update_string.unbind(1))
	SVG.root_tag.tag_moved.connect(update_string.unbind(2))
	
	if GlobalSettings.save_svg:
		string = GlobalSettings.save_data.svg
		string_to_replace_root_tag(string)
	else:
		update_string()

func sync_data() -> void:
	var err_id := SVGParser.get_svg_error(string)
	parsing_finished.emit(err_id)
	if err_id == &"":
		var new_root_tag:TagSVG = SVGParser.text_to_svg(string)
		update_root_tag(new_root_tag)

func update_string() -> void:
	string = SVGParser.svg_to_text(root_tag)

func string_to_replace_root_tag(string) -> void:
	root_tag.replace_self(SVGParser.text_to_svg(string))

func update_root_tag(new_tagSVG:TagSVG) -> void:
	root_tag.attributes.width.set_value(new_tagSVG.attributes.width.get_value())
	root_tag.attributes.height.set_value(new_tagSVG.attributes.height.get_value())
	root_tag.attributes.viewBox.set_value(new_tagSVG.attributes.viewBox.get_value())
	var number_child_root_tag = root_tag.get_child_count()
	var number_child_new_tagSVG = new_tagSVG.get_child_count()
	var number_child_to_delete = 0
	if number_child_root_tag < number_child_new_tagSVG:
		number_child_to_delete = number_child_new_tagSVG - number_child_root_tag
	for idx in range(0,number_child_new_tagSVG - 1):
		var new_child =  new_tagSVG.child_tags[idx]
		var old_child = root_tag.child_tags[idx]
		if new_child.title == old_child.title:
			for key in new_child.attributes:
				if old_child.attributes.has(key):
					old_child.attributes[key].set_value(new_child.attributes[key].get_value())
		else:
			root_tag.add_tag(new_child)
			root_tag.move_tag(number_child_root_tag,idx)
	while number_child_to_delete > 0:
		root_tag.delete_tag(number_child_new_tagSVG)
		number_child_to_delete -= 1
