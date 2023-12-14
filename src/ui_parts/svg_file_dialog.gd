extends FileDialog

func _on_file_selected(_path: String) -> void:
	queue_free()

func _on_canceled() -> void:
	queue_free()

func _on_confirmed() -> void:
	queue_free()
