extends VTitledPanel


const Tile = preload("res://src/ui_widgets/icon_view_tile.gd")
const TileScene = preload("res://src/ui_widgets/icon_view_tile.tscn")
const ColorSwatch = preload("res://src/ui_widgets/color_swatch.gd")
const ColorEdit = preload("res://src/ui_widgets/color_edit.gd")


@onready var icon_view_tile_container: Control = %IconViewTileContainer
@onready var add_new_size_button: Button = %AddNewSizeButton
@onready var reset_button: Button = %ResetButton
@onready var texture_rect: TextureRect = %TextureRect
@onready var scaled_preview: Control = %ScaledPreview
@onready var scaled_preview_panel: PanelContainer = %ScaledPreviewPanel
@onready var clear_button: Button = %ClearButton
@onready var size_label: Label = %SizeLabel
@onready var split_container: SplitContainer = %SplitContainer
@onready var transparent_color_swatch: ColorSwatch = %TransparentColorSwatch
@onready var black_color_swatch: ColorSwatch = %BlackColorSwatch
@onready var white_color_swatch: ColorSwatch = %WhiteColorSwatch
@onready var color_edit: ColorEdit = %ColorEdit


var needs_update := false
var selected_tile: Tile = null


func _ready() -> void:
	transparent_color_swatch.color = "currentColor"
	transparent_color_swatch.current_color = Color.TRANSPARENT
	black_color_swatch.color = "currentColor"
	black_color_swatch.current_color = Color.BLACK
	white_color_swatch.color = "currentColor"
	white_color_swatch.current_color = Color.WHITE
	for swatch: ColorSwatch in [transparent_color_swatch, black_color_swatch, white_color_swatch]:
		swatch.pressed.connect(func(): color_edit.value = swatch.current_color.to_html())
	color_edit.value_changed.connect(_update_preview_bg)
	color_edit.value = Configs.savedata.icon_view_bg_override.to_html()
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	reset_button.pressed.connect(reset_tiles)
	add_new_size_button.pressed.connect(_add_new_tile)
	clear_button.pressed.connect(reset_tiles.bind([]))
	State.svg_changed.connect(update_tiles)
	visibility_changed.connect(func(): if visible and needs_update: update_tiles())
	split_container.resized.connect(func(): split_container.vertical = split_container.size.y * 2.0 > split_container.size.x)
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
	texture_rect.size_flags_stretch_ratio = float(texture_rect.texture.get_width()) / float(texture_rect.texture.get_height())
	#texture_rect.custom_minimum_size.x = texture_rect.size.y * float(texture_rect.texture.get_width()) / float(texture_rect.texture.get_height())
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


var colored_sb := StyleBoxFlat.new()
func _update_preview_bg(new_value: String) -> void:
	var new_color := Color.html(new_value)
	if new_color == Color.TRANSPARENT:
		scaled_preview_panel.remove_theme_stylebox_override("panel")
	else:
		colored_sb.bg_color = new_color
		scaled_preview_panel.add_theme_stylebox_override("panel", colored_sb)
	Configs.savedata.icon_view_bg_override = new_color
