extends VTitledPanel


const Tile = preload("res://src/ui_widgets/icon_view_tile.gd")
const TileScene = preload("res://src/ui_widgets/icon_view_tile.tscn")


@onready var icon_view_tile_container: Control = %IconViewTileContainer
@onready var add_new_size_button: Button = %AddNewSizeButton
@onready var reset_button: Button = %ResetButton
@onready var texture_rect: TextureRect = %TextureRect
@onready var scaled_preview: HBoxContainer = %ScaledPreview


var needs_update := false
var selected_tile: int


func _ready() -> void:
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	reset_button.pressed.connect(reset_tiles)
	add_new_size_button.pressed.connect(_add_new_tile)
	State.svg_changed.connect(update_tiles)
	visibility_changed.connect(func(): if visible and needs_update: update_tiles())
	load_tiles()
	await get_tree().process_frame
	update_tiles()


func load_tiles() -> void:
	_delete_tiles()
	scaled_preview.hide()
	for new_size in Configs.savedata.icon_view_sizes:
		icon_view_tile_container.add_child(_create_new_tile(new_size))
	update_tiles.call_deferred()


func reset_tiles() -> void:
	_delete_tiles()
	scaled_preview.hide()
	for new_size in PackedInt64Array([16, 24, 32, 48, 64]):
		icon_view_tile_container.add_child(_create_new_tile(new_size))
	update_tiles.call_deferred()


func _add_new_tile() -> void:
	icon_view_tile_container.add_child(_create_new_tile(16))
	update_tiles.call_deferred()


func _create_new_tile(new_size: int) -> Tile:
	var tile := TileScene.instantiate()
	tile.texture_size = new_size
	tile.remove_requested.connect(func():
		# queue_free doesn't immediately remove the child?
		_delete_tile(tile)
		_update_savedata()
	)
	tile.selected.connect(func():
		selected_tile = tile.get_index()
		texture_rect.texture = tile.texture
		scaled_preview.show()
		_update_texture_rect_size()
	)
	tile.texture_changed.connect(func():
		if tile.get_index() == selected_tile:
			texture_rect.texture = tile.texture
			_update_texture_rect_size()
	)
	tile.texture_size_changed.connect(_update_savedata)
	return tile


func update_tiles() -> void:
	_update_savedata()
	if not visible:
		needs_update = true
		return
	var svg_text := SVGParser.root_to_export_markup(State.root_element)
	for child: Tile in icon_view_tile_container.get_children():
		child.svg_markup = State.svg_text
	if selected_tile >= 0 and selected_tile < icon_view_tile_container.get_child_count():
		texture_rect.texture = icon_view_tile_container.get_child(selected_tile).texture
		_update_texture_rect_size()


func _update_texture_rect_size() -> void:
	if not texture_rect.texture:
		scaled_preview.hide()
		return
	texture_rect.custom_minimum_size = texture_rect.texture.get_size()


func sync_theming() -> void:
	color = Color.TRANSPARENT
	border_color = ThemeUtils.subtle_panel_border_color
	title_color = ThemeUtils.basic_panel_inner_color


func _delete_tiles() -> void:
	for child in icon_view_tile_container.get_children():
		icon_view_tile_container.remove_child(child)
		child.queue_free()


func _delete_tile(tile: Tile) -> void:
	icon_view_tile_container.remove_child(tile)
	tile.queue_free()


func _update_savedata() -> void:
	var sizes: PackedInt64Array
	for child: Tile in icon_view_tile_container.get_children():
		sizes.append(child.texture_size)
	Configs.savedata.icon_view_sizes = sizes
