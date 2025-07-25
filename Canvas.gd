class_name Canvas extends SubViewportContainer

var view_rasterized := false
var show_grid := true
var show_handles := true
var show_reference := false
var overlay_reference := false

var camera_zoom: float
var camera_position: Vector2
var camera_unsnapped_position: Vector2

signal zoom_changed

func toggle_view_rasterized() -> void:
	view_rasterized = not view_rasterized

func toggle_show_grid() -> void:
	show_grid = not show_grid

func toggle_show_handles() -> void:
	show_handles = not show_handles

func toggle_show_reference() -> void:
	show_reference = not show_reference

func toggle_overlay_reference() -> void:
	overlay_reference = not overlay_reference

func set_zoom(new_value: float) -> void:
	if camera_zoom != new_value:
		camera_zoom = new_value
		zoom_changed.emit()


const GRID_TICKS_INTERVAL = 4
const GRID_TICK_DISTANCE = float(GRID_TICKS_INTERVAL)

var ci := get_canvas_item()
var grid_ci := RenderingServer.canvas_item_create()
var grid_numbers_ci := RenderingServer.canvas_item_create()
var reference_image_ci := RenderingServer.canvas_item_create()

var reference_texture: Texture2D


func _ready() -> void:
	var viewport := SubViewport.new()
	add_child(viewport)
	viewport.set_script(load("res://src/ui_parts/viewport.gd"))
	viewport.size_2d_override_stretch = true
	viewport.disable_3d = true
	viewport.handle_input_locally = false
	viewport.gui_snap_controls_to_pixels = false
	
	var reference_texture_rect := TextureRect.new()
	reference_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reference_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reference_texture_rect.visible = false
	viewport.add_child(reference_texture_rect)
	var checkerboard_texture_rect := TextureRect.new()
	checkerboard_texture_rect.texture = load("res://assets/icons/backgrounds/Checkerboard.svg")
	checkerboard_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	checkerboard_texture_rect.stretch_mode = TextureRect.STRETCH_TILE
	checkerboard_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var zoom_shader_material := ShaderMaterial.new()
	zoom_shader_material.shader = load("res://src/shaders/zoom_shader.gdshader")
	checkerboard_texture_rect.material = zoom_shader_material
	viewport.add_child(checkerboard_texture_rect)
	var display_texture_rect := TextureRect.new()
	display_texture_rect.set_script(load("res://src/ui_parts/display_texture.gd"))
	checkerboard_texture_rect.add_child(display_texture_rect)
	var controls := Control.new()
	controls.set_script(load("res://src/ui_parts/handles_manager.gd"))
	viewport.add_child(controls)
	
	Configs.grid_color_changed.connect(queue_redraw)
	update_show_grid()
	RenderingServer.canvas_item_set_parent(grid_ci, ci)
	RenderingServer.canvas_item_set_parent(grid_numbers_ci, ci)
	State.svg_resized.connect(queue_redraw)
	State.zoom_changed.connect(change_zoom)
	State.zoom_changed.connect(queue_redraw)

func exit_tree() -> void:
	RenderingServer.free_rid(grid_ci)
	RenderingServer.free_rid(grid_numbers_ci)
