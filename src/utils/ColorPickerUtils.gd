class_name ColorPickerUtils extends RefCounted

enum PickerShape {VHS_CIRCLE}
enum ColorModel {RGB, HSV, HSL}

static func color_model_to_string(model: ColorModel) -> String:
	# These color models have somewhat common abbreviations in like three languages out there.
	# But people understand and often even prefer the English version. Won't be making these translatable.
	match model:
		ColorModel.RGB: return "RGB"
		ColorModel.HSV: return "HSV"
		ColorModel.HSL: return "HSL"
	return ""

static func picker_shape_to_string(shape: PickerShape) -> String:
	# TODO Should probably localize these.
	match shape:
		PickerShape.VHS_CIRCLE: return "VHS Circle"
	return ""

static func get_channel_letter(channel_index: int) -> String:
	if channel_index == 3:
		return "A"
	match Configs.savedata.color_picker_current_model:
		ColorModel.RGB: return "RGB"[channel_index]
		ColorModel.HSV: return "HSV"[channel_index]
		ColorModel.HSL: return "HSL"[channel_index]
	return ""

static func get_channel_offset(color: Color, channel_index: int) -> float:
	if channel_index == 3:
		return color.a
	match Configs.savedata.color_picker_current_model:
		ColorModel.RGB:
			match channel_index:
				0: return color.r
				1: return color.g
				2: return color.b
		ColorModel.HSV:
			match channel_index:
				0: return color.h
				1: return color.s
				2: return color.v
		ColorModel.HSL:
			match channel_index:
				0: return color.h
				1:
					var max_val := maxf(color.r, maxf(color.g, color.b))
					var min_val := minf(color.r, minf(color.g, color.b))
					if max_val + min_val == 1.0:
						return 0.0
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

static func set_channel_offset(color: Color, channel_index: int, offset: float) -> Color:
	var new_color := color
	if channel_index == 3:
		new_color.a = clampf(offset, 0.0, 1.0)
		return new_color
	
	match Configs.savedata.color_picker_current_model:
		ColorModel.RGB:
			match channel_index:
				0: new_color.r = clampf(offset, 0.0, 1.0)
				1: new_color.g = clampf(offset, 0.0, 1.0)
				2: new_color.b = clampf(offset, 0.0, 1.0)
		ColorModel.HSV:
			match channel_index:
				0: new_color.h = clampf(offset, 0.0, 0.9999)
				1: new_color.s = clampf(offset, 0.0005, 1.0)
				2: new_color.v = clampf(offset, 0.0005, 1.0)
		ColorModel.HSL:
			match channel_index:
				0: new_color.h = clampf(offset, 0.0, 0.9999)
				1, 2:
					var s := clampf(get_channel_offset(new_color, 1) if channel_index == 2 else offset, 0.0005, 1.0)
					var l := clampf(get_channel_offset(new_color, 2) if channel_index == 1 else offset, 0.0005, 0.9995)
					
					var c := (1.0 - absf(2.0 * l - 1.0)) * s
					var hp := color.h * 6
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
					
					new_color.r = clampf(r1 + m, 0.0, 1.0)
					new_color.g = clampf(g1 + m, 0.0, 1.0)
					new_color.b = clampf(b1 + m, 0.0, 1.0)
	return new_color

static func set_primary_slider_offset(color: Color, offset: float) -> Color:
	var new_color := color
	match Configs.savedata.color_picker_current_shape:
		PickerShape.VHS_CIRCLE: new_color.v = clampf(offset, 0.0001, 1.0)
	return new_color
