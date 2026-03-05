shader_type canvas_item;

uniform vec4 base_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool horizontal = true;
uniform bool inverted = false;

// 0 = Alpha
// RGB --> 1 = Red, 2 = Green, 3 = Blue
// HSV --> 4 = Hue, 5 = HSV saturation, 6 = Value
// HSL --> 7 = Hue, 8 = HSL saturation, 9 = Lightness
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

vec3 rgb2hsl(vec3 c) {
    float r = c.r;
    float g = c.g;
    float b = c.b;
    float maxc = max(r, max(g, b));
    float minc = min(r, min(g, b));
    float L = (maxc + minc) * 0.5;
    float d = maxc - minc;

    float H = 0.0;
    if (d > 1e-10) {
        if (maxc == r) {
            H = mod((g - b) / d, 6.0);
        } else if (maxc == g) {
            H = ((b - r) / d) + 2.0;
        } else {
            H = ((r - g) / d) + 4.0;
        }
        H /= 6.0; // normalize to 0..1
        if (H < 0.0) H += 1.0;
    } else {
        H = 0.0; // hue undefined for gray; choose 0
    }

    float S = 0.0;
    if (d > 1e-10) {
        S = d / (1.0 - abs(2.0 * L - 1.0));
    } else {
        S = 0.0;
    }

    return vec3(H, S, L);
}

// HSL -> RGB
vec3 hsl2rgb(vec3 hsl) {
	float H = hsl.x;
	float S = hsl.y;
	float L = hsl.z;
	
	float C = (1.0 - abs(2.0 * L - 1.0)) * S;
	float Hp = H * 6.0;
	float X = C * (1.0 - abs(mod(Hp, 2.0) - 1.0));
	
	vec3 rgb1;
	if (0.0 <= Hp && Hp < 1.0) {
		rgb1 = vec3(C, X, 0.0);
	} else if (1.0 <= Hp && Hp < 2.0) {
		rgb1 = vec3(X, C, 0.0);
	} else if (2.0 <= Hp && Hp < 3.0) {
		rgb1 = vec3(0.0, C, X);
	} else if (3.0 <= Hp && Hp < 4.0) {
		rgb1 = vec3(0.0, X, C);
	} else if (4.0 <= Hp && Hp < 5.0) {
		rgb1 = vec3(X, 0.0, C);
	} else {
		rgb1 = vec3(C, 0.0, X);
	}
	
	float m = L - 0.5 * C;
	return rgb1 + vec3(m);
}

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
	} else if (interpolation >= 4 && interpolation <= 6) {
		vec3 hsv = rgb2hsv(base_color.rgb);
		if (interpolation == 4) {
			hsv.x = offset;
		} else if (interpolation == 5) {
			hsv.y = offset;
		} else if (interpolation == 6) {
			hsv.z = offset;
		}
		COLOR = vec4(hsv2rgb(hsv), 1.0);
	}
}
