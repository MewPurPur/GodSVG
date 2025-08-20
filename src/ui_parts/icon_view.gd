extends VTitledPanel


const Tile = preload("res://src/ui_widgets/icon_view_tile.gd")
const TileScene = preload("res://src/ui_widgets/icon_view_tile.tscn")


@onready var icon_view_tile_container: Control = %IconViewTileContainer
@onready var add_new_size_button: Button = %AddNewSizeButton
@onready var reset_button: Button = %ResetButton
@onready var texture_rect: TextureRect = %TextureRect
@onready var scaled_preview: Control = %ScaledPreview
@onready var clear_button: Button = %ClearButton
@onready var size_label: Label = %SizeLabel


var needs_update := false
var selected_tile: Tile = null


func _ready() -> void:
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	reset_button.pressed.connect(reset_tiles)
	add_new_size_button.pressed.connect(_add_new_tile)
	clear_button.pressed.connect(reset_tiles.bind([]))
	State.svg_changed.connect(update_tiles)
	visibility_changed.connect(func(): if visible and needs_update: update_tiles())
	load_tiles()
	update_tiles()


func load_tiles() -> void:
	_delete_tiles()
	scaled_preview.hide()
	for new_size in Configs.savedata.icon_view_sizes:
		icon_view_tile_container.add_child(_create_new_tile(new_size))
	update_tiles.call_deferred()


func reset_tiles(sizes: PackedInt64Array = [16, 24, 32, 48, 64]) -> void:
	_delete_tiles()
	scaled_preview.hide()
	for new_size in sizes:
		icon_view_tile_container.add_child(_create_new_tile(new_size))
	update_tiles.call_deferred()


func _add_new_tile() -> void:
	icon_view_tile_container.add_child(_create_new_tile(16))
	update_tiles.call_deferred()


func _create_new_tile(new_size: int) -> Tile:
	var tile := TileScene.instantiate()
	tile.texture_size = new_size
	tile.remove_requested.connect(func():
		if selected_tile == tile:
			selected_tile = null
			scaled_preview.hide()
		_delete_tile(tile)
		_update_savedata()
	)
	tile.selected.connect(func():
		selected_tile = tile
		texture_rect.texture = tile.texture
		scaled_preview.show()
		_update_texture_rect_size()
	)
	tile.texture_changed.connect(func():
		if selected_tile == tile:
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
	if selected_tile:
		texture_rect.texture = selected_tile.texture
		_update_texture_rect_size()


func _update_texture_rect_size() -> void:
	if not texture_rect.texture:
		scaled_preview.hide()
		return
	texture_rect.custom_minimum_size = texture_rect.texture.get_size()
	size_label.text = selected_tile.texture_size_string


func sync_theming() -> void:
	color = Color.TRANSPARENT
	border_color = ThemeUtils.subtle_panel_border_color
	title_color = ThemeUtils.basic_panel_inner_color


func _delete_tiles() -> void:
	selected_tile = null
	for child in icon_view_tile_container.get_children():
		icon_view_tile_container.remove_child(child)
		child.queue_free()


func _delete_tile(tile: Tile) -> void:
	# queue_free doesn't immediately remove the child?
	icon_view_tile_container.remove_child(tile)
	tile.queue_free()


func _update_savedata() -> void:
	var sizes: PackedInt64Array
	for child: Tile in icon_view_tile_container.get_children():
		sizes.append(child.texture_size)
	Configs.savedata.icon_view_sizes = sizes
