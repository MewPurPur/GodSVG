extends VTitledPanel

const ColorSwatch = preload("res://src/ui_widgets/color_swatch.gd")
const ColorEdit = preload("res://src/ui_widgets/color_edit.gd")
const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

const NumberEditScene = preload("res://src/ui_widgets/number_edit.tscn")

const more_icon = preload("res://assets/icons/SmallMore.svg")
const edit_icon = preload("res://assets/icons/Edit.svg")
const delete_icon = preload("res://assets/icons/Delete.svg")
const plus_icon = preload("res://assets/icons/Plus.svg")

const TILE_MARGIN = 2.0
const TILE_TOP_PADDING = 4.0
const TILE_LEFT_PADDING = 4.0
const TILE_RIGHT_PADDING = 4.0
const TILE_BOTTOM_PADDING = 2.0
const ICON_TEXT_SPACING = 4.0
const MORE_ICON_SIZE = 16.0
const MAX_ICON_PREVIEW_SIZE = 128

@onready var icon_preview_tiles: ProceduralControl = %IconPreviewTiles
@onready var add_new_preview_button: Button = %AddNewPreviewButton
@onready var texture_rect: TextureRect = %TextureRect
@onready var scaled_preview_panel: PanelContainer = %ScaledPreviewPanel
@onready var size_label: Label = %SizeLabel
@onready var split_container: SplitContainer = %SplitContainer
@onready var transparent_color_swatch: ColorSwatch = %TransparentColorSwatch
@onready var black_color_swatch: ColorSwatch = %BlackColorSwatch
@onready var white_color_swatch: ColorSwatch = %WhiteColorSwatch
@onready var color_edit: ColorEdit = %ColorEdit
@onready var preview_top_panel: PanelContainer = $SplitContainer/PreviewTopPanel
@onready var more_button: Button = $ActionContainer/MoreButton
@onready var size_label_margins: MarginContainer = %SizeLabelMargins
@onready var precise_path_mode_dropdown: Control = %PrecisePathModeDropdown
@onready var precise_path_mode_container: HBoxContainer = %PrecisePathModeContainer

class IconPreviewTileData extends RefCounted:
	var index := -1
	var position: Vector2
	var size: Vector2
	var preview_rect: Rect2
	var label_rect: Rect2
	var more_button_rect: Rect2
	var bigger_dimension: int
	var label_text: String
	var preview_texture: Texture2D
	
	func _init(new_index: int) -> void:
		index = new_index
		bigger_dimension = Configs.savedata.preview_sizes[index]
		var svg_size := State.root_element.get_size()
		var multiplier := bigger_dimension / maxf(svg_size.x, svg_size.y)
		svg_size *= multiplier
		
		label_text = "%d×%d (%sx)" % [int(svg_size.x), int(svg_size.y), Utils.num_simple(multiplier, 1 if multiplier > 10 else 2)]
		var label_size := ThemeUtils.main_font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		var preview_size := svg_size if bigger_dimension <= MAX_ICON_PREVIEW_SIZE else svg_size * MAX_ICON_PREVIEW_SIZE / maxf(svg_size.x, svg_size.y)
		var bottom_row_size := label_size.x + MORE_ICON_SIZE
		
		# The position needs to be set when all sizes are known, so only size is set here.
		size = Vector2(maxf(preview_size.x, bottom_row_size) + TILE_LEFT_PADDING + TILE_RIGHT_PADDING,
				preview_size.y + label_size.y + TILE_TOP_PADDING + TILE_BOTTOM_PADDING + ICON_TEXT_SPACING)
		
		if preview_size.x >= bottom_row_size:
			preview_rect = Rect2(Vector2(TILE_TOP_PADDING, TILE_LEFT_PADDING), preview_size)
			var half_offset := roundf((preview_size.x - label_size.x - MORE_ICON_SIZE - 1) / 2.0)
			label_rect = Rect2(Vector2(TILE_TOP_PADDING + half_offset, TILE_LEFT_PADDING + preview_size.y + ICON_TEXT_SPACING), label_size - Vector2(1, 0))
			more_button_rect = Rect2(Vector2(TILE_TOP_PADDING + label_size.x + half_offset, label_rect.position.y + 2), Vector2(MORE_ICON_SIZE, MORE_ICON_SIZE))
		else:
			preview_rect = Rect2(Vector2(TILE_TOP_PADDING, TILE_LEFT_PADDING) + Vector2(roundf((bottom_row_size - preview_size.x) / 2.0), 0), preview_size)
			label_rect = Rect2(Vector2(TILE_TOP_PADDING + 1, TILE_LEFT_PADDING + preview_size.y + ICON_TEXT_SPACING), label_size - Vector2(1, 0))
			more_button_rect = Rect2(Vector2(TILE_TOP_PADDING + label_size.x, label_rect.position.y + 2), Vector2(MORE_ICON_SIZE, MORE_ICON_SIZE))
		
		if Configs.savedata.previews_use_pebble_preview:
			var svg := SVGParser.markup_to_root(State.stable_export_markup).svg
			if svg != null:
				var pdc := PDCImage.new()
				pdc.precise_path_mode = Configs.savedata.previews_precise_path_mode
				# Convert the SVG to PDCImage then back to SVG for accurate display
				pdc.load_from_svg(svg)
				var buffer := pdc.encode()
				var decoded_pdc := PDCImage.new()
				decoded_pdc.load_from_pdc(buffer)
				preview_texture = DPITexture.create_from_string(decoded_pdc.to_svg(), multiplier)
		else:
			preview_texture = DPITexture.create_from_string(State.stable_export_markup, multiplier)

