extends VBoxContainer

const settings_menu = preload("settings_menu.tscn")
const about_menu = preload("about_menu.tscn")
const docs = preload("docs.tscn")

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")
const BetterToggleButtonType = preload("res://src/ui_elements/BetterToggleButton.gd")

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const NumberField = preload("res://src/ui_elements/number_field.tscn")

@onready var viewport: SubViewport = $ViewportPanel/ViewportContainer/Viewport
@onready var controls: Control = %Checkerboard/Controls
@onready var grid_visuals: Camera2D = $ViewportPanel/ViewportContainer/Viewport/ViewCamera
@onready var visuals_button: Button = %LeftMenu/Visuals
@onready var more_button: Button = %LeftMenu/MoreOptions
@onready var snapper: NumberEditType = %LeftMenu/Snapping/NumberEdit
@onready var snap_button: BetterToggleButtonType = %LeftMenu/Snapping/SnapButton


func _ready() -> void:
	update_snap_config()

func update_snap_config() -> void:
	var snap_config := GlobalSettings.save_data.snap
	var snap_enabled := snap_config > 0.0
	snap_button.button_pressed = snap_enabled
	snapper.editable = snap_enabled
	snapper.set_value(absf(snap_config))

func _on_settings_pressed() -> void:
	var settings_menu_instance := settings_menu.instantiate()
	HandlerGUI.add_overlay(settings_menu_instance)

func _on_visuals_button_pressed() -> void:
	var btn_arr: Array[Button] = [
		Utils.create_checkbox(tr(&"#show_grid"), toggle_grid_visuals, grid_visuals.visible),
		Utils.create_checkbox(tr(&"#show_handles"), toggle_handles_visuals,
				controls.visible),
		Utils.create_checkbox(tr(&"#rasterize_svg"), toggle_rasterization,
				viewport.display_texture.rasterized),
	]
	
	var visuals_popup := ContextPopup.instantiate()
	add_child(visuals_popup)
	visuals_popup.set_button_array(btn_arr, true)
	Utils.popup_under_rect_center(visuals_popup, visuals_button.get_global_rect(),
			get_viewport())

func _on_more_options_pressed() -> void:
	var about_btn := Utils.create_btn(tr(&"#about_button_text"), open_about, false,
			load("res://visual/icon.svg"))
	about_btn.expand_icon = true
	var buttons_arr: Array[Button] = [
		Utils.create_btn(tr(&"#repo_button_text"), open_godsvg_repo, false,
				load("res://visual/icons/Link.svg")),
		about_btn,
		Utils.create_btn(tr(&"#docs_button_text"), open_docs, false,
				load("res://visual/icons/Docs.svg")),
		Utils.create_btn(tr(&"#donate_button_text"), open_sponsor, false,
				load("res://visual/icons/Heart.svg")),
	]
	
	var more_popup := ContextPopup.instantiate()
	add_child(more_popup)
	more_popup.set_button_array(buttons_arr, true)
	Utils.popup_under_rect_center(more_popup, more_button.get_global_rect(),
			get_viewport())

func open_godsvg_repo() -> void:
	OS.shell_open("https://github.com/MewPurPur/GodSVG")

func open_about() -> void:
	var about_menu_instance := about_menu.instantiate()
	HandlerGUI.add_overlay(about_menu_instance)

func open_docs() -> void:
	var docs_instance := docs.instantiate()
	HandlerGUI.add_overlay(docs_instance)

func open_sponsor() -> void:
	OS.shell_open("https://github.com/sponsors/MewPurPur")

func toggle_grid_visuals() -> void:
	grid_visuals.visible = not grid_visuals.visible

func toggle_handles_visuals() -> void:
	controls.visible = not controls.visible

func toggle_rasterization() -> void:
	viewport.display_texture.rasterized = not viewport.display_texture.rasterized


func _on_snap_button_toggled(toggled_on: bool) -> void:
	GlobalSettings.modify_save_data(&"snap",
			absf(GlobalSettings.save_data.snap) * (1 if toggled_on else -1))
	update_snap_config()

func _on_number_edit_value_changed(new_value: float) -> void:
	GlobalSettings.modify_save_data(&"snap",
			new_value * signf(GlobalSettings.save_data.snap))
	update_snap_config()
