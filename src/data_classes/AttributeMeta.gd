## Attributes are handled by elements instead of having their own class, but they sometimes
## need to hold some metadata for based on their current syntax type for convenience.
## Elements take care of syncing this data.
@abstract class_name AttributeMeta

func _init(initial_value := "") -> void:
	sync(initial_value)

@abstract func sync(value: String)