var tiles: Array[IconPreviewTileData] = []
var hovered_tile_index := -1
var selected_tile_index := -1
var edited_tile_index := -1
var edit_field: NumberEdit

func _ready() -> void:
	%PrecisePathModeContainer/Label.text = Translator.translate("Precise") + ":"
	icon_preview_tiles.draw.connect(_on_preview_tiles_draw)
	icon_preview_tiles.gui_input.connect(_on_tiles_gui_input)
	icon_preview_tiles.mouse_exited.connect(_on_tiles_mouse_exited)
	more_button.pressed.connect(_on_more_button_pressed)
	
	transparent_color_swatch.color = "none"
	transparent_color_swatch.pressed.connect(func(): color_edit.value = "#fff0")
	black_color_swatch.color = "#000"
	black_color_swatch.pressed.connect(func(): color_edit.value = "#000")
	white_color_swatch.color = "#fff"
	white_color_swatch.pressed.connect(func(): color_edit.value = "#fff")
	
	color_edit.value_changed.connect(_update_preview_background)
	color_edit.value = Configs.savedata.previews_background.to_html()
	
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	
	add_new_preview_button.tooltip_text = Translator.translate("Add new preview")
	add_new_preview_button.pressed.connect(_add_new_tile)
	
	State.svg_changed.connect(sync_tiles)
	visibility_changed.connect(
		func() -> void:
			if visible:
				sync_tiles()
	)
	split_container.resized.connect(
		func():
			split_container.vertical = (split_container.size.y * 2.0 > split_container.size.x)
			sync_preview_top_panel_expand_margins()
			sync_tile_positions()
	)
	icon_preview_tiles.resized.connect(sync_tile_positions)
	
	if Configs.savedata.previews_use_pebble_preview:
		_toggle_use_pebble_preview()
		_toggle_use_pebble_preview()
	else:
		_toggle_use_pebble_preview()
	precise_path_mode_dropdown.set_value(Configs.savedata.previews_precise_path_mode, 0)
	precise_path_mode_dropdown.value_changed.connect(_on_precise_path_mode_dropdown_value_changed)
	
	sync_tiles()
	HandlerGUI.register_focus_sequence(self, [add_new_preview_button,
			transparent_color_swatch, black_color_swatch, white_color_swatch, color_edit, more_button])


