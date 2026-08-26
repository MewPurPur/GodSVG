extends VBoxContainer

const ShortcutConfigWidgetScene = preload("res://src/ui_widgets/setting_shortcut.tscn")
const ShortcutShowcaseWidgetScene = preload("res://src/ui_widgets/presented_shortcut.tscn")

@onready var categories_container: HFlowContainer = $CategoriesContainer
@onready var shortcuts_container: VBoxContainer = $ShortcutsContainer

const shortcut_categories: PackedStringArray = ["file", "edit", "view", "tool", "help"]
var category_buttons: Dictionary[String, Button] = {}
var action_configs: Dictionary[String, Control] = {}

var undo_redo: UndoRedoRef
var scroll_to_callback: Callable
var settings_tab_change_callable: Callable

func get_translated_shortcut_tab(tab_index: String) -> String:
	match tab_index:
		"file": return Translator.translate("File")
		"edit": return Translator.translate("Edit")
		"view": return Translator.translate("View")
		"tool": return Translator.translate("Tool")
		"help": return Translator.translate("Help")
	return ""

func _ready() -> void:
	var button_group := ButtonGroup.new()
	for i in shortcut_categories.size():
		var category := shortcut_categories[i]
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = button_group
		category_buttons[category] = btn
		btn.toggled.connect(
			func(toggled_on: bool):
				if toggled_on:
					show_shortcuts_from_category(category)
		)
		var sync_button_locale :=\
			func() -> void:
				btn.text = get_translated_shortcut_tab(category)
		Configs.language_changed.connect(sync_button_locale)
		sync_button_locale.call()
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		categories_container.add_child(btn)
		if i == 0:
			btn.button_pressed = true
			btn.pressed.emit()

func setup_undo_redo_utensils(new_undo_redo: UndoRedoRef, new_scroll_to_callback: Callable, new_settings_tab_change_callable: Callable) -> void:
	undo_redo = new_undo_redo
	scroll_to_callback = new_scroll_to_callback
	settings_tab_change_callable = new_settings_tab_change_callable


func highlight_action(category: String, action: String) -> void:
	var category_button := category_buttons[category]
	if not category_button.button_pressed:
		category_button.button_pressed = true
		await get_tree().process_frame
	action_configs[action]
	scroll_to_callback.call(action_configs[action].get_global_rect(), 0.16)


func show_shortcuts_from_category(category: String) -> void:
	for child in shortcuts_container.get_children():
		shortcuts_container.remove_child(child)
		child.queue_free()
	action_configs.clear()
	
	for action in ShortcutUtils.get_actions(category):
		var shortcut_config: Control
		if ShortcutUtils.is_action_modifiable(action):
			shortcut_config = ShortcutConfigWidgetScene.instantiate()
			shortcut_config.shortcuts_edited.connect(
				func(new_shortcuts: Array[InputEvent]) -> void:
					_on_shortcuts_edited(action, new_shortcuts, category)
			)
		else:
			shortcut_config = ShortcutShowcaseWidgetScene.instantiate()
		
		shortcut_config.action = action
		shortcut_config.scroll_to_callback = scroll_to_callback
		shortcuts_container.add_child(shortcut_config)
		action_configs[action] = shortcut_config
	
	var focus_sequence: Array[Control]
	focus_sequence.assign(categories_container.get_children())
	focus_sequence.append_array(shortcuts_container.get_children())
	HandlerGUI.register_focus_sequence(self, focus_sequence)

func _on_shortcuts_edited(action: String, new_shortcuts: Array[InputEvent], category: String) -> void:
	undo_redo.create_action()
	undo_redo.add_do_method(Configs.savedata.action_modify_shortcuts.bind(action, new_shortcuts))
	undo_redo.add_do_method(settings_tab_change_callable)
	undo_redo.add_do_method(highlight_action.bind(category, action))
	undo_redo.add_undo_method(Configs.savedata.action_modify_shortcuts.bind(action, Configs.savedata.action_get_shortcuts(action)))
	undo_redo.add_undo_method(settings_tab_change_callable)
	undo_redo.add_undo_method(highlight_action.bind(category, action))
	undo_redo.commit_action(false)
	# Only this method needs to run, so commit execution was disabled.
	Configs.savedata.action_modify_shortcuts(action, new_shortcuts)
