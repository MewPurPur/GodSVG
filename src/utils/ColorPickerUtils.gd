class_name ColorPickerUtils extends RefCounted

# The color picker uses a 64-bit color because the precision is necessary for the approach of
# things like keeping colors almost-grayscale-but-not-quite to preserve their hue.
class PreciseColor:
	var paint: String
	var r: float
	var g: float
	var b: float
	var a: float
	
	func _init(new_r: float, new_g: float, new_b: float, new_a: float) -> void:
		r = new_r
		g = new_g
		b = new_b
		a = new_a
		paint = Color(r, g, b, a).to_html(a != 1.0)
	
	static func from_color(color: Color) -> PreciseColor:
		return PreciseColor.new(color.r, color.g, color.b, color.a)
	
	static func from_array(array: PackedFloat64Array) -> PreciseColor:
		return PreciseColor.new(array[0], array[1], array[2], array[3])
	
	func duplicate() -> PreciseColor:
		var new_color := PreciseColor.new(r, g, b, a)
		new_color.paint = paint
		return new_color
	
	func copy_values_from(color: PreciseColor) -> void:
		r = color.r
		g = color.g
		b = color.b
		a = color.a
		calibrate_paint()
	
	func _to_string() -> String:
		return "PreciseColor(%s, %s, %s, %s)" % [r, g, b, a]
	
	func to_color() -> Color:
		return Color(r, g, b, a)
	
	func to_array() -> PackedFloat64Array:
		return PackedFloat64Array([r, g, b, a])
	
	func equals(color: PreciseColor) -> bool:
		return r == color.r and g == color.g and b == color.b and a == color.a
	
	func set_paint(new_paint: String) -> void:
		paint = new_paint
		if Color.html_is_valid(new_paint):
			var color := Color.html(new_paint)
			r = color.r
			g = color.g
			b = color.b
			a = color.a
			shift_hsv()
	
	func set_hue(h: float, update_paint := true) -> void:
		var s := get_saturation()
		var v := get_value()
		var h_adj := fposmod(h, 1.0) * 6.0
		var i := int(floor(h_adj))
		var f := h_adj - float(i)
		var p := v * (1.0 - s)
		var q := v * (1.0 - s * f)
		var t := v * (1.0 - s * (1.0 - f))
		match i:
			0: r = v; g = t; b = p
			1: r = q; g = v; b = p
			2: r = p; g = v; b = t
			3: r = p; g = q; b = v
			4: r = t; g = p; b = v
			_: r = v; g = p; b = q
		if update_paint:
			calibrate_paint()
	
	func set_saturation(s: float, update_paint := true) -> void:
		var v := get_value()
		var new_s := clampf(s, 0.0, 1.0)
		
		if new_s <= 0.0:
			r = v
			g = v
			b = v
			return
		
		var h_adj := get_hue() * 6.0
		var i := int(floor(h_adj))
		var f := h_adj - float(i)
		
		var p := v * (1.0 - new_s)
		var q := v * (1.0 - new_s * f)
		var t := v * (1.0 - new_s * (1.0 - f))
		
		match i:
			0: r = v; g = t; b = p
			1: r = q; g = v; b = p
			2: r = p; g = v; b = t
			3: r = p; g = q; b = v
			4: r = t; g = p; b = v
			_: r = v; g = p; b = q
		if update_paint:
			calibrate_paint()
	
	func set_value(v: float, update_paint := true) -> void:
		var s := get_saturation()
		var new_v := maxf(v, 0.0)
		
		if s <= 0.0:
			r = new_v
			g = new_v
			b = new_v
			return
		
		var h_adj := get_hue() * 6.0
		var i := int(floor(h_adj))
		var f := h_adj - float(i)
		
		var p := new_v * (1.0 - s)
		var q := new_v * (1.0 - s * f)
		var t := new_v * (1.0 - s * (1.0 - f))
		
		match i:
			0: r = new_v; g = t; b = p
			1: r = q; g = new_v; b = p
			2: r = p; g = new_v; b = t
			3: r = p; g = q; b = new_v
			4: r = t; g = p; b = new_v
			_: r = new_v; g = p; b = q
		if update_paint:
			calibrate_paint()
	
	func shift_hsv() -> void:
		set_hue(clampf(get_hue(), 0.0, 0.9999), false)
		set_value(clampf(get_value(), 0.0001, 1.0), false)
		set_saturation(clampf(get_saturation(), 0.0001, 1.0), false)
		calibrate_paint()
	
	func get_hue() -> float:
		var max_val := maxf(r, maxf(g, b))
		var min_val := minf(r, minf(g, b))
		var delta := max_val - min_val
		if delta <= 0.0:
			return 0.0
		
		var h := 0.0
		if max_val == r:
			h = (g - b) / delta
		elif max_val == g:
			h = 2.0 + (b - r) / delta
		else:
			h = 4.0 + (r - g) / delta
		return fposmod(h/6, 1.0)
	
	func get_saturation() -> float:
		var max_val := maxf(r, maxf(g, b))
		var min_val := minf(r, minf(g, b))
		if max_val <= 0.0:
			return 0.0
		return clampf((max_val - min_val) / max_val, 0.0, 1.0)
	
	func get_value() -> float:
		return maxf(r, maxf(g, b))
	
	func get_luminance_imprecise() -> float:
		return Color(r, g, b).get_luminance()
	
	# Removing the saturation and hue clamping fixes paint conversion in edge cases.
	# e.g., H = 0.0001, S = 0.0001, V = 0.5 --> Color(0.5, 0.4999, 0.4999) --> "807f7f".
	func calibrate_paint() -> void:
		var color := duplicate()
		color.set_saturation(snappedf(get_saturation(), 1/1600.0), false)
		color.set_hue(snappedf(get_hue(), 1/5760.0), false)
		paint = color.to_color().to_html(a != 1.0)

