shader_type canvas_item;
render_mode unshaded;

uniform float clock = 0.0;
uniform float direction = 1.0;
varying vec2 local_point;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), u.x), u.y);
}

void vertex() {
	local_point = VERTEX;
}

void fragment() {
	vec2 uv = local_point / vec2(460.0, 220.0) + 0.5;
	vec2 flow = vec2(uv.x * 3.0 - clock * direction * 2.7, uv.y * 5.0);
	float curl = noise(flow * 1.7) * 0.6 + noise(flow * 3.4) * 0.25;
	float wisps = pow(max(0.0, sin(uv.y * 21.0 + curl * 6.0 + uv.x * 3.0)), 3.0);
	float edge = smoothstep(0.0, 0.22, uv.x) * (1.0 - smoothstep(0.72, 1.0, uv.x));
	float height = smoothstep(0.0, 0.24, uv.y) * (1.0 - smoothstep(0.74, 1.0, uv.y));
	COLOR = vec4(0.66, 0.8, 0.75, (wisps * 0.07 + curl * 0.055) * edge * height);
}
