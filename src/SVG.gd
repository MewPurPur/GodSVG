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


func is_error(check_string:String) -> bool:
	var err_id := SVGParser.get_svg_syntax_error(check_string)
	parsing_finished.emit(err_id)
	if err_id == &"":
		return false
	return true

func sync_data() -> void:
	if not is_error(string):
		update_tags()

func update_string() -> void:
	string = SVGParser.svg_to_text(root_tag)

func update_tags() -> void:
	root_tag.replace_self(SVGParser.text_to_svg(string))

func update_using_svg_diff(new_string:String) -> void:
	if is_error(new_string): return
	var svg_changes:Array = SVGParser.get_svg_text_changes(string,new_string)
	#actions availed:svg_tag_change,insert_tag,remove_tag,add_child_tag,modify_tag,
	#               :replace_tag
	string = new_string
	if svg_changes.is_empty(): return
	var ref_tags:Dictionary = {}#{tid:tag}
	#1 edit pass, svg_tag_change and save reference tags  to be use in edit pass 2 and 3
	for action in svg_changes:
		if action.action_name == "svg_tag_change":
			var unknown: Array[AttributeUnknown] = []
			for attribute_name in action.attributes:
				if attribute_name == "tag_name": continue
				if root_tag.attributes.has(attribute_name):
					var tag_attribute = root_tag.attributes[attribute_name]
					if typeof(tag_attribute.get_value()) == Variant.Type.TYPE_STRING:
						tag_attribute.set_value(action.attributes[attribute_name], false)
					elif typeof(tag_attribute.get_value()) == Variant.Type.TYPE_FLOAT:
						tag_attribute.set_value(action.attributes[attribute_name].to_float(), false)
				else:
					unknown.append(AttributeUnknown.new(attribute_name, action.attributes[attribute_name]))
			root_tag.set_unknown_attributes(unknown)
			svg_changes.remove_at(svg_changes.find(action))
		elif not action.action_name == "add_child_tag":
			var idx = action.index if not action.index == null else ""
			var idx_as_tid:Array = Array(idx.trim_prefix("[").trim_suffix("]").split(","))\
									.map(func(str_num): return int(str_num)-1)
			if not idx_as_tid[-1] >= root_tag.get_by_tid(Utils\
								.get_parent_tid(PackedInt32Array(idx_as_tid))).get_child_count():
				ref_tags[str(idx_as_tid)] = root_tag.get_by_tid(PackedInt32Array(idx_as_tid))
	#2 edit pass, focuses on modify, insert, remove tag
	for action in svg_changes:
		var idx = action.index if not action.index == null else ""
		var idx_as_tid:Array = Array(idx.trim_prefix("[").trim_suffix("]").split(","))\
									.map(func(str_num): return int(str_num)-1)
		if not action.action_name == "add_child_tag":
			var tag: Tag
			if action.action_name == "modify_tag":
				tag = ref_tags[str(idx_as_tid)]
			else:
				match action.attributes.tag_name:
					"circle": tag = TagCircle.new()
					"ellipse": tag = TagEllipse.new()
					"rect": tag = TagRect.new()
					"path": tag = TagPath.new()
					"line": tag = TagLine.new()
					_: tag = TagUnknown.new(action.attributes.tag_name)
			
			var unknown: Array[AttributeUnknown] = []
			for attribute_name in action.attributes:
				if attribute_name == "tag_name": continue
				if tag.attributes.has(attribute_name):
					var tag_attribute:Attribute = tag.attributes[attribute_name]
					if typeof(tag_attribute.get_value()) == Variant.Type.TYPE_STRING:
						tag_attribute.set_value(action.attributes[attribute_name])
					elif typeof(tag_attribute.get_value()) == Variant.Type.TYPE_FLOAT:
						tag_attribute.set_value(action.attributes[attribute_name].to_float())
				else:
					var tag_attribute:AttributeUnknown
					for attribute in tag.unknown_attributes:
						if attribute.name == attribute_name:
							tag_attribute = attribute
					if not tag_attribute == null:
						tag_attribute.set_value(action.attributes[attribute_name])
						unknown.append(tag_attribute)
					else:
						unknown.append(AttributeUnknown.new(\
													attribute_name, action.attributes[attribute_name]))
					if not unknown.is_empty() or tag.unknown_attributes.is_empty():
						tag.set_unknown_attributes(unknown)
						root_tag.tag_layout_changed.emit()
			if action.action_name == "modify_tag":#check for removed attributes
				for attribute_name in tag.attributes:
					if not action.attributes.has(attribute_name):
						var tag_attribute:Attribute = tag.attributes[attribute_name]
						tag_attribute.set_value(tag_attribute.default)
				if unknown.is_empty() and not tag.unknown_attributes.is_empty():
					tag.set_unknown_attributes([])
					root_tag.tag_layout_changed.emit()
			if action.action_name == "insert_tag":
				root_tag.add_tag(tag,PackedInt32Array(idx_as_tid))
			elif action.action_name == "replace_tag":
				var ref_tag = ref_tags[str(idx_as_tid)]
				ref_tag.replace_self(tag)
			elif action.action_name == "remove_tag":
				var ref_tag = ref_tags[str(idx_as_tid)]
				var ref_tag_tid = idx_as_tid
				ref_tag_tid[-1] = root_tag.get_by_tid(Utils\
								.get_parent_tid(PackedInt32Array(idx_as_tid))).child_tags\
								.find(ref_tag)
				root_tag.delete_tags([PackedInt32Array(ref_tag_tid)])
			svg_changes.remove_at(svg_changes.find(action))
	#4 edit pass, focuses on adding child tags
	for action in svg_changes:
		var idx = action.index if not action.index == null else ""
		var idx_as_tid:Array = Array(idx.trim_prefix("[").trim_suffix("]").split(","))\
									.map(func(str_num): return int(str_num)-1)
		if action.action_name == "add_child_tag":
			var tag: Tag
			match action.attributes.tag_name:
				"circle": tag = TagCircle.new()
				"ellipse": tag = TagEllipse.new()
				"rect": tag = TagRect.new()
				"path": tag = TagPath.new()
				"line": tag = TagLine.new()
				_: tag = TagUnknown.new(action.attributes.tag_name)
			var unknown: Array[AttributeUnknown] = []
			for attribute_name in action.attributes:
				if attribute_name == "tag_name": continue
				if tag.attributes.has(attribute_name):
					var tag_attribute = tag.attributes[attribute_name]
					if typeof(tag_attribute.get_value()) == Variant.Type.TYPE_STRING:
						tag_attribute.set_value(action.attributes[attribute_name], false)
					elif typeof(tag_attribute.get_value()) == Variant.Type.TYPE_FLOAT:
						tag_attribute.set_value(action.attributes[attribute_name].to_float(), false)
				else:
					unknown.append(AttributeUnknown.new(attribute_name, action.attributes[attribute_name]))
			tag.set_unknown_attributes(unknown)
			root_tag.add_tag(tag,PackedInt32Array(idx_as_tid))
		svg_changes.remove_at(svg_changes.find(action))
	
