extends VBoxContainer

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")
const ZoomWidget = preload("res://src/ui_widgets/zoom_widget.gd")

@onready var canvas: SubViewportContainer = $ViewportPanel/VBoxContainer/Canvas
@onready var reference_button: Button = %LeftMenu/Reference
@onready var visuals_button: Button = %LeftMenu/Visuals
@onready var snapper: NumberEdit = %LeftMenu/Snapping/SnapNumberEdit
@onready var snap_button: BetterButton = %LeftMenu/Snapping/SnapButton
@onready var viewport_panel: PanelContainer = $ViewportPanel
@onready var toolbar: PanelContainer = $ViewportPanel/VBoxContainer/Toolbar
@onready var zoom_widget: ZoomWidget = %ZoomMenu

func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("view_show_grid", State.toggle_show_grid, ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	shortcuts.add_shortcut("view_show_handles", State.toggle_show_handles, ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	shortcuts.add_shortcut("view_rasterized_svg", State.toggle_view_rasterized, ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	shortcuts.add_shortcut("load_reference", FileUtils.open_image_import_dialog, ShortcutsRegistration.Behavior.PASS_THROUGH_POPUPS)
	shortcuts.add_shortcut("view_show_reference", func() -> void:
			Configs.savedata.get_active_tab().show_reference = not Configs.savedata.get_active_tab().show_reference,
			ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	shortcuts.add_shortcut("view_overlay_reference", func() -> void:
			Configs.savedata.get_active_tab().overlay_reference = not Configs.savedata.get_active_tab().overlay_reference,
			ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	shortcuts.add_shortcut("toggle_snap", func() -> void: Configs.savedata.snap *= -1, ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS)
	shortcuts.add_shortcut("debug", State.toggle_show_debug)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	zoom_widget.setup_limits(Canvas.MIN_ZOOM, Canvas.MAX_ZOOM)
	zoom_widget.zoom_in_pressed.connect(canvas.zoom_in)
	zoom_widget.zoom_out_pressed.connect(canvas.zoom_out)
	zoom_widget.zoom_reset_pressed.connect(canvas.center_frame)
	State.zoom_changed.connect(func() -> void: zoom_widget.sync_to_value(State.zoom))
	
	reference_button.pressed.connect(_on_reference_button_pressed)
	visuals_button.pressed.connect(_on_visuals_button_pressed)
	snap_button.toggled.connect(_on_snap_button_toggled)
	snapper.value_changed.connect(_on_snap_number_edit_value_changed)
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	Configs.snap_changed.connect(update_snap_config)
	update_snap_config()
	Configs.theme_changed.connect(sync_theming)
	sync_theming()


func sync_localization() -> void:
	%LeftMenu/Visuals.tooltip_text = Translator.translate("Visuals")
	%LeftMenu/Snapping/SnapNumberEdit.tooltip_text = Translator.translate("Snap size")

func sync_theming() -> void:
	var toolbar_stylebox := StyleBoxFlat.new()
	toolbar_stylebox.bg_color = ThemeUtils.soft_base_color
	toolbar_stylebox.set_content_margin_all(4)
	toolbar.add_theme_stylebox_override("panel", toolbar_stylebox)
	
	var frame := StyleBoxFlat.new()
	frame.draw_center = false
	frame.border_width_left = 2
	frame.border_width_top = 2
	frame.border_color = ThemeUtils.overlay_panel_border_color
	frame.content_margin_left = 2.0
	frame.content_margin_top = 2.0
	viewport_panel.add_theme_stylebox_override("panel", frame)

func update_snap_config() -> void:
	var snap_config := Configs.savedata.snap
	var snap_enabled := snap_config > 0.0
	snap_button.button_pressed = snap_enabled
	snapper.editable = snap_enabled
	snapper.set_value(absf(snap_config))

func _on_zoom_changed() -> void:
	zoom_widget.sync_to_value(State.zoom)

func _on_reference_button_pressed() -> void:
	var active_tab := Configs.savedata.get_active_tab()
	var has_reference := is_instance_valid(active_tab.reference_image)
	var btn_arr: Array[Button] = [
		ContextPopup.create_shortcut_button("load_reference"),
		ContextPopup.create_button(Translator.translate("Paste reference image"),
				paste_reference_image, not Utils.has_clipboard_image_web_safe(), load("res://assets/icons/Paste.svg")),
		ContextPopup.create_button(Translator.translate("Clear reference image"),
				clear_reference_image, not has_reference, load("res://assets/icons/Clear.svg")),
		ContextPopup.create_shortcut_checkbox("view_show_reference", active_tab.show_reference and has_reference, not has_reference),
		ContextPopup.create_shortcut_checkbox("view_overlay_reference", active_tab.overlay_reference and has_reference, not has_reference)
	]
	
	var reference_popup := ContextPopup.new()
	reference_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(reference_popup, reference_button.get_global_rect(), get_viewport())

func paste_reference_image() -> void:
	FileUtils.load_reference_from_image(DisplayServer.clipboard_get_image())

func clear_reference_image() -> void:
	FileUtils.load_reference_from_image(null)

func _on_visuals_button_pressed() -> void:
	var btn_arr: Array[Button] = [
		ContextPopup.create_shortcut_checkbox("view_show_grid", State.show_grid),
		ContextPopup.create_shortcut_checkbox("view_show_handles", State.show_handles),
		ContextPopup.create_shortcut_checkbox("view_rasterized_svg", State.view_rasterized)
	]
	
	var visuals_popup := ContextPopup.new()
	visuals_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(visuals_popup, visuals_button.get_global_rect(), get_viewport())


func _on_snap_button_toggled(toggled_on: bool) -> void:
	Configs.savedata.snap = absf(Configs.savedata.snap) if toggled_on else -absf(Configs.savedata.snap)

func _on_snap_number_edit_value_changed(new_value: float) -> void:
	Configs.savedata.snap = new_value * signf(Configs.savedata.snap)
