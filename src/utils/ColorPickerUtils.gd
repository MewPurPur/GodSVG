class_name ColorPickerUtils extends RefCounted

# The color picker uses a 64-bit color because the precision is necessary for the approach of
# things like keeping colors almost-grayscale-but-not-quite to preserve their hue.
class PreciseColor:
	var r: float
	var g: float
	var b: float
	var a: float
	
	func _init(new_r: float, new_g: float, new_b: float, new_a: float) -> void:
		r = new_r
		g = new_g
		b = new_b
		a = new_a
	
	func _to_string() -> String:
		return "PreciseColor(%s, %s, %s, %s)" % [r, g, b, a]
	
	static func from_color(color: Color) -> PreciseColor:
		return PreciseColor.new(color.r, color.g, color.b, color.a)
	
	func to_color() -> Color:
		return Color(r, g, b, a)
	
	func duplicate() -> PreciseColor:
		return PreciseColor.new(r, g, b, a)
	
	func equals(color: PreciseColor) -> bool:
		return r == color.r and g == color.g and b == color.b and a == color.a
	
	func set_hue(h: float) -> void:
		var new_color := Color(r, g, b)
		new_color.h = h
		r = new_color.r
		g = new_color.g
		b = new_color.b
	
	func set_saturation(s: float) -> void:
		var new_color := Color(r, g, b)
		new_color.s = s
		r = new_color.r
		g = new_color.g
		b = new_color.b
	
	func set_value(v: float) -> void:
		var new_color := Color(r, g, b)
		new_color.v = v
		r = new_color.r
		g = new_color.g
		b = new_color.b
	
	func shift_hsv() -> void:
		set_hue(clampf(get_hue(), 0.0, 0.9999))
		set_value(clampf(get_value(), 0.0001, 1.0))
		set_saturation(clampf(get_saturation(), 0.0001, 1.0))
	
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

enum PickerShape {HS_V_CIRCLE, HS_L_CIRCLE, SV_H_SQUARE, SL_H_SQUARE}
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
	return ""

static func picker_shape_get_geometric_shape(shape: PickerShape) -> PickerGeometricShape:
	match shape:
		PickerShape.SV_H_SQUARE, PickerShape.SL_H_SQUARE: return PickerGeometricShape.SQUARE_AND_BAR
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
					var s := clampf(get_channel_offset(color, 1) if channel_index == 2 else offset, 0.0001, 1.0)
					var l := clampf(get_channel_offset(color, 2) if channel_index == 1 else offset, 0.0001, 0.9999)
					
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
		PickerShape.SV_H_SQUARE: return color.get_hue()
	return 0.0

static func set_primary_slider_offset(color: PreciseColor, offset: float) -> void:
	match Configs.savedata.color_picker_current_shape:
		PickerShape.HS_V_CIRCLE: set_channel_offset_for_model(color, 2, offset, ColorModel.HSV)
		PickerShape.HS_L_CIRCLE: set_channel_offset_for_model(color, 2, offset, ColorModel.HSL)
		PickerShape.SV_H_SQUARE, PickerShape.SL_H_SQUARE: set_channel_offset_for_model(color, 0, offset, ColorModel.HSV)
