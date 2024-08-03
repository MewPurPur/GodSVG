# Run with Ctrl+Shift+X.
# A script intended to generate a theme for temporary testing in the editor.
# Make sure to delete it after.
@tool
extends EditorScript

func _run() -> void:
	var theme := ThemeGenerator.generate_theme()
	ResourceSaver.save(theme, "res://godot_only/temp_theme.tres")
	print("Theme updated.")
