## A <path> element.
class_name ElementPath extends Element

const name = "path"
const possible_conversions: PackedStringArray = []

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
		var cmd_char := cmd.command_char.to_upper()
		match cmd_char:
			"M", "L":
				# Move / Line
				var end_x: float = cmd.x
				var end_y: float = cmd.y
				min_x = minf(min_x, end_x)
				min_y = minf(min_y, end_y)
				max_x = maxf(max_x, end_x)
				max_y = maxf(max_y, end_y)
			"H":
				# Horizontal line
				var end_x: float = cmd.x
				min_x = minf(min_x, end_x)
				max_x = maxf(max_x, end_x)
			"V":
				# Vertical line
				var end_y: float = cmd.y
				min_y = minf(min_y, end_y)
				max_y = maxf(max_y, end_y)
			"C", "S":
				# Cubic Bezier curve
				var cp2 := Utils64Bit.get_vector(pathdata.get_implied_S_control(cmd_idx)) if cmd_char == "S" else Vector2(cmd.x1, cmd.y1)
				
				min_x = minf(min_x, cmd.x)
				min_y = minf(min_y, cmd.y)
				max_x = maxf(max_x, cmd.x)
				max_y = maxf(max_y, cmd.y)
				
				var i := cp2 - Vector2(cmd.start_x, cmd.start_y)
				var j := Vector2(cmd.x2, cmd.y2) - cp2
				var k := Vector2(cmd.x, cmd.y) - Vector2(cmd.x2, cmd.y2)
				
				var a := 3 * i - 6 * j + 3 * k
				var b := 6 * j - 6 * i
				var c := 3 * i
				
				var sol_x := _solve_quadratic(a.x, b.x, c.x)
				for sol in sol_x:
					if sol > 0 and sol < 1:
						var pt := Utils.cubic_bezier_point(cmd.start_x, cp2[0], cmd.x2, cmd.x, sol)
						min_x = minf(pt, min_x)
						max_x = maxf(pt, max_x)
				
				var sol_y := _solve_quadratic(a.y, b.y, c.y)
				for sol in sol_y:
					if sol > 0 and sol < 1:
						var pt := Utils.cubic_bezier_point(cmd.start_y, cp2[1], cmd.y2, cmd.y, sol)
						min_y = minf(pt, min_y)
						max_y = maxf(pt, max_y)
			"Q", "T":
				# Quadratic Bezier curve
				var cp2 := pathdata.get_implied_T_control(cmd_idx) if cmd_char == "T" else PackedFloat64Array([cmd.x1, cmd.y1])
				
				min_x = minf(min_x, cmd.x)
				min_y = minf(min_y, cmd.y)
				max_x = maxf(max_x, cmd.x)
				max_y = maxf(max_y, cmd.y)
				
				var t_x: float = (cmd.start_x - cp2[0]) / (cmd.start_x - 2 * cp2[0] + cmd.x)
				if 0 <= t_x and t_x <= 1:
					var x_extrema := Utils.quadratic_bezier_point(cmd.start_x, cp2[0], cmd.x, t_x)
					min_x = minf(min_x, x_extrema)
					max_x = maxf(max_x, x_extrema)
				
				var t_y: float = (cmd.start_y - cp2[1]) / (cmd.start_y - 2 * cp2[1] + cmd.y)
				if 0 <= t_y and t_y <= 1:
					var y_extrema := Utils.quadratic_bezier_point(cmd.y, cp2[1], cmd.y, t_y)
					min_y = minf(min_y, y_extrema)
					max_y = maxf(max_y, y_extrema)
			"A":
				# Elliptical arc.
				min_x = minf(min_x, cmd.x)
				min_y = minf(min_y, cmd.y)
				max_x = maxf(max_x, cmd.x)
				max_y = maxf(max_y, cmd.y)
				
				if (cmd.start_x == cmd.x and cmd.start_y == cmd.y) or cmd.rx == 0 or cmd.ry == 0:
					continue
				
				var r := Vector2(cmd.rx, cmd.ry).abs()
				# Obtain center parametrization.
				var rot := deg_to_rad(cmd.rot)
				var cosine := cos(rot)
				var sine := sin(rot)
				var half_x: float = (cmd.start_x - cmd.x) / 2
				var half_y: float = (cmd.start_y - cmd.y) / 2
				var x1 := half_x * cosine + half_y * sine
				var y1 := -half_x * sine + half_y * cosine
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
				var c_x := ct.x * cosine - ct.y * sine + lerpf(cmd.start_x, cmd.x, 0.5)
				var c_y := ct.x * sine + ct.y * cosine + lerpf(cmd.start_y, cmd.y, 0.5)
				var tv := Vector2(x1 - ct.x, y1 - ct.y) / r
				var theta1 := tv.angle()
				var delta_theta := fposmod(tv.angle_to(Vector2(-x1 - ct.x, -y1 - ct.y) / r), TAU)
				if cmd.sweep_flag == 0:
					theta1 += delta_theta
					delta_theta = TAU - delta_theta
				theta1 = fposmod(theta1, TAU)
				
				var rot_h := tan(rot)
				var extreme1 := atan2(-r.y * rot_h, r.x)
				var extreme2 := atan2(r.y, r.x * rot_h)
				for angle: float in [extreme1, extreme2, PI + extreme1, PI + extreme2]:
					if (angle < theta1 or angle > theta1 + delta_theta) and (angle + TAU < theta1 or angle + TAU > theta1 + delta_theta):
						continue
					var extreme_point := Vector2(c_x + r.x * cos(angle) * cosine - r.y * sin(angle) * sine,
							c_y + r.x * cos(angle) * sine + r.y * sin(angle) * cosine)
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