class ColorConfig:
	# "Initial" variables store what the color string was when the color picker was opened.
	# "Backup" variables store the old color when using keywords or starting a dragging operation.
	var color: ColorPickerUtils.PreciseColor  # Current paint.
	var initial_color: ColorPickerUtils.PreciseColor  # The paint when the color picker was opened.
	var backup_color: ColorPickerUtils.PreciseColor  # The paint before starting a dragging operation.
	signal color_changed
	var undo_redo := UndoRedoRef.new()
	
	func _set_color(new_paint: String, new_color_array: PackedFloat64Array) -> void:
		color = ColorPickerUtils.PreciseColor.from_array(new_color_array)
		color.paint = new_paint
		backup_color.copy_values_from(color)
		backup_color.paint = new_paint
		color_changed.emit()
	
	func _set_color_paint(new_paint: String) -> void:
		color.set_paint(new_paint)
		color_changed.emit()
	
	func set_color_to_string(new_paint: String) -> void:
		new_paint = new_paint.strip_edges()
		if color.paint.strip_edges() == new_paint:
			return
		undo_redo.create_action()
		undo_redo.add_do_method(_set_color_paint.bind(new_paint))
		undo_redo.add_undo_method(_set_color_paint.bind(color.paint))
		undo_redo.commit_action()
	
	func register_visual_change() -> void:
		if Color.html_is_valid(color.paint) and color.equals(backup_color):
			return
		undo_redo.create_action()
		undo_redo.add_do_method(_set_color.bind(color.paint, color.to_array()))
		undo_redo.add_undo_method(_set_color.bind(backup_color.paint, backup_color.to_array()))
		undo_redo.commit_action()

enum PickerShape {HS_V_CIRCLE, HS_L_CIRCLE, SV_H_SQUARE, SL_H_SQUARE, HL_S_SQUARE, NORMAL_MAP}
enum ColorModel {RGB, HSV, HSL}
enum PickerGeometricShape {CIRCLE_AND_BAR, SQUARE_AND_BAR}

