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
	
	var prev_offset := -1.0
	var initial_color := ""
	var initial_opacity := -1.0
	var has_effective_transition := false
	
	for child in element.get_children():
		if not child is ElementStop:
			continue
		
		var stop_offset := clampf(child.get_attribute_num("offset"), 0.0, 1.0)
		var stop_opacity := clampf(child.get_attribute_num("stop-opacity"), 0.0, 1.0)
		var stop_color: String = child.get_attribute_true_color("stop-color")
		
		if initial_color.is_empty():
			prev_offset = stop_offset
			initial_color = stop_color
			initial_opacity = stop_opacity
			continue
		
		# Different color from the initial one (which, even at offset 0, still always
		# has effect on the stroke). Mark it for having the potential to begin an
		# effective transition if the next stop offset is greater.
		has_effective_transition = not (ColorParser.are_colors_same(
				initial_color, stop_color) and initial_opacity == stop_opacity) and\
				(initial_opacity != 0 or stop_opacity > 0)
		
		if has_effective_transition and stop_offset > prev_offset:
			break
		
		prev_offset = stop_offset
	
	if initial_color.is_empty():
		warnings.append(Translator.translate("No <stop> elements under this gradient."))
	elif not has_effective_transition:
		# A potential effective transition being last would still mean it's a real
		# transition. Even at offset 1, it would still have an effect on the stroke.
		warnings.append(Translator.translate("This gradient is a solid color."))
	
	return warnings
