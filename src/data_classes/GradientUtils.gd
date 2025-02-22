class_name GradientUtils extends RefCounted

static func generate_gradient(element: Element) -> Gradient:
	if not (element is ElementLinearGradient or element is ElementRadialGradient):
		return null
	
	var gradient := Gradient.new()
	gradient.remove_point(0)
	
	var current_offset := 0.0
	var is_gradient_empty := true
	
	for child in element.get_children():
		if not child is ElementStop:
			continue
		
		current_offset = clamp(child.get_attribute_num("offset"), current_offset, 1.0)
		gradient.add_point(current_offset,
				Color(ColorParser.text_to_color(child.get_attribute_true_color("stop-color")),
				child.get_attribute_num("stop-opacity")))
		
		if is_gradient_empty:
			is_gradient_empty = false
			gradient.remove_point(0)
	
	if is_gradient_empty:
		gradient.set_color(0, Color.TRANSPARENT)
	
	return gradient


static func get_gradient_warnings(element: Element) -> PackedStringArray:
	if not (element is ElementLinearGradient or element is ElementRadialGradient):
		return PackedStringArray()
	
	var warnings := PackedStringArray()
	
	if not element.has_attribute("id"):
		warnings.append(Translator.translate("No \"id\" attribute defined."))
	
	var first_stop_color := ""
	var first_stop_opacity := -1.0
	var is_solid_color := true
	for child in element.get_children():
		if not child is ElementStop:
			continue
		
		var stop_opacity := maxf(child.get_attribute_num("stop-opacity"), 0.0)
		var stop_color: String = child.get_attribute_true_color("stop-color")
		
		if first_stop_color.is_empty():
			first_stop_opacity = stop_opacity
			first_stop_color = stop_color
		elif is_solid_color and not (ColorParser.are_colors_same(first_stop_color,
		stop_color) and first_stop_opacity == stop_opacity) and\
		not (first_stop_opacity == 0 and stop_opacity <= 0):
			is_solid_color = false
			break
	
	if first_stop_color.is_empty():
		warnings.append(Translator.translate("No <stop> elements under this gradient."))
	elif is_solid_color:
		warnings.append(Translator.translate("This gradient is a solid color."))
	
	return warnings
