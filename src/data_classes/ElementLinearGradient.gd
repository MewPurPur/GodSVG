class_name ElementLinearGradient extends Element

const name = "linearGradient"
const possible_conversions = []

func get_own_default(attribute_name: String) -> String:
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
	if not has_attribute("id"):
		warnings.append(TranslationServer.translate("No id attribute defined."))
	
	var has_stops := false
	for child in get_children():
		if child is ElementStop:
			has_stops = true
			break
	if not has_stops:
		warnings.append(TranslationServer.translate("No stop elements under this gradient."))
	
	return warnings

func generate_texture() -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.gradient = Utils.generate_gradient(self)
	texture.fill_from = Vector2(get_attribute_num("x1"), get_attribute_num("y1"))
	texture.fill_to = Vector2(get_attribute_num("x2"), get_attribute_num("y2"))
	
	if get_attribute_value("gradientUnits") == "userSpaceOnUse":
		texture.fill_from /= svg.get_size()
		texture.fill_to /= svg.get_size()
	
	match get_attribute_value("spreadMethod"):
		"repeat": texture.repeat = GradientTexture2D.REPEAT
		"reflect": texture.repeat = GradientTexture2D.REPEAT_MIRROR
	
	return texture
