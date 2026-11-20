## Attributes are handled by elements instead of having their own class, but they sometimes
## need to hold some metadata for based on their current syntax type for convenience.
## Elements take care of syncing this data.
@abstract class_name AttributeMeta

@warning_ignore("unused_signal")
signal meta_changed(new_text: String)

func _init(initial_value := "") -> void:
	sync(initial_value)

@abstract func sync(value: String)
@abstract func to_text(formatter := Configs.savedata.editor_formatter)
@abstract func _sync_text()