func sync_theming() -> void:
	preview_top_panel.add_theme_stylebox_override("panel", get_theme_stylebox("tabbar_background", "TabContainer"))
	sync_preview_top_panel_expand_margins()
	color = Color.TRANSPARENT
	border_color = ThemeUtils.subtle_panel_border_color
	title_color = ThemeUtils.basic_panel_inner_color

func sync_preview_top_panel_expand_margins() -> void:
	var stylebox := preview_top_panel.get_theme_stylebox("panel").duplicate()
	if split_container.vertical:
		stylebox.expand_margin_top = 8.0
		stylebox.expand_margin_left = 0.0
	else:
		stylebox.expand_margin_top = 0.0
		stylebox.expand_margin_left = 8.0
	preview_top_panel.add_theme_stylebox_override("panel", stylebox)
	size_label_margins.add_theme_constant_override("margin_top", -3 if split_container.vertical else 1)

func sync_tiles() -> void:
	tiles.clear()
	for i in Configs.savedata.preview_sizes.size():
		tiles.append(IconPreviewTileData.new(i))
	icon_preview_tiles.queue_redraw()
	sync_tile_positions()
	_sync_texture()

func sync_tile_positions() -> void:
	var current_x := TILE_MARGIN
	var current_y := TILE_MARGIN
	var row_height := 0.0
	var row_start_index := 0
	
	for index in tiles.size():
		var tile := tiles[index]
		var tile_needed_width := tile.size.x + TILE_MARGIN * 2.0
		
		if current_x + tile_needed_width > icon_preview_tiles.size.x and index > row_start_index:
			# Finalize current row by centering horizontally and aligning vertically.
			var row_width := current_x - TILE_MARGIN
			var offset_x := roundf((icon_preview_tiles.size.x - row_width) / 2.0)
			for i in range(row_start_index, index):
				tiles[i].position.x += offset_x
				tiles[i].position.y = current_y + (row_height - tiles[i].size.y) / 2.0
			
			# Start new row.
			current_y += row_height + TILE_MARGIN * 2.0
			current_x = TILE_MARGIN
			row_height = 0.0
			row_start_index = index
		
		# Add tile to current row.
		tile.position.x = current_x
		current_x += tile.size.x + TILE_MARGIN * 2.0
		row_height = maxf(row_height, tile.size.y)
	
	# Finalize last row.
	if row_start_index < tiles.size():
		var row_width := current_x - TILE_MARGIN
		var offset_x := (icon_preview_tiles.size.x - row_width) / 2.0
		for i in range(row_start_index, tiles.size()):
			tiles[i].position.x += offset_x
			tiles[i].position.y = current_y + (row_height - tiles[i].size.y) / 2.0
	
	icon_preview_tiles.custom_minimum_size.y = current_y + row_height + TILE_MARGIN
	icon_preview_tiles.queue_redraw()
	
	icon_preview_tiles.buttons.clear()
	for tile in tiles:
		icon_preview_tiles.buttons.append(ProceduralControl.ButtonData.create_from_icon(
				Rect2(tile.position + tile.more_button_rect.position, tile.more_button_rect.size), _show_tile_popup_under_more_button.bind(tile), more_icon))


func _on_preview_tiles_draw() -> void:
	var font := ThemeUtils.main_font
	var font_size := get_theme_font_size("font_size", "Label")
	
	for tile in tiles:
		var stylebox: StyleBox
		if tile.index == selected_tile_index:
			stylebox = get_theme_stylebox("pressed", "Button")
		elif tile.index == hovered_tile_index:
			stylebox = get_theme_stylebox("hover", "Button")
		else:
			stylebox = get_theme_stylebox("normal", "Button")
		
		stylebox.draw(icon_preview_tiles.ci, Rect2(tile.position, tile.size))
		
		if tile.preview_texture:
			tile.preview_texture.draw_rect(icon_preview_tiles.ci, Rect2(tile.position + tile.preview_rect.position, tile.preview_rect.size), false)
		
		font.draw_string(icon_preview_tiles.ci, tile.position + tile.label_rect.position + Vector2(0, 14),
				tile.label_text, HORIZONTAL_ALIGNMENT_LEFT, tile.label_rect.size.x, font_size, ThemeUtils.text_color)


