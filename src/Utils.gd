class_name Utils extends RefCounted

# In my opinion, this is nicer than groups.
enum CustomNotification {
	LANGUAGE_CHANGED = 300,
	UI_SCALE_CHANGED = 301,
	THEME_CHANGED = 302,
	NUMBER_PRECISION_CHANGED = 303,
	HIGHLIGHT_COLORS_CHANGED = 304,
	BASIC_COLORS_CHANGED = 305,
	HANDLE_VISUALS_CHANGED = 306,
}

# Enum with values to be used for set_value() of attribute editors.
# REGULAR means that the attribute will update if the new value is different.
# INTERMEDIATE and FINAL cause the attribute update to have the corresponding sync mode.
# FINAL also causes the equivalence check to be skipped.
enum UpdateType {REGULAR, INTERMEDIATE, FINAL}

enum InteractionType {NONE = 0, HOVERED = 1, SELECTED = 2, HOVERED_SELECTED = 3}


static func is_string_upper(string: String) -> bool:
	return string.to_upper() == string

static func is_string_lower(string: String) -> bool:
	return string.to_lower() == string

static func get_file_name(string: String) -> String:
	return string.get_file().trim_suffix("." + string.get_extension())


# Resize the control to be resized automatically to its text width, up to a maximum.
# The property name defaults account for most controls that may need to use this.
static func set_max_text_width(control: Control, max_width: float, buffer: float,
text_property := "text", font_property := "font",
font_size_property := "font_size") -> void:
	control.custom_minimum_size.x = minf(control.get_theme_font(
			font_property).get_string_size(control.get(text_property),
			HORIZONTAL_ALIGNMENT_FILL, -1,
			control.get_theme_font_size(font_size_property)).x + buffer, max_width)


static func get_cubic_bezier_points(cp1: Vector2, cp2: Vector2, cp3: Vector2,
cp4: Vector2) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.add_point(cp1, Vector2(), cp2)
	curve.add_point(cp4, cp3)
	return curve.tessellate(6, 1)

static func get_quadratic_bezier_points(cp1: Vector2, cp2: Vector2,
cp3: Vector2) -> PackedVector2Array:
	return Utils.get_cubic_bezier_points(
			cp1, 2/3.0 * (cp2 - cp1), 2/3.0 * (cp2 - cp3), cp3)

# Ellipse parametric equation.
static func E(c: Vector2, r: Vector2, cosine: float, sine: float, t: float) -> Vector2:
	var xt := r.x * cos(t)
	var yt := r.y * sin(t)
	return c + Vector2(xt * cosine - yt * sine, xt * sine + yt * cosine)

# Ellipse parametric equation derivative (for tangents).
static func Et(r: Vector2, cosine: float, sine: float, t: float) -> Vector2:
	var xt := -r.x * sin(t)
	var yt := r.y * cos(t)
	return Vector2(xt * cosine - yt * sine, xt * sine + yt * cosine)


# [1] > [1, 2] > [1, 0] > [0]
static func compare_tids(tid1: PackedInt32Array, tid2: PackedInt32Array) -> bool:
	var smaller_tid_size := mini(tid1.size(), tid2.size())
	for i in smaller_tid_size:
		if tid1[i] < tid2[i]:
			return true
		elif tid1[i] > tid2[i]:
			return false
	return tid1.size() > smaller_tid_size

static func compare_tids_r(tid1: PackedInt32Array, tid2: PackedInt32Array) -> bool:
	return compare_tids(tid2, tid1)

# Indirect parent, i.e. ancestor. Passing the root tag as parent will return false.
static func is_tid_parent(parent: PackedInt32Array, child: PackedInt32Array) -> bool:
	if parent.is_empty():
		return false
	var parent_size := parent.size()
	if parent_size >= child.size():
		return false
	
	for i in parent_size:
		if parent[i] != child[i]:
			return false
	return true

static func is_tid_parent_or_self(parent: PackedInt32Array,
child: PackedInt32Array) -> bool:
	return is_tid_parent(parent, child) or parent == child

static func get_parent_tid(tid: PackedInt32Array) -> PackedInt32Array:
	var parent_tid := tid.duplicate()
	parent_tid.resize(tid.size() - 1)
	return parent_tid

static func are_tid_parents_same(tid1: PackedInt32Array, tid2: PackedInt32Array) -> bool:
	if tid1.size() != tid2.size():
		return false
	for i in tid1.size() - 1:
		if tid1[i] != tid2[i]:
			return false
	return true

# Filter out all descendants.
static func filter_descendant_tids(tids: Array[PackedInt32Array]) -> Array[PackedInt32Array]:
	var new_tids: Array[PackedInt32Array] = tids.duplicate()
	new_tids.sort_custom(Utils.compare_tids_r)
	# Linear scan to filter out the descendants.
	var last_accepted := new_tids[0]
	var i := 1
	while i < new_tids.size():
		var tid := new_tids[i]
		if Utils.is_tid_parent_or_self(last_accepted, tid):
			new_tids.remove_at(i)
		else:
			last_accepted = new_tids[i]
			i += 1
	return new_tids


static func is_event_drag(event: InputEvent) -> bool:
	return event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_LEFT

static func is_event_drag_start(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and\
			event.is_pressed()

static func is_event_drag_end(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and\
			event.is_released()

static func is_event_cancel(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cancel") or\
			event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT


# Used to somewhat prevent unwanted inputs from triggering tag drag & drop.
static func mouse_filter_pass_non_drag_events(event: InputEvent) -> Control.MouseFilter:
	return Control.MOUSE_FILTER_STOP if event is InputEventMouseMotion and\
			event.button_mask == MOUSE_BUTTON_MASK_LEFT else Control.MOUSE_FILTER_PASS

static func throw_mouse_motion_event(viewport: Viewport) -> void:
	var mouse_motion_event := InputEventMouseMotion.new()
	mouse_motion_event.position = viewport.get_mouse_position()
	Input.parse_input_event(mouse_motion_event)


static func get_last_dir() -> String:
	if GlobalSettings.save_data.last_used_dir.is_empty()\
	or not DirAccess.dir_exists_absolute(GlobalSettings.save_data.last_used_dir):
		return OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	else:
		return GlobalSettings.save_data.last_used_dir