static func color_model_to_string(model: ColorModel) -> String:
	# These color models have somewhat common abbreviations in like three languages out there.
	# But people understand and often even prefer the English version. Won't be making these translatable.
	match model:
		ColorModel.RGB: return "RGB"
		ColorModel.HSV: return "HSV"
		ColorModel.HSL: return "HSL"
	return ""

static func picker_shape_to_string(shape: PickerShape) -> String:
	match shape:
		PickerShape.HS_V_CIRCLE: return "HS+V Circle"
		PickerShape.HS_L_CIRCLE: return "HS+L Circle"
		PickerShape.SV_H_SQUARE: return "SV+H Square"
		PickerShape.SL_H_SQUARE: return "SL+H Square"
		PickerShape.HL_S_SQUARE: return "HL+S Square"
		PickerShape.NORMAL_MAP: return "Normal Circle"
	return ""

static func get_current_picker_shape_geometric_shape() -> PickerGeometricShape:
	return picker_shape_get_geometric_shape(Configs.savedata.color_picker_current_shape)

static func picker_shape_get_geometric_shape(shape: PickerShape) -> PickerGeometricShape:
	match shape:
		PickerShape.SV_H_SQUARE, PickerShape.SL_H_SQUARE, PickerShape.HL_S_SQUARE: return PickerGeometricShape.SQUARE_AND_BAR
	return PickerGeometricShape.CIRCLE_AND_BAR

static func picker_shape_to_icon(shape: PickerShape) -> Texture2D:
	match picker_shape_get_geometric_shape(shape):
		PickerGeometricShape.SQUARE_AND_BAR: return preload("res://assets/icons/SquareAndSlider.svg")
	return preload("res://assets/icons/CircleAndSlider.svg")

static func get_channel_letter(channel_index: int) -> String:
	if channel_index == 3:
		return "A"
	match Configs.savedata.color_picker_current_model:
		ColorModel.RGB: return "RGB"[channel_index]
		ColorModel.HSV: return "HSV"[channel_index]
		ColorModel.HSL: return "HSL"[channel_index]
	return ""

static func get_channel_offset(color: PreciseColor, channel_index: int) -> float:
	return get_channel_offset_for_model(color, channel_index, Configs.savedata.color_picker_current_model)

static func get_channel_offset_for_model(color: PreciseColor, channel_index: int, color_model: ColorModel) -> float:
	if channel_index == 3:
		return color.a
	match color_model:
		ColorModel.RGB:
			match channel_index:
				0: return color.r
				1: return color.g
				2: return color.b
		ColorModel.HSV:
			match channel_index:
				0: return color.get_hue()
				1: return color.get_saturation()
				2: return color.get_value()
		ColorModel.HSL:
			match channel_index:
				0: return color.get_hue()
				1:
					var max_val := maxf(color.r, maxf(color.g, color.b))
					var min_val := minf(color.r, minf(color.g, color.b))
					return (max_val - min_val) / (1.0 - absf(max_val + min_val - 1.0))
				2: return (maxf(color.r, maxf(color.g, color.b)) + minf(color.r, minf(color.g, color.b))) / 2.0
	return 0.0

static func get_channel_fidelity(channel_index: int) -> int:
	if channel_index == 3:
		return 255
	match Configs.savedata.color_picker_current_model:
		ColorModel.RGB: return 255
		ColorModel.HSV, ColorModel.HSL: return 360 if channel_index == 0 else 100
	return 1

static func set_channel_offset(color: PreciseColor, channel_index: int, offset: float) -> void:
	set_channel_offset_for_model(color, channel_index, offset, Configs.savedata.color_picker_current_model)

