extends PanelContainer

func _on_github_link_pressed() -> void:
	OS.shell_open("https://github.com/sponsors/MewPurPur")

func _on_ko_fi_link_pressed() -> void:
	OS.shell_open("https://ko-fi.com/mewpurpur")

func _on_close_pressed() -> void:
	HandlerGUI.remove_overlay()
