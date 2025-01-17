extends HBoxContainer

const MacMenu = preload("res://src/ui_parts/global_menu.tscn")

@onready var panel_container: PanelContainer = $PanelContainer

func _ready() -> void:
	#var svg_text := FileAccess.get_file_as_string(
			#ProjectSettings.globalize_path("res://godot_only/source_assets/splash.svg"))
	#var root := SVGParser.text_to_root(svg_text, Formatter.new()).svg
	#var t := Time.get_ticks_msec()
	#root.optimize(true)
	#print(Time.get_ticks_msec() - t)
	
	Configs.theme_changed.connect(update_theme)
	update_theme()
	if NativeMenu.has_feature(NativeMenu.FEATURE_GLOBAL_MENU):
		add_child(MacMenu.instantiate())

func update_theme() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = ThemeUtils.overlay_panel_inner_color
	stylebox.set_content_margin_all(0)
	panel_container.add_theme_stylebox_override("panel", stylebox)
