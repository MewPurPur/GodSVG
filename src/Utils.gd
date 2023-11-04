class_name Utils extends RefCounted

static func is_string_upper(string: String) -> bool:
	return string.to_upper() == string

static func is_string_lower(string: String) -> bool:
	return string.to_lower() == string

static func defocus_control_on_outside_click(control: Control, event: InputEvent) -> void:
	if (control.has_focus() and event is InputEventMouseButton and\
	not control.get_global_rect().has_point(event.position)):
		control.release_focus()

static func calculate_popup_rect(button_global_pos: Vector2,
button_size: Vector2, popup_size: Vector2, align_center := false) -> Rect2:
	var screen_h: int =\
			ProjectSettings.get_setting("display/window/size/viewport_height", 640)
	var popup_pos := Vector2.ZERO
	# Popup below if there's enough space or we're in the bottom half of the screen.
	if button_global_pos.y + button_size.y + popup_size.y < screen_h or\
	button_global_pos.y + button_size.y / 2 <= screen_h / 2.0:
		popup_pos.y = button_global_pos.y + button_size.y
	else:
		popup_pos.y = button_global_pos.y - popup_size.y
	# Align horizontally.
	if align_center:
		popup_pos.x = button_global_pos.x - popup_size.x / 2 + button_size.x / 2
	else:
		popup_pos.x = button_global_pos.x
	return Rect2(popup_pos, popup_size)

static func get_cubic_bezier_points(cp1: Vector2, cp2: Vector2,
cp3: Vector2, cp4: Vector2) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.add_point(cp1, Vector2(), cp2)
	curve.add_point(cp4, cp3)
	return curve.tessellate(5, 2)

static func get_quadratic_bezier_points(cp1: Vector2, cp2: Vector2,
cp3: Vector2) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.add_point(cp1, Vector2(), 2/3.0 * (cp2 - cp1))
	curve.add_point(cp3, 2/3.0 * (cp2 - cp3))
	return curve.tessellate(5, 2)

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

# This function evaluates expressions even if "," or ";" is used as a decimal separator.
static func evaluate_numeric_expression(text: String) -> float:
	var expr := Expression.new()
	var err := expr.parse(text.replace(",", "."))
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	err = expr.parse(text.replace(";", "."))
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	err = expr.parse(text)
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	return NAN

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

# Indirect parent, i.e. ancestor.
static func is_tid_parent(parent: PackedInt32Array, child: PackedInt32Array) -> bool:
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
