class_name ElementRadialGradient extends Element

const name = "radialGradient"
const possible_conversions = []

func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"cx", "cy", "r": return "50%"
		"gradientUnits": return "objectBoundingBox"
		"spreadMethod": return "pad"
		_: return ""

func get_percentage_handling(attribute_name: String) -> DB.PercentageHandling:
	if get_attribute_value("gradientUnits") == "objectBoundingBox" and\
	attribute_name in ["cx", "cy", "r"]:
		return DB.PercentageHandling.FRACTION
	else:
		return super(attribute_name)

func get_config_warnings() -> PackedStringArray:
	var warnings := super()
	if not has_attribute("id"):
		warnings.append(TranslationServer.translate("No \"id\" attribute defined."))
	
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
		warnings.append(TranslationServer.translate("No <stop> elements under this gradient."))
	elif is_solid_color:
		warnings.append(TranslationServer.translate("This gradient is a solid color."))
	
	return warnings

func generate_texture() -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.gradient = Utils.generate_gradient(self)
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(get_attribute_num("cx"), get_attribute_num("cy"))
	texture.fill_to = Vector2(get_attribute_num("cx") + get_attribute_num("r"),
			get_attribute_num("cy"))
	
	if get_attribute_value("gradientUnits") == "userSpaceOnUse":
		texture.fill_from /= svg.get_size()
		texture.fill_to /= svg.get_size()
	
	match get_attribute_value("spreadMethod"):
		"repeat": texture.repeat = GradientTexture2D.REPEAT
		"reflect": texture.repeat = GradientTexture2D.REPEAT_MIRROR
	
	return texture
