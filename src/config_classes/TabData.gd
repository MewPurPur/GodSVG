# A resource that keeps track of the tabs.
class_name TabData extends ConfigResource

const DEFAULT_SVG = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"></svg>'
const EDITED_FILES_DIR = "user://edited"

signal name_changed
var presented_name: String:
	set(new_value):
		if presented_name != new_value:
			presented_name = new_value
			name_changed.emit()

var active := false

var fully_loaded := true
var empty_unsaved := false
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
		_sync()

func setup_svg_text(new_text: String) -> void:
	_svg_text = new_text
	State.svg_text = new_text
	_save_svg_text()
	fully_loaded = true

func get_svg_text() -> String:
	return _svg_text


@export var svg_file_path: String:
	set(new_value):
		if svg_file_path != new_value:
			svg_file_path = new_value
			emit_changed()
			_sync()

@export var id := -1:
	set(new_value):
		if id != new_value:
			id = new_value
			emit_changed()
			_sync()

func _init(new_id := -1) -> void:
	id = new_id
	Configs.language_changed.connect(_on_language_changed)
	super()

func get_edited_file_path() -> String:
	return get_edited_file_path_for_id(id)

static func get_edited_file_path_for_id(checked_id: int) -> String:
	return "%s/save%d.svg" % [EDITED_FILES_DIR, checked_id]


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


func _on_language_changed() -> void:
	if svg_file_path.is_empty():
		_sync()

func _sync() -> void:
	if not svg_file_path.is_empty():
		# The extension is included in the presented name too.
		# It's always in the end anyway so it can't hide useless info.
		# And also, it prevents ".svg" from being presented as an empty string.
		presented_name = svg_file_path.get_file()
		empty_unsaved = false
	elif SVGParser.text_check_is_root_empty(get_true_svg_text()):
		empty_unsaved = true
		presented_name = "[ %s ]" % Translator.translate("Empty")
	else:
		empty_unsaved = false
		presented_name = "[ %s ]" % Translator.translate("Unsaved")


func activate() -> void:
	active = true
	_svg_text = FileAccess.get_file_as_string(get_edited_file_path())

func deactivate() -> void:
	active = false
	_svg_text = ""

func get_true_svg_text() -> String:
	return _svg_text if active else FileAccess.get_file_as_string(get_edited_file_path())
