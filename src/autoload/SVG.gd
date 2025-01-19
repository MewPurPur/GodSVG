# This singleton handles the two representations of the SVG:
# The SVG text, and the native ElementSVG representation.
extends Node

signal changed_unknown
signal resized

# These signals copy the ones in ElementRoot.
# ElementRoot is not persistent, while these signals can be connected to reliably.
signal any_attribute_changed(xid: PackedInt32Array)
signal xnodes_added(xids: Array[PackedInt32Array])
signal xnodes_deleted(xids: Array[PackedInt32Array])
signal xnodes_moved_in_parent(parent_xid: PackedInt32Array, old_indices: Array[int])
signal xnodes_moved_to(xids: Array[PackedInt32Array], location: PackedInt32Array)
signal xnode_layout_changed  # Emitted together with any of the above 4.
signal basic_xnode_text_changed
signal basic_xnode_rendered_text_changed

signal parsing_finished(error_id: SVGParser.ParseError)
signal changed  # Should only connect to persistent parts of the UI.

const DEFAULT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"></svg>'

var _current_size := Vector2.ZERO

var _update_pending := false
var _save_pending := false

# "unstable_text" is the current state, which might have errors (i.e., while using the
# code editor). "text" is the last state without errors.
# These both differ from "Configs.svg_text" which is the state as saved to file,
# which doesn't happen while dragging handles or typing in the code editor for example.
var unstable_text := ""
var text := ""
var root_element: ElementRoot

var UR := UndoRedo.new()

func _enter_tree() -> void:
	root_element = ElementRoot.new(Configs.savedata.editor_formatter)

func _ready() -> void:
	changed_unknown.connect(queue_update)
	xnode_layout_changed.connect(queue_update)
	any_attribute_changed.connect(queue_update.unbind(1))
	basic_xnode_text_changed.connect(queue_update)
	basic_xnode_rendered_text_changed.connect(queue_update)
	
	var cmdline_args := OS.get_cmdline_args()
	var load_cmdl := false
	if not (OS.is_debug_build() and not OS.has_feature("template")) and\
	cmdline_args.size() >= 1:
		load_cmdl = true
	
	await get_tree().root.ready  # Await tree ready to be able to add error dialogs.
	
	# Guarantee a proper SVG text first, as the import warnings dialog
	# that might pop up from command line file opening is cancellable.
	if not Configs.svg_text.is_empty():
		apply_svg_text(Configs.svg_text)
	else:
		apply_svg_text(DEFAULT)
	
	if load_cmdl:
		FileUtils.apply_svg_from_path(cmdline_args[0])
	
	UR.clear_history()

func _exit_tree() -> void:
	UR.free()

# Syncs text to the elements.
func queue_update() -> void:
	_update.call_deferred()
	_update_pending = true

func queue_save() -> void:
	_save.call_deferred()
	_save_pending = true

func _update() -> void:
	if not _update_pending:
		return
	_update_pending = false
	text = SVGParser.root_to_text(root_element, Configs.savedata.editor_formatter)
	changed.emit()

func _save() -> void:
	if not _save_pending:
		return
	_save_pending = false
	
	unstable_text = ""
	var saved_text := Configs.svg_text
	if saved_text == text:
		return
	UR.create_action("")
	UR.add_do_property(Configs, "svg_text", text)
	UR.add_undo_property(Configs, "svg_text", saved_text)
	UR.add_do_property(self, "text", text)
	UR.add_undo_property(self, "text", saved_text)
	UR.commit_action()


func sync_elements() -> void:
	var text_to_parse := text if unstable_text.is_empty() else unstable_text
	var svg_parse_result := SVGParser.text_to_root(text_to_parse,
			Configs.savedata.editor_formatter)
	parsing_finished.emit(svg_parse_result.error)
	if svg_parse_result.error == SVGParser.ParseError.OK:
		text = unstable_text
		unstable_text = ""
		root_element = svg_parse_result.svg
		root_element.any_attribute_changed.connect(any_attribute_changed.emit)
		root_element.xnodes_added.connect(xnodes_added.emit)
		root_element.xnodes_deleted.connect(xnodes_deleted.emit)
		root_element.xnodes_moved_in_parent.connect(xnodes_moved_in_parent.emit)
		root_element.xnodes_moved_to.connect(xnodes_moved_to.emit)
		root_element.xnode_layout_changed.connect(xnode_layout_changed.emit)
		root_element.attribute_changed.connect(_on_root_attribute_changed)
		root_element.basic_xnode_text_changed.connect(basic_xnode_text_changed.emit)
		root_element.basic_xnode_rendered_text_changed.connect(
				basic_xnode_rendered_text_changed.emit)
		changed_unknown.emit()
		_update_current_size()


func _on_root_attribute_changed(attribute_name: String) -> void:
	if attribute_name in ["width", "height", "viewBox"]:
		_update_current_size()

func _update_current_size() -> void:
	if _current_size != root_element.get_size():
		_current_size = root_element.get_size()
		resized.emit()


func undo() -> void:
	if UR.has_undo():
		UR.undo()
		SVG.sync_elements()

func redo() -> void:
	if UR.has_redo():
		UR.redo()
		SVG.sync_elements()


func apply_svg_text(new_text: String, save := true) -> void:
	unstable_text = new_text
	sync_elements()
	if save:
		queue_save()

func optimize() -> void:
	SVG.root_element.optimize()
	SVG.queue_save()

func get_export_text() -> String:
	return SVGParser.root_to_text(root_element, Configs.savedata.export_formatter)
