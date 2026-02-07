extends VBoxContainer

const PaletteConfigWidgetScene = preload("res://src/ui_widgets/palette_config.tscn")

@onready var palette_container: VBoxContainer = $PaletteContainer
@onready var add_button: Button = $ButtonsContainer/AddButton
@onready var import_button: Button = $ButtonsContainer/ImportButton

var undo_redo := UndoRedoRef.new()

func _ready() -> void:
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	add_button.pressed.connect(add_empty_palette)
	import_button.pressed.connect(_popup_xml_palette_options.bind(import_button))
	rebuild_palettes()

func sync_localization() -> void:
	add_button.text = Translator.translate("New palette")
	import_button.text = Translator.translate("New palette from XML")

func rebuild_palettes() -> void:
	for palette_config in palette_container.get_children():
		palette_config.queue_free()
	for palette in Configs.savedata.get_palettes():
		var palette_config := PaletteConfigWidgetScene.instantiate()
		palette_container.add_child(palette_config)
		palette_config.assign_palette(palette)
		palette_config.layout_changed.connect(rebuild_palettes)


func _popup_xml_palette_options(palette_xml_button: Button) -> void:
	var btn_arr: Array[ContextButton] = [
		ContextButton.create_custom(Translator.translate("Import XML"), add_imported_palette, preload("res://assets/icons/Import.svg")),
		ContextButton.create_custom(Translator.translate("Paste XML"), add_pasted_palette, preload("res://assets/icons/Paste.svg"),
				not Palette.is_valid_palette(Utils.get_clipboard_web_safe()))
	]
	
	var context_popup := ContextPopup.create(btn_arr)
	HandlerGUI.popup_under_rect_center(context_popup, palette_xml_button.get_global_rect(), get_viewport())


func add_empty_palette() -> void:
	_shared_add_palette_logic(Palette.new())

func add_pasted_palette() -> void:
	_shared_add_palettes_logic(Palette.text_to_palettes(Utils.get_clipboard_web_safe()))

func add_imported_palette() -> void:
	FileUtils.open_xml_import_dialog(_on_import_palette_finished)

func _on_import_palette_finished(file_text: String) -> void:
	_shared_add_palettes_logic(Palette.text_to_palettes(file_text))

func _shared_add_palettes_logic(palettes: Array[Palette]) -> void:
	if not palettes.is_empty():
		_shared_add_palette_logic(palettes[0])

func _shared_add_palette_logic(palette: Palette) -> void:
	Configs.savedata.add_palette(palette)
	rebuild_palettes()
