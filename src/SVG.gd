# This singleton handles the two representations of the SVG:
# The SVG text, and the native TagSVG representation.
extends Node

signal parsing_finished(error_id: SVGParser.ParseError)
signal svg_text_changed()

const DEFAULT = '<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg"></svg>'

var text := "":
	set(value):
		text = value
		svg_text_changed.emit()

var root_tag := TagSVG.new()

var UR := UndoRedo.new()

func _ready() -> void:
	UR.version_changed.connect(_on_undo_redo)
	root_tag.changed_unknown.connect(update_text.bind(false))
	root_tag.attribute_changed.connect(update_text)
	root_tag.child_attribute_changed.connect(update_text)
	root_tag.tag_layout_changed.connect(update_text)
	
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


func update_tags() -> void:
	var svg_parse_result := SVGParser.text_to_svg(text)
	parsing_finished.emit(svg_parse_result.error)
	if svg_parse_result.error == SVGParser.ParseError.OK:
		root_tag.replace_self(svg_parse_result.svg)


func update_text(undo_redo := true) -> void:
	if undo_redo:
		UR.create_action("")
		UR.add_do_property(self, "text", SVGParser.svg_to_text(root_tag))
		UR.add_undo_property(self, "text", GlobalSettings.save_data.svg_text)
		UR.commit_action()
		GlobalSettings.modify_save_data("svg_text", text)
	else:
		text = SVGParser.svg_to_text(root_tag)

func undo() -> void:
	if UR.has_undo():
		UR.undo()
		update_tags()

func redo() -> void:
	if UR.has_redo():
		UR.redo()
		update_tags()

func _on_undo_redo() -> void:
	GlobalSettings.modify_save_data("svg_text", text)


func refresh() -> void:
	SVG.root_tag.replace_self(SVG.root_tag.duplicate())

func apply_svg_text(svg_text: String,) -> void:
	text = svg_text
	GlobalSettings.modify_save_data("svg_text", text)
	update_tags()