func _on_tiles_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var old_hovered_index := hovered_tile_index
		hovered_tile_index = -1
		
		for tile in tiles:
			if Rect2(tile.position, tile.size).has_point(event.position):
				hovered_tile_index = tile.index
				break
		
		if old_hovered_index != hovered_tile_index:
			icon_preview_tiles.queue_redraw()
	
	elif event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
				_select_tile(hovered_tile_index)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				if hovered_tile_index >= 0:
					for tile in tiles:
						if Rect2(tile.position, tile.size).has_point(event.position):
							_show_tile_popup_at_pos(tile, event.global_position)
							break
				else:
					var btn_array: Array[ContextButton] = [ContextButton.create_custom(Translator.translate("Add new preview"), _add_new_tile, plus_icon)]
					var vp := get_viewport()
					HandlerGUI.popup_under_pos(ContextPopup.create(btn_array), vp.get_mouse_position(), vp)


func _on_tiles_mouse_exited() -> void:
	hovered_tile_index = -1
	icon_preview_tiles.queue_redraw()

func _select_tile(tile_index: int) -> void:
	selected_tile_index = tile_index
	size_label.text = tiles[tile_index].label_text if tile_index >= 0 else ""
	preview_top_panel.visible = (tile_index >= 0)
	_sync_texture()
	icon_preview_tiles.queue_redraw()

func _sync_texture() -> void:
	if selected_tile_index >= 0:
		texture_rect.texture = tiles[selected_tile_index].preview_texture


func _generate_tile_popup(tile: IconPreviewTileData) -> ContextPopup:
	var btn_arr: Array[ContextButton] = [
		ContextButton.create_custom(Translator.translate("Edit"), _edit_tile_size.bind(tile), edit_icon),
		ContextButton.create_custom(Translator.translate("Delete"), _delete_tile.bind(tile), delete_icon),
	]
	return ContextPopup.create(btn_arr, true)

func _show_tile_popup_at_pos(tile: IconPreviewTileData, pos: Vector2) -> void:
	HandlerGUI.popup_under_pos(_generate_tile_popup(tile), pos, get_viewport())

func _show_tile_popup_under_more_button(tile: IconPreviewTileData) -> void:
	HandlerGUI.popup_under_rect_center(_generate_tile_popup(tile),
			Rect2(icon_preview_tiles.global_position + tile.position + tile.more_button_rect.position, tile.more_button_rect.size), get_viewport())


func _edit_tile_size(tile: IconPreviewTileData) -> void:
	edited_tile_index = tile.index
	
	edit_field = NumberEditScene.instantiate()
	edit_field.initial_value = tile.bigger_dimension
	edit_field.min_value = 1.0
	edit_field.max_value = 16384.0
	edit_field.is_float = false
	icon_preview_tiles.add_child(edit_field)
	edit_field.text = String.num_uint64(tile.bigger_dimension)
	edit_field.position = icon_preview_tiles.position + tile.position + tile.label_rect.position - Vector2(3, 4)
	edit_field.size = tile.label_rect.size
	edit_field.add_theme_font_override("font", ThemeUtils.main_font)
	edit_field.focus_exited.connect(edit_field.queue_free)
	edit_field.value_changed.connect(_on_edit_field_value_changed)
	edit_field.grab_focus()
	edit_field.select_all()

