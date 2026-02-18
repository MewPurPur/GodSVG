shader_type canvas_item;

uniform vec4 ant_color_1: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 ant_color_2: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float ant_width = 2.0;
uniform float ant_length = 10.0;
uniform float ant_speed = 30.0;

varying float cos_skew;
varying float max_rotation_factor;

void vertex() {
	// A bunch of hacks to deal with rotated or skewed drawing resulting in
	// ants that are too long, fast, and sometimes wide.
	vec2 col0 = MODEL_MATRIX[0].xy;
	vec2 col1 = MODEL_MATRIX[1].xy;
	
	float dot_product = dot(normalize(col0), normalize(col1) * sign(col0.x * col1.y - col0.y * col1.x));
	
	float rotation = atan(col0.y, col0.x);
	max_rotation_factor = max(abs(cos(rotation)), abs(sin(rotation)));
	cos_skew = cos(acos(clamp(dot_product, -1.0, 1.0)) - PI * 0.5);
}

void fragment() {
	float corrected_length = ant_length * cos_skew * max_rotation_factor;
	float corrected_speed = ant_speed * cos_skew * max_rotation_factor;
	float corrected_width = ant_width * max_rotation_factor;
	
	vec2 uv = UV;
	vec2 fw = fwidth(uv);
	float adjusted_ant_width = min(corrected_width, min(0.5 / fw.x, 0.5 / fw.y));
	vec2 aw = fw * adjusted_ant_width;
	
	vec2 cond = (sign(abs(uv - 0.5) - 0.5 + aw) + 1.0) * 0.5 * ceil(((sign(uv.yx - aw.yx) + 1.0) * 0.5 * (sign(uv - 0.5) * vec2(0.5, -0.5) + 0.5) * 0.5 + (sign(1.0 - aw.yx - uv.yx) + 1.0) * 0.5 * (sign(uv - 0.5) * vec2(-0.5, 0.5)+ 0.5) * 0.5));
	float dir = dot(vec2(cond.y, -cond.x), sign(uv.yx - 0.5) * uv / aw);
	float ant_type = round(fract((dir * adjusted_ant_width + TIME * corrected_speed) * 0.5 / corrected_length));
	vec4 ant_color = mix(ant_color_1, ant_color_2, ant_type);
	COLOR = (cond.x + cond.y) * ant_color;
}
