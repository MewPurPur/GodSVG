extends PanelContainer

signal color_deletion_requested

@onready var color_label: Label = %LabelContainer/ColorLabel
@onready var color_name_edit: BetterLineEdit = %ConfigureContainer/TopContainer/ColorNameEdit
@onready var color_edit: LineEditButton = %ConfigureContainer/BottomContainer/ColorEdit
@onready var edit_button: Button = $ConfigureContainer/TopContainer/LabelContainer/EditButton
@onready var delete_button: Button = %ConfigureContainer/BottomContainer/DeleteButton
@onready var label_container: HBoxContainer = %LabelContainer

var palette: Palette
var idx: int

func _ready() -> void:
	Configs.language_changed.connect(sync_localization)
	set_label_text(palette.get_color_name(idx))
	color_edit.value = palette.get_color(idx)
	sync_localization()
	color_name_edit.text_submitted.connect(_on_name_edit_text_submitted)
	color_name_edit.text_change_canceled.connect(hide_name_edit)
	edit_button.pressed.connect(_on_edit_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)
	HandlerGUI.register_focus_sequence(self, [edit_button, color_name_edit, color_edit, delete_button], true)


func sync_localization() -> void:
	%LabelContainer/EditButton.tooltip_text = Translator.translate("Edit color name")
	$ConfigureContainer/BottomContainer/DeleteButton.tooltip_text = Translator.translate("Delete color")

func _on_edit_button_pressed() -> void:
	color_name_edit.text = palette.get_color_name(idx)
	color_name_edit.show()
	color_name_edit.grab_focus()
	color_name_edit.caret_column = color_name_edit.text.length()
	label_container.hide()


func _on_name_edit_text_submitted(new_text: String) -> void:
	var new_name := new_text.strip_edges()
	set_label_text(new_name)
	hide_name_edit()


func hide_name_edit() -> void:
	color_name_edit.hide()
	label_container.show()

func set_label_text(new_text: String) -> void:
	if new_text.is_empty():
		color_label.text = Translator.translate("Unnamed")
		color_label.add_theme_color_override("font_color",
				ThemeUtils.subtle_text_color)
	else:
		color_label.text = new_text
		color_label.remove_theme_color_override("font_color")


func _on_delete_button_pressed() -> void:
	color_deletion_requested.emit()
	queue_free()
