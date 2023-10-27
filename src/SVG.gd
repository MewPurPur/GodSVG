extends Node

signal updated_root_tag

var string: String = ""
var root_tag:TagSVG = TagSVG.new()

var root_tag_old_attributes: Dictionary = {}
var deregestered_attributes_from_undoredo:Dictionary = {} #Attribute:Old_value

signal parsing_finished(error_id: StringName)

func _ready() -> void:
	if GlobalSettings.save_svg:
		string = GlobalSettings.save_data.svg
		string_to_replace_root_tag(string)
	else:
		update_string_from_root_tag()
		connect_root_tag_signals()
	for key in root_tag.attributes:
		root_tag_old_attributes[key] = root_tag.attributes[key].duplicate()

func connect_root_tag_signals() -> void:
	root_tag.changed_unknown.connect(update_string_from_root_tag)
	root_tag.attribute_changed.connect(update_string_from_root_tag)
	root_tag.child_tag_attribute_changed.connect(update_string_from_root_tag)
	root_tag.tag_added.connect(update_string_from_root_tag.unbind(1))
	root_tag.tag_deleted.connect(update_string_from_root_tag.unbind(2))
	root_tag.tag_moved.connect(update_string_from_root_tag.unbind(2))
	
	root_tag.attribute_changed.connect(add_undoredo_SVG_root)
	root_tag.child_tag_attribute_change_details.connect(add_undoredo_child_tag_attribute)
	root_tag.tag_added.connect(add_undoredo_tag_added)
	root_tag.tag_deleted.connect(add_undoredo_tag_delete)
	root_tag.tag_moved.connect(add_undoredo_tag_moved)

func sync_data() -> void:
	var err_id := SVGParser.get_svg_error(string)
	parsing_finished.emit(err_id)
	if err_id == &"":
		string_to_tags()


func tags_to_string() -> void:
	var w: float = root_tag.attributes.width.get_value()
	var h: float = root_tag.attributes.height.get_value()
	var viewbox: Rect2 = root_tag.attributes.viewBox.get_value()
	# Opening
	string = '<svg width="%s" height="%s" viewBox="%s"' % [String.num(w, 4),
			String.num(h, 4), AttributeRect.rect_to_string(viewbox)]
	string += ' xmlns="http://www.w3.org/2000/svg">'
	
	for inner_tag in root_tag.child_tags:
		string += '<' + inner_tag.title
		for attribute_key in inner_tag.attributes:
			var attribute: Attribute = inner_tag.attributes[attribute_key]
			var value: Variant = attribute.get_value()
			if value == attribute.default:
				continue
			
			string += " " + attribute_key + '="'
			match attribute.type:
				Attribute.Type.INT:
					string += value.to_int()
				Attribute.Type.FLOAT, Attribute.Type.UFLOAT, Attribute.Type.NFLOAT:
					string += String.num(value, 4)
				Attribute.Type.COLOR, Attribute.Type.PATHDATA, Attribute.Type.ENUM:
					string += value
				Attribute.Type.RECT:
					string += AttributeRect.rect_to_string(value)
			string += '"'
		string += '/>'
	# Closing
	string += '</svg>'

func string_to_tags() -> void:
	var new_tags: Array[Tag] = []
	var parser := XMLParser.new()
	parser.open_buffer(string.to_ascii_buffer())
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name := parser.get_node_name()
			var attribute_dict := {}
			for i in range(parser.get_attribute_count()):
				attribute_dict[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
			
			# SVG tag requires width and height without defaults, so do the logic early.
			if node_name == "svg":
				var new_w: float = attribute_dict["width"].to_float() if\
						attribute_dict.has("width") else 0.0
				var new_h: float = attribute_dict["height"].to_float() if\
						attribute_dict.has("height") else 0.0
				var new_viewbox := AttributeRect.string_to_rect(attribute_dict["viewBox"])\
						if attribute_dict.has("viewBox") else Rect2(0, 0, new_w, new_h)
				root_tag.set_canvas(new_w, new_h, new_viewbox)
			else:
				var tag: Tag
				match node_name:
					"circle": tag = TagCircle.new()
					"ellipse": tag = TagEllipse.new()
					"rect": tag = TagRect.new()
					"path": tag = TagPath.new()
					"line": tag = TagLine.new()
					_: tag = Tag.new()
				for element in attribute_dict:
					if tag.attributes.has(element):
						var attribute: Attribute = tag.attributes[element]
						if typeof(attribute.get_value()) == Variant.Type.TYPE_STRING:
							attribute.set_value(attribute_dict[element], false)
						elif typeof(attribute.get_value()) == Variant.Type.TYPE_FLOAT:
							attribute.set_value(attribute_dict[element].to_float())
				new_tags.append(tag)
	root_tag.replace_tags(new_tags)


# TODO Can definitely be improved.
func get_svg_error() -> String:
	# Easy cases.
	if string.is_empty():
		return tr(&"#err_empty_svg")
	
	if string.count("<") != string.count(">"):
		return tr(&"#err_improper_nesting")
	
	var parser := XMLParser.new()
	parser.open_buffer(string.to_ascii_buffer())
	if string.begins_with("<?"):
		parser.skip_section()
	
	var nodes: Array[String] = []  # Serves as a sort of stack.
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name := parser.get_node_name()
			# First node must be "svg", last node must be closing "svg".
			if nodes.is_empty():
				if node_name != "svg":
					return tr(&"#err_not_svg")
			
			var offset := parser.get_node_offset()
			# Don't add tags that were closed right away to the stack.
			var closure_pos := string.find("/>", offset)
			if closure_pos == -1 or not closure_pos < string.find(">", offset):
				nodes.append(node_name)
		
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			var node_name := parser.get_node_name()
			if nodes.is_empty() or node_name != nodes.back():
				return tr(&"#err_improper_nesting")
			nodes.pop_back()
	return "" if nodes.is_empty() else tr(&"#err_improper_closing")