static func set_channel_offset_for_model(color: PreciseColor, channel_index: int, offset: float, color_model: ColorModel) -> void:
	if channel_index == 3:
		color.a = clampf(offset, 0.0, 1.0)
	
	match color_model:
		ColorModel.RGB:
			match channel_index:
				0: color.r = clampf(offset, 0.0, 1.0)
				1: color.g = clampf(offset, 0.0, 1.0)
				2: color.b = clampf(offset, 0.0, 1.0)
		ColorModel.HSV:
			match channel_index:
				0: color.set_hue(clampf(offset, 0.0, 0.9999))
				1: color.set_saturation(clampf(offset, 0.0001, 1.0))
				2: color.set_value(clampf(offset, 0.0001, 1.0))
		ColorModel.HSL:
			match channel_index:
				0: color.set_hue(clampf(offset, 0.0, 0.9999))
				1, 2:
					var s := clampf(get_channel_offset_for_model(color, 1, color_model) if channel_index == 2 else offset, 0.0001, 1.0)
					var l := clampf(get_channel_offset_for_model(color, 2, color_model) if channel_index == 1 else offset, 0.0001, 0.9999)
					
					var c := (1.0 - absf(2.0 * l - 1.0)) * s
					var hp := color.get_hue() * 6
					var x := c * (1.0 - absf(fposmod(hp, 2.0) - 1.0))
					var m := l - c * 0.5
					
					var r1 := 0.0
					var g1 := 0.0
					var b1 := 0.0
					match int(hp):
						0: r1 = c; g1 = x
						1: r1 = x; g1 = c
						2: g1 = c; b1 = x
						3: g1 = x; b1 = c
						4: r1 = x; b1 = c
						_: r1 = c; b1 = x
					
					color.r = clampf(r1 + m, 0.0, 1.0)
					color.g = clampf(g1 + m, 0.0, 1.0)
					color.b = clampf(b1 + m, 0.0, 1.0)

static func get_primary_slider_offset(color: PreciseColor) -> float:
	match Configs.savedata.color_picker_current_shape:
		PickerShape.HS_V_CIRCLE: return get_channel_offset_for_model(color, 2, ColorModel.HSV)
		PickerShape.HS_L_CIRCLE: return get_channel_offset_for_model(color, 2, ColorModel.HSL)
		PickerShape.HL_S_SQUARE: return get_channel_offset_for_model(color, 1, ColorModel.HSL)
		PickerShape.SV_H_SQUARE, PickerShape.SL_H_SQUARE: return color.get_hue()
		PickerShape.NORMAL_MAP:
			var n = Vector3(color.r * 2 - 1, color.g * 2 - 1, color.b * 2 - 1)
			return Vector2(n.x, n.y).length()
	return 0.0

static func set_primary_slider_offset(color: PreciseColor, offset: float) -> void:
	match Configs.savedata.color_picker_current_shape:
		PickerShape.HS_V_CIRCLE: set_channel_offset_for_model(color, 2, offset, ColorModel.HSV)
		PickerShape.HS_L_CIRCLE: set_channel_offset_for_model(color, 2, offset, ColorModel.HSL)
		PickerShape.HL_S_SQUARE: set_channel_offset_for_model(color, 1, offset, ColorModel.HSL)
		PickerShape.SV_H_SQUARE, PickerShape.SL_H_SQUARE: set_channel_offset_for_model(color, 0, offset, ColorModel.HSV)
		PickerShape.NORMAL_MAP:
			var n := Vector3(color.r * 2.0 - 1.0, color.g * 2.0 - 1.0, color.b * 2.0 - 1.0)
			var dir = Vector2(n.x, n.y)
			if dir.length() > 0.0:
				dir = dir.normalized()
			var p = dir * clampf(offset, 0.0001, 0.9999)
			var z = sqrt(maxf(0.0, 1.0 - p.x * p.x - p.y * p.y))
			var v = Vector3(p.x, p.y, z)
			color.r = v.x * 0.5 + 0.5
			color.g = v.y * 0.5 + 0.5
			color.b = v.z * 0.5 + 0.5

