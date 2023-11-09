shader_type canvas_item;

uniform vec3 base_color = vec3(1.0, 1.0, 1.0);
// 0 = Red, 1 = Green, 2 = Blue, 3 = Hue, 4 = Saturation, 5 = Value
uniform int interpolation = 0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	if (interpolation == 0) {
		COLOR = vec4(UV.x, base_color.g, base_color.b, 1.0);
	} else if (interpolation == 1) {
		COLOR = vec4(base_color.r, UV.x, base_color.b, 1.0);
	} else if (interpolation == 2) {
		COLOR = vec4(base_color.r, base_color.g, UV.x, 1.0);
	} else {
		vec3 hsv = rgb2hsv(base_color.rgb);
		if (interpolation == 3) {
			hsv.x = UV.x;
		} else if (interpolation == 4) {
			hsv.y = UV.x;
		} else if (interpolation == 5) {
			hsv.z = UV.x;
		}
		COLOR = vec4(hsv2rgb(hsv), 1.0);
	}
}