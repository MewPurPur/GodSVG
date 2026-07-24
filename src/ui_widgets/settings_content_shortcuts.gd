extends VBoxContainer

const ShortcutConfigWidgetScene = preload("res://src/ui_widgets/setting_shortcut.tscn")
const ShortcutShowcaseWidgetScene = preload("res://src/ui_widgets/presented_shortcut.tscn")

@onready var categories_container: HFlowContainer = $CategoriesContainer
@onready var shortcuts_container: VBoxContainer = $ShortcutsContainer

const shortcut_categories: PackedStringArray = ["file", "edit", "view", "tool", "help"]
var category_buttons: Dictionary[String, Button]

var undo_redo := UndoRedoRef.new()

func get_translated_shortcut_tab(tab_idx: String) -> String:
	match tab_idx:
		"file": return Translator.translate("File")
		"edit": return Translator.translate("Edit")
		"view": return Translator.translate("View")
		"tool": return Translator.translate("Tool")
		"help": return Translator.translate("Help")
	return ""

func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("ui_undo", undo_redo.undo)
	shortcuts.add_shortcut("ui_redo", undo_redo.redo)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	category_buttons.clear()
	var button_group := ButtonGroup.new()
	for category in shortcut_categories:
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
		btn.focus_mode = Control.FOCUS_NONE
		btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		categories_container.add_child(btn)
	categories_container.get_child(0).button_pressed = true
	categories_container.get_child(0).pressed.emit()

func activate_category(category: String) -> void:
	category_buttons[category].button_pressed = true


func show_shortcuts_from_category(category: String) -> void:
	for child in shortcuts_container.get_children():
		child.queue_free()
	
	for action in ShortcutUtils.get_actions(category):
		var shortcut_config: Control
		if ShortcutUtils.is_action_modifiable(action):
			shortcut_config = ShortcutConfigWidgetScene.instantiate()
			shortcut_config.shortcuts_modified.connect(
				func(new_shortcuts: Array[InputEvent]) -> void:
					_on_shortcuts_modified(action, new_shortcuts, category)
			)
		else:
			shortcut_config = ShortcutShowcaseWidgetScene.instantiate()
		
		shortcut_config.action = action
		shortcuts_container.add_child(shortcut_config)

func _on_shortcuts_modified(action: String, new_shortcuts: Array[InputEvent], category: String) -> void:
	undo_redo.create_action()
	undo_redo.add_do_method(Configs.savedata.action_modify_shortcuts.bind(action, new_shortcuts))
	undo_redo.add_do_method(activate_category.bind(category))
	undo_redo.add_undo_method(Configs.savedata.action_modify_shortcuts.bind(action, Configs.savedata.action_get_shortcuts(action)))
	undo_redo.add_undo_method(activate_category.bind(category))
	undo_redo.commit_action()
