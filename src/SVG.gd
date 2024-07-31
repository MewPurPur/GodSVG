# This singleton handles the two representations of the SVG:
# The SVG text, and the native ElementSVG representation.
extends Node

signal changed_unknown
signal resized

# These signals copy the ones in ElementRoot.
# ElementRoot is not persistent, while these signals can be connected to reliably.
signal any_attribute_changed(xid: PackedInt32Array)
signal elements_added(xids: Array[PackedInt32Array])
signal elements_deleted(xids: Array[PackedInt32Array])
signal elements_moved_in_parenet(parent_xid: PackedInt32Array, old_indices: Array[int])
signal elements_moved_to(xids: Array[PackedInt32Array], location: PackedInt32Array)
signal elements_layout_changed  # Emitted together with any of the above 4.

signal parsing_finished(error_id: SVGParser.ParseError)
signal text_changed

const DEFAULT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"></svg>'

var current_size := Vector2.ZERO

var update_pending := false
var save_pending := false

var text := ""

var root_element := ElementRoot.new()

var UR := UndoRedo.new()

func _ready() -> void:
	UR.version_changed.connect(_on_undo_redo)
	changed_unknown.connect(queue_update)
	elements_layout_changed.connect(queue_update)
	any_attribute_changed.connect(queue_update.unbind(1))
	
	var cmdline_args := OS.get_cmdline_args()
	var load_cmdl := false
	if not (OS.is_debug_build() and not OS.has_feature("template")) and\
	cmdline_args.size() >= 1:
		load_cmdl = true
	
	await get_tree().root.ready  # Await tree ready to be able to add error dialogs.
	
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


func queue_update() -> void:
	update_pending = true

func queue_save() -> void:
	save_pending = true

func _process(_delta: float) -> void:
	if update_pending:
		update_text()
		update_pending = false
	if save_pending:
		save_text()
		save_pending = false


func sync_elements() -> void:
	var svg_parse_result := SVGParser.text_to_root(text)
	parsing_finished.emit(svg_parse_result.error)
	if svg_parse_result.error == SVGParser.ParseError.OK:
		root_element = svg_parse_result.svg
		root_element.any_attribute_changed.connect(any_attribute_changed.emit)
		root_element.elements_added.connect(elements_added.emit)
		root_element.elements_deleted.connect(elements_deleted.emit)
		root_element.elements_moved_in_parenet.connect(elements_moved_in_parenet.emit)
		root_element.elements_moved_to.connect(elements_moved_to.emit)
		root_element.elements_layout_changed.connect(elements_layout_changed.emit)
		root_element.attribute_changed.connect(_on_root_attribute_changed)
		changed_unknown.emit()
		update_current_size()


func _on_root_attribute_changed(attribute_name: String) -> void:
	if attribute_name in ["width", "height", "viewBox"]:
		update_current_size()

func update_current_size() -> void:
	if current_size != root_element.get_size():
		current_size = root_element.get_size()
		resized.emit()

func update_text() -> void:
	set_text(SVGParser.root_to_text(root_element))

func set_text(new_text: String) -> void:
	text = new_text
	text_changed.emit()

func save_text() -> void:
	var saved_text := GlobalSettings.save_data.svg_text
	if saved_text == text:
		return
	UR.create_action("")
	UR.add_do_property(GlobalSettings.save_data, "svg_text", text)
	UR.add_undo_property(GlobalSettings.save_data, "svg_text", saved_text)
	UR.add_do_property(self, "text", text)
	UR.add_undo_property(self, "text", saved_text)
	UR.commit_action()

func undo() -> void:
	if UR.has_undo():
		UR.undo()
		sync_elements()

func redo() -> void:
	if UR.has_redo():
		UR.redo()
		sync_elements()

func _on_undo_redo() -> void:
	GlobalSettings.modify_save_data("svg_text", text)

func apply_svg_text(svg_text: String) -> void:
	set_text(svg_text)
	save_text()
	sync_elements()

func optimize() -> void:
	SVG.root_element.optimize()
	SVG.queue_save()
