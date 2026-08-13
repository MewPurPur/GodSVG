extends VTitledPanel

const ColorEditWithOptions = preload("res://src/ui_widgets/color_edit_with_options.gd")
const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

const PreviewPresentationPopupScene = preload("res://src/ui_widgets/preview_presentation_popup.tscn")
const NumberEditScene = preload("res://src/ui_widgets/number_edit.tscn")

const TILE_MARGIN = 2.0
const TILE_PADDING = 4.0
const ACTION_BUTTON_SIZE = 16.0
const MAX_ICON_PREVIEW_SIZE = 128

@onready var icon_preview_tiles: ProceduralControl = %IconPreviewTiles
@onready var texture_rect: TextureRect = %TextureRect
@onready var scaled_preview_panel: PanelContainer = %ScaledPreviewPanel
@onready var size_label: Label = %SizeLabel
@onready var split_container: SplitContainer = %SplitContainer
@onready var preview_top_panel: PanelContainer = $SplitContainer/PreviewTopPanel
@onready var size_label_margins: MarginContainer = %SizeLabelMargins
@onready var add_button: Button = $ActionContainer/AddButton
@onready var presentation_config_button: Button = $ActionContainer/PresentationConfigButton
@onready var more_button: Button = $ActionContainer/MoreButton

# Computes all layout data for one preview tile.
class IconPreviewTileData extends RefCounted:
	var index := -1
	var position: Vector2
	var size: Vector2
	var preview_rect: Rect2
	var dimensions_label_pos: Vector2
	var additional_label_pos: Vector2
	var dimensions_label_width: float
	var action_button_rect: Rect2
	var bigger_dimension: int
	var dimensions_text: String
	var additional_text: String
	var preview_texture: DPITexture
	
	func _init(new_index: int) -> void:
		index = new_index
		bigger_dimension = Configs.savedata.preview_presentation_sizes[index]
		var svg_size := Vector2(State.root_element.width, State.root_element.height)
		var multiplier := bigger_dimension / maxf(svg_size.x, svg_size.y)
		svg_size *= multiplier
		var font := ThemeUtils.main_font
		
		preview_texture = DPITexture.create_from_string(State.stable_export_markup, multiplier)
		dimensions_text = "%d×%d" % [preview_texture.get_width(), preview_texture.get_height()]
		var precision := 0
		if multiplier < 1:
			precision = 3
		elif multiplier < 10:
			precision = 2
		elif multiplier < 100:
			precision = 1
		additional_text = " (%sx)" % Utils.num_simple(multiplier, precision)
		dimensions_label_width = font.get_string_size(dimensions_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var additional_text_width := font.get_string_size(additional_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var full_text_width := dimensions_label_width + additional_text_width
		var preview_size := svg_size if bigger_dimension <= MAX_ICON_PREVIEW_SIZE else svg_size * MAX_ICON_PREVIEW_SIZE / maxf(svg_size.x, svg_size.y)
		var bottom_row_width := dimensions_label_width + maxf(additional_text_width, ACTION_BUTTON_SIZE)
		
		# The position needs to be set when all sizes are known, so only size is set here.
		size = Vector2(maxf(preview_size.x, bottom_row_width) + TILE_PADDING * 2, preview_size.y + 18 + TILE_PADDING * 2)
		
		# Wide previews keep the text centered beneath them, while narrow previews are centered over the label row.
		if preview_size.x >= bottom_row_width:
			preview_rect = Rect2(Vector2(TILE_PADDING, TILE_PADDING), preview_size)
			dimensions_label_pos = Vector2(TILE_PADDING + roundf((preview_size.x - full_text_width) / 2.0) + 2, TILE_PADDING + preview_size.y)
		else:
			preview_rect = Rect2(Vector2(TILE_PADDING, TILE_PADDING) + Vector2(roundf((bottom_row_width - preview_size.x) / 2.0), 0), preview_size)
			dimensions_label_pos = Vector2(TILE_PADDING + 2, TILE_PADDING + preview_size.y)
		additional_label_pos = dimensions_label_pos + Vector2(dimensions_label_width, 0)
		action_button_rect = Rect2(Vector2(additional_label_pos.x + (additional_text_width - ACTION_BUTTON_SIZE) / 2, additional_label_pos.y + 2),
				Vector2(ACTION_BUTTON_SIZE, ACTION_BUTTON_SIZE))
		

var tiles: Array[IconPreviewTileData] = []
var hovered_tile_index := -1
var selected_tile_index := -1
var edited_tile_index := -1
var edit_field: NumberEdit

var presentation_config_button_ci := RenderingServer.canvas_item_create()

func _ready() -> void:
	icon_preview_tiles.draw.connect(_on_preview_tiles_draw)
	icon_preview_tiles.gui_input.connect(_on_tiles_gui_input)
	icon_preview_tiles.mouse_exited.connect(_on_tiles_mouse_exited)
	more_button.pressed.connect(_on_more_button_pressed)
	
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	
	add_button.pressed.connect(_add_new_tile)
	
	RenderingServer.canvas_item_set_parent(presentation_config_button_ci, presentation_config_button.get_canvas_item())
	presentation_config_button.pressed.connect(_on_presentation_config_button_pressed)
	presentation_config_button.draw.connect(
		func() -> void:
			Configs.savedata.preview_presentation.draw_on_button(presentation_config_button, presentation_config_button_ci)
	)
	
	State.svg_changed.connect(sync_tiles)
	ThemeUtils.main_font.changed.connect(sync_tiles)
	visibility_changed.connect(
		func() -> void:
			if visible:
				sync_tiles()
	)
	split_container.resized.connect(
		func() -> void:
			split_container.vertical = (split_container.size.y * 2.0 > split_container.size.x)
			sync_preview_top_panel_expand_margins()
			sync_tile_positions()
	)
	icon_preview_tiles.resized.connect(sync_tile_positions)
	sync_tiles()
	_sync_preview_background()
	HandlerGUI.register_focus_sequence(self, [add_button, presentation_config_button, more_button])

func sync_theming() -> void:
	preview_top_panel.add_theme_stylebox_override("panel", get_theme_stylebox("tabbar_background", "TabContainer"))
	sync_preview_top_panel_expand_margins()
	color = Color.TRANSPARENT
	border_color = ThemeUtils.subtle_panel_border_color
	title_color = ThemeUtils.basic_panel_inner_color

func sync_localization() -> void:
	add_button.text = Translator.translate("Add preview")

func _exit_tree() -> void:
	RenderingServer.free_rid(presentation_config_button_ci)


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
	for i in Configs.savedata.preview_presentation_sizes.size():
		tiles.append(IconPreviewTileData.new(i))
	icon_preview_tiles.queue_redraw()
	sync_tile_positions()
	_sync_texture()

# Reflow tiles into centered rows whenever the panel resizes or the tile set changes.
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
	_sync_buttons()
	set_hovered_to_pos(icon_preview_tiles.get_local_mouse_position())
	icon_preview_tiles.queue_redraw()


func _on_preview_tiles_draw() -> void:
	var font := ThemeUtils.main_font
	var font_size := get_theme_font_size("font_size", "Label")
	
	for tile in tiles:
		var stylebox: StyleBox
		if tile.index == selected_tile_index:
			stylebox = get_theme_stylebox("hover_pressed" if tile.index == hovered_tile_index else "pressed", "Button")
		else:
			stylebox = get_theme_stylebox("hover" if tile.index == hovered_tile_index else "normal", "Button")
		stylebox.draw(icon_preview_tiles.ci, Rect2(tile.position, tile.size))
		
		if tile.preview_texture:
			tile.preview_texture.draw_rect(icon_preview_tiles.ci, Rect2(tile.position + tile.preview_rect.position, tile.preview_rect.size), false)
		
		font.draw_string(icon_preview_tiles.ci, tile.position + tile.dimensions_label_pos + Vector2(0, 14),
				tile.dimensions_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ThemeUtils.text_color)
		if tile.index != selected_tile_index:
			font.draw_string(icon_preview_tiles.ci, tile.position + tile.additional_label_pos + Vector2(0, 14),
					tile.additional_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ThemeUtils.dimmer_text_color)


func _on_tiles_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	set_hovered_to_pos(event.position)
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_tile(hovered_tile_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if hovered_tile_index >= 0:
				for tile in tiles:
					if Rect2(tile.position, tile.size).has_point(event.position):
						_show_tile_popup_at_pos(tile, event.global_position)
						break
			else:
				var btn_array: Array[ContextButton] = [
					ContextButton.create_custom(Translator.translate("Add preview"), _add_new_tile, preload("res://assets/icons/Plus.svg"))
				]
				var vp := get_viewport()
				HandlerGUI.popup_under_pos(ContextPopup.create(btn_array), vp.get_mouse_position(), vp)

func _on_tiles_mouse_exited() -> void:
	hovered_tile_index = -1
	icon_preview_tiles.queue_redraw()

func set_hovered_to_pos(pos: Vector2) -> void:
	var old_hovered_index := hovered_tile_index
	hovered_tile_index = -1
	for tile in tiles:
		if Rect2(tile.position, tile.size).has_point(pos):
			hovered_tile_index = tile.index
			break
	if old_hovered_index != hovered_tile_index:
		icon_preview_tiles.queue_redraw()

func _select_tile(tile_index: int) -> void:
	if tile_index == selected_tile_index:
		return
	selected_tile_index = tile_index
	
	if tile_index < 0:
		icon_preview_tiles.buttons.clear()
		preview_top_panel.visible = false
		return
	preview_top_panel.visible = true
	
	_sync_texture()
	_sync_buttons()

func _sync_buttons() -> void:
	if selected_tile_index < 0:
		return
	var tile := tiles[selected_tile_index]
	icon_preview_tiles.buttons.clear()
	icon_preview_tiles.buttons.append.call_deferred(ProceduralControl.ButtonData.create_from_icon(
			Rect2(tile.position + tile.action_button_rect.position, tile.action_button_rect.size), _show_tile_popup_under_more_button.bind(tile),
			preload("res://assets/icons/SmallMore.svg")))
	icon_preview_tiles.queue_redraw.call_deferred()

func _sync_texture() -> void:
	if selected_tile_index < 0:
		return
	
	var tile := tiles[selected_tile_index]
	size_label.text = tile.dimensions_text + tile.additional_text
	
	texture_rect.texture = Configs.savedata.preview_presentation.generate_texture(
			Configs.savedata.preview_presentation_sizes[selected_tile_index] / maxf(State.root_element.width, State.root_element.height))


func _generate_tile_popup(tile: IconPreviewTileData) -> ContextPopup:
	var btn_arr: Array[ContextButton] = [
		ContextButton.create_custom(Translator.translate("Edit"), _edit_tile_size.bind(tile), preload("res://assets/icons/Edit.svg")),
		ContextButton.create_custom(Translator.translate("Delete"), _delete_tile.bind(tile), preload("res://assets/icons/Delete.svg")),
	]
	return ContextPopup.create(btn_arr, true)

func _show_tile_popup_at_pos(tile: IconPreviewTileData, pos: Vector2) -> void:
	HandlerGUI.popup_under_pos(_generate_tile_popup(tile), pos, get_viewport())

func _show_tile_popup_under_more_button(tile: IconPreviewTileData) -> void:
	HandlerGUI.popup_under_rect_center(_generate_tile_popup(tile),
			Rect2(icon_preview_tiles.global_position + tile.position + tile.action_button_rect.position, tile.action_button_rect.size), get_viewport())


func _edit_tile_size(tile: IconPreviewTileData) -> void:
	edited_tile_index = tile.index
	
	edit_field = NumberEditScene.instantiate()
	edit_field.initial_value = tile.bigger_dimension
	edit_field.min_value = 1.0
	edit_field.max_value = 16384.0
	edit_field.is_float = false
	icon_preview_tiles.add_child(edit_field)
	edit_field.text = String.num_uint64(tile.bigger_dimension)
	edit_field.position = icon_preview_tiles.position + tile.position + tile.dimensions_label_pos - Vector2(5, 4)
	edit_field.size = Vector2(tile.dimensions_label_width + 1, 0)
	edit_field.add_theme_font_override("font", ThemeUtils.main_font)
	edit_field.editing_toggled.connect(_on_edit_field_editing_toggled)
	edit_field.value_changed.connect(_on_edit_field_value_changed)
	edit_field.grab_focus()
	edit_field.select_all()

func _on_edit_field_value_changed(new_value: float) -> void:
	var sizes := Configs.savedata.preview_presentation_sizes.duplicate()
	sizes[edited_tile_index] = roundi(new_value)
	Configs.savedata.preview_presentation_sizes = sizes
	sync_tiles()
	if edited_tile_index == selected_tile_index:
		_select_tile(edited_tile_index)

func _on_edit_field_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		edit_field.queue_free()

func _delete_tile(tile: IconPreviewTileData) -> void:
	var sizes := Configs.savedata.preview_presentation_sizes.duplicate()
	if tile.index >= 0 and tile.index <= Configs.savedata.preview_presentation_sizes.size() - 1:
		sizes.remove_at(tile.index)
		Configs.savedata.preview_presentation_sizes = sizes
		_select_tile(-1)
		sync_tiles()

func are_tiles_default() -> bool:
	return Configs.savedata.preview_presentation_sizes == SaveData.DEFAULT_PREVIEW_SIZES

func are_tiles_sorted() -> bool:
	var sorted_array := Configs.savedata.preview_presentation_sizes.duplicate()
	sorted_array.sort()
	return Configs.savedata.preview_presentation_sizes == sorted_array

func sort_tiles() -> void:
	_select_tile(-1)
	Configs.savedata.preview_presentation_sizes.sort()
	sync_tiles()

func reset_tiles() -> void:
	_select_tile(-1)
	Configs.savedata.preview_presentation_sizes = SaveData.DEFAULT_PREVIEW_SIZES.duplicate()
	sync_tiles()

func clear_all_tiles() -> void:
	_select_tile(-1)
	Configs.savedata.preview_presentation_sizes = PackedInt32Array()
	sync_tiles()

func _add_new_tile() -> void:
	var old_icon_sizes := Configs.savedata.preview_presentation_sizes.duplicate()
	old_icon_sizes.append(16)
	Configs.savedata.preview_presentation_sizes = old_icon_sizes
	sync_tiles()

func _sync_preview_background() -> void:
	sync_tiles()
	if Configs.savedata.preview_presentation.background_color.a == 0.0:
		scaled_preview_panel.remove_theme_stylebox_override("panel")
	else:
		var colored_sb := StyleBoxFlat.new()
		colored_sb.bg_color = Configs.savedata.preview_presentation.background_color
		scaled_preview_panel.add_theme_stylebox_override("panel", colored_sb)


func _on_presentation_config_button_pressed() -> void:
	var preview_presentation_popup := PreviewPresentationPopupScene.instantiate()
	preview_presentation_popup.presentation_changed.connect(_sync_texture)
	preview_presentation_popup.presentation_changed.connect(_sync_preview_background)
	preview_presentation_popup.presentation_changed.connect(presentation_config_button.queue_redraw)
	HandlerGUI.popup_under_rect_center(preview_presentation_popup, presentation_config_button.get_global_rect(), get_viewport())

func _on_more_button_pressed() -> void:
	var btn_array: Array[ContextButton] = [
		ContextButton.create_custom(Translator.translate("Reset to default"), reset_tiles,
				preload("res://assets/icons/Reload.svg"), are_tiles_default()),
		ContextButton.create_custom(Translator.translate("Clear all"), clear_all_tiles,
				preload("res://assets/icons/Clear.svg"), Configs.savedata.preview_presentation_sizes.is_empty()),
		ContextButton.create_custom(Translator.translate("Sort"), sort_tiles,
				preload("res://assets/icons/Sort.svg"), are_tiles_sorted()),
	]
	HandlerGUI.popup_under_rect_center(ContextPopup.create(btn_array), more_button.get_global_rect(), get_viewport())
