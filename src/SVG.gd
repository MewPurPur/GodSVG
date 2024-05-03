# This singleton handles the two representations of the SVG:
# The SVG text, and the native TagSVG representation.
extends Node

# These are all attributes in RootTag. The RootTag is constantly changed,
# but it connects to these signals, so other parts of the editor can connect to them.
signal attribute_changed(undo_redo: bool)
signal child_attribute_changed(undo_redo: bool)
signal changed_unknown
signal tags_added(tids: Array[PackedInt32Array])
signal tags_deleted(tids: Array[PackedInt32Array])
signal tags_moved_in_parent(parent_tid: PackedInt32Array, old_indices: Array[int])
signal tags_moved_to(tids: Array[PackedInt32Array], location: PackedInt32Array)
signal tag_layout_changed  # Emitted together with any of the above 5.

signal resized
signal parsing_finished(error_id: SVGParser.ParseError)
signal svg_text_changed

const AlertDialog := preload("res://src/ui_parts/alert_dialog.tscn")
const ImportWarningDialog = preload("res://src/ui_parts/import_warning_dialog.tscn")

const DEFAULT = '<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg"></svg>'

var text := "":
	set(value):
		text = value
		svg_text_changed.emit()

var root_tag := TagSVG.new()

var UR := UndoRedo.new()

var size := Vector2.INF:
	set(value):
		if size != value:
			size = value
			resized.emit()

func _ready() -> void:
	UR.version_changed.connect(_on_undo_redo)
	changed_unknown.connect(update_text.bind(false))
	attribute_changed.connect(update_text)
	child_attribute_changed.connect(update_text)
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
		apply_svg_from_path(cmdline_args[0])
	
	UR.clear_history()


func update_tags() -> void:
	var svg_parse_result := SVGParser.text_to_svg(text)
	parsing_finished.emit(svg_parse_result.error)
	if svg_parse_result.error == SVGParser.ParseError.OK:
		root_tag = svg_parse_result.svg
		root_tag.attribute_changed.connect(emit_attribute_changed)

func emit_attribute_changed() -> void:
	attribute_changed.emit()


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
	SVG.root_tag = SVG.root_tag.duplicate()


func apply_svg_from_path(path: String) -> int:
	var svg_file := FileAccess.open(path, FileAccess.READ)
	var error := ""
	var extension := path.get_extension()
	
	GlobalSettings.modify_save_data("last_used_dir", path.get_base_dir())
	
	if extension.is_empty():
		error = "The file extension is empty. Only \"svg\" files are supported."
	elif extension == "tscn":
		return ERR_FILE_CANT_OPEN
	elif extension != "svg":
		error = tr("\"{passed_extension}\" is a unsupported file extension. Only \"svg\" files are supported.").format({"passed_extension": extension})
	elif svg_file == null:
		error = "The file couldn't be opened.\nTry checking the file path, ensure that the file is not deleted, or choose a different file."
	
	if not error.is_empty():
		var alert_dialog := AlertDialog.instantiate()
		HandlerGUI.add_overlay(alert_dialog)
		alert_dialog.setup(error, "Alert!", 280.0)
		return ERR_FILE_CANT_OPEN
	
	var svg_text := svg_file.get_as_text()
	var warning_panel := ImportWarningDialog.instantiate()
	warning_panel.imported.connect(FileUtils.finish_import.bind(svg_text, path))
	warning_panel.set_svg(svg_text)
	HandlerGUI.add_overlay(warning_panel)
	return OK

func apply_svg_text(svg_text: String,) -> void:
	text = svg_text
	GlobalSettings.modify_save_data("svg_text", text)
	update_tags()


func get_all_tids() -> Array[PackedInt32Array]:
	var tids: Array[PackedInt32Array] = []
	var unchecked_tids: Array[PackedInt32Array] = []
	for idx in get_child_count():
		unchecked_tids.append(PackedInt32Array([idx]))
	
	while not unchecked_tids.is_empty():
		var checked_tid: PackedInt32Array = unchecked_tids.pop_back()
		var checked_tag: Tag = get_tag(checked_tid)
		for idx in checked_tag.get_child_count():
			var new_tid := checked_tid.duplicate()
			new_tid.append(idx)
			unchecked_tids.append(new_tid)
		tids.append(checked_tid)
	return tids

func get_tag(tid: PackedInt32Array) -> Tag:
	var current_tag := root_tag
	for idx in tid:
		if idx >= current_tag.child_tags.size():
			return null
		current_tag = current_tag.child_tags[idx]
	return current_tag


