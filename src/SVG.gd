## This singleton handles the two representations of the SVG:
## The SVG text, and the native [TagSVG] representation.
extends Node

const AlertDialog := preload("res://src/ui_parts/alert_dialog.tscn")
const ImportWarningDialog = preload("res://src/ui_parts/import_warning_dialog.tscn")

var text := ""
var root_tag := TagSVG.new()

var saved_text := ""
var UR := UndoRedo.new()

signal parsing_finished(error_id: StringName) 

func _ready() -> void:
	SVG.root_tag.changed_unknown.connect(update_text.bind(false))
	SVG.root_tag.attribute_changed.connect(update_text)
	SVG.root_tag.child_attribute_changed.connect(update_text)
	SVG.root_tag.tag_layout_changed.connect(update_text)
	
	var cmdline_args := OS.get_cmdline_args()
	var load_cmdl: bool
	if OS.is_debug_build() and not OS.has_feature("template"):
		load_cmdl = false
	elif cmdline_args.size() >= 1:
		load_cmdl = true
		
	await get_tree().process_frame # Warning dialogs on cmdline file opening would not work otherwise.
	if (apply_svg_from_path(cmdline_args[0]) if load_cmdl else -1) == OK:
		pass
	elif not GlobalSettings.save_data.svg_text.is_empty():
		text = GlobalSettings.save_data.svg_text
		saved_text = GlobalSettings.save_data.svg_text
		update_tags()
	else:
		root_tag.attributes.width.set_num(16.0, Attribute.SyncMode.SILENT)
		root_tag.attributes.height.set_num(16.0, Attribute.SyncMode.SILENT)
		update_text(false)
	UR.clear_history()


func update_tags() -> void:
	var err_id := SVGParser.get_svg_syntax_error(text)
	parsing_finished.emit(err_id)
	if err_id == &"":
		root_tag.replace_self(SVGParser.text_to_svg(text))

func update_text(undo_redo := true) -> void:
	if undo_redo:
		UR.create_action("")
		UR.add_do_property(self, &"text", SVGParser.svg_to_text(root_tag))
		UR.add_undo_property(self, &"text", saved_text)
		UR.commit_action()
		saved_text = text
	else:
		text = SVGParser.svg_to_text(root_tag)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"redo"):
		if UR.has_redo():
			UR.redo()
			update_tags()
	elif event.is_action_pressed(&"undo") and UR.has_undo():
		UR.undo()
		update_tags()

func apply_svg_from_path(path: String) -> int:
	var svg_file := FileAccess.open(path, FileAccess.READ)
	var error := ""
	var extension := path.get_extension()
	
	if extension.is_empty():
		error = "#file_open_empty_extension"
	elif extension == &"tscn":
		return ERR_FILE_CANT_OPEN
	elif not extension == &"svg":
		error = tr(
			"#file_open_unsupported_extension").format({"passed_extension": extension})
	elif svg_file == null:
		error = "#file_open_fail_message"
	if not error.is_empty():
		var alert_dialog := AlertDialog.instantiate()
		get_tree().get_root().add_child(alert_dialog)
		alert_dialog.setup(error, "#alert", 280.0)
		return ERR_FILE_CANT_OPEN
	
	var svg_text := svg_file.get_as_text()
	var warning_panel := ImportWarningDialog.instantiate()
	warning_panel.imported.connect(func (svg: String) -> void:
		text = svg
		saved_text = svg
		update_tags()
		)
	warning_panel.set_svg(svg_text)
	get_tree().get_root().add_child(warning_panel)
	return OK
