class_name ShortcutsRegistration extends RefCounted

@warning_ignore("unused_signal")
signal activated(activated_action: String)

enum Behavior {PASS_THROUGH_ALL, PASS_THROUGH_POPUPS, PASS_THROUGH_AND_PRESERVE_POPUPS, NO_PASSTHROUGH, STRICT_NO_PASSTHROUGH}

const BEHAVIOR_PRIORITY: Array[ShortcutsRegistration.Behavior] = [
	ShortcutsRegistration.Behavior.STRICT_NO_PASSTHROUGH,
	ShortcutsRegistration.Behavior.NO_PASSTHROUGH,
	ShortcutsRegistration.Behavior.PASS_THROUGH_POPUPS,
	ShortcutsRegistration.Behavior.PASS_THROUGH_AND_PRESERVE_POPUPS,
	ShortcutsRegistration.Behavior.PASS_THROUGH_ALL,
]

# The elements with the same indices from these 3 arrays corresponds to a shortcut registration.
var actions := PackedStringArray()
var behaviors: Array[Behavior] = []
var callbacks: Array[Callable] = []

func add_shortcut(new_action: String, new_callback: Callable, new_behavior := Behavior.NO_PASSTHROUGH) -> void:
	if new_action in actions:
		return
	actions.append(new_action)
	behaviors.append(new_behavior)
	callbacks.append(new_callback)

func remove_shortcuts(actions_to_remove: PackedStringArray) -> void:
	for action_to_remove in actions_to_remove:
		if not action_to_remove in actions:
			continue
		var action_idx := actions.find(action_to_remove)
		actions.remove_at(action_idx)
		behaviors.remove_at(action_idx)
		callbacks.remove_at(action_idx)

func are_registrations_empty() -> bool:
	return actions.is_empty()
