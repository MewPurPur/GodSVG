shader_type canvas_item;

// 0 = HS+V Circle
// 1 = SV+H Square
uniform int interpolation = 0;
uniform float third_value = 1.0;

void fragment() {
	if (interpolation == 0) {
		float x = UV.x - 0.5;
		float y = UV.y - 0.5;
		float a = atan(y, x);
		x += 0.001;
		y += 0.001;
		float b = float(sqrt(x * x + y * y) < 0.5);
		x -= 0.002;
		float b2 = float(sqrt(x * x + y * y) < 0.5);
		y -= 0.002;
		float b3 = float(sqrt(x * x + y * y) < 0.5);
		x += 0.002;
		float b4 = float(sqrt(x * x + y * y) < 0.5);
		COLOR = vec4(mix(vec3(1.0), clamp(abs(fract(vec3((a - TAU) / TAU) + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - vec3(3.0)) - vec3(1.0), 0.0, 1.0), ((float(sqrt(x * x + y * y)) * 2.0)) / 1.0) * vec3(third_value), (b + b2 + b3 + b4) / 4.0);
	} else if (interpolation == 1) {
		float s = clamp(UV.x, 0.0, 1.0);
		float val = clamp(1.0 - UV.y, 0.0, 1.0);
		float c = val * s;
		float hp = third_value * 6.0;
		float xcol = c * (1.0 - abs(mod(hp, 2.0) - 1.0));
		float m = val - c;
		vec3 col;
		if (hp < 1.0) {
			col = vec3(c, xcol, 0.0);
		} else if (hp < 2.0) {
			col = vec3(xcol, c, 0.0);
		} else if (hp < 3.0) {
			col = vec3(0.0, c, xcol);
		} else if (hp < 4.0) {
			col = vec3(0.0, xcol, c);
		} else if (hp < 5.0) {
			col = vec3(xcol, 0.0, c);
		} else {
			col = vec3(c, 0.0, xcol);
		}
		col += vec3(m);
		COLOR = vec4(col, 1.0);
	}
}
