extends Node

signal updated_root_tag

var string: String = ""
var root_tag:TagSVG = TagSVG.new()

var root_tag_old_attributes: Dictionary = {}

signal parsing_finished(err_text: String)

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
	var error_text: String= get_svg_error(string)
	parsing_finished.emit(error_text)
	if error_text.is_empty():
		var new_root_tag:TagSVG = string_to_tags(string)
		update_root_tag(new_root_tag)

func tags_to_string(tagSVG:TagSVG) -> String:
	var w: float = tagSVG.attributes.width.get_value()
	var h: float = tagSVG.attributes.height.get_value()
	var viewbox: Rect2 = tagSVG.attributes.viewBox.get_value()
	# Opening
	var new_stringSVG:String
	new_stringSVG = '<svg width="%s" height="%s" viewBox="%s"' % [String.num(w, 4),
			String.num(h, 4), AttributeRect.rect_to_string(viewbox)]
	new_stringSVG += ' xmlns="http://www.w3.org/2000/svg">'
	
	for inner_tag in tagSVG.child_tags:
		new_stringSVG += '<' + inner_tag.title
		for attribute_key in inner_tag.attributes:
			var attribute: Attribute = inner_tag.attributes[attribute_key]
			var value: Variant = attribute.get_value()
			if value == attribute.default:
				continue
			
			new_stringSVG += " " + attribute_key + '="'
			match attribute.type:
				Attribute.Type.INT:
					new_stringSVG += value.to_int()
				Attribute.Type.FLOAT, Attribute.Type.UFLOAT, Attribute.Type.NFLOAT:
					new_stringSVG += String.num(value, 4)
				Attribute.Type.COLOR, Attribute.Type.PATHDATA, Attribute.Type.ENUM:
					new_stringSVG += value
				Attribute.Type.RECT:
					new_stringSVG += AttributeRect.rect_to_string(value)
			new_stringSVG += '"'
		new_stringSVG += '/>'
	# Closing
	new_stringSVG += '</svg>'
	return new_stringSVG

func string_to_tags(stringSVG:String) -> TagSVG:
	var new_tagSVG:TagSVG = TagSVG.new()
	var new_tags: Array[Tag] = []
	var parser := XMLParser.new()
	parser.open_buffer(stringSVG.to_ascii_buffer())
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
				new_tagSVG.set_canvas(new_w, new_h, new_viewbox)
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
	new_tagSVG.replace_tags(new_tags)
	return new_tagSVG

# TODO Can definitely be improved.
func get_svg_error(stringSVG:String) -> String:
	# Easy cases.
	if stringSVG.is_empty():
		return tr(&"#err_empty_svg")
	
	if stringSVG.count("<") != stringSVG.count(">"):
		return tr(&"#err_improper_nesting")
	
	var parser := XMLParser.new()
	parser.open_buffer(stringSVG.to_ascii_buffer())
	if stringSVG.begins_with("<?"):
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
			var closure_pos := stringSVG.find("/>", offset)
			if closure_pos == -1 or not closure_pos < stringSVG.find(">", offset):
				nodes.append(node_name)
		
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			var node_name := parser.get_node_name()
			if nodes.is_empty() or node_name != nodes.back():
				return tr(&"#err_improper_nesting")
			nodes.pop_back()
	return "" if nodes.is_empty() else tr(&"#err_improper_closing")

func update_string_from_root_tag() -> void:
	string = tags_to_string(root_tag)

func  string_to_replace_root_tag(stringSVG:String) -> void:
	var new_root_tag:TagSVG = string_to_tags(stringSVG)
	root_tag = new_root_tag
	connect_root_tag_signals()
	updated_root_tag.emit()

