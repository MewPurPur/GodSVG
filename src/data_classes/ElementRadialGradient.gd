# A <radialGradient> element.
class_name ElementRadialGradient extends ElementBaseGradient

const name = "radialGradient"

func _get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"cx", "cy", "r": return "50%"
		"fx": return get_implied_attribute_value("cx")
		"fy": return get_implied_attribute_value("cy")
		"gradientUnits": return "objectBoundingBox"
		"spreadMethod": return "pad"
		_: return ""

func get_percentage_handling(attribute_name: String) -> DB.PercentageHandling:
	if get_attribute_value("gradientUnits") in ["objectBoundingBox", ""] and attribute_name in ["cx", "cy", "r", "fx", "fy"]:
		return DB.PercentageHandling.FRACTION
	else:
		return super(attribute_name)

func generate_texture() -> SVGTexture:
	var svg_texture_text := """<svg width="64" height="64" xmlns="http://www.w3.org/2000/svg"><radialGradient id="a" """
	
	var scaling := Vector2(64.0, 64.0) / svg.get_size()
	var is_user_space_on_use := (get_attribute_value("gradientUnits") == "userSpaceOnUse")
	
	for attrib in ["cx", "fx"]:
		if has_attribute(attrib):
			var attrib_num := get_attribute_num(attrib)
			if is_user_space_on_use:
				attrib_num *= scaling.x
			svg_texture_text += """%s="%f" """ % [attrib, attrib_num]
	
	for attrib in ["cy", "fy"]:
		if has_attribute(attrib):
			var attrib_num := get_attribute_num(attrib)
			if is_user_space_on_use:
				attrib_num *= scaling.y
			svg_texture_text += """%s="%f" """ % [attrib, attrib_num]
	
	if has_attribute("r"):
		var attrib_num := get_attribute_num("r")
		if is_user_space_on_use:
			attrib_num *= scaling.length() / sqrt(2)
		svg_texture_text += """r="%f" """ % attrib_num
	
	if has_attribute("gradientTransform"):
		if is_user_space_on_use:
			svg_texture_text += """gradientTransform="scale(%f %f) %s scale(%f %f)" """ % [scaling.x, scaling.y,
					get_attribute_value("gradientTransform"), 1/scaling.x, 1/scaling.y]
		else:
			svg_texture_text += """gradientTransform="%s" """ % get_attribute_value("gradientTransform")
	
	for attrib in ["spreadMethod", "gradientUnits"]:
		if has_attribute(attrib):
			svg_texture_text += """%s="%s" """ % [attrib, get_attribute_value(attrib)]
	
	svg_texture_text += ">"
	
	for child in get_children():
		if not child is ElementStop:
			continue
		
		svg_texture_text += "<stop "
		for attribute: Attribute in child.get_all_attributes():
			var value := attribute.get_value()
			if not '"' in value:
				svg_texture_text += ' %s="%s"' % [attribute.name, value]
			else:
				svg_texture_text += " %s='%s'" % [attribute.name, value]
		svg_texture_text += "/>"
	
	svg_texture_text += """</radialGradient><rect fill="url(#a)" width="100%%" height="100%%"/></svg>"""
	return SVGTexture.create_from_string(svg_texture_text)
