extends PanelContainer

# This overengineered menu mostly has logic around not hiding the text as you move your
# mouse between the buttons. The text stays unless the mouse moves too far away from
# the specific button that showed the current list of pros/cons.

enum Link {NONE, GITHUB, KO_FI, PATREON}
var current_link := Link.NONE

@onready var clarifications: RichTextLabel = %Clarifications
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var margin_container: MarginContainer = %MarginContainer
@onready var github_link: Button = %MarginContainer/HBoxContainer/GithubLink
@onready var ko_fi_link: Button = %MarginContainer/HBoxContainer/KoFiLink
@onready var patreon_link: Button = %MarginContainer/HBoxContainer/PatreonLink
@onready var hbox: HBoxContainer = %MarginContainer/HBoxContainer

func _ready() -> void:
	close_button.text = Translator.translate("Cancel")
	close_button.pressed.connect(queue_free)
	set_link(Link.NONE)
	
	github_link.pressed.connect(OS.shell_open.bind("https://github.com/sponsors/MewPurPur"))
	ko_fi_link.pressed.connect(OS.shell_open.bind("https://ko-fi.com/mewpurpur"))
	patreon_link.pressed.connect(OS.shell_open.bind("https://www.patreon.com/GodSVG"))
	github_link.mouse_entered.connect(set_link.bind(Link.GITHUB))
	ko_fi_link.mouse_entered.connect(set_link.bind(Link.KO_FI))
	patreon_link.mouse_entered.connect(set_link.bind(Link.PATREON))
	margin_container.gui_input.connect(_on_margin_container_gui_input)
	margin_container.mouse_exited.connect(set_link.bind(Link.NONE))


func _on_margin_container_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	
	if current_link == Link.NONE:
		return
	
	var hbox_pos := hbox.position
	
	if (current_link == Link.GITHUB and not Rect2(hbox_pos + github_link.position - Vector2(13, 13),
	github_link.size + Vector2(26, 26)).has_point(event.position)) or\
	(current_link == Link.KO_FI and not Rect2(hbox_pos + ko_fi_link.position - Vector2(13, 13),
	ko_fi_link.size + Vector2(26, 26)).has_point(event.position)) or\
	(current_link == Link.PATREON and not Rect2(hbox_pos + patreon_link.position - Vector2(13, 13),
	patreon_link.size + Vector2(26, 26)).has_point(event.position)):
		set_link(Link.NONE)


func set_link(new_link: Link) -> void:
	current_link = new_link
	if new_link == Link.NONE:
		clarifications.clear()
		clarifications.push_color(ThemeUtils.common_subtle_text_color)
		clarifications.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		clarifications.add_text("\nHover a platform for details.")
		return
	
	var title: String
	var pros: PackedStringArray
	var cons: PackedStringArray
	match new_link:
		Link.GITHUB:
			title = "Guthub Sponsors"
			pros = PackedStringArray(["Low extra fees", "Can donate an arbitrary amount",
					"Includes all perks"])
			cons = PackedStringArray()
		Link.KO_FI:
			title = "Ko-Fi"
			pros = PackedStringArray(["Low extra fees", "Can donate an arbitrary amount"])
			cons = PackedStringArray(["No perks"])
		Link.PATREON:
			title = "Patreon"
			pros = PackedStringArray(["Includes all perks"])
			cons = PackedStringArray(["Higher extra fees", "Can only donate fixed amounts"])
	
	clarifications.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	clarifications.clear()
	clarifications.push_bold()
	clarifications.add_text(title + ":")
	clarifications.pop()
	clarifications.push_color(Configs.savedata.basic_color_valid)
	for pro in pros:
		clarifications.add_text("\n+ " + pro)
	clarifications.push_color(Configs.savedata.basic_color_error)
	for con in cons:
		clarifications.add_text("\n– " + con)
