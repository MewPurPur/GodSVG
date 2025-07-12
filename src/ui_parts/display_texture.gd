extends TextureRect

var update_semaphore := Semaphore.new()
var update_thread := Thread.new()
var update_data: Dictionary[String, Variant]

var view_rect := Rect2():
	set(new_value):
		if view_rect != new_value:
			view_rect = new_value
			queue_update()

var _update_pending := false

func _ready() -> void:
	State.svg_changed.connect(queue_update)
	State.zoom_changed.connect(queue_update)
	State.view_rasterized_changed.connect(_on_view_rasterized_changed)
	update_thread.start(_update_thread)
	queue_update()

func _exit_tree() -> void:
	update_data = { "exit": true }
	update_semaphore.post()
	update_thread.wait_to_finish()

func _on_view_rasterized_changed() -> void:
	if State.zoom != 1.0:
		queue_update()


func queue_update() -> void:
	_update.call_deferred()
	_update_pending = true

func _update() -> void:
	if not _update_pending:
		return

	_update_pending = false
	var image_zoom := 1.0 if State.view_rasterized and State.zoom > 1.0 else State.zoom
	var pixel_size := 1 / image_zoom
	
	# Translate to canvas coords.
	var display_rect := view_rect.grow(pixel_size * 2)
	display_rect.position = display_rect.position.snapped(Vector2(pixel_size, pixel_size))
	display_rect.position.x = maxf(display_rect.position.x, 0.0)
	display_rect.position.y = maxf(display_rect.position.y, 0.0)
	display_rect.size = display_rect.size.snapped(Vector2(pixel_size, pixel_size))
	display_rect.end.x = minf(display_rect.end.x, ceili(State.root_element.width))
	display_rect.end.y = minf(display_rect.end.y, ceili(State.root_element.height))
		
	Utils.set_control_position_fixed(self, display_rect.position)
	update_data = {
		"exit": false,
		"display_rect": display_rect,
		"image_zoom": image_zoom,
		"root_element": State.root_element,
		"custom_width": display_rect.size.x,
		"custom_height": display_rect.size.y,
		"custom_viewbox": Rect2(State.root_element.world_to_canvas(display_rect.position), display_rect.size / State.root_element.canvas_transform.get_scale())
	}
	update_semaphore.post()
	size = display_rect.size

func _update_thread() -> void:
	while true:
		update_semaphore.wait()
		var data := update_data.duplicate()
		if data.exit:
			return
		
		var svg_text := SVGParser.root_cutout_to_text(
			data.root_element,
			data.custom_width,
			data.custom_height,
			data.custom_viewbox
		)
		var new_texture = SVGTexture.create_from_string(svg_text, data.image_zoom)
		call_thread_safe("_set_texture", new_texture)

func _set_texture(new_texture: Texture2D) -> void:
	texture = new_texture
