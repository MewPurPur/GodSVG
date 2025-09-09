## A resource that keeps track of a tab.
class_name TabData extends ConfigResource

var _sync_pending := false

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

var reference_image: Texture2D
var overlay_reference := false
var show_reference := true
var undo_redo: UndoRedoRef
var camera_center := Vector2(NAN, NAN)
var camera_zoom := -1.0

var active := false
var empty_unsaved := false

# This variable represents the saved state of the SVG. Intermediate operations such as
# dragging a handle or editing the code shouldn't affect this variable.
var _svg_text := ""

func set_svg_text(new_text: String) -> void:
	if new_text == _svg_text:
		return
	
	if not is_instance_valid(undo_redo):
		undo_redo = UndoRedoRef.new()
	var old_value := _svg_text
	undo_redo.create_action()
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
		var edited_text_parse_result := SVGParser.markup_to_root(FileAccess.get_file_as_string(get_edited_file_path()))
		if edited_text_parse_result.error == SVGParser.ParseError.OK:
			FileAccess.open(edited_file_path, FileAccess.WRITE).store_string(SVGParser.root_to_export_markup(edited_text_parse_result.svg))
		else:
			FileAccess.open(edited_file_path, FileAccess.WRITE).store_string(_svg_text)
	queue_sync()

func save_to_bound_path() -> void:
	if Configs.savedata.get_active_tab() != self:
		return
	FileAccess.open(svg_file_path, FileAccess.WRITE).store_string(State.get_export_text())
	queue_sync()

func set_initial_svg_text(new_text: String) -> void:
	_svg_text = new_text
	_save_svg_text()

func get_svg_text() -> String:
	return _svg_text


@export var svg_file_path: String:
	set(new_value):
		if svg_file_path != new_value:
			svg_file_path = new_value
			emit_changed()
			queue_sync()

@export var id := -1:
	set(new_value):
		if id != new_value:
			id = new_value
			emit_changed()
			queue_sync()

func _init(new_id := -1) -> void:
	id = new_id
	Configs.language_changed.connect(_on_language_changed)
	_connect_to_export_formatter_change.call_deferred()
	super()

func _connect_to_export_formatter_change() -> void:
	Configs.savedata.export_formatter.changed.connect(_save_svg_text)

func get_edited_file_path() -> String:
	return get_edited_file_path_for_id(id)

static func get_edited_file_path_for_id(checked_id: int) -> String:
	return "%s/save%d.svg" % [EDITED_FILES_DIR, checked_id]


func get_presented_svg_file_path() -> String:
	return Utils.simplify_file_path(svg_file_path)


func undo() -> void:
	if is_instance_valid(undo_redo) and undo_redo.has_undo():
		undo_redo.undo()
		State.apply_markup(get_svg_text(), true)

func redo() -> void:
	if is_instance_valid(undo_redo) and undo_redo.has_redo():
		undo_redo.redo()
		State.apply_markup(get_svg_text(), true)


func _on_language_changed() -> void:
	if not is_saved():
		queue_sync()

func queue_sync() -> void:
	_sync.call_deferred()
	_sync_pending = true

func _sync() -> void:
	if not _sync_pending:
		return
	_sync_pending = false
	
	if is_saved():
		# The extension is included in the presented name because it's always in the end and can't hide useless info.
		presented_name = svg_file_path.get_file()
		empty_unsaved = false
		
		if OS.has_feature("web"):
			marked_unsaved = false
		else:
			var edited_text_parse_result := SVGParser.markup_to_root(FileAccess.get_file_as_string(get_edited_file_path()))
			if edited_text_parse_result.error == SVGParser.ParseError.OK:
				marked_unsaved = FileAccess.get_file_as_string(svg_file_path) != SVGParser.root_to_export_markup(edited_text_parse_result.svg)
			else:
				marked_unsaved = FileAccess.get_file_as_string(svg_file_path) != FileAccess.get_file_as_string(get_edited_file_path())
	
	elif not FileAccess.file_exists(get_edited_file_path()) or SVGParser.markup_check_is_root_empty(get_true_svg_text()):
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

func is_empty() -> bool:
	return empty_unsaved

func is_saved() -> bool:
	return not svg_file_path.is_empty()
