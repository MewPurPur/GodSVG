shader_type canvas_item;

#include "res://src/shaders/color_models.gdshaderinc"

uniform vec4 base_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool horizontal = true;
uniform bool inverted = false;

// 0 = Alpha
// RGB --> 1 = Red, 2 = Green, 3 = Blue
// HSV --> 4 = Hue, 5 = HSV saturation, 6 = Value
// HSL --> 4 = Hue, 7 = HSL saturation, 8 = Lightness
// TODO OKHSL --> 9 = OKHSL hue, 10 = OKHSL saturation, 11 = OKHSL lightness
// 100 = Normal intensity
uniform int interpolation = 0;

void fragment() {
	float offset = (horizontal ? UV.x : UV.y);
	offset = (inverted ? 1.0 - offset : offset);
	
	if (interpolation == 0) {
		COLOR = vec4(base_color.r, base_color.g, base_color.b, offset);
	} else if (interpolation == 1) {
		COLOR = vec4(offset, base_color.g, base_color.b, 1.0);
	} else if (interpolation == 2) {
		COLOR = vec4(base_color.r, offset, base_color.b, 1.0);
	} else if (interpolation == 3) {
		COLOR = vec4(base_color.r, base_color.g, offset, 1.0);
	} else if (interpolation <= 6) {
		vec3 hsv = rgb_to_hsv(base_color.rgb);
		if (interpolation == 4) {
			hsv.x = offset;
		} else if (interpolation == 5) {
			hsv.y = offset;
		} else if (interpolation == 6) {
			hsv.z = offset;
		}
		COLOR = vec4(hsv_to_rgb(hsv), 1.0);
	} else if (interpolation <= 8) {
		vec3 hsl = rgb_to_hsl(base_color.rgb);
		if (interpolation == 7) {
			hsl.y = offset;
		} else if (interpolation == 8) {
			hsl.z = offset;
		}
		COLOR = vec4(hsl_to_rgb(hsl), 1.0);
	} else if (interpolation == 100) {
		vec2 dir = normalize(base_color.rgb * 2.0 - 1.0).xy;
		float len = length(dir);
		if (len > 0.00001) {
		    dir /= len;
		} else {
		    dir = vec2(0.0);
		}
		vec2 xy = dir * offset;
		COLOR = vec4(vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy)))) * 0.5 + 0.5, 1.0);
	} else {
		COLOR = base_color;
	}
}
