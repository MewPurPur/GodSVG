class_name SVGParser extends RefCounted

static func svg_to_text(svg_tag: TagSVG) -> String:
	var w: float = svg_tag.attributes.width.get_value()
	var h: float = svg_tag.attributes.height.get_value()
	var viewbox: Rect2 = svg_tag.attributes.viewBox.get_value()
	
	var text := '<svg width="%s" height="%s" viewBox="%s"' % [String.num(w, 4),
			String.num(h, 4), AttributeRect.rect_to_string(viewbox)]
	for attribute in svg_tag.unknown_attributes:
		text += " " + attribute.name + '="' + attribute.get_value() + '"'
	text += ">"
	
	for inner_tag in svg_tag.child_tags:
		text += _tag_to_text(inner_tag)
	return text + '</svg>'

static func _tag_to_text(tag: Tag) -> String:
	var text := ""
	text += '<' + tag.name
	for attribute_key in tag.attributes:
		var attribute: Attribute = tag.attributes[attribute_key]
		var value: Variant = attribute.get_value()
		if value == attribute.default:
			continue
		
		text += " " + attribute_key + '="'
		match attribute.type:
			Attribute.Type.INT:
				text += value.to_int()
			Attribute.Type.FLOAT, Attribute.Type.UFLOAT, Attribute.Type.NFLOAT:
				text += String.num(value, 4)
			Attribute.Type.COLOR, Attribute.Type.PATHDATA, Attribute.Type.ENUM:
				text += value
			Attribute.Type.RECT:
				text += AttributeRect.rect_to_string(value)
		text += '"'
	
	for attribute in tag.unknown_attributes:
		text += " " + attribute.name + '="' + attribute.get_value() + '"'
	
	if tag.is_standalone():
		text += '/>'
	else:
		text += '>'
		for child_tag in tag.child_tags:
			text += _tag_to_text(child_tag)
		text += '</' + tag.name + '>'
	
	return text


