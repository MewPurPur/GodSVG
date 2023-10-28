extends Node

signal parsing_finished(error_id: StringName)

var string: String = ""
var root_tag:TagSVG = TagSVG.new()

var root_tag_old_attributes: Dictionary = {}
var deregestered_attributes_from_undoredo:Dictionary = {} #Attribute:Old_value

func _ready() -> void:
	if GlobalSettings.save_svg:
		string = GlobalSettings.save_data.svg
		sync_data()
	else:
		update_string()
	connect_root_tag_signals()
	for key in root_tag.attributes:
		root_tag_old_attributes[key] = root_tag.attributes[key].duplicate()

func connect_root_tag_signals() -> void:
	root_tag.changed_unknown.connect(update_string)
	root_tag.attribute_changed.connect(update_string)
	root_tag.child_tag_attribute_changed.connect(update_string)
	root_tag.tag_added.connect(update_string.unbind(1))
	root_tag.tag_deleted.connect(update_string.unbind(2))
	root_tag.tag_moved.connect(update_string.unbind(2))
	
	root_tag.attribute_changed.connect(add_undoredo_SVG_root)
	root_tag.child_tag_attribute_change_details.connect(add_undoredo_child_tag_attribute)
	root_tag.tag_added.connect(add_undoredo_tag_added)
	root_tag.tag_deleted.connect(add_undoredo_tag_delete)
	root_tag.tag_moved.connect(add_undoredo_tag_moved)

func sync_data() -> void:
	var err_id := SVGParser.get_svg_error(string)
	parsing_finished.emit(err_id)
	if err_id == &"":
		update_tags()

func update_string() -> void:
	string = SVGParser.svg_to_text(root_tag)

func update_tags() -> void:
	root_tag.replace_self(SVGParser.text_to_svg(string))

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

func deregester_from_undoredo(attribute:Attribute)-> void:
	if not deregestered_attributes_from_undoredo.has(attribute):
		deregestered_attributes_from_undoredo[attribute] = attribute.get_value()

func reregester_to_undoredo(attribute:Attribute)-> void:
	if deregestered_attributes_from_undoredo.has(attribute):
		var old_value = deregestered_attributes_from_undoredo[attribute]
		var new_value = attribute.get_value()
		deregestered_attributes_from_undoredo.erase(attribute)
		var child_tag:Tag
		var attribute_name:String
		for child in root_tag.child_tags:
			for key in child.attributes:
				if attribute == child.attributes[key]:
					child_tag = child
					attribute_name = key
		if not child_tag == null or not attribute_name == null:
			add_undoredo_child_tag_attribute(
				old_value,new_value,child_tag,attribute_name)

func add_undoredo_child_tag_attribute(old_value:Variant, new_value:Variant,\
	child_tag:Tag ,attribute_name:String) -> void:
	if UndoRedoManager.is_excuting or child_tag.attributes[attribute_name] in\
		 deregestered_attributes_from_undoredo.keys():
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
