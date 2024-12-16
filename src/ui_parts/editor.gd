extends HBoxContainer

const GlobalActions = preload("res://src/ui_parts/global_actions.gd")

const MacMenu = preload("res://src/ui_parts/mac_menu.tscn")

@onready var panel_container: PanelContainer = $PanelContainer
@onready var code_editor: VBoxContainer = %MainContainer/CodeEditor
@onready var inspector: Container = %MainContainer/Inspector

func _ready() -> void:
	Configs.theme_changed.connect(update_theme)
	Configs.layout_changed.connect(update_layout)
	update_theme()
	update_layout()
	if NativeMenu.has_feature(NativeMenu.FEATURE_GLOBAL_MENU):
		add_child(MacMenu.instantiate())

func update_theme() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = ThemeConfig.overlay_panel_inner_color
	stylebox.set_content_margin_all(0)
	panel_container.add_theme_stylebox_override("panel", stylebox)

func update_layout() -> void:
	match Configs.savedata.layout:
		GlobalActions.Layout.ONLY_INSPECTOR:
			code_editor.hide()
			inspector.show()
		GlobalActions.Layout.ONLY_CODE_EDITOR:
			code_editor.show()
			inspector.hide()
		GlobalActions.Layout.CODE_EDITOR_TOP_INSPECTOR_BOTTOM:
			code_editor.show()
			inspector.show()
