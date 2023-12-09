## This singleton handles the two representations of the SVG:
## The SVG text, and the native [TagSVG] representation.
extends Node

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
	
	var loading_from_file := false
	var cmdline_args := OS.get_cmdline_args()
	if cmdline_args.size() > 0:
		var svg_file := FileAccess.open(cmdline_args[0], FileAccess.READ)
		if svg_file != null:
			loading_from_file = true
	
	if loading_from_file:
		var svg_text := FileAccess.open(cmdline_args[0], FileAccess.READ).get_as_text()
		text = svg_text
		saved_text = svg_text
		update_tags();
	elif GlobalSettings.save_data.svg_text.is_empty():
		root_tag.attributes.width.set_value(16.0, Attribute.SyncMode.SILENT)
		root_tag.attributes.height.set_value(16.0, Attribute.SyncMode.SILENT)
		update_text(false)
	else:
		text = GlobalSettings.save_data.svg_text
		saved_text = GlobalSettings.save_data.svg_text
		update_tags()
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
