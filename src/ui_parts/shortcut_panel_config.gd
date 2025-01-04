extends PanelContainer

@onready var slots = [%slot0/Dropdown, %slot1/Dropdown, %slot2/Dropdown, %slot3/Dropdown, %slot4/Dropdown]

var shortcuts_dict: Dictionary # shortcut_description: shortcut_name
var selected_shortcuts: Dictionary # slot: shortcut_name

func _ready() -> void:
	%Title.text = Translator.translate("Configure Shortcut Panel")
	%VerticalPanel.text = Translator.translate("Switch to vertical panel")
	%LockPanelPosition.text = Translator.translate("Lock panel position")
	%CloseButton.text = Translator.translate("Close")
	%CloseButton.grab_focus()
	setup_shortcut_slots()
	# TODO Implement these properly when more configs are implemented.
	%VerticalPanel.queue_free()
	%LockPanelPosition.queue_free()
	#%VerticalPanel.button_pressed = Configs.savedata.vertical_panel
	#%LockPanelPosition.button_pressed = Configs.savedata.lock_panel_position

func setup_shortcut_slots() -> void:
	for i in range(slots.size()):
		slots[i].value_changed.connect(_on_shortcut_selected.bind(i))
		%SlotContainer.get_node("slot"+str(i)+"/ResetButton").pressed.connect(clear_slot.bind(i))
	
	# Collect all shortcuts
	var shortcuts: Array[String]
	for s_name in ShortcutUtils.get_all_shortcuts():
		var events := InputMap.action_get_events(s_name)
		if not events.is_empty():
			var s_description: String = TranslationUtils.get_shortcut_description(s_name)
			shortcuts_dict[s_description] = s_name # For later fetching the shortcut name using its description
			shortcuts.append(s_description)
	
	# Append shortcuts to each dropdown
	for slot_dropdown in slots:
		slot_dropdown.values.append_array(shortcuts)
	
	for i in Configs.savedata.get_shortcut_panel_presented_shortcuts():
		var s: String = Configs.savedata.get_shortcut_panel_presented_shortcut(i)
		slots[i].set_value(TranslationUtils.get_shortcut_description(s))


func _on_shortcut_selected(s_description: String, slot: int) -> void:
	var s_name: String = shortcuts_dict[s_description]
	selected_shortcuts[slot] = s_name
	update_popup_options()
	%SlotContainer.get_node("slot"+str(slot)+"/ResetButton").show()
	%SlotContainer.get_node("slot"+str(slot)+"/icon").icon = ShortcutUtils.get_shortcut_icon(s_name)

func clear_slot(slot: int) ->void:
	selected_shortcuts.erase(slot)
	slots[slot].set_value("", false)
	update_popup_options()
	%SlotContainer.get_node("slot"+str(slot)+"/icon").icon = null
	%SlotContainer.get_node("slot"+str(slot)+"/ResetButton").hide()

func update_popup_options() -> void:
	var disabled_values: PackedStringArray
	for s_name in selected_shortcuts.values():
		disabled_values.append(TranslationUtils.get_shortcut_description(s_name))
	
	for slot_index in range(5):
		slots[slot_index].disabled_values = disabled_values


func _on_close_button_pressed() -> void:
	Configs.savedata.set_shortcut_panel_presented_shortcuts(selected_shortcuts)
	HandlerGUI.shortcut_panel.update()
	get_parent().queue_free()