static func set_color_area_coordinates(color: PreciseColor, coordinates: Vector2) -> void:
	# Unique case.
	match Configs.savedata.color_picker_current_shape:
		PickerShape.NORMAL_MAP:
			var p := coordinates * 2 - Vector2(1, 1)
			p.y = -p.y
			if p.length() > 1.0:
				p = p.normalized()
			var z := sqrt(maxf(0.0, 1.0 - p.x * p.x - p.y * p.y))
			var n := Vector3(p.x, p.y, z)
			color.r = n.x * 0.5 + 0.5
			color.g = n.y * 0.5 + 0.5
			color.b = n.z * 0.5 + 0.5
			return
	
	# Don't clamp coordinates, this allows keyboard navigation to overextend and make it easier to snap to the right value at edges.
	var channel1_index: int
	var channel2_index: int
	var model: ColorModel
	
	match Configs.savedata.color_picker_current_shape:
		PickerShape.HS_V_CIRCLE:
			channel1_index = 0
			channel2_index = 1
			model = ColorModel.HSV
		PickerShape.HS_L_CIRCLE:
			channel1_index = 0
			channel2_index = 1
			model = ColorModel.HSL
		PickerShape.SV_H_SQUARE:
			channel1_index = 1
			channel2_index = 2
			model = ColorModel.HSV
		PickerShape.SL_H_SQUARE:
			channel1_index = 1
			channel2_index = 2
			model = ColorModel.HSL
		PickerShape.HL_S_SQUARE:
			channel1_index = 0
			channel2_index = 2
			model = ColorModel.HSL
	
	match ColorPickerUtils.get_current_picker_shape_geometric_shape():
		PickerGeometricShape.CIRCLE_AND_BAR:
			ColorPickerUtils.set_channel_offset_for_model(color, channel1_index, fposmod(Vector2(0.5, 0.5).angle_to_point(coordinates), TAU) / TAU, model)
			ColorPickerUtils.set_channel_offset_for_model(color, channel2_index, minf(coordinates.distance_to(Vector2(0.5, 0.5)) * 2.0, 1.0), model)
		PickerGeometricShape.SQUARE_AND_BAR:
			ColorPickerUtils.set_channel_offset_for_model(color, channel1_index, clampf(coordinates.x, 0.0, 1.0), model)
			ColorPickerUtils.set_channel_offset_for_model(color, channel2_index, 1.0 - clampf(coordinates.y, 0.0, 1.0), model)

static func get_color_area_coordinates(color: PreciseColor) -> Vector2:
	match Configs.savedata.color_picker_current_shape:
		PickerShape.NORMAL_MAP:
			var n := Vector3(color.r * 2 - 1, color.g * 2 - 1, color.b * 2 - 1)
			return Vector2(n.x, -n.y) * 0.5 + Vector2(0.5, 0.5)
	
	var channel1_index := 0
	var channel2_index := 0
	var model: ColorModel
	
	match Configs.savedata.color_picker_current_shape:
		PickerShape.HS_V_CIRCLE:
			channel1_index = 0
			channel2_index = 1
			model = ColorModel.HSV
		PickerShape.HS_L_CIRCLE:
			channel1_index = 0
			channel2_index = 1
			model = ColorModel.HSL
		PickerShape.SV_H_SQUARE:
			channel1_index = 1
			channel2_index = 2
			model = ColorModel.HSV
		PickerShape.SL_H_SQUARE:
			channel1_index = 1
			channel2_index = 2
			model = ColorModel.HSL
		PickerShape.HL_S_SQUARE:
			channel1_index = 0
			channel2_index = 2
			model = ColorModel.HSL
	
	match ColorPickerUtils.get_current_picker_shape_geometric_shape():
		PickerGeometricShape.CIRCLE_AND_BAR:
			return Vector2(0.5, 0.5) + Vector2.from_angle(ColorPickerUtils.get_channel_offset_for_model(color, channel1_index, model) * TAU) *\
					ColorPickerUtils.get_channel_offset_for_model(color, channel2_index, model) * 0.5
		PickerGeometricShape.SQUARE_AND_BAR:
			return Vector2(ColorPickerUtils.get_channel_offset_for_model(color, channel1_index, model),
					1.0 - ColorPickerUtils.get_channel_offset_for_model(color, channel2_index, model))
	return Vector2(NAN, NAN)