func add_tag(new_tag: Tag, new_tid: PackedInt32Array) -> void:
	var parent_tid := Utils.get_parent_tid(new_tid)
	root_tag.get_tag(parent_tid).child_tags.insert(new_tid[-1], new_tag)
	new_tag.attribute_changed.connect(emit_child_attribute_changed)
	var new_tid_array: Array[PackedInt32Array] = [new_tid]
	tags_added.emit(new_tid_array)
	tag_layout_changed.emit()

func delete_tags(tids: Array[PackedInt32Array]) -> void:
	if tids.is_empty():
		return
	
	tids = Utils.filter_descendant_tids(tids)
	for tid in tids:
		var parent_tid := Utils.get_parent_tid(tid)
		var parent_tag := get_tag(parent_tid)
		if parent_tag != null:
			var tag_idx := tid[-1]
			if tag_idx < parent_tag.get_child_count():
				parent_tag.child_tags.remove_at(tag_idx)
	tags_deleted.emit(tids)
	tag_layout_changed.emit()

# Moves tags up or down, not to an arbitrary position.
func move_tags_in_parent(tids: Array[PackedInt32Array], down: bool) -> void:
	var signal_args := root_tag.move_tags_in_parent(tids, down)
	if not signal_args.is_empty():
		tags_moved_in_parent.emit(signal_args[0], signal_args[1])
		tag_layout_changed.emit()

# Moves tags to an arbitrary position. The first moved tag will move to the location TID.
func move_tags_to(tids: Array[PackedInt32Array], location: PackedInt32Array) -> void:
	var signal_args := root_tag.move_tags_to(tids, location)
	if not signal_args.is_empty():
		tags_moved_to.emit(signal_args[0], signal_args[1])
		tag_layout_changed.emit()

# Duplicates tags and puts them below.
func duplicate_tags(tids: Array[PackedInt32Array]) -> void:
	var tids_added := root_tag.duplicate_tags(tids)
	tags_added.emit(tids_added)
	tag_layout_changed.emit()

func replace_tag(tid: PackedInt32Array, new_tag: Tag) -> void:
	root_tag.replace_tag(tid, new_tag)
	tag_layout_changed.emit()

func emit_child_attribute_changed() -> void:
	child_attribute_changed.emit()


# Optimizes the SVG text in more ways than what autoformatting allows.
# The return value is true if the SVG can be optimized, otherwise false.
# If apply_changes is false, you'll only get the return value.
func optimize(not_applied := false) -> bool:
	var svg_tag: TagSVG= root_tag.duplicate()  # Only needed if changes are applied. Welp.
	for tid in svg_tag.get_all_tids():
		var tag := svg_tag.get_tag(tid)
		match tag.name:
			"ellipse":
				# If possible, turn ellipses into circles.
				if tag.can_replace("circle"):
					if not_applied:
						return true
					svg_tag.replace_tag(tid, get_tag(tid).get_replacement("circle"))
			"line":
				# Turn lines into paths.
				if not_applied:
					return true
				svg_tag.replace_tag(tid, get_tag(tid).get_replacement("path"))
			"rect":
				# If possible, turn rounded rects into circles or ellipses.
				if tag.can_replace("circle"):
					if not_applied:
						return true
					svg_tag.replace_tag(tid, get_tag(tid).get_replacement("circle"))
				elif tag.can_replace("ellipse"):
					if not_applied:
						return true
					svg_tag.replace_tag(tid, get_tag(tid).get_replacement("ellipse"))
				elif tag.attributes.rx.get_num() == 0 and tag.attributes.ry.get_num() == 0:
					# If the rectangle is not rounded, turn it into a path.
					if not_applied:
						return true
					svg_tag.replace_tag(tid, get_tag(tid).get_replacement("path"))
			"path":
				var pathdata: AttributePath = tag.attributes.d
				# Simplify A rotation to 0 degrees for circular arcs.
				for cmd_idx in pathdata.get_command_count():
					var command := pathdata.get_command(cmd_idx)
					var cmd_char := command.command_char
					if cmd_char in "Aa" and command.rx == command.ry and command.rot != 0:
						if not_applied:
							return true
						pathdata.set_command_property(cmd_idx, "rot", 0)
				# Replace L with H or V when possible.
				for cmd_idx in pathdata.get_command_count():
					var command := pathdata.get_command(cmd_idx)
					var cmd_char := command.command_char
					if cmd_char == "l":
						if command.x == 0:
							if not_applied:
								return true
							pathdata.convert_command(cmd_idx, "v")
						elif command.y == 0:
							if not_applied:
								return true
							pathdata.convert_command(cmd_idx, "h")
					elif cmd_char == "L":
						if command.x == command.start.x:
							if not_applied:
								return true
							pathdata.convert_command(cmd_idx, "V")
						elif command.y == command.start.y:
							if not_applied:
								return true
							pathdata.convert_command(cmd_idx, "H")
	return false
