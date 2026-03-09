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
