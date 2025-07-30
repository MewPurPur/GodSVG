class_name ShortcutRegistrationArray extends RefCounted

var shortcuts := PackedStringArray()
var actions: Array[Callable] = []
var disabled_callbacks: Array[Callable] = []
var check_toggle_callbacks: Array[Callable] = []

func add_action_shortcut(new_shortcut: String, new_action: Callable,
new_disabled_callback := Callable()) -> void:
	shortcuts.append(new_shortcut)
	actions.append(new_action)
	disabled_callbacks.append(new_disabled_callback)
	check_toggle_callbacks.append(Callable())

func add_toggle_shortcut(new_shortcut: String, new_action: Callable,
new_check_toggle_callback: Callable, new_disabled_callback := Callable()) -> void:
	shortcuts.append(new_shortcut)
	actions.append(new_action)
	disabled_callbacks.append(new_disabled_callback)
	check_toggle_callbacks.append(new_check_toggle_callback)
