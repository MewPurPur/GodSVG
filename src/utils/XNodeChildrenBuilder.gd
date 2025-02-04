class_name XNodeChildrenBuilder

const ElementFrame = preload("res://src/ui_widgets/element_frame.tscn")
const BasicXNodeFrame = preload("res://src/ui_widgets/basic_xnode_frame.tscn")

static func create(element: Element) -> Array[Control]:
	var arr: Array[Control] = []
	for xnode in element.get_children():
		if xnode.is_element():
			var element_editor := ElementFrame.instantiate()
			element_editor.element = xnode
			arr.append(element_editor)
		else:
			var xnode_editor := BasicXNodeFrame.instantiate()
			xnode_editor.xnode = xnode
			arr.append(xnode_editor)
	return arr

static func generate_drag_preview(xids: Array[PackedInt32Array]) -> Control:
	var xnode_container := VBoxContainer.new()
	for data_idx in range(xids.size() - 1, -1, -1):
		var drag_xid := xids[data_idx]
		var drag_xnode := State.root_element.get_xnode(drag_xid)
		if drag_xnode is Element:
			var preview := ElementFrame.instantiate()
			preview.element = State.root_element.get_xnode(drag_xid)
			preview.custom_minimum_size.x = 360.0
			preview.z_index = 2
			xnode_container.add_child(preview)
		elif drag_xnode is BasicXNode:
			var preview := BasicXNodeFrame.instantiate()
			preview.xnode = State.root_element.get_xnode(drag_xid)
			preview.custom_minimum_size.x = 360.0
			preview.z_index = 2
			xnode_container.add_child(preview)
	
	xnode_container.modulate = Color(1, 1, 1, 0.85)
	return xnode_container
