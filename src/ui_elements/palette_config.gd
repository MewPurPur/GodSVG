extends VBoxContainer

const ColorSwatch = preload("res://src/ui_elements/color_swatch.tscn")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")

signal color_picked(color: String)
signal layout_changed

var current_palette: ColorPalette
var currently_edited_idx := -1

@onready var palette_label: Label = %MainContainer/HBoxContainer/PaletteLabel
@onready var name_edit: BetterLineEdit = %MainContainer/HBoxContainer/NameEdit
@onready var name_edit_button: Button = %MainContainer/HBoxContainer/EditButton
@onready var colors_container: HFlowContainer = %MainContainer/ColorsContainer
@onready var action_button: Button = $PaletteConfig/HBoxContainer/ActionButton

@onready var color_config: PanelContainer = $ColorConfig
@onready var color_label: Label = %ColorInspector/NameContainer/HBoxContainer/NameLabel

# Used to setup a palette for this element.
func assign_palette(palette: ColorPalette) -> void:
	current_palette = palette
	rebuild_colors()

# Rebuilds the content of the colors container.
func rebuild_colors() -> void:
	for child in colors_container.get_children():
		child.queue_free()
	
	set_label_text(current_palette.title)
	if current_palette.title.is_empty():
		popup_edit_name()
	
	for i in current_palette.colors.size():
		var swatch := ColorSwatch.instantiate()
		swatch.color_palette = current_palette
		swatch.idx = i
		swatch.type = swatch.Type.CONFIGURE_COLOR
		swatch.pressed.connect(show_editing_bar.bind(i))
		colors_container.add_child(swatch)
		if i == currently_edited_idx:
			# If you add a color, after the rebuild you should instantly edit the new color.
			show_editing_bar(i)
	# Add the add button.
	var fake_swatch := ColorSwatch.instantiate()
	fake_swatch.type = fake_swatch.Type.ADD_COLOR
	fake_swatch.pressed.connect(add_color)
	colors_container.add_child(fake_swatch)


func show_editing_bar(idx: int) -> void:
	currently_edited_idx = idx
	color_config.show()

func hide_editing_bar() -> void:
	color_config.hide()

func set_color_label_text(new_text: String) -> void:
	if new_text.is_empty():
		color_label.text = tr("Unnamed")
		color_label.add_theme_color_override("font_color",
				ThemeGenerator.common_subtle_text_color)
	else:
		color_label.text = new_text
		color_label.tooltip_text = new_text
		color_label.remove_theme_color_override("font_color")


func popup_edit_name() -> void:
	palette_label.hide()
	name_edit_button.hide()
	name_edit.show()
	name_edit.text = current_palette.title
	name_edit.grab_focus()
	name_edit.caret_column = name_edit.text.length()

func hide_name_edit() -> void:
	palette_label.show()
	name_edit_button.show()
	name_edit.hide()

# Update text color to red if the title won't work (because it's a duplicate).
func _on_name_edit_text_changed(new_text: String) -> void:
	var names: Array[String] = []
	for palette in GlobalSettings.palettes:
		names.append(palette.title)
	name_edit.add_theme_color_override("font_color", GlobalSettings.get_validity_color(
			new_text in names and new_text != current_palette.title))

func _on_name_edit_text_submitted(new_title: String) -> void:
	new_title = new_title.strip_edges()
	var titles: Array[String] = []
	for palette in GlobalSettings.palettes:
		titles.append(palette.title)
	
	if not new_title.is_empty() and new_title != current_palette.title and\
	not new_title in titles:
		current_palette.title = new_title
		GlobalSettings.save_palettes()
	
	set_label_text(current_palette.title)
	hide_name_edit()

func _on_name_edit_text_change_canceled() -> void:
	hide_name_edit()

func add_color() -> void:
	current_palette.add_color()
	currently_edited_idx = current_palette.colors.size() - 1
	rebuild_colors()

func set_label_text(new_text: String) -> void:
	if new_text.is_empty():
		palette_label.text = tr("Unnamed")
		palette_label.add_theme_color_override("font_color",
				GlobalSettings.basic_color_error)
	else:
		palette_label.text = new_text
		palette_label.remove_theme_color_override("font_color")

func delete_color(color_idx: int) -> void:
	current_palette.remove_color(color_idx)
	rebuild_colors()

