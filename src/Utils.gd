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


static func is_string_upper(string: String) -> bool:
	return string.to_upper() == string

static func is_string_lower(string: String) -> bool:
	return string.to_lower() == string

static func defocus_control_on_outside_click(control: Control, event: InputEvent) -> void:
	if (control.has_focus() and event is InputEventMouseButton and\
	not control.get_global_rect().has_point(event.position)):
		control.release_focus()

static func popup_under_control(popup: Popup, control: Control) -> void:
	var screen_h := control.get_viewport_rect().size.y
	var popup_pos := Vector2.ZERO
	var true_global_pos = control.global_position
	# Popup below if there's enough space or we're in the bottom half of the screen.
	if true_global_pos.y + control.size.y + popup.size.y < screen_h or\
	true_global_pos.y + control.size.y / 2 <= screen_h / 2.0:
		popup_pos.y = true_global_pos.y + control.size.y
	else:
		popup_pos.y = true_global_pos.y - popup.size.y
	# Horizontal alignment and other things.
	popup_pos.x = true_global_pos.x
	popup_pos += control.get_viewport().get_screen_transform().get_origin()
	popup.popup(Rect2(popup_pos, popup.size))

static func popup_under_control_centered(popup: Popup, control: Control) -> void:
	var screen_h := control.get_viewport_rect().size.y
	var popup_pos := Vector2.ZERO
	var true_global_pos = control.global_position
	# Popup below if there's enough space or we're in the bottom half of the screen.
	if true_global_pos.y + control.size.y + popup.size.y < screen_h or\
	true_global_pos.y + control.size.y / 2 <= screen_h / 2.0:
		popup_pos.y = true_global_pos.y + control.size.y
	else:
		popup_pos.y = true_global_pos.y - popup.size.y
	# Align horizontally and other things.
	popup_pos.x = true_global_pos.x - popup.size.x / 2.0 + control.size.x / 2
	popup_pos += control.get_viewport().get_screen_transform().get_origin()
	popup.popup(Rect2(popup_pos, popup.size))

static func popup_under_mouse(popup: Popup, mouse_pos: Vector2) -> void:
	popup.popup(Rect2(mouse_pos, popup.size))

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
	return not compare_tids(tid1, tid2)

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

static func get_parent_tid(tid: PackedInt32Array) -> PackedInt32Array:
	var parent_tid := tid.duplicate()
	parent_tid.resize(tid.size() - 1)
	return parent_tid

# If parent is moving children are also moving
static func filter_tids_remove_children(tids: Array[PackedInt32Array]) -> Array[PackedInt32Array]:
	var new_tids: Array[PackedInt32Array] = tids.duplicate()
	new_tids = new_tids.filter(func(tid:PackedInt32Array):
		var check_tid: PackedInt32Array = []
		for part in tid:
			check_tid.append(part)
			if ( check_tid in new_tids and not check_tid == tid
				and is_tid_parent(check_tid,tid)
			):
				return false
		return true
		)
	return new_tids

# [0] > [1] > [1, 2] > [2]
static func sort_tids(tids: Array[PackedInt32Array]) -> Array[PackedInt32Array]:
	var new_tids: Array[PackedInt32Array] = tids.duplicate()
	new_tids.sort_custom(Utils.compare_tids)
	return new_tids

static func get_viewbox_zoom(viewbox: Rect2, width: float, height: float) -> float:
	return minf(width / viewbox.size.x, height / viewbox.size.y)


static func is_event_drag(event: InputEvent) -> bool:
	return event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_LEFT

static func is_event_drag_start(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and\
			event.is_pressed()

static func is_event_drag_end(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and\
			event.is_released()


static func get_last_dir() -> String:
	if GlobalSettings.save_data.last_used_dir.is_empty()\
	or not DirAccess.dir_exists_absolute(GlobalSettings.save_data.last_used_dir):
		return OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	else:
		return GlobalSettings.save_data.last_used_dir
