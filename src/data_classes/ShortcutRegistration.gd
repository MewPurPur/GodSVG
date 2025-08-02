class_name ShortcutsRegistration extends RefCounted

@warning_ignore("unused_signal")
signal activated(activated_action: String)

enum Behavior {PASS_THROUGH_ALL, PASS_THROUGH_POPUPS, PASS_THROUGH_AND_PRESERVE_POPUPS, NO_PASSTHROUGH, STRICT_NO_PASSTHROUGH}

# The elements with the same indices from these 3 arrays corresponds to a shortcut registration.
var actions := PackedStringArray()
var behaviors: Array[Behavior] = []
var callbacks: Array[Callable] = []

func add_shortcut(new_action: String, new_callback: Callable, new_behavior := Behavior.NO_PASSTHROUGH) -> void:
	actions.append(new_action)
	behaviors.append(new_behavior)
	callbacks.append(new_callback)
