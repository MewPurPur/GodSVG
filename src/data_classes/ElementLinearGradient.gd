# A <linearGradient> element.
class_name ElementLinearGradient extends Element

const name = "linearGradient"
const possible_conversions = []

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
	if not has_attribute("id"):
		warnings.append(Translator.translate("No \"id\" attribute defined."))
	
	var first_stop_color := ""
	var first_stop_opacity := -1.0
	var is_solid_color := true
	for child in get_children():
		if child is ElementStop:
			if first_stop_color.is_empty():
				first_stop_color = child.get_attribute_value("stop-color")
				first_stop_opacity = maxf(0.0, child.get_attribute_num("stop-opacity"))
			elif is_solid_color and not (ColorParser.are_colors_same(first_stop_color,
			child.get_attribute_value("stop-color")) and\
			first_stop_opacity == child.get_attribute_num("stop-opacity")) and\
			not (first_stop_opacity == 0 and child.get_attribute_num("stop-opacity") <= 0):
				is_solid_color = false
				break
	
	if first_stop_color.is_empty():
		warnings.append(Translator.translate("No <stop> elements under this gradient."))
	elif is_solid_color:
		warnings.append(Translator.translate("This gradient is a solid color."))
	
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