func _on_edit_field_value_changed(new_value: float) -> void:
	var sizes := Configs.savedata.preview_sizes.duplicate()
	sizes[edited_tile_index] = roundi(new_value)
	Configs.savedata.preview_sizes = sizes
	sync_tiles()
	if edited_tile_index == selected_tile_index:
		_select_tile(edited_tile_index)

func _delete_tile(tile: IconPreviewTileData) -> void:
	var sizes := Configs.savedata.preview_sizes.duplicate()
	if tile.index >= 0 and tile.index <= Configs.savedata.preview_sizes.size() - 1:
		sizes.remove_at(tile.index)
		Configs.savedata.preview_sizes = sizes
		selected_tile_index = -1
		sync_tiles()

func are_tiles_default() -> bool:
	return Configs.savedata.preview_sizes == SaveData.DEFAULT_PREVIEW_SIZES

func are_tiles_sorted() -> bool:
	var sorted_array := Configs.savedata.preview_sizes.duplicate()
	sorted_array.sort()
	return Configs.savedata.preview_sizes == sorted_array

func sort_tiles() -> void:
	_select_tile(-1)
	Configs.savedata.preview_sizes.sort()
	sync_tiles()

func reset_tiles() -> void:
	_select_tile(-1)
	Configs.savedata.preview_sizes = SaveData.DEFAULT_PREVIEW_SIZES.duplicate()
	sync_tiles()

func clear_all_tiles() -> void:
	_select_tile(-1)
	Configs.savedata.preview_sizes = PackedInt32Array()
	sync_tiles()

func _add_new_tile() -> void:
	var old_icon_sizes := Configs.savedata.preview_sizes.duplicate()
	old_icon_sizes.append(16)
	Configs.savedata.preview_sizes = old_icon_sizes
	sync_tiles()

func _update_preview_background(new_value: String) -> void:
	Configs.savedata.previews_background = ColorParser.text_to_color(new_value, Color.BLACK, true)
	sync_tiles()
	if Configs.savedata.previews_background == Color.TRANSPARENT:
		scaled_preview_panel.remove_theme_stylebox_override("panel")
	else:
		var colored_sb := StyleBoxFlat.new()
		colored_sb.bg_color = Configs.savedata.previews_background
		scaled_preview_panel.add_theme_stylebox_override("panel", colored_sb)


func _toggle_use_pebble_preview() -> void:
	Configs.savedata.previews_use_pebble_preview = not Configs.savedata.previews_use_pebble_preview
	precise_path_mode_container.visible = Configs.savedata.previews_use_pebble_preview
	sync_tiles()


func _on_more_button_pressed() -> void:
	var pebble_preview_checkbox := ContextButton.create_custom_checkbox(Translator.translate("Preview as PDC"),
		_toggle_use_pebble_preview, Configs.savedata.previews_use_pebble_preview)
	pebble_preview_checkbox.auto_toggle = true
	pebble_preview_checkbox.theme_type = "PebbleCheckBox"
	var btn_array: Array[ContextButton] = [
		ContextButton.create_custom(Translator.translate("Reset to default"), reset_tiles,
				preload("res://assets/icons/Reload.svg"), are_tiles_default()),
		ContextButton.create_custom(Translator.translate("Clear all"), clear_all_tiles,
				preload("res://assets/icons/Clear.svg"), Configs.savedata.preview_sizes.is_empty()),
		ContextButton.create_custom(Translator.translate("Sort"), sort_tiles,
				preload("res://assets/icons/Sort.svg"), are_tiles_sorted()),
		 pebble_preview_checkbox,
	]
	HandlerGUI.popup_under_rect_center(ContextPopup.create(btn_array), more_button.get_global_rect(), get_viewport())

func _on_precise_path_mode_dropdown_value_changed(new_precise_path_mode: PDCImage.PrecisePathMode) -> void:
	Configs.savedata.previews_precise_path_mode = new_precise_path_mode
	sync_tiles()
