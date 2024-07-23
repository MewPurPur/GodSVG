shader_type canvas_item;

uniform float uv_scale = 1.0;

void fragment() {
	COLOR = texture(TEXTURE, UV * uv_scale);
}
