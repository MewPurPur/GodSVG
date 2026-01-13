@abstract class_name Utils

const IMAGE_FORMATS: PackedStringArray = ["png", "jpg", "jpeg", "webp", "svg"]
const DYNAMIC_FONT_FORMATS: PackedStringArray = ["ttf", "otf", "woff", "woff2", "pfb", "pfm"]

const MAX_NUMERIC_PRECISION = 6
const MAX_ANGLE_PRECISION = 4

enum InteractionType {NONE = 0, HOVERED = 1, SELECTED = 2, HOVERED_SELECTED = 3}
enum LayoutPart {NONE, CODE_EDITOR, INSPECTOR, VIEWPORT, PREVIEWS}

const _LAYOUT_ICONS: Dictionary[LayoutPart, Texture2D] = {
	LayoutPart.CODE_EDITOR: preload("res://assets/icons/CodeEditor.svg"),
	LayoutPart.INSPECTOR: preload("res://assets/icons/Inspector.svg"),
	LayoutPart.VIEWPORT: preload("res://assets/icons/Viewport.svg"),
	LayoutPart.PREVIEWS: preload("res://assets/icons/Previews.svg"),
}
const _LAYOUT_PLACEHOLDER_ICON = preload("res://assets/icons/Placeholder.svg")

static func get_layout_part_icon(layout_part: LayoutPart) -> Texture2D:
	return _LAYOUT_ICONS.get(layout_part, _LAYOUT_PLACEHOLDER_ICON)


static func num_simple(number: float, decimals := -1) -> String:
	return String.num(number, decimals).trim_suffix(".0")

static func is_string_upper(string: String) -> bool:
	return string.to_upper() == string

static func is_string_lower(string: String) -> bool:
	return string.to_lower() == string

static func get_file_name(string: String) -> String:
	return string.get_file().trim_suffix("." + string.get_extension())

static func get_lowercase_extension(string: String) -> String:
	return string.get_extension().to_lower()

## Method for showing the file path without stuff like "/home/mewpurpur/".
static func simplify_file_path(file_path: String) -> String:
	var home_dir := get_home_dir()
	if file_path.begins_with(home_dir):
		return "~/" + file_path.trim_prefix(home_dir).trim_prefix("/").trim_prefix("\\")
	return file_path

## Returns the directory considered home, such as "/home/mewpurpur/".
static func get_home_dir() -> String:
	return OS.get_environment("USERPROFILE" if OS.get_name() == "Windows" else "HOME")


# Resizes the control to be resized automatically to its text width, up to a maximum.
# The property name defaults account for most controls that may need to use this.
static func set_max_text_width(control: Control, max_width: float, buffer: float,
text_property := "text", font_property := "font", font_size_property := "font_size") -> void:
	control.custom_minimum_size.x = minf(control.get_theme_font(font_property).get_string_size(control.get(text_property),
			HORIZONTAL_ALIGNMENT_FILL, -1, control.get_theme_font_size(font_size_property)).x + buffer, max_width)


static func get_cubic_bezier_points(cp1: Vector2, cp2: Vector2, cp3: Vector2, cp4: Vector2) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.add_point(cp1, Vector2(), cp2)
	curve.add_point(cp4, cp3)
	return curve.tessellate(6, 1)

static func get_quadratic_bezier_points(cp1: Vector2, cp2: Vector2, cp3: Vector2) -> PackedVector2Array:
	return Utils.get_cubic_bezier_points(cp1, 2/3.0 * (cp2 - cp1), 2/3.0 * (cp2 - cp3), cp3)

# Calculate quadratic bezier point coordinate along an axis.
static func quadratic_bezier_point(p0: float, p1: float, p2: float, t: float) -> float:
	var u := 1.0 - t
	return u * u * p0 + 2 * u * t * p1 + t * t * p2

# Calculate cubic bezier point coordinate along an axis.
static func cubic_bezier_point(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	var u := 1.0 - t
	return u * u * u * p0 + 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t * p3

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


static func is_event_drag(event: InputEvent) -> bool:
	return event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_LEFT

static func is_event_drag_start(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()

static func is_event_drag_end(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released()

static func is_event_drag_cancel(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cancel") or event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT

# Used to somewhat prevent unwanted inputs from triggering XNode drag & drop.
static func mouse_filter_pass_non_drag_events(event: InputEvent) -> Control.MouseFilter:
	return Control.MOUSE_FILTER_STOP if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT else Control.MOUSE_FILTER_PASS


static func has_clipboard_web_safe() -> bool:
	if OS.has_feature("web"):
		return false
	return DisplayServer.clipboard_has()

static func get_clipboard_web_safe() -> String:
	if OS.has_feature("web"):
		return ""
	return DisplayServer.clipboard_get()

static func has_clipboard_image_web_safe() -> bool:
	if OS.has_feature("web"):
		return false
	return DisplayServer.clipboard_has_image()


static func vector2_min_element(vector: Vector2) -> float:
	return vector[vector.min_axis_index()]


static func vector3_min_element(vector: Vector3) -> float:
	return vector[vector.min_axis_index()]


static func vector4_min_element(vector: Vector4) -> float:
	return vector[vector.min_axis_index()]


static func vector2_max_element(vector: Vector2) -> float:
	return vector[vector.max_axis_index()]


static func vector3_max_element(vector: Vector3) -> float:
	return vector[vector.max_axis_index()]


static func vector4_max_element(vector: Vector4) -> float:
	return vector[vector.max_axis_index()]


static func vector2i_min_element(vector: Vector2i) -> int:
	return vector[vector.min_axis_index()]


static func vector3i_min_element(vector: Vector3i) -> int:
	return vector[vector.min_axis_index()]


static func vector4i_min_element(vector: Vector4i) -> int:
	return vector[vector.min_axis_index()]


static func vector2i_max_element(vector: Vector2i) -> int:
	return vector[vector.max_axis_index()]


static func vector3i_max_element(vector: Vector3i) -> int:
	return vector[vector.max_axis_index()]


static func vector4i_max_element(vector: Vector4i) -> int:
	return vector[vector.max_axis_index()]
