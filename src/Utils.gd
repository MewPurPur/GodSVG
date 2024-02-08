class_name Utils extends RefCounted

const path_command_char_dict = {
	"M": "Move to", "L": "Line to", "H": "Horizontal Line to", "V": "Vertical Line to",
	"Z": "Close Path", "A": "Elliptical Arc to", "Q": "Quadratic Bezier to",
	"T": "Shorthand Quadratic Bezier to", "C": "Cubic Bezier to",
	"S": "Shorthand Cubic Bezier to"
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
text_property := &"text", font_property := &"font",
font_size_property := &"font_size") -> void:
	control.custom_minimum_size.x = minf(control.get_theme_font(
			font_property).get_string_size(control.get(text_property),
			HORIZONTAL_ALIGNMENT_FILL, -1,
			control.get_theme_font_size(font_size_property)).x + buffer, max_width)

# Should usually be the global rect of a control.
static func popup_under_rect(popup: Popup, rect: Rect2, viewport: Viewport) -> void:
	var screen_transform := viewport.get_screen_transform()
	var screen_h := viewport.get_visible_rect().size.y
	var popup_pos := Vector2.ZERO
	# Popup below if there's enough space or we're in the bottom half of the screen.
	if rect.position.y + rect.size.y + popup.size.y < screen_h or\
	rect.position.y + rect.size.y / 2 <= screen_h / 2.0:
		popup_pos.y = rect.position.y + rect.size.y
	else:
		popup_pos.y = rect.position.y - popup.size.y
	# Horizontal alignment and other things.
	popup_pos.x = rect.position.x
	popup_pos += screen_transform.get_origin() / screen_transform.get_scale()
	popup.popup(Rect2(popup_pos, popup.size))

# Should usually be the global rect of a control.
static func popup_under_rect_center(popup: Popup, rect: Rect2, viewport: Viewport) -> void:
	var screen_transform := viewport.get_screen_transform()
	var screen_h := viewport.get_visible_rect().size.y
	var popup_pos := Vector2.ZERO
	# Popup below if there's enough space or we're in the bottom half of the screen.
	if rect.position.y + rect.size.y + popup.size.y < screen_h or\
	rect.position.y + rect.size.y / 2 <= screen_h / 2.0:
		popup_pos.y = rect.position.y + rect.size.y
	else:
		popup_pos.y = rect.position.y - popup.size.y
	# Align horizontally and other things.
	popup_pos.x = rect.position.x - popup.size.x / 2.0 + rect.size.x / 2
	popup_pos += screen_transform.get_origin() / screen_transform.get_scale()
	popup.popup(Rect2(popup_pos, popup.size))

# Should usually be the global position of the mouse.
static func popup_under_pos(popup: Popup, pos: Vector2, viewport: Viewport) -> void:
	var screen_transform := viewport.get_screen_transform()
	pos += screen_transform.get_origin() / screen_transform.get_scale()
	popup.popup(Rect2(pos, popup.size))

static func create_btn(text: String, press_action: Callable, disabled := false,
icon: Texture2D = null) -> Button:
	var btn := Button.new()
	btn.text = text
	if icon != null:
		btn.icon = icon
	if disabled:
		btn.disabled = true
	else:
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(press_action)
	return btn

static func create_checkbox(text: String, toggle_action: Callable,
start_pressed: bool) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = text
	checkbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	checkbox.button_pressed = start_pressed
	checkbox.pressed.connect(toggle_action)
	return checkbox


static func get_cubic_bezier_points(cp1: Vector2, cp2: Vector2,
cp3: Vector2, cp4: Vector2) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.add_point(cp1, Vector2(), cp2)
	curve.add_point(cp4, cp3)
	return curve.tessellate(6, 1)

static func get_quadratic_bezier_points(cp1: Vector2, cp2: Vector2,
cp3: Vector2) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.add_point(cp1, Vector2(), 2/3.0 * (cp2 - cp1))
	curve.add_point(cp3, 2/3.0 * (cp2 - cp3))
	return curve.tessellate(6, 1)

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

# Used to somewhat prevent unwanted inputs from triggering tag drag & drop.
static func mouse_filter_pass_non_drag_events(event: InputEvent) -> Control.MouseFilter:
	return Control.MOUSE_FILTER_STOP if event is InputEventMouseMotion and\
			event.button_mask == MOUSE_BUTTON_MASK_LEFT else Control.MOUSE_FILTER_PASS


static func get_last_dir() -> String:
	if GlobalSettings.save_data.last_used_dir.is_empty()\
	or not DirAccess.dir_exists_absolute(GlobalSettings.save_data.last_used_dir):
		return OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	else:
		return GlobalSettings.save_data.last_used_dir
