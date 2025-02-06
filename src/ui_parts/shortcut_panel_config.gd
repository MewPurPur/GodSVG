extends PanelContainer

const clear_icon = preload("res://assets/icons/Clear.svg")

const Dropdown = preload("res://src/ui_widgets/dropdown.tscn")
const DropdownType = preload("res://src/ui_widgets/dropdown.gd")
const ShortcutPanel = preload("res://src/ui_parts/shortcut_panel.gd")

@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var slot_container: VBoxContainer = %SlotContainer
@onready var layout_dropdown: HBoxContainer = %LayoutDropdown

func _ready() -> void:
	close_button.pressed.connect(queue_free)
	close_button.text = Translator.translate("Close")
	%Title.text = Translator.translate("Configure Shortcut Panel")
	%LayoutLabel.text = Translator.translate("Layout")
	layout_dropdown.values = [Translator.translate("Horizontal strip"),
			Translator.translate("Horizontal with two rows"),
			Translator.translate("Vertical strip")]
	layout_dropdown.set_value(Configs.savedata.shortcut_panel_layout)
	layout_dropdown.value_changed.connect(_on_layout_dropdown_value_changed)
	update_shortcut_slots()

func update_shortcut_slots() -> void:
	var shortcut_texts: Dictionary[String, String] = {}  # action: action_description
	for shortcut in ShortcutUtils.get_all_shortcuts():
		shortcut_texts[shortcut] = TranslationUtils.get_shortcut_description(shortcut)
	
	for child in slot_container.get_children():
		child.queue_free()
	
	for i in range(SaveData.SHORTCUT_PANEL_MAX_SLOTS):
		var current_shortcut := Configs.savedata.get_shortcut_panel_slot(i)
		
		var hbox := HBoxContainer.new()
		slot_container.add_child(hbox)
		
		var icon_presentation := PanelContainer.new()
		icon_presentation.custom_minimum_size = Vector2(28, 28)
		if not current_shortcut.is_empty():
			var icon := TextureRect.new()
			icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			icon.texture = ShortcutUtils.get_shortcut_icon(current_shortcut)
			icon_presentation.add_child(icon)
		hbox.add_child(icon_presentation)
		
		var dropdown := Dropdown.instantiate()
		dropdown.custom_minimum_size = Vector2(100, 28)
		dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dropdown.align_left = true
		dropdown.value_text_map = shortcut_texts
		dropdown.values = ShortcutUtils.get_all_shortcuts()
		dropdown.disabled_values = Configs.savedata.get_shortcut_panel_slots().values()
		dropdown.set_value(current_shortcut, false)
		dropdown.value_changed.connect(_on_dropdown_value_changed.bind(i))
		hbox.add_child(dropdown)
		
		if current_shortcut.is_empty():
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			spacer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			spacer.custom_minimum_size = Vector2(28, 28)
			hbox.add_child(spacer)
		else:
			var clear_button := Utils.make_standard_button()
			clear_button.theme_type_variation = "FlatButton"
			clear_button.icon = clear_icon
			clear_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			clear_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			clear_button.custom_minimum_size = Vector2(28, 28)
			clear_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			clear_button.pressed.connect(_on_clear_button_pressed.bind(i))
			hbox.add_child(clear_button)


func _on_dropdown_value_changed(shortcut: String, slot: int) -> void:
	Configs.savedata.set_shortcut_panel_slot(slot, shortcut)
	update_shortcut_slots()

func _on_clear_button_pressed(slot: int) -> void:
	Configs.savedata.erase_shortcut_panel_slot(slot)
	update_shortcut_slots()

func _on_layout_dropdown_value_changed(new_value: ShortcutPanel.Layout) -> void:
	Configs.savedata.shortcut_panel_layout = new_value
