class_name TabData extends Resource

@export var edited_file_path := ""
@export var svg_file_path := ""

var UR := UndoRedo.new()

func get_svg_text() -> String:
	var fa := FileAccess.open(edited_file_path, FileAccess.READ)
	if fa != null:
		return fa.get_as_text()
	return ""

func clear() -> void:
	svg_file_path = ""

func update_svg_text(new_text: String) -> void:
	var fa := FileAccess.open(edited_file_path, FileAccess.WRITE)
	if fa != null:
		fa.store_string(new_text)
