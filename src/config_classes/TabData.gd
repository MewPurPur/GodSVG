# A resource that keeps track of the tabs.
class_name TabData extends ConfigResource

const EDITED_FILES_DIR = "user://edited"

signal name_changed
var presented_name: String:
	set(new_value):
		if presented_name != new_value:
			presented_name = new_value
			name_changed.emit()

var active := false

var is_new := false
var is_empty_and_unsaved := false
var undo_redo: UndoRedo
var reference_image: Texture2D

# This variable represents the saved state of the SVG. Intermediate operations such as
# dragging a handle or editing the code shouldn't affect this variable.
var _svg_text := ""

func set_svg_text(new_text: String) -> void:
	if new_text == _svg_text:
		return
	
	if not is_instance_valid(undo_redo):
		undo_redo = UndoRedo.new()
	var old_value := _svg_text
	undo_redo.create_action("")
	undo_redo.add_do_property(self, "_svg_text", new_text)
	undo_redo.add_undo_property(self, "_svg_text", old_value)
	undo_redo.add_do_property(State, "svg_text", new_text)
	undo_redo.add_undo_property(State, "svg_text", old_value)
	undo_redo.add_do_method(_save_svg_text)
	undo_redo.add_undo_method(_save_svg_text)
	undo_redo.commit_action()

func _save_svg_text() -> void:
	if not FileAccess.file_exists(get_edited_file_path()):
		DirAccess.make_dir_recursive_absolute(get_edited_file_path().get_base_dir())
	FileAccess.open(get_edited_file_path(), FileAccess.WRITE).store_string(_svg_text)
	
	if svg_file_path.is_empty():
		sync()

func setup_svg_text(new_text: String) -> void:
	_svg_text = new_text
	State.svg_text = new_text
	_save_svg_text()
	is_new = false

func get_svg_text() -> String:
	return _svg_text


@export var svg_file_path: String:
	set(new_value):
		if svg_file_path != new_value:
			svg_file_path = new_value
			emit_changed()
			sync()

@export var id := -1:
	set(new_value):
		if id != new_value:
			id = new_value
			emit_changed()
			sync()

func _init(new_id := -1) -> void:
	id = new_id
	super()

func get_edited_file_path() -> String:
	return "%s/save%d.svg" % [EDITED_FILES_DIR, id]


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(undo_redo):
			undo_redo.free()

func undo() -> void:
	if is_instance_valid(undo_redo) and undo_redo.has_undo():
		undo_redo.undo()
		State.sync_elements()

func redo() -> void:
	if is_instance_valid(undo_redo) and undo_redo.has_redo():
		undo_redo.redo()
		State.sync_elements()

func sync() -> void:
	if not svg_file_path.is_empty():
		presented_name = svg_file_path.get_file()
		is_empty_and_unsaved = false
	elif SVGParser.text_check_is_root_empty(get_true_svg_text()):
		is_empty_and_unsaved = true
		presented_name = "[ %s ]" % Translator.translate("Empty")
	else:
		is_empty_and_unsaved = false
		presented_name = "[ %s ]" % Translator.translate("Unsaved")


func activate() -> void:
	active = true
	_svg_text = FileAccess.get_file_as_string(get_edited_file_path())

func deactivate() -> void:
	active = false
	_svg_text = ""

func get_true_svg_text() -> String:
	return _svg_text if active else FileAccess.get_file_as_string(get_edited_file_path())