func move_color(old_color_idx: int, new_color_idx: int) -> void:
	if old_color_idx < new_color_idx:
		var old_color = current_palette.colors.pop_at(old_color_idx)
		var old_color_name = current_palette.color_names.pop_at(old_color_idx)
		current_palette.colors.insert(new_color_idx - 1, old_color)
		current_palette.color_names.insert(new_color_idx - 1, old_color_name)
		rebuild_colors()
	elif old_color_idx > new_color_idx + 1:
		var old_color = current_palette.colors.pop_at(old_color_idx)
		var old_color_name = current_palette.color_names.pop_at(old_color_idx)
		current_palette.colors.insert(new_color_idx, old_color)
		current_palette.color_names.insert(new_color_idx, old_color_name)
		rebuild_colors()

func delete(idx: int) -> void:
	GlobalSettings.palettes.remove_at(idx)
	GlobalSettings.save_palettes()
	layout_changed.emit()

func move_up(idx: int) -> void:
	var palette: ColorPalette = GlobalSettings.palettes.pop_at(idx)
	GlobalSettings.palettes.insert(idx - 1, palette)
	GlobalSettings.save_palettes()
	layout_changed.emit()

func move_down(idx: int) -> void:
	var palette: ColorPalette = GlobalSettings.palettes.pop_at(idx)
	GlobalSettings.palettes.insert(idx + 1, palette)
	GlobalSettings.save_palettes()
	layout_changed.emit()

func paste_palette(idx: int) -> void:
	GlobalSettings.palettes[idx] = ColorPalette.from_text(DisplayServer.clipboard_get())
	# If another palette has the same title, disable the title.
	for i in GlobalSettings.palettes.size():
		if i == idx:
			continue
		if GlobalSettings.palettes[i].title == GlobalSettings.palettes[idx].title:
			GlobalSettings.palettes[idx].title = ""
			break
	GlobalSettings.save_palettes()
	layout_changed.emit()


func _on_action_button_pressed() -> void:
	var palette_idx := -1
	for idx in GlobalSettings.palettes.size():
		if GlobalSettings.palettes[idx].title == current_palette.title:
			palette_idx = idx
	
	var btn_arr: Array[Button] = []
	
	if palette_idx >= 1:
		btn_arr.append(Utils.create_btn(tr("Move Up"), move_up.bind(palette_idx),
				false, load("res://visual/icons/MoveUp.svg")))
	if palette_idx < GlobalSettings.palettes.size() - 1:
		btn_arr.append(Utils.create_btn(tr("Move Down"), move_down.bind(palette_idx),
				false, load("res://visual/icons/MoveDown.svg")))
	btn_arr.append(Utils.create_btn(tr("Copy as XML"),
			DisplayServer.clipboard_set.bind(GlobalSettings.palettes[palette_idx].to_text()),
			false, load("res://visual/icons/Copy.svg")))
	btn_arr.append(Utils.create_btn(tr("Paste XML"), paste_palette.bind(palette_idx),
			!ColorPalette.is_valid_palette(DisplayServer.clipboard_get()),
			load("res://visual/icons/Paste.svg")))
	btn_arr.append(Utils.create_btn(tr("Delete"), delete.bind(palette_idx),
			false, load("res://visual/icons/Delete.svg")))
	
	var context_popup := ContextPopup.instantiate()
	add_child(context_popup)
	context_popup.set_button_array(btn_arr, true)
	Utils.popup_under_rect_center(context_popup, action_button.get_global_rect(),
			get_viewport())


# Drag and drop logic.
var proposed_drop_idx := -1

func is_data_named_color(data: Variant) -> bool:
	return typeof(data) == TYPE_ARRAY and data.size() == 2 and\
	typeof(data[0]) == TYPE_OBJECT and data[0] is ColorPalette and\
	typeof(data[1]) == TYPE_INT

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if is_data_named_color(data) and\
	colors_container.get_rect().grow(4).has_point(at_position):
		at_position = colors_container.get_local_mouse_position()
		var new_idx := 0
		for swatch in colors_container.get_children():
			if swatch.type != swatch.Type.CONFIGURE_COLOR or\
			swatch.get_rect().end.y >= at_position.y and\
			swatch.get_rect().get_center().x >= at_position.x:
				break
			new_idx += 1
		
		proposed_drop_idx = new_idx
		for swatch in colors_container.get_children():
			swatch.proposed_drop_idx = new_idx
		return (data[1] != new_idx and data[1] != new_idx - 1)
	else:
		proposed_drop_idx = -1
		for swatch in colors_container.get_children():
			swatch.proposed_drop_idx = -1
		return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if proposed_drop_idx != -1:
		if data[0] == current_palette:
			move_color(data[1], proposed_drop_idx)
		#else:
			#current_palette.colors.insert(proposed_drop_idx, data[0].colors[data[1]])
			#current_palette.color_names.insert(proposed_drop_idx, data[0].color_names[data[1]])
