class_name BasicXNode extends XNode

signal text_changed  # Any text change.
signal rendered_text_changed  # Text changes that could affect the SVG.

enum NodeType {COMMENT, TEXT, CDATA, UNKNOWN}
var _type := NodeType.UNKNOWN
var _text := ""

func set_text(new_text: String) -> void:
	if _text != new_text:
		_text = new_text
		text_changed.emit()
		root.basic_xnode_text_changed.emit()
		if _type != NodeType.COMMENT:
			rendered_text_changed.emit()
			root.basic_xnode_rendered_text_changed.emit()

func _init(new_type: NodeType, new_text: String) -> void:
	_type = new_type
	_text = new_text

func duplicate() -> BasicXNode:
	return BasicXNode.new(_type, _text)

func can_merge() -> bool:
	if parent.get_child_count() > xid[-1] + 1:
		var next_xnode := parent.get_child(xid[-1] + 1)
		if next_xnode is BasicXNode and next_xnode.get_type() == _type:
			return true
	if xid[-1] > 0:
		var prev_xnode := parent.get_child(xid[-1] - 1)
		if prev_xnode is BasicXNode and prev_xnode.get_type() == _type:
			return true
	return false

func merge() -> void:
	var merged_text := _text
	var start_index := xid[-1]
	var end_index := xid[-1]
	
	# Merge with previous and next XML nodes.
	while start_index > 0:
		var prev_xnode := parent.get_child(start_index - 1)
		if prev_xnode is BasicXNode and prev_xnode.get_type() == _type:
			merged_text = prev_xnode.get_text() + merged_text
			start_index -= 1
		else:
			break
	
	while end_index < parent.get_child_count() - 1:
		var next_xnode := parent.get_child(end_index + 1)
		if next_xnode is BasicXNode and next_xnode.get_type() == _type:
			merged_text += next_xnode.get_text()
			end_index += 1
		else:
			break
	
	# Remove merged XML nodes.
	for i in range(end_index, start_index, -1):
		if i != xid[-1]:
			parent.remove_child(i)
	
	set_text(merged_text)

static func get_type_string(node_type: NodeType) -> String:
	match node_type:
		NodeType.COMMENT: return TranslationServer.translate("Comment")
		NodeType.TEXT: return TranslationServer.translate("Text")
		NodeType.CDATA: return "CDATA"
		_: return ""

func get_possible_conversions() -> Array[NodeType]:
	var conversions: Array[NodeType] = []
	if (_type == NodeType.TEXT or _type == NodeType.CDATA) and\
	GlobalSettings.savedata.editor_formatter.xml_keep_comments:
		conversions.append(NodeType.COMMENT)
	
	if _type == NodeType.COMMENT or _type == NodeType.CDATA:
		conversions.append(NodeType.TEXT)
	if _type == NodeType.COMMENT or _type == NodeType.TEXT:
		conversions.append(NodeType.CDATA)
	return conversions

func get_type() -> NodeType:
	return _type

func get_text() -> String:
	return _text

func get_replacement(new_type: NodeType) -> BasicXNode:
	return BasicXNode.new(new_type, _text)

func check_text_validity(checked_text: String) -> bool:
	match _type:
		NodeType.COMMENT: return not ("--" in checked_text or checked_text.ends_with("-"))
		NodeType.CDATA: return not "]]>" in checked_text
		NodeType.TEXT:
			return not ("]]>" in checked_text or "<" in checked_text or "&" in checked_text)
		_: return true
