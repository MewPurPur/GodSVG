# This singleton handles the two representations of the SVG:
# The SVG text, and the native TagSVG representation.
extends Node

signal changed_unknown
signal resized

signal attribute_somewhere_changed(xid: PackedInt32Array)
signal tags_added(xids: Array[PackedInt32Array])
signal tags_deleted(xids: Array[PackedInt32Array])
signal tags_moved_in_parent(parent_xid: PackedInt32Array, old_indices: Array[int])
signal tags_moved_to(xids: Array[PackedInt32Array], location: PackedInt32Array)
signal tag_layout_changed  # Emitted together with any of the above 5.

signal parsing_finished(error_id: SVGParser.ParseError)

const DEFAULT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"></svg>'

var text := ""

var root_tag := TagRoot.new()

var UR := UndoRedo.new()

func _ready() -> void:
	UR.version_changed.connect(_on_undo_redo)
	changed_unknown.connect(update_text.bind(false))
	attribute_somewhere_changed.connect(update_text.unbind(1))
	tag_layout_changed.connect(update_text)
	
	var cmdline_args := OS.get_cmdline_args()
	var load_cmdl := false
	if not (OS.is_debug_build() and not OS.has_feature("template")) and\
	cmdline_args.size() >= 1:
		load_cmdl = true
	
	await get_tree().get_root().ready  # Await tree ready to be able to add error dialogs.
	
	# Guarantee a proper SVG text first, as the import warnings dialog
	# that might pop up from command line file opening is cancellable.
	if not GlobalSettings.save_data.svg_text.is_empty():
		apply_svg_text(GlobalSettings.save_data.svg_text)
	else:
		apply_svg_text(DEFAULT)
	
	if load_cmdl:
		FileUtils.apply_svg_from_path(cmdline_args[0])
	
	UR.clear_history()

func _exit_tree() -> void:
	UR.free()

func sync() -> void:
	var old_size := root_tag.get_size()
	var svg_parse_result := SVGParser.text_to_root(text)
	parsing_finished.emit(svg_parse_result.error)
	if svg_parse_result.error == SVGParser.ParseError.OK:
		root_tag = svg_parse_result.svg
		root_tag.attribute_somewhere_changed.connect(attribute_somewhere_changed.emit)
		root_tag.tags_added.connect(tags_added.emit)
		root_tag.tags_deleted.connect(tags_deleted.emit)
		root_tag.tags_moved_in_parent.connect(tags_moved_in_parent.emit)
		root_tag.tags_moved_to.connect(tags_moved_to.emit)
		root_tag.tag_layout_changed.connect(tag_layout_changed.emit)
		changed_unknown.emit()
		if root_tag.get_size() != old_size:
			resized.emit()


func update_text(undo_redo := true) -> void:
	if undo_redo:
		UR.create_action("")
		UR.add_do_property(self, "text", SVGParser.root_to_text(root_tag))
		UR.add_undo_property(self, "text", GlobalSettings.save_data.svg_text)
		UR.commit_action()
		GlobalSettings.modify_save_data("svg_text", text)
	else:
		text = SVGParser.root_to_text(root_tag)

func undo() -> void:
	if UR.has_undo():
		UR.undo()
		sync()

func redo() -> void:
	if UR.has_redo():
		UR.redo()
		sync()

func _on_undo_redo() -> void:
	GlobalSettings.modify_save_data("svg_text", text)

func apply_svg_text(svg_text: String) -> void:
	text = svg_text
	GlobalSettings.modify_save_data("svg_text", text)
	sync()
