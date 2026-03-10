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
