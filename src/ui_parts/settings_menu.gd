extends ColorRect

@onready var window_mode_button: CheckBox = %WindowMode
@onready var svg_button: CheckBox = %SVG
@onready var lang_button: Button = %Language
@onready var lang_popup: Popup = $LangPopup

func _ready() -> void:
	update_language_button()
	var buttons_arr: Array[Button] = []
	for lang in ["en", "bg"]:
		var button := Button.new()
		button.text = TranslationServer.get_locale_name(lang) + " (" + lang + ")"
		button.pressed.connect(_on_language_chosen.bind(lang))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		buttons_arr.append(button)
	lang_popup.set_btn_array(buttons_arr)
	
	window_mode_button.button_pressed = GlobalSettings.save_window_mode
	svg_button.button_pressed = GlobalSettings.save_svg

func _on_window_mode_pressed() -> void:
	GlobalSettings.save_window_mode = not GlobalSettings.save_window_mode

func _on_svg_pressed() -> void:
	GlobalSettings.save_svg = not GlobalSettings.save_svg

func _on_close_pressed() -> void:
	queue_free()

func _on_language_pressed() -> void:
	lang_popup.popup(Utils.calculate_popup_rect(lang_button.global_position,
			lang_button.size, lang_popup.size))

func _on_language_chosen(locale: String) -> void:
	lang_popup.hide()
	GlobalSettings.language = locale
	update_language_button()

func update_language_button() -> void:
	lang_button.text = tr(&"#language") + ": " + TranslationServer.get_locale().to_upper()


func _on_zoom_pressed():
	GlobalSettings.invert_zoom = not GlobalSettings.invert_zoom
