# A resource that keeps track of the tabs.
class_name TabData extends ConfigResource

const DEFAULT_SVG = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"></svg>'
const EDITED_FILES_DIR = "user://edited"

signal status_changed
var presented_name: String:
	set(new_value):
		if presented_name != new_value:
			presented_name = new_value
			status_changed.emit()

var marked_unsaved := false:
	set(new_value):
		if marked_unsaved != new_value:
			marked_unsaved = new_value
			status_changed.emit()

var active := false

var fully_loaded := true
var empty_unsaved := false
var undo_redo: UndoRedoRef
var reference_image: Texture2D

# This variable represents the saved state of the SVG. Intermediate operations such as
# dragging a handle or editing the code shouldn't affect this variable.
var _svg_text := ""

func set_svg_text(new_text: String) -> void:
	if new_text == _svg_text:
		return
	
	if not is_instance_valid(undo_redo):
		undo_redo = UndoRedoRef.new()
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
	var edited_file_path := get_edited_file_path()
	if not FileAccess.file_exists(edited_file_path):
		DirAccess.make_dir_recursive_absolute(edited_file_path.get_base_dir())
	
	if active:
		FileAccess.open(edited_file_path, FileAccess.WRITE).store_string(_svg_text)
	else:
		var edited_text_parse_result := SVGParser.text_to_root(
				FileAccess.get_file_as_string(get_edited_file_path()))
		
		if is_instance_valid(edited_text_parse_result.svg):
			FileAccess.open(edited_file_path, FileAccess.WRITE).store_string(
					SVGParser.root_to_export_text(edited_text_parse_result.svg))
	_sync()

func save_to_bound_path() -> void:
	if Configs.savedata.get_active_tab() != self:
		return
	FileAccess.open(svg_file_path, FileAccess.WRITE).store_string(State.get_export_text())
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
			_sync.call_deferred()

@export var id := -1:
	set(new_value):
		if id != new_value:
			id = new_value
			emit_changed()
			_sync.call_deferred()

func _init(new_id := -1) -> void:
	id = new_id
	Configs.language_changed.connect(_on_language_changed)
	super()
	_connect_to_export_formatter_change.call_deferred()

func _connect_to_export_formatter_change() -> void:
	Configs.savedata.export_formatter.changed.connect(_save_svg_text)

func get_edited_file_path() -> String:
	return get_edited_file_path_for_id(id)

static func get_edited_file_path_for_id(checked_id: int) -> String:
	return "%s/save%d.svg" % [EDITED_FILES_DIR, checked_id]

# Method for showing the file path without stuff like "/home/mewpurpur/".
# This information is pretty much always unnecessary clutter.
func get_presented_svg_file_path() -> String:
	var home_dir: String
	if OS.get_name() == "Windows":
		home_dir = OS.get_environment("USERPROFILE")
	else:
		home_dir = OS.get_environment("HOME")
	
	if svg_file_path.begins_with(home_dir):
		return svg_file_path.trim_prefix(home_dir).trim_prefix("/").trim_prefix("\\")
	return svg_file_path


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
		
		var edited_text_parse_result := SVGParser.text_to_root(
				FileAccess.get_file_as_string(get_edited_file_path()))
		
		if is_instance_valid(edited_text_parse_result.svg):
			marked_unsaved = FileAccess.get_file_as_string(svg_file_path) !=\
					SVGParser.root_to_export_text(edited_text_parse_result.svg)
		else:
			marked_unsaved = true
	elif SVGParser.text_check_is_root_empty(get_true_svg_text()):
		empty_unsaved = true
		marked_unsaved = false
		presented_name = "[ %s ]" % Translator.translate("Empty")
	else:
		empty_unsaved = false
		marked_unsaved = false
		presented_name = "[ %s ]" % Translator.translate("Unsaved")


func activate() -> void:
	active = true
	_svg_text = FileAccess.get_file_as_string(get_edited_file_path())

func deactivate() -> void:
	active = false
	_svg_text = ""

func get_true_svg_text() -> String:
	return _svg_text if active else FileAccess.get_file_as_string(get_edited_file_path())
