extends VBoxContainer

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

@onready var viewport: SubViewport = %Viewport
@onready var reference_texture: TextureRect = %Viewport/ReferenceTexture
@onready var reference_button: Button = %LeftMenu/Reference
@onready var visuals_button: Button = %LeftMenu/Visuals
@onready var snapper: NumberEdit = %LeftMenu/Snapping/SnapNumberEdit
@onready var snap_button: BetterButton = %LeftMenu/Snapping/SnapButton
@onready var viewport_panel: PanelContainer = $ViewportPanel
@onready var debug_container: MarginContainer = $ViewportPanel/DebugMargins
@onready var debug_label: Label = %DebugContainer/DebugLabel
@onready var input_debug_label: Label = %DebugContainer/InputDebugLabel
@onready var toolbar: PanelContainer = $ViewportPanel/VBoxContainer/Toolbar

var reference_overlay := false

func _ready() -> void:
	Configs.language_changed.connect(update_translations)
	Configs.snap_changed.connect(update_snap_config)
	Configs.theme_changed.connect(update_theme)
	Configs.active_tab_changed.connect(sync_reference_image)
	Configs.active_tab_reference_changed.connect(sync_reference_image)
	sync_reference_image()
	State.show_reference_changed.connect(_on_show_reference_updated)
	_on_show_reference_updated()
	State.overlay_reference_changed.connect(_on_overlay_reference_updated)
	_on_overlay_reference_updated()
	State.show_debug_changed.connect(_on_show_debug_changed)
	_on_show_debug_changed()
	update_translations()
	update_theme()
	update_snap_config()
	get_window().window_input.connect(_update_input_debug)


func update_translations() -> void:
	%LeftMenu/Visuals.tooltip_text = Translator.translate("Visuals")
	%LeftMenu/Snapping/SnapNumberEdit.tooltip_text = Translator.translate("Snap size")

func update_theme() -> void:
	var toolbar_stylebox := StyleBoxFlat.new()
	toolbar_stylebox.bg_color = ThemeUtils.overlay_panel_inner_color.lerp(Color.WHITE, 0.01)
	toolbar_stylebox.set_content_margin_all(4)
	toolbar.add_theme_stylebox_override("panel", toolbar_stylebox)
	
	var frame := StyleBoxFlat.new()
	frame.draw_center = false
	frame.border_width_left = 2
	frame.border_width_top = 2
	frame.border_color = ThemeUtils.connected_button_border_color_pressed
	frame.content_margin_left = 2.0
	frame.content_margin_top = 2.0
	viewport_panel.add_theme_stylebox_override("panel", frame)

func update_snap_config() -> void:
	var snap_config := Configs.savedata.snap
	var snap_enabled := snap_config > 0.0
	snap_button.button_pressed = snap_enabled
	snapper.editable = snap_enabled
	snapper.set_value(absf(snap_config))


func _on_reference_pressed() -> void:
	var btn_arr: Array[Button] = [
		ContextPopup.create_shortcut_button("load_reference"),
		ContextPopup.create_button(Translator.translate("Paste reference image"),
				paste_reference_image, not Utils.has_clipboard_image_web_safe(),
				load("res://assets/icons/Paste.svg")),
		ContextPopup.create_shortcut_checkbox("view_show_reference", reference_texture.visible),
		ContextPopup.create_shortcut_checkbox("view_overlay_reference", reference_overlay)
	]
	
	var reference_popup := ContextPopup.new()
	reference_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(reference_popup, reference_button.get_global_rect(),
			get_viewport())

func paste_reference_image() -> void:
	FileUtils.load_reference_from_image(DisplayServer.clipboard_get_image())

func _on_visuals_button_pressed() -> void:
	var btn_arr: Array[Button] = [
		ContextPopup.create_shortcut_checkbox("view_show_grid", State.show_grid),
		ContextPopup.create_shortcut_checkbox("view_show_handles", State.show_handles),
		ContextPopup.create_shortcut_checkbox("view_rasterized_svg", State.view_rasterized)
	]
	
	var visuals_popup := ContextPopup.new()
	visuals_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(visuals_popup, visuals_button.get_global_rect(),
			get_viewport())


func _on_show_reference_updated() -> void:
	reference_texture.visible = State.show_reference

func _on_overlay_reference_updated() -> void:
	if State.overlay_reference:
		viewport.move_child(reference_texture, viewport.get_child_count() - 1)
	else:
		viewport.move_child(reference_texture, 0)

func sync_reference_image() ->  void:
	var reference := Configs.savedata.get_active_tab().reference_image
	if is_instance_valid(reference):
		reference_texture.texture = reference
		reference_texture.show()
	else:
		reference_texture.texture = null
		reference_texture.hide()

func _on_snap_button_toggled(toggled_on: bool) -> void:
	Configs.savedata.snap = absf(Configs.savedata.snap) if toggled_on\
			else -absf(Configs.savedata.snap)

func _on_snap_number_edit_value_changed(new_value: float) -> void:
	Configs.savedata.snap = new_value * signf(Configs.savedata.snap)


func _on_show_debug_changed() -> void:
	if State.show_debug:
		debug_container.show()
		update_debug()
		input_debug_label.text = ""
	else:
		debug_container.hide()

# The strings here are intentionally not localized.
func update_debug() -> void:
	var debug_text := ""
	debug_text += "FPS: %d\n" % Performance.get_monitor(Performance.TIME_FPS)
	debug_text += "Static Mem: %s\n" % String.humanize_size(int(Performance.get_monitor(
			Performance.MEMORY_STATIC)))
	debug_text += "Nodes: %d\n" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	debug_text += "Stray nodes: %d\n" % Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	debug_text += "Objects: %d\n" % Performance.get_monitor(Performance.OBJECT_COUNT)
	debug_label.text = debug_text
	# Set up the next update if the container is still visible.
	if debug_container.visible:
		get_tree().create_timer(1.0).timeout.connect(update_debug)

var last_event_text := ""
var last_event_repeat_count := 1

func _update_input_debug(event: InputEvent) -> void:
	if debug_container.visible and event.is_pressed():
		var new_text := input_debug_label.text
		var event_text := event.as_text()
		if event is InputEventMouse:
			event_text += " (" + String.num(event.position.x, 2) = ", " + String.num(event.position.y, 2) + ")"
		if event_text == last_event_text:
			last_event_repeat_count += 1
			new_text = new_text.left(new_text.rfind("\n", new_text.length() - 2) + 1)
			event_text += " (%d)" % last_event_repeat_count
		else:
			last_event_text = event_text
			last_event_repeat_count = 1
		if new_text.count("\n") >= 5:
			new_text = new_text.right(-new_text.find("\n") - 1)
		new_text += event_text + "\n"
		input_debug_label.text = new_text
