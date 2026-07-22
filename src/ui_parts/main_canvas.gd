extends Canvas

var reference_image: Texture2D:
	set(new_value):
		if reference_image != new_value:
			reference_image = new_value
			Configs.savedata.get_active_tab().reference_image = new_value
			sync_reference_image()

var show_reference := true:
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


var reference_image_ci: RID

func _ready() -> void:
	super()
	checkerboard.resized.connect(sync_reference_image)
	camera_zoom_changed.connect(sync_reference_image_filtering)
	camera_center_changed.connect(sync_camera_center_in_tab)
	camera_zoom_changed.connect(sync_camera_zoom_in_tab)
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("view_show_grid", toggle_show_grid, ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	shortcuts.add_shortcut("view_show_handles", toggle_show_handles, ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	shortcuts.add_shortcut("view_rasterized_svg", toggle_view_rasterized, ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	State.parsing_finished.connect(react_to_last_parsing)
	react_to_last_parsing()
	
	State.svg_edited.connect(_on_svg_changed.bind(true))
	State.svg_switched_to_another.connect(_on_svg_changed.bind(false))
	State.hover_changed.connect(_on_hover_changed)
	State.selection_changed.connect(_on_selection_changed)
	
	Configs.active_tab_changed.connect(sync_reference_image)
	Configs.active_tab_changed.connect(sync_camera.call_deferred)
	await get_tree().process_frame
	center_frame()

func sync_camera_center_in_tab() -> void:
	Configs.savedata.get_active_tab().camera_center = camera_center

func sync_camera_zoom_in_tab() -> void:
	Configs.savedata.get_active_tab().camera_zoom = camera_zoom

func sync_svg_size() -> void:
	if _current_svg_size != root_element.get_size():
		_current_svg_size = root_element.get_size()
		sync_checkerboard()
		center_frame()
		queue_redraw()

var _current_svg_size: Vector2

func react_to_last_parsing() -> void:
	if State.last_parse_error == SVGParser.ParseError.OK:
		root_element = State.root_element
	else:
		if State.stable_editor_markup.is_empty():
			root_element = ElementRoot.new()

func _on_svg_changed(is_edit: bool) -> void:
	if is_edit:
		sync_svg_size()
	else:
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
		if not reference_image_ci.is_valid():
			reference_image_ci = RenderingServer.canvas_item_create()
			RenderingServer.canvas_item_set_parent(reference_image_ci, checkerboard.get_canvas_item())
		
		var image_size := active_tab.reference_image.get_size()
		var factor := minf(checkerboard.size.x / image_size.x, checkerboard.size.y / image_size.y)
		var draw_size := image_size * factor
		var rect := Rect2((checkerboard.size - draw_size) * 0.5, draw_size)
		
		RenderingServer.canvas_item_clear(reference_image_ci)
		RenderingServer.canvas_item_add_texture_rect(reference_image_ci, rect, active_tab.reference_image)
		RenderingServer.canvas_item_set_visible(reference_image_ci, active_tab.show_reference)
		RenderingServer.canvas_item_set_draw_behind_parent(reference_image_ci, not active_tab.overlay_reference)
	elif reference_image_ci.is_valid():
		RenderingServer.canvas_item_clear(reference_image_ci)
		RenderingServer.free_rid(reference_image_ci)
		reference_image_ci = RID()

func sync_reference_image_filtering() -> void:
	var active_tab := Configs.savedata.get_active_tab()
	if is_instance_valid(active_tab.reference_image):
		var image_size := active_tab.reference_image.get_size()
		var factor := minf(checkerboard.size.x / image_size.x, checkerboard.size.y / image_size.y) * camera_zoom
		RenderingServer.canvas_item_set_default_texture_filter(reference_image_ci,
				RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST if factor >= 2 else RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_LINEAR)

func sync_camera() -> void:
	var active_tab := Configs.savedata.get_active_tab()
	if active_tab.camera_center.is_finite() and active_tab.camera_zoom > 0:
		camera_center = active_tab.camera_center
		camera_zoom = active_tab.camera_zoom
		adjust_view()
	else:
		center_frame()
		# Make sure to sync them in case they didn't change after the centering.
		sync_camera_center_in_tab()
		sync_camera_zoom_in_tab()
