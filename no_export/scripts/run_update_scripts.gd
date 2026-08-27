# Run with Ctrl+Shift+X.
@tool
extends EditorScript

func _run() -> void:
	for path in ["res://no_export/scripts/update_translations.gd", "res://no_export/scripts/update_desktop_file.gd"]:
		load(path).new()._run()
