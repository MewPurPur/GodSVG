#ifndef COLOR_CONVERT_GDSHADERINC
#define COLOR_CONVERT_GDSHADERINC

vec3 rgb_to_hsv(vec3 color) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(color.bg, K.wz), vec4(color.gb, K.xy), step(color.b, color.g));
	vec4 q = mix(vec4(p.xyw, color.r), vec4(color.r, p.yzx), step(p.x, color.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 color) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(color.xxx + K.xyz) * 6.0 - K.www);
	return color.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), color.y);
}

vec3 rgb_to_hsl(vec3 color) {
	float maxc = max(color.r, max(color.g, color.b));
	float minc = min(color.r, min(color.g, color.b));
	float L = (maxc + minc) * 0.5;
	float d = maxc - minc;

	float H = 0.0;
	if (d > 1e-10) {
		if (maxc == color.r) {
			H = mod((color.g - color.b) / d, 6.0);
		} else if (maxc == color.g) {
			H = ((color.b - color.r) / d) + 2.0;
		} else {
			H = ((color.r - color.g) / d) + 4.0;
		}
		H /= 6.0;
		if (H < 0.0) {
			H += 1.0;
		}
	} else {
		H = 0.0;
	}
	
	float S = 0.0;
	if (d > 1e-10) {
		S = d / (1.0 - abs(2.0 * L - 1.0));
	} else {
		S = 0.0;
	}
	
	return vec3(H, S, L);
}

vec3 hsl_to_rgb(vec3 hsl) {
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

#endif
