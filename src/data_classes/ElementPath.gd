# A <path> element.
class_name ElementPath extends Element

const name = "path"
const possible_conversions: Array[String] = []

func user_setup(precise_pos := PackedFloat64Array([0.0, 0.0])) -> void:
	if precise_pos != PackedFloat64Array([0.0, 0.0]):
		var attrib := get_attribute("d")
		attrib.insert_command(0, "M")
		attrib.set_command_property(0, "x", precise_pos[0])
		attrib.set_command_property(0, "y", precise_pos[1])

func _get_own_default(attribute_name: String) -> String:
	if attribute_name == "opacity":
		return "1"
	return ""

func get_bounding_box() -> Rect2:
	if not has_attribute("d"):
		return Rect2()
	
	var pathdata: AttributePathdata = get_attribute("d")
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	
	for cmd_idx in pathdata.get_command_count():
		var cmd := pathdata.get_command(cmd_idx)
		var relative := cmd.relative
		var cmd_char := cmd.command_char.to_upper()
		match cmd_char:
			"M", "L":
				# Move / Line
				var v := Vector2(cmd.x, cmd.y)
				var end := cmd.get_start_coords() + v if relative else v
				min_x = minf(min_x, end.x)
				min_y = minf(min_y, end.y)
				max_x = maxf(max_x, end.x)
				max_y = maxf(max_y, end.y)
			"H":
				# Horizontal line
				var v := Vector2(cmd.x, 0)
				var end := cmd.get_start_coords() + v if relative else v
				min_x = minf(min_x, end.x)
				max_x = maxf(max_x, end.x)
			"V":
				# Vertical line
				var v := Vector2(0, cmd.y)
				var end := cmd.get_start_coords() + v if relative else v
				min_y = minf(min_y, end.y)
				max_y = maxf(max_y, end.y)
			"C", "S":
				# Cubic Bezier curve
				var v := Vector2(cmd.x, cmd.y)
				var v1 := Vector2(cmd.x1, cmd.y1) if cmd_char == "C" else\
						pathdata.get_implied_S_control(cmd_idx)
				var v2 := Vector2(cmd.x2, cmd.y2)
				var cp1 := cmd.get_start_coords()
				var cp4 := cp1 + v if relative else v
				var cp2 := cp1 + v1 if relative else v1
				var cp3 := cp1 + v2 if relative else v2
				
				min_x = minf(min_x, cp4.x)
				min_y = minf(min_y, cp4.y)
				max_x = maxf(max_x, cp4.x)
				max_y = maxf(max_y, cp4.y)
				
				var i := cp2 - cp1
				var j := cp3 - cp2
				var k := cp4 - cp3
				
				var a := 3 * i - 6 * j + 3 * k
				var b := 6 * j - 6 * i
				var c := 3 * i
				
				var sol_x := _solve_quadratic(a.x, b.x, c.x)
				for sol in sol_x:
					if sol > 0 and sol < 1:
						var pt := Utils.cubic_bezier_point(cp1.x, cp2.x, cp3.x, cp4.x, sol)
						min_x = minf(pt, min_x)
						max_x = maxf(pt, max_x)
				
				var sol_y := _solve_quadratic(a.y, b.y, c.y)
				for sol in sol_y:
					if sol > 0 and sol < 1:
						var pt := Utils.cubic_bezier_point(cp1.y, cp2.y, cp3.y, cp4.y, sol)
						min_y = minf(pt, min_y)
						max_y = maxf(pt, max_y)
			"Q", "T":
				# Quadratic Bezier curve
				var v := Vector2(cmd.x, cmd.y)
				var v1 := Vector2(cmd.x1, cmd.y1) if cmd_char == "Q" else\
						pathdata.get_implied_T_control(cmd_idx)
				
				var cp1 := cmd.get_start_coords()
				var cp2 := cp1 + v1 if relative else v1
				var cp3 := cp1 + v if relative else v
				
				min_x = minf(min_x, cp3.x)
				min_y = minf(min_y, cp3.y)
				max_x = maxf(max_x, cp3.x)
				max_y = maxf(max_y, cp3.y)
				
				var t_x := (cp1.x - cp2.x) / (cp1.x - 2 * cp2.x + cp3.x)
				if 0 <= t_x and t_x <= 1:
					var x_extrema := Utils.quadratic_bezier_point(cp1.x, cp2.x, cp3.x, t_x)
					min_x = minf(min_x, x_extrema)
					max_x = maxf(max_x, x_extrema)
				
				var t_y := (cp1.y - cp2.y) / (cp1.y - 2 * cp2.y + cp3.y)
				if 0 <= t_y and t_y <= 1:
					var y_extrema := Utils.quadratic_bezier_point(cp1.y, cp2.y, cp3.y, t_y)
					min_y = minf(min_y, y_extrema)
					max_y = maxf(max_y, y_extrema)
			"A":
				# Elliptical arc.
				var start := cmd.get_start_coords()
				var v := Vector2(cmd.x, cmd.y)
				var end := start + v if relative else v
				
				min_x = minf(min_x, end.x)
				min_y = minf(min_y, end.y)
				max_x = maxf(max_x, end.x)
				max_y = maxf(max_y, end.y)
				
				if start == end or cmd.rx == 0 or cmd.ry == 0:
					continue
				
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
				var c := Vector2(ct.x * cosine - ct.y * sine,
						ct.x * sine + ct.y * cosine) + start.lerp(end, 0.5)
				var tv := Vector2(x1 - ct.x, y1 - ct.y) / r
				var theta1 := tv.angle()
				var delta_theta := fposmod(tv.angle_to(
						Vector2(-x1 - ct.x, -y1 - ct.y) / r), TAU)
				if cmd.sweep_flag == 0:
					theta1 += delta_theta
					delta_theta = TAU - delta_theta
				theta1 = fposmod(theta1, TAU)
				
				var rot_h := tan(rot)
				var extreme1 := atan2(-r.y * rot_h, r.x)
				var extreme2 := atan2(r.y, r.x * rot_h)
				for angle: float in [extreme1, extreme2, PI + extreme1, PI + extreme2]:
					if (angle < theta1 or angle > theta1 + delta_theta) and\
					(angle + TAU < theta1 or angle + TAU > theta1 + delta_theta):
						continue
					var extreme_point := Vector2(
							c.x + r.x * cos(angle) * cosine - r.y * sin(angle) * sine,
							c.y + r.x * cos(angle) * sine + r.y * sin(angle) * cosine)
					min_x = minf(min_x, extreme_point.x)
					min_y = minf(min_y, extreme_point.y)
					max_x = maxf(max_x, extreme_point.x)
					max_y = maxf(max_y, extreme_point.y)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func _solve_quadratic(a: float, b: float, c: float) -> Array[float]:
	if a == 0:
		return [-c/b]
	
	var D := sqrt(b * b - 4 * a * c)
	if is_nan(D):
		return []
	else:
		return [(-b + D) / (2 * a), (-b - D) / (2 * a)]
