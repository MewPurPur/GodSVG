shader_type canvas_item;

uniform vec4 ant_color_1: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 ant_color_2: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float ant_width = 2.0;
uniform float ant_length = 10.0;
uniform float ant_speed = 30.0;

void fragment() {
	vec2 uv = UV;
	vec2 fw = fwidth(uv);
	float adjusted_ant_width = min(ant_width, min(0.5 / fw.x, 0.5 / fw.y));
	vec2 aw = fw * adjusted_ant_width;

	vec2 cond = (sign(abs(uv - 0.5) - 0.5 + aw) + 1.0) * 0.5 * ceil(((sign(uv.yx - aw.yx) + 1.0) * 0.5 * (sign(uv - 0.5) * vec2(0.5, -0.5) + 0.5) * 0.5 + (sign(1.0 - aw.yx - uv.yx) + 1.0) * 0.5 * (sign(uv - 0.5) * vec2(-0.5, 0.5)+ 0.5) * 0.5));
	float dir = dot(vec2(cond.y, -cond.x), sign(uv.yx - 0.5) * uv / aw);
	float ant_type = round(fract((dir * adjusted_ant_width + TIME * ant_speed) * 0.5 / ant_length));
	vec4 ant_color = mix(ant_color_1, ant_color_2, ant_type);
	COLOR = (cond.x + cond.y) * ant_color;
}
