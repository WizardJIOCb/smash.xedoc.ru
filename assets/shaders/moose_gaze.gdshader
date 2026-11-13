shader_type canvas_item;

uniform sampler2D near_eye : source_color, filter_linear;
uniform sampler2D far_eye : source_color, filter_linear;
uniform float forward_gaze : hint_range(0.0, 1.0) = 1.0;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

vec4 eye_patch(vec4 original, vec2 pixel, vec4 rect, sampler2D donor) {
	vec2 uv = (pixel - rect.xy) / rect.zw;
	vec2 border = min(uv, vec2(1.0) - uv);
	float feather = smoothstep(0.0, 0.12, min(border.x, border.y));
	vec4 eye = texture(donor, clamp(uv, vec2(0.0), vec2(1.0)));
	return vec4(mix(original.rgb, eye.rgb, feather * eye.a * forward_gaze), original.a);
}

void fragment() {
	vec4 head = texture(TEXTURE, UV);
	vec2 pixel = UV * vec2(468.0, 333.0);
	head = eye_patch(head, pixel, vec4(265.0, 155.0, 46.0, 25.0), near_eye);
	head = eye_patch(head, pixel, vec4(317.0, 155.0, 22.0, 16.0), far_eye);
	COLOR = head * vertex_tint;
}
