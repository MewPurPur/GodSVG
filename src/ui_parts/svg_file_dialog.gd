extends PanelContainer

signal file_selected(path: String)

func _on_file_selected(path: String) -> void:
	file_selected.emit(path)
	queue_free()

func _on_canceled() -> void:
	queue_free()

func _on_confirmed() -> void:
	queue_free()
