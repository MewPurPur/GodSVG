class_name XNodeChildrenBuilder

const ElementFrame = preload("res://src/ui_widgets/element_frame.tscn")
const BasicXNodeFrame = preload("res://src/ui_widgets/basic_xnode_frame.tscn")

static func create(element: Element) -> Array[Control]:
	var arr: Array[Control] = []
	for xnode in element.get_children():
		if xnode is Element:
			var element_editor := ElementFrame.instantiate()
			element_editor.element = xnode
			arr.append(element_editor)
		else:
			var xnode_editor := BasicXNodeFrame.instantiate()
			xnode_editor.xnode = xnode
			arr.append(xnode_editor)
	return arr
