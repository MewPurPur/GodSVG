extends PanelContainer

@onready var clarifications: RichTextLabel = %Clarifications
@onready var close_button: Button = $VBoxContainer/CloseButton

func _ready() -> void:
	close_button.pressed.connect(queue_free)
	reset_clarifications()

func _on_github_link_pressed() -> void:
	OS.shell_open("https://github.com/sponsors/MewPurPur")

func _on_ko_fi_link_pressed() -> void:
	OS.shell_open("https://ko-fi.com/mewpurpur")

func _on_patreon_link_pressed() -> void:
	OS.shell_open("https://www.patreon.com/GodSVG")


# Shouldn't be localized.

func _on_github_link_mouse_entered() -> void:
	show_description("Guthub Sponsors", PackedStringArray(["Low extra fees",
			"Can donate an arbitrary amount", "Includes all perks"]))

func _on_ko_fi_link_mouse_entered() -> void:
	show_description("Ko-Fi", PackedStringArray(["Low extra fees",
			"Can donate an arbitrary amount"]), PackedStringArray(["No perks"]))

func _on_patreon_link_mouse_entered() -> void:
	show_description("Patreon", PackedStringArray(["Includes all perks"]),
			PackedStringArray(["Higher extra fees", "Can only donate fixed amounts"]))

func _on_link_mouse_exited() -> void:
	reset_clarifications()


func show_description(title: String, pros: PackedStringArray, cons := PackedStringArray()) -> void:
	clarifications.clear()
	clarifications.push_bold()
	clarifications.add_text(title + ":")
	clarifications.pop()
	clarifications.push_color(Configs.savedata.theme_config.basic_color_valid)
	for pro in pros:
		clarifications.add_text("\n+ " + pro)
	clarifications.push_color(Configs.savedata.theme_config.basic_color_error)
	for con in cons:
		clarifications.add_text("\n– " + con)

func reset_clarifications() -> void:
	clarifications.clear()
	clarifications.push_color(ThemeConfig.common_subtle_text_color)
	clarifications.add_text("\nHover a platform for details.")
