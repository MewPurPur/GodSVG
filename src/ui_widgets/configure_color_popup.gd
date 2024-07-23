extends PanelContainer

signal color_deletion_requested

@onready var color_label: Label = %LabelContainer/ColorLabel
@onready var color_name_edit: BetterLineEdit = %ConfigureContainer/TopContainer/NameEdit
@onready var color_edit: LineEditButton = %ConfigureContainer/BottomContainer/ColorEdit
@onready var delete_button: Button = %ConfigureContainer/BottomContainer/DeleteButton
@onready var label_container: HBoxContainer = %LabelContainer

var color_palette: ColorPalette
var idx: int


func _ready() -> void:
	GlobalSettings.language_changed.connect(update_translation)
	set_label_text(color_palette.color_names[idx])
	color_edit.value = color_palette.colors[idx]
	update_translation()


func update_translation() -> void:
	%LabelContainer/EditButton.tooltip_text =\
			TranslationServer.translate("Edit color name")
	$ConfigureContainer/BottomContainer/DeleteButton.tooltip_text =\
			TranslationServer.translate("Delete color")
func _on_edit_button_pressed() -> void:
	color_name_edit.text = color_palette.color_names[idx]
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
		color_label.text = TranslationServer.translate("Unnamed")
		color_label.add_theme_color_override("font_color",
				ThemeGenerator.common_subtle_text_color)
	else:
		color_label.text = new_text
		color_label.remove_theme_color_override("font_color")


func _on_delete_button_pressed() -> void:
	color_deletion_requested.emit()
	queue_free()
