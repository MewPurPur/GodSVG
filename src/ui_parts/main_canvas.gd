extends Canvas

var reference_image: Texture2D:
	set(new_value):
		if reference_image != new_value:
			reference_image = new_value
			Configs.savedata.get_active_tab().reference_image = new_value
			sync_reference_image()

var show_reference := false:
	set(new_value):
		if show_reference != new_value:
			show_reference = new_value
			Configs.savedata.get_active_tab().show_reference = new_value
			sync_reference_image()

var overlay_reference := false:
	set(new_value):
		if overlay_reference != new_value:
			overlay_reference = new_value
			Configs.savedata.get_active_tab().overlay_reference = new_value
			sync_reference_image()


var reference_texture_rect: TextureRect

func _ready() -> void:
	super()
	camera_center_changed.connect(func() -> void: Configs.savedata.get_active_tab().camera_center = camera_center)
	camera_zoom_changed.connect(func() -> void: Configs.savedata.get_active_tab().camera_zoom = camera_zoom)
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("view_show_grid", toggle_show_grid, ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	shortcuts.add_shortcut("view_show_handles", toggle_show_handles, ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	shortcuts.add_shortcut("view_rasterized_svg", toggle_view_rasterized, ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	State.svg_changed.connect(_on_svg_changed)
	_on_svg_changed()
	State.hover_changed.connect(_on_hover_changed)
	State.selection_changed.connect(_on_selection_changed)
	
	Configs.active_tab_changed.connect(sync_reference_image)
	Configs.active_tab_changed.connect(_on_svg_changed)
	Configs.active_tab_changed.connect(sync_camera.call_deferred)
	await get_tree().process_frame
	center_frame()

func _on_svg_resized() -> void:
	sync_checkerboard()
	center_frame()
	queue_redraw()

var _current_svg_size: Vector2

func _on_root_element_attribute_changed(attribute_name: String) -> void:
	if attribute_name in ["width", "height", "viewBox"]:
		_current_svg_size = root_element.get_size()
		_on_svg_resized()

func _on_svg_changed() -> void:
	if root_element != State.root_element:
		root_element = State.root_element
		root_element.attribute_changed.connect(_on_root_element_attribute_changed)
	
	_current_svg_size = root_element.get_size()
	queue_texture_update()
	handles_manager.queue_update_handles()

func _on_hover_changed() -> void:
	hovered_xid = State.hovered_xid
	semi_hovered_xid = State.semi_hovered_xid
	inner_hovered = State.inner_hovered

func _on_selection_changed() -> void:
	selected_xids = State.selected_xids
	selection_pivot_xid = State.selection_pivot_xid
	semi_selected_xid = State.semi_selected_xid
	inner_selections = State.inner_selections
	inner_selection_pivot = State.inner_selection_pivot


func zoom_in() -> void:
	set_zoom(camera_zoom * sqrt(2))

func zoom_out() -> void:
	set_zoom(camera_zoom / sqrt(2))

func sync_reference_image() -> void:
	var active_tab := Configs.savedata.get_active_tab()
	if is_instance_valid(active_tab.reference_image):
		if not is_instance_valid(reference_texture_rect):
			reference_texture_rect = TextureRect.new()
			reference_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			reference_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			reference_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			viewport.add_child(reference_texture_rect)
			var _on_checkerboard_resized := func() -> void:
					reference_texture_rect.size = checkerboard.size
			checkerboard.resized.connect(_on_checkerboard_resized)
			reference_texture_rect.tree_exited.connect(checkerboard.resized.disconnect.bind(_on_checkerboard_resized))
			_on_checkerboard_resized.call()
		
		reference_texture_rect.texture = active_tab.reference_image
		reference_texture_rect.visible = active_tab.show_reference
		viewport.move_child(reference_texture_rect, -1 if active_tab.overlay_reference else 0)
	elif is_instance_valid(reference_texture_rect):
		reference_texture_rect.queue_free()

func sync_camera() -> void:
	var active_tab := Configs.savedata.get_active_tab()
	if active_tab.camera_center.is_finite() and active_tab.camera_zoom > 0:
		camera_center = active_tab.camera_center
		camera_zoom = active_tab.camera_zoom
		adjust_view()
	else:
		center_frame()