static func text_to_svg(text: String) -> TagSVG:
	text = text.strip_edges() #need due to a godot  bug
	var svg_tag := TagSVG.new()
	var parser := XMLParser.new()
	parser.open_buffer(text.to_ascii_buffer())
	var unclosed_tag_stack: Array[Tag] = [svg_tag]
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var node_name := parser.get_node_name()
				var attrib_dict := {}
				for i in range(parser.get_attribute_count()):
					attrib_dict[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
				
				# SVG tag requires width and height without defaults, so do the logic early.
				if node_name == "svg":
					var new_w: float = attrib_dict["width"].to_float() if\
							attrib_dict.has("width") else 0.0
					var new_h: float = attrib_dict["height"].to_float() if\
							attrib_dict.has("height") else 0.0
					var new_viewbox := AttributeRect.string_to_rect(attrib_dict["viewBox"])\
							if attrib_dict.has("viewBox") else Rect2(0, 0, new_w, new_h)
					if new_w == 0.0 and new_h == 0.0 and new_viewbox.size != Vector2(0, 0):
						new_w = new_viewbox.size.x
						new_h = new_viewbox.size.y
					
					svg_tag.attributes.width.set_value(new_w, false)
					svg_tag.attributes.height.set_value(new_h, false)
					svg_tag.attributes.viewBox.set_value(new_viewbox, false)
					
					var unknown: Array[AttributeUnknown] = []
					for element in attrib_dict:
						if svg_tag.attributes.has(element):
							var attribute: Attribute = svg_tag.attributes[element]
							if typeof(attribute.get_value()) == Variant.Type.TYPE_STRING:
								attribute.set_value(attrib_dict[element],
										Attribute.UpdateType.SILENT)
							elif typeof(attribute.get_value()) == Variant.Type.TYPE_FLOAT:
								attribute.set_value(attrib_dict[element].to_float(),
										Attribute.UpdateType.SILENT)
						else:
							unknown.append(AttributeUnknown.new(element, attrib_dict[element]))
					svg_tag.set_unknown_attributes(unknown)
					
				else:
					var tag: Tag
					match node_name:
						"circle": tag = TagCircle.new()
						"ellipse": tag = TagEllipse.new()
						"rect": tag = TagRect.new()
						"path": tag = TagPath.new()
						"line": tag = TagLine.new()
						_: tag = TagUnknown.new(node_name)
					
					var unknown: Array[AttributeUnknown] = []
					for element in attrib_dict:
						if tag.attributes.has(element):
							var attribute: Attribute = tag.attributes[element]
							if typeof(attribute.get_value()) == Variant.Type.TYPE_STRING:
								attribute.set_value(attrib_dict[element],
										Attribute.UpdateType.SILENT)
							elif typeof(attribute.get_value()) == Variant.Type.TYPE_FLOAT:
								attribute.set_value(attrib_dict[element].to_float(),
										Attribute.UpdateType.SILENT)
						else:
							unknown.append(AttributeUnknown.new(element, attrib_dict[element]))
					tag.set_unknown_attributes(unknown)
					
					# Check if we're entering or exiting the tag.
					var node_offset := parser.get_node_offset()
					var closure_pos := text.find("/>", node_offset)
					if closure_pos == -1 or closure_pos >= text.find(">", node_offset):
						unclosed_tag_stack.append(tag)
					else:
						unclosed_tag_stack.back().child_tags.append(tag)
			XMLParser.NODE_ELEMENT_END:
				if unclosed_tag_stack.size() > 1:
					var closed_tag: Tag = unclosed_tag_stack.pop_back()
					unclosed_tag_stack.back().child_tags.append(closed_tag)
	
	return svg_tag


# TODO Can definitely be improved.
static func get_svg_syntax_error(text: String) -> StringName:
	text = text.strip_edges() #need due to a godot  bug
	# Easy cases.
	if text.is_empty():
		return &"#err_empty_svg"
	
	if text.count("<") != text.count(">"):
		return &"#err_improper_nesting"
	
	var parser := XMLParser.new()
	parser.open_buffer(text.to_ascii_buffer())
	if text.begins_with("<?"):
		parser.skip_section()
	
	var nodes: Array[String] = []  # Serves as a sort of stack.
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name := parser.get_node_name()
			# First node must be "svg", last node must be closing "svg".
			if nodes.is_empty():
				if node_name != "svg":
					return &"#err_not_svg"
			
			var offset := parser.get_node_offset()
			# Don't add tags that were closed right away to the stack.
			var closure_pos := text.find("/>", offset)
			if closure_pos == -1 or closure_pos >= text.find(">", offset):
				nodes.append(node_name)
		
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			var node_name := parser.get_node_name()
			if nodes.is_empty() or node_name != nodes.back():
				return &"#err_improper_nesting"
			nodes.pop_back()
	return &"" if nodes.is_empty() else &"#err_improper_closing"


static  func get_svg_text_changes(old_text: String, new_text: String) -> Array:
	#simple Diff tool that return array changes made to svg text changes, can be matched to TagSVG
	#there only 4 true action when editing text svg: add tag,remove tag, modify attribute,replace
	#actions availed:svg_tag_change,insert_tag,remove_tag,add_child_tag,modify_tag,
	#               :replace_tag
	var svg_changes:Array = []
	var old_text_compare:Dictionary = svg_text_compare_format(old_text)
	var new_text_compare:Dictionary = svg_text_compare_format(new_text)
	if old_text_compare.is_empty() or new_text_compare.is_empty():
		return svg_changes
	#check for svg root tag
	if not old_text_compare["[0]"] == new_text_compare["[0]"]:
		var change:Dictionary = {
			"action_name" : "svg_tag_change",
			"attributes" : new_text_compare["[0]"],
			"index" : null
			}
		svg_changes.append(change)
	old_text_compare.erase("[0]")
	new_text_compare.erase("[0]")
	#check for add,removed,modified and replaced tags
	var old_text_key_point:int = 0
	var new_text_key_point:int = 0
	while new_text_key_point < len(new_text_compare.keys()):
		var key = new_text_compare.keys()[new_text_key_point]
		var key_idx:Array = Array(key.trim_prefix("[").trim_suffix("]").split(","))\
								.map(func(str_num): return int(str_num))
		var nesting_level:int = len(key_idx) - 1
		var old_text_idx:String
		if not old_text_key_point > (len(old_text_compare.keys()) - 1): 
			old_text_idx = str(old_text_compare.keys()[old_text_key_point])
		else:
			#clear tag add at the end of nested tag
			var change:Dictionary = {
				"action_name" : "insert_tag",
				"attributes" : new_text_compare[key],
				"index" : key,
				}
			svg_changes.append(change)
			new_text_key_point += 1
			continue
		var nesting_old_text_idx:int =len(Array(old_text_idx.trim_prefix("[").trim_suffix("]").split(",")))
		if (nesting_level + 1) < nesting_old_text_idx:
			# the only/all nested child(ren)  was removed
			var change:Dictionary = {
				"action_name" : "remove_tag",
				"attributes" : old_text_compare[old_text_idx],
				"index" : old_text_idx,
				}
			svg_changes.append(change)
			var child_tags_count = 0
			for tag_key in old_text_compare:
				if tag_key.begins_with(key.trim_suffix("]")):
					child_tags_count += 1
			old_text_key_point += child_tags_count# skip it self and it's children
			continue
		elif (nesting_level + 1) > nesting_old_text_idx:
			#add first nested child(ren)
			var change:Dictionary = {
				"action_name" : "add_child_tag",
				"attributes" : new_text_compare[key],
				"index" : key,
				}
			svg_changes.append(change)
			new_text_key_point += 1
			continue
		
		if not new_text_compare[key] == old_text_compare[old_text_idx]:
			if new_text_compare[key].tag_name == old_text_compare[old_text_idx].tag_name:
				#clear modify tag attributes
				var change:Dictionary = {
					"action_name" : "modify_tag",
					"attributes" : new_text_compare[key],
					"index" : old_text_idx,
					}
				svg_changes.append(change)
				new_text_key_point += 1
				old_text_key_point += 1
				continue
			
			#count number of tag after in new_text_compare at same current nesting level
			var next_new_text_idx:Array = key_idx
			next_new_text_idx[nesting_level] += 1
			var tags_count:int = 0
			while true:
				if new_text_compare.has(str(next_new_text_idx)):
					next_new_text_idx[nesting_level] += 1
					tags_count += 1
				else:
					break
			var in_new_tag_count_after:int = tags_count
			#count number of tag after in old_text_compare at same current nesting level
			var next_old_text_idx:Array = Array(old_text_idx.trim_prefix("[").trim_suffix("]")\
												.split(",")).map(func(str_num): return int(str_num))
			next_old_text_idx[nesting_level] += 1
			tags_count = 0
			while true:
				if old_text_compare.has(str(next_old_text_idx)):
					next_old_text_idx[nesting_level] += 1
					tags_count += 1
				else:
					break
			var in_old_tag_count_after:int = tags_count
			if in_new_tag_count_after == in_old_tag_count_after:
				#clear replaced tag
				var change:Dictionary = {
					"action_name" : "replace_tag",
					"attributes" : new_text_compare[key],
					"index" : old_text_idx,
					}
				svg_changes.append(change)
				new_text_key_point += 1
				old_text_key_point += 1
				continue
			#if false tag was removed
			var is_added:bool = in_new_tag_count_after > in_old_tag_count_after
			if is_added:
				#clear added tag
				var change:Dictionary = {
					"action_name" : "insert_tag",
					"attributes" : new_text_compare[key],
					"index" : old_text_idx,
					}
				svg_changes.append(change)
				new_text_key_point += 1
				continue
			else:
				#clear removed tag
				var change:Dictionary = {
					"action_name" : "remove_tag",
					"attributes" : old_text_compare[old_text_idx],
					"index" : old_text_idx,
					}
				svg_changes.append(change)
				tags_count = 0
				for tag_key in old_text_compare:
					if tag_key.begins_with(key.trim_suffix("]")):
						tags_count += 1
				old_text_key_point += tags_count# skip it self and it's children
				continue
		
		new_text_key_point += 1
		old_text_key_point += 1
	
	while old_text_key_point < len(old_text_compare.keys()):
		#clear removed tag in nesting level zero (child to svg tag)
		var old_text_idx = str(old_text_compare.keys()[old_text_key_point])
		var change:Dictionary = {
			"action_name" : "remove_tag",
			"attributes" : old_text_compare[old_text_idx],
			"index" : old_text_idx,
			}
		svg_changes.append(change)
		old_text_key_point += 1
	return svg_changes


static func svg_text_compare_format(text: String) -> Dictionary:
	text = text.strip_edges() #need due to a godot  bug
	var compare_format:Dictionary = {}
	# compare_format (key is tag idx - chained for child)[1,1,1] : svg tag attrib_dict similar tids but in string
	#compare_format [0] is reserved for svg root tag ,hence chils start at idx 1
	var parser := XMLParser.new()
	parser.open_buffer(text.to_ascii_buffer())
	var nesting_level:int = 0 # zero are svg root tag children
	var tag_count:Array = [0]#append for higher nesting_level and pop when exist
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var node_name := parser.get_node_name()
				var attrib_dict := {"tag_name" = node_name }
				for i in range(parser.get_attribute_count()):
					attrib_dict[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
				compare_format[str(tag_count)] = attrib_dict
				if not node_name == "svg":
					var node_offset := parser.get_node_offset()
					var closure_pos := text.find("/>", node_offset)
					if closure_pos == -1 or closure_pos >= text.find(">", node_offset):
						nesting_level += 1
						tag_count.append(1)
					else:
						tag_count[nesting_level] += 1
				else:
					tag_count[nesting_level] += 1
			XMLParser.NODE_ELEMENT_END:
				if len(tag_count) > 1:
					nesting_level -= 1
					tag_count.pop_back()
				tag_count[nesting_level] += 1
	return compare_format
