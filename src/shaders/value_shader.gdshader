shader_type canvas_item;

uniform vec3 base_color = vec3(1.0, 1.0, 1.0);

void fragment() {
    COLOR = vec4(mix(vec3(0.0, 0.0, 0.0), base_color, 1.0 - UV.y), 1.0);
}