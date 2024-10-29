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

static func generate_drag_preview(xids: Array[PackedInt32Array], ) -> Control:
	var xnode_container := VBoxContainer.new()
	for data_idx in range(xids.size() - 1, -1, -1):
		var drag_xid := xids[data_idx]
		var drag_xnode := SVG.root_element.get_xnode(drag_xid)
		if drag_xnode is Element:
			var preview := ElementFrame.instantiate()
			preview.element = SVG.root_element.get_xnode(drag_xid)
			preview.custom_minimum_size.x = 360.0
			preview.z_index = 2
			xnode_container.add_child(preview)
		elif drag_xnode is BasicXNode:
			var preview := BasicXNodeFrame.instantiate()
			preview.xnode = SVG.root_element.get_xnode(drag_xid)
			preview.custom_minimum_size.x = 360.0
			preview.z_index = 2
			xnode_container.add_child(preview)
	
	#var vp := SubViewport.new()
	#vp.transparent_bg = true
	#vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	#vp.size = Vector2.ZERO
	#vp.add_child(elements_container)
	#add_child(vp)
	#vp.transparent_bg = false
	#var texture_rect := TextureRect.new()
	#await RenderingServer.frame_post_draw
	#texture_rect.texture = ImageTexture.create_from_image(vp.get_texture().get_image())
	#texture_rect.modulate = Color(1, 1, 1, 0.85)
	#vp.queue_free()
	#set_drag_preview(texture_rect)
	xnode_container.modulate = Color(1, 1, 1, 0.85)
	return xnode_container
