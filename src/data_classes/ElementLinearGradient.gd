# A <linearGradient> element.
class_name ElementLinearGradient extends Element

const name = "linearGradient"
const possible_conversions: Array[String] = []

func _get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"x1", "y1", "y2": return "0%"
		"x2": return "100%"
		"gradientUnits": return "objectBoundingBox"
		"spreadMethod": return "pad"
		_: return ""

func get_percentage_handling(attribute_name: String) -> DB.PercentageHandling:
	if get_attribute_value("gradientUnits") == "objectBoundingBox" and\
	attribute_name in ["x1", "y1", "x2", "y2"]:
		return DB.PercentageHandling.FRACTION
	else:
		return super(attribute_name)

func get_config_warnings() -> PackedStringArray:
	var warnings := super()
	warnings += GradientUtils.get_gradient_warnings(self)
	return warnings

func generate_texture() -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.gradient = GradientUtils.generate_gradient(self)
	texture.fill_from = Vector2(get_attribute_num("x1"), get_attribute_num("y1"))
	texture.fill_to = Vector2(get_attribute_num("x2"), get_attribute_num("y2"))
	
	if get_attribute_value("gradientUnits") == "userSpaceOnUse":
		texture.fill_from /= svg.get_size()
		texture.fill_to /= svg.get_size()
	
	match get_attribute_value("spreadMethod"):
		"repeat": texture.repeat = GradientTexture2D.REPEAT
		"reflect": texture.repeat = GradientTexture2D.REPEAT_MIRROR
	
	return texture
