extends HBoxContainer

@onready var panel_container: PanelContainer = $HSplitContainer/PanelContainer

func _notification(what: int) -> void:
	if what in [NOTIFICATION_READY, Utils.CustomNotification.THEME_CHANGED]:
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = ThemeGenerator.overlay_panel_inner_color
		stylebox.content_margin_left = 6
		stylebox.content_margin_top = 6
		stylebox.content_margin_bottom = 6
		stylebox.expand_margin_right = 6
		panel_container.add_theme_stylebox_override("panel", stylebox)
