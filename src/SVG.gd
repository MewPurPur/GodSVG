extends Node

var string := ""
var root_tag := TagSVG.new()
var root_tag_last_value:TagSVG

signal parsing_finished(err_text: String)

func _ready() -> void:
	SVG.root_tag.changed_unknown.connect(sync_string)
	SVG.root_tag.attribute_changed.connect(sync_string)
	SVG.root_tag.child_tag_attribute_changed.connect(sync_string.unbind(1))
	SVG.root_tag.tag_added.connect(sync_string.unbind(1))
	SVG.root_tag.tag_deleted.connect(sync_string.unbind(2))
	SVG.root_tag.tag_moved.connect(sync_string.unbind(2))
	
	if GlobalSettings.save_svg:
		string = GlobalSettings.save_data.svg
		sync_data()
	else:
		tags_to_string()
	
	root_tag_last_value = root_tag.duplicate()
	SVG.root_tag.attribute_changed.connect(add_undoredo_SVG_root)
	SVG.root_tag.child_tag_attribute_changed.connect(add_undoredo_child_tag_attribute)
	SVG.root_tag.tag_added.connect(add_undoredo_tag_added)
	SVG.root_tag.tag_deleted.connect(add_undoredo_tag_delete)
	SVG.root_tag.tag_moved.connect(add_undoredo_tag_moved)

func sync_data() -> void:
	var error_text := get_svg_error()
	parsing_finished.emit(error_text)
	if error_text.is_empty():
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

func add_undoredo_SVG_root():
	var new_width: float = root_tag.attributes.width.get_value()
	var new_length: float = root_tag.attributes.height.get_value()
	var new_viewbox: Rect2 = root_tag.attributes.viewBox.get_value()
	var last_width: float = root_tag_last_value.attributes.width.get_value()
	var last_length: float = root_tag_last_value.attributes.height.get_value()
	var last_viewbox: Rect2 = root_tag_last_value.attributes.viewBox.get_value()
	var changed = false
	if new_viewbox != last_viewbox:
		changed = true
		root_tag_last_value.attributes.viewBox._value = new_viewbox
	if new_width != last_width:
		changed = true
		root_tag_last_value.attributes.width.set_value(new_width)
		root_tag_last_value.attributes.viewBox._value.size.x = new_width
	if new_length != last_length:
		changed = true
		root_tag_last_value.attributes.height.set_value(new_length)
		root_tag_last_value.attributes.viewBox._value.size.y = new_length
	if not changed or UndoRedoManager.is_excuting:
		return
	UndoRedoManager.add_action_simple_methods(
		"Change SVG root",
		root_tag.set_canvas.bind(new_width,new_length,new_viewbox),
		root_tag.set_canvas.bind(last_width,last_length,last_viewbox),
		root_tag,
		false
		)

func add_undoredo_child_tag_attribute(child_tag:Tag):
	#get indexand use it to find its last values
	var child_inx = root_tag.find_child_tag(child_tag)
	var last_value_child_tag = root_tag_last_value.get_child_tag(child_inx)
	var changed = false
	var changed_attribute_key:String = ""
	var new_value
	var old_value
	for key in child_tag.attributes:
		if last_value_child_tag.attributes[key].get_value() != child_tag.attributes[key].get_value():
			changed = true
			changed_attribute_key = key
			new_value = child_tag.attributes[key].get_value()
			old_value = last_value_child_tag.attributes[key].get_value()
			last_value_child_tag.attributes[key].set_value(new_value)
	if not changed or UndoRedoManager.is_excuting:
		return
	UndoRedoManager.add_action_simple_methods(
		"Change " + child_tag.title + " : " + changed_attribute_key,
		child_tag.attributes[changed_attribute_key].set_value.bind(new_value),
		child_tag.attributes[changed_attribute_key].set_value.bind(old_value),
		child_tag.attributes[changed_attribute_key],
		false
		)

func  add_undoredo_tag_added(child_tag:Tag):
	root_tag_last_value.add_tag(child_tag.duplicate())
	if UndoRedoManager.is_excuting:
		return
	UndoRedoManager.add_action_simple_methods(
		"Added or Removed "+ child_tag.title,
		root_tag.add_tag.bind(child_tag),
		root_tag.delete_tag_with_reference.bind(child_tag),
		child_tag,
		false
		)
		
func  add_undoredo_tag_delete(idx:int,child_tag:Tag):
	root_tag_last_value.delete_tag(idx)
	if UndoRedoManager.is_excuting:
		return
	UndoRedoManager.add_action_simple_methods(
		"Added or Removed "+ child_tag.title,
		root_tag.delete_tag_with_reference.bind(child_tag),
		root_tag.add_tag_and_move_to.bind(child_tag,idx),
		child_tag,
		false
		)
		
func add_undoredo_tag_moved(old_idx:int , new_idx:int):
	root_tag_last_value.move_tag(new_idx, old_idx)
	if UndoRedoManager.is_excuting:
		return
	UndoRedoManager.add_action_simple_methods(
		"Moved "+ root_tag.get_child_tag(new_idx).title,
		root_tag.move_tag.bind(old_idx , new_idx),
		root_tag.move_tag.bind(new_idx, old_idx),
		root_tag,
		false
		)
