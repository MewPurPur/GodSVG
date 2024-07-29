extends HBoxContainer

const MacMenu = preload("res://src/ui_parts/global_menu.tscn")

@onready var panel_container: PanelContainer = $HSplitContainer/PanelContainer

func _ready() -> void:
	GlobalSettings.theme_changed.connect(update_theme)
	update_theme()
	if NativeMenu.has_feature(NativeMenu.FEATURE_GLOBAL_MENU):
		add_child(MacMenu.instantiate())

func update_theme() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = ThemeGenerator.overlay_panel_inner_color
	stylebox.set_content_margin_all(6)
	panel_container.add_theme_stylebox_override("panel", stylebox)
