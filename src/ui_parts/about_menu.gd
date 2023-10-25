extends ColorRect

const project_founder_list: Array[String] = ["MewPurPur"]
const project_manager_list: Array[String] = ["MewPurPur"]
const developers_list: Array[String] = ["ajreckof", "Kiisu-Master", "MewPurPur",
		"Serem Titus (SeremTitus)", "Swarkin"]

@onready var authors_label: RichTextLabel = %AuthorsLabel

func _ready() -> void:
	add_section("Project Founder", project_founder_list)
	add_section("Project Manager", project_manager_list)
	add_section("Developers", developers_list)

func add_section(section_title: String, authors: Array[String]):
	authors_label.push_bold()
	authors_label.add_text(section_title + ":")
	authors_label.pop()
	authors_label.newline()
	authors_label.push_table(1)
	for author in authors:
		authors_label.push_cell()
		authors_label.push_bgcolor(Color(0.15, 0.2, 0.3))
		authors_label.add_text(author)
		authors_label.pop()
		authors_label.pop()
	authors_label.pop()
	authors_label.newline()

func _on_godot_license_pressed() -> void:
	OS.shell_open("https://godotengine.org/license/")

func _on_close_pressed() -> void:
	queue_free()
