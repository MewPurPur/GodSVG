extends ColorRect

signal file_selected(path: String)

func _on_file_dialog_file_selected(path: String) -> void:
	file_selected.emit(path)
	queue_free()


func _on_file_dialog_canceled() -> void:
	queue_free()

func _on_file_dialog_confirmed() -> void:
	queue_free()
