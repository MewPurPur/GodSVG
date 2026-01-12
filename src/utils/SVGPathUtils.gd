class_name SVGPathUtils

@warning_ignore("unused_parameter")
static func get_path_element_points(
	element: Element,
	normal_polylines: Array[PackedVector2Array],
	normal_multiline: PackedVector2Array = [],
	curve_tolerance_degrees: float = 1.0,
	hovered_polylines: Array[PackedVector2Array] = [],
	hovered_multiline: PackedVector2Array = [],
	selected_polylines: Array[PackedVector2Array] = [],
	selected_multiline: PackedVector2Array = [],
	hovered_selected_polylines: Array[PackedVector2Array] = [],
	hovered_selected_multiline: PackedVector2Array = [],
	canvas: Canvas = null,
) -> void:
	assert(element.name == "path")
	var pathdata: AttributePathdata = element.get_attribute("d")
	if pathdata.get_command_count() == 0 or not pathdata.get_command(0).command_char in "Mm":
		return  # Nothing to draw.
	var current_mode := Utils.InteractionType.NONE
					
	for cmd_idx in pathdata.get_command_count():
		# Drawing logic.
		var points := PackedVector2Array()
		var tangent_points := PackedVector2Array()
		var cmd := pathdata.get_command(cmd_idx)
		var relative := cmd.relative
		
		current_mode = Utils.InteractionType.NONE
		if canvas != null:
			if canvas.is_hovered(element.xid, cmd_idx, true):
				@warning_ignore("int_as_enum_without_cast")
				current_mode += Utils.InteractionType.HOVERED
			if canvas.is_selected(element.xid, cmd_idx, true):
				@warning_ignore("int_as_enum_without_cast")
				current_mode += Utils.InteractionType.SELECTED
		
		match cmd.command_char.to_upper():
			"L":
				# Line contour.
				var v := Vector2(cmd.x, cmd.y)
				var end := cmd.get_start_coords() + v if relative else v
				points = PackedVector2Array([cmd.get_start_coords(), end])
			"H":
				# Horizontal line contour.
				var v := Vector2(cmd.x, 0)
				var end := cmd.get_start_coords() + v if relative else Vector2(v.x, cmd.start_y)
				points = PackedVector2Array([cmd.get_start_coords(), end])
			"V":
				# Vertical line contour.
				var v := Vector2(0, cmd.y)
				var end := cmd.get_start_coords() + v if relative else Vector2(cmd.start_x, v.y)
				points = PackedVector2Array([cmd.get_start_coords(), end])
			"C":
				# Cubic Bezier curve contour.
				var v := Vector2(cmd.x, cmd.y)
				var v1 := Vector2(cmd.x1, cmd.y1)
				var v2 := Vector2(cmd.x2, cmd.y2)
				var cp1 := cmd.get_start_coords()
				var cp4 := cp1 + v if relative else v
				var cp2 := v1 if relative else v1 - cp1
				var cp3 := v2 - v
				
				points = Utils.get_cubic_bezier_points(cp1, cp2, cp3, cp4, curve_tolerance_degrees)
				tangent_points.append_array(PackedVector2Array([cp1, cp1 + cp2, cp1 + v2 if relative else v2, cp4]))
			"S":
				# Shorthand cubic Bezier curve contour.
				if cmd_idx == 0:
					break
				
				var v := Vector2(cmd.x, cmd.y)
				var v1 := pathdata.get_implied_S_control(cmd_idx)
				var v2 := Vector2(cmd.x2, cmd.y2)
				
				var cp1 := cmd.get_start_coords()
				var cp4 := cp1 + v if relative else v
				var cp2 := v1 if relative else v1 - cp1
				var cp3 := v2 - v
				
				points = Utils.get_cubic_bezier_points(cp1, cp2, cp3, cp4, curve_tolerance_degrees)
				tangent_points.append_array(PackedVector2Array([cp1, cp1 + cp2, cp1 + v2 if relative else v2, cp4]))
			"Q":
				# Quadratic Bezier curve contour.
				var v := Vector2(cmd.x, cmd.y)
				var v1 := Vector2(cmd.x1, cmd.y1)
				var cp1 := cmd.get_start_coords()
				var cp2 := cp1 + v1 if relative else v1
				var cp3 := cp1 + v if relative else v
				
				points = Utils.get_quadratic_bezier_points(cp1, cp2, cp3, curve_tolerance_degrees)
				tangent_points.append_array(PackedVector2Array([cp1, cp2, cp2, cp3]))
			"T":
				# Shorthand quadratic Bezier curve contour.
				var v := Vector2(cmd.x, cmd.y)
				var v1 := pathdata.get_implied_T_control(cmd_idx)
				
				var cp1 := cmd.get_start_coords()
				var cp2 := v1 + cp1 if relative else v1
				var cp3 := cp1 + v if relative else v
				
				if is_nan(cp2.x) and is_nan(cp2.y):
					points = PackedVector2Array([cp1, cp3])
				else:
					points = Utils.get_quadratic_bezier_points(cp1, cp2, cp3, curve_tolerance_degrees)
					tangent_points.append_array(PackedVector2Array([cp1, cp2, cp2, cp3]))
			"A":
				# Elliptical arc contour.
				var start := cmd.get_start_coords()
				var v := Vector2(cmd.x, cmd.y)
				var end := start + v if relative else v
				# Correct for out-of-range radii.
				if start == end:
					continue
				elif cmd.rx == 0 or cmd.ry == 0:
					points = PackedVector2Array([start, end])
				
				var r := Vector2(cmd.rx, cmd.ry).abs()
				# Obtain center parametrization.
				var rot := deg_to_rad(cmd.rot)
				var cosine := cos(rot)
				var sine := sin(rot)
				var half := (start - end) / 2
				var x1 := half.x * cosine + half.y * sine
				var y1 := -half.x * sine + half.y * cosine
				var r2 := Vector2(r.x * r.x, r.y * r.y)
				var x12 := x1 * x1
				var y12 := y1 * y1
				var cr := x12 / r2.x + y12 / r2.y
				if cr > 1:
					cr = sqrt(cr)
					r *= cr
					r2 = Vector2(r.x * r.x, r.y * r.y)
				
				var dq := r2.x * y12 + r2.y * x12
				var pq := (r2.x * r2.y - dq) / dq
				var sc := sqrt(maxf(0, pq))
				if cmd.large_arc_flag == cmd.sweep_flag:
					sc = -sc
				
				var ct := Vector2(r.x * sc * y1 / r.y, -r.y * sc * x1 / r.x)
				var c := Vector2(ct.x * cosine - ct.y * sine, ct.x * sine + ct.y * cosine) + start.lerp(end, 0.5)
				var tv := Vector2(x1 - ct.x, y1 - ct.y) / r
				var theta1 := tv.angle()
				var delta_theta := fposmod(tv.angle_to(Vector2(-x1 - ct.x, -y1 - ct.y) / r), TAU)
				if cmd.sweep_flag == 0:
					theta1 += delta_theta
					delta_theta = TAU - delta_theta
				
				# Now we have a center parametrization (r, c, theta1, delta_theta).
				# We will approximate the elliptical arc with Bezier curves.
				# Use the method described in https://www.blog.akhil.cc/ellipse
				# (but with modifications because it wasn't working fully).
				var segments := delta_theta * 4/PI
				var n := floori(segments)
				var p1 := Utils.E(c, r, cosine, sine, theta1)
				var e1 := Utils.Et(r, cosine, sine, theta1)
				var alpha := 0.26511478
				var t := theta1 + PI/4
				var cp: Array[PackedVector2Array] = []
				for _i in n:
					var p2 := Utils.E(c, r, cosine, sine, t)
					var e2 := Utils.Et(r, cosine, sine, t)
					cp.append(PackedVector2Array([p1, alpha * e1, -alpha * e2, p2]))
					p1 = p2
					e1 = e2
					t += PI/4
				
				if n != ceili(segments) and not is_equal_approx(n, segments):
					t = theta1 + delta_theta
					var p2 := Utils.E(c, r, cosine, sine, t)
					var e2 := Utils.Et(r, cosine, sine, t)
					alpha *= fposmod(delta_theta, PI/4) / (PI/4)
					cp.append(PackedVector2Array([p1, alpha * e1, -alpha * e2, p2]))
				
				for p in cp:
					points += Utils.get_cubic_bezier_points(p[0], p[1], p[2], p[3], curve_tolerance_degrees)
			"Z":
				# Path closure contour.
				var prev_M_idx := cmd_idx - 1
				var prev_M_cmd := pathdata.get_command(prev_M_idx)
				while prev_M_idx >= 0:
					if prev_M_cmd.command_char in "Mm":
						break
					prev_M_idx -= 1
					prev_M_cmd = pathdata.get_command(prev_M_idx)
				if prev_M_idx == -1:
					break
				
				var end := Vector2(prev_M_cmd.x, prev_M_cmd.y)
				if prev_M_cmd.relative:
					end += prev_M_cmd.get_start_coords()
				
				points = PackedVector2Array([cmd.get_start_coords(), end])
			"M":
				continue
		
		var final_transform := element.get_transform()
		points = final_transform * points
		tangent_points = final_transform * tangent_points
		match current_mode:
			Utils.InteractionType.NONE:
				normal_polylines.append(points)
				normal_multiline += tangent_points
			Utils.InteractionType.HOVERED:
				hovered_polylines.append(points)
				hovered_multiline += tangent_points
			Utils.InteractionType.SELECTED:
				selected_polylines.append(points)
				selected_multiline += tangent_points
			Utils.InteractionType.HOVERED_SELECTED:
				hovered_selected_polylines.append(points)
				hovered_selected_multiline += tangent_points
