extends PanelContainer

@onready var authors_label: RichTextLabel = %AuthorsLabel
@onready var version_label: Label = %VersionLabel

func _ready() -> void:
	version_label.text = "GodSVG " + ProjectSettings.get_setting(
			&"application/config/version", "Version information unavailable")
	add_section("Project Founder", AppInfo.project_founders)
	add_section("Project Manager", AppInfo.project_managers)
	add_section("Developers", AppInfo.authors)

func add_section(section_title: String, authors: Array[String]):
	authors_label.push_bold()
	authors_label.add_text(section_title + ":")
	authors_label.pop()
	authors_label.newline()
	authors_label.push_list(0, RichTextLabel.LIST_DOTS, false)
	for author in authors:
		authors_label.add_text(author)
		authors_label.newline()
	authors_label.pop()

func _on_components_pressed() -> void:
	OS.shell_open("https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt")


func _on_close_pressed() -> void:
	queue_free()