func update_root_tag(new_tagSVG:TagSVG) -> void:
	root_tag.attributes.width.set_value(new_tagSVG.attributes.width.get_value())
	root_tag.attributes.height.set_value(new_tagSVG.attributes.height.get_value())
	root_tag.attributes.viewBox.set_value(new_tagSVG.attributes.viewBox.get_value())
	var number_child_root_tag = root_tag.get_child_count()
	var number_child_new_tagSVG = new_tagSVG.get_child_count()
	var number_child_to_delete = 0
	if number_child_root_tag < number_child_new_tagSVG:
		number_child_to_delete = number_child_new_tagSVG - number_child_root_tag
	var delete_at: Array[int] = []
	for idx in range(0,number_child_new_tagSVG - 1):
		var new_child =  new_tagSVG.get_child_tag(idx)
		var old_child = root_tag.get_child_tag(idx)
		if new_child.title == old_child.title:
			for key in new_child.attributes:
				if old_child.attributes.has(key):
					old_child.attributes[key].set_value(new_child.attributes[key].get_value())
		else:
			root_tag.add_tag_and_move_to(new_child.duplicate(),idx)
			delete_at.append(idx)
	var emit_updated_root_tag = false
	while number_child_to_delete > 0:
		emit_updated_root_tag = true
		#deleted without trigering tag_deleted signal
		var deleted_tag:Tag = root_tag.child_tags.pop_back()
		var idx:int = number_child_root_tag + 1 if not delete_at.is_empty() else delete_at.pop_front()
		root_tag.add_undoredo_tag_moved(idx,deleted_tag)
		number_child_to_delete -= 1
	if emit_updated_root_tag:
		updated_root_tag.emit()
	
func add_undoredo_SVG_root() -> void:
	var new_width: float = root_tag.attributes.width.get_value()
	var new_length: float = root_tag.attributes.height.get_value()
	var new_viewbox: Rect2 = root_tag.attributes.viewBox.get_value()
	var old_width: float = root_tag_old_attributes.width.get_value()
	var old_length: float = root_tag_old_attributes.height.get_value()
	var old_viewbox: Rect2 = root_tag_old_attributes.viewBox.get_value()
	var changed = false
	if new_viewbox != old_viewbox:
		changed = true
		root_tag_old_attributes.viewBox._value = new_viewbox
	if new_width != old_width:
		changed = true
		root_tag_old_attributes.width.set_value(new_width)
		root_tag_old_attributes.viewBox._value.size.x = new_width
	if new_length != old_length:
		changed = true
		root_tag_old_attributes.height.set_value(new_length)
		root_tag_old_attributes.viewBox._value.size.y = new_length
	if not changed or UndoRedoManager.is_excuting:
		return
	UndoRedoManager.add_action_simple_methods(
		"Change SVG root",
		root_tag.set_canvas.bind(new_width,new_length,new_viewbox),
		root_tag.set_canvas.bind(old_width,old_length,old_viewbox),
		root_tag,
		false
		)

func add_undoredo_child_tag_attribute(old_value:Variant, new_value:Variant,\
	child_tag:Tag ,attribute_name:String) -> void:
	if UndoRedoManager.is_excuting:
		return
	UndoRedoManager.add_action_simple_methods(
		"Change " + child_tag.title + " : " + attribute_name,
		child_tag.attributes[attribute_name].set_value.bind(new_value),
		child_tag.attributes[attribute_name].set_value.bind(old_value),
		child_tag.attributes[attribute_name],
		false
		)

func  add_undoredo_tag_added(child_tag:Tag) -> void:
	if UndoRedoManager.is_excuting:
		return
	UndoRedoManager.add_action_simple_methods(
		"Added or Removed "+ child_tag.title,
		root_tag.add_tag.bind(child_tag),
		root_tag.delete_tag_with_reference.bind(child_tag),
		child_tag,
		false
		)
		
func  add_undoredo_tag_delete(idx:int,child_tag:Tag) -> void:
	if UndoRedoManager.is_excuting:
		return
	UndoRedoManager.add_action_simple_methods(
		"Added or Removed "+ child_tag.title,
		root_tag.delete_tag_with_reference.bind(child_tag),
		root_tag.add_tag_and_move_to.bind(child_tag,idx),
		child_tag,
		false
		)
		
func add_undoredo_tag_moved(old_idx:int , new_idx:int) -> void:
	if UndoRedoManager.is_excuting:
		return
	UndoRedoManager.add_action_simple_methods(
		"Moved "+ root_tag.get_child_tag(new_idx).title,
		root_tag.move_tag.bind(old_idx , new_idx),
		root_tag.move_tag.bind(new_idx, old_idx),
		root_tag,
		false
		)
