extends PanelContainer

@onready var project_founder_list: PanelGrid = %ProjectFounder/List
@onready var authors_list: PanelGrid = %Developers/List
@onready var version_label: Label = %VersionLabel

func _ready() -> void:
	version_label.text = "GodSVG " + ProjectSettings.get_setting(
			"application/config/version", "Version information unavailable")
	project_founder_list.items = AppInfo.project_founder_and_manager
	project_founder_list.setup()
	authors_list.items = AppInfo.authors
	authors_list.setup()

func _on_components_pressed() -> void:
	OS.shell_open("https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt")


func _on_close_pressed() -> void:
	queue_free()
