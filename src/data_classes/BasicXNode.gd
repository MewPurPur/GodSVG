## Any XML node that's not an element.
class_name BasicXNode extends XNode

signal text_changed  # Any text change.
signal rendered_text_changed  # Text changes that could affect the SVG.

enum NodeType {COMMENT, TEXT, CDATA}
var _type: NodeType
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

static func get_type_string(node_type: NodeType) -> String:
	match node_type:
		NodeType.COMMENT: return Translator.translate("Comment")
		NodeType.TEXT: return Translator.translate("Text")
		NodeType.CDATA: return "CDATA"
		_: return ""

func get_possible_conversions() -> Array[NodeType]:
	var conversions: Array[NodeType] = []
	if (_type == NodeType.TEXT or _type == NodeType.CDATA) and not Configs.savedata.editor_formatter.xml_remove_comments:
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
			if "]]>" in checked_text or "<" in checked_text:
				return false
			var current_pos := 0
			while true:
				var amp_pos := checked_text.find("&", current_pos)
				if amp_pos == -1:
					break
				
				var semi_pos := checked_text.find(";", amp_pos + 1)
				if semi_pos == -1:
					return false
				
				var entity_body := checked_text.substr(amp_pos + 1, semi_pos - amp_pos - 1)
				if entity_body.begins_with("#"):
					var num_body := entity_body.substr(1, entity_body.length() - 1)
					if num_body.is_empty():
						return false
					elif (num_body.begins_with("x") or num_body.begins_with("X")) and\
					not num_body.substr(1, num_body.length() - 1).is_valid_hex_number():
						return false
					else:
						for c in num_body:
							if not (c >= "0" and c <= "9"):
								return false
				else:
					# The only predefined XML entities.
					if not entity_body in ["lt", "gt", "amp", "apos", "quot"]:
						return false
				current_pos = semi_pos + 1
			return true
		
		_: return true
