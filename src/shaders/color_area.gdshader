shader_type canvas_item;

#include "res://src/shaders/color_models.gdshaderinc"

// 0 = HS+V Circle
// 1 = HS+L Circle
// 2 = SV+H Square
// 3 = SL+H Square
uniform int interpolation = 0;
uniform float third_value = 1.0;

void fragment() {
	if (interpolation == 0) {
		vec2 p = UV - vec2(0.5);
		float dist = length(p);
		float edge = fwidth(dist);
		COLOR = vec4(hsv_to_rgb(vec3(fract(atan(p.y, p.x) / TAU), clamp(dist * 2.0, 0.0, 1.0), third_value)), 1.0 - smoothstep(0.5 - edge * 0.5, 0.5 + edge * 0.5, dist));
	} else if (interpolation == 1) {
		vec2 p = UV - vec2(0.5);
		float dist = length(p);
		float edge = fwidth(dist);
		COLOR = vec4(hsl_to_rgb(vec3(fract(atan(p.y, p.x) / TAU), clamp(dist * 2.0, 0.0, 1.0), third_value)), 1.0 - smoothstep(0.5 - edge * 0.5, 0.5 + edge * 0.5, dist));
	} else if (interpolation == 2) {
		COLOR = vec4(hsv_to_rgb(vec3(third_value, clamp(UV.x, 0.0, 1.0), clamp(1.0 - UV.y, 0.0, 1.0))), 1.0);
	} else if (interpolation == 3) {
		COLOR = vec4(hsl_to_rgb(vec3(third_value, clamp(UV.x, 0.0, 1.0), clamp(1.0 - UV.y, 0.0, 1.0))), 1.0);
	}
}
