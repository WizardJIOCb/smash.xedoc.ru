shader_type canvas_item;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float luminance = dot(original.rgb, vec3(0.25, 0.6, 0.15));
	vec3 cold = mix(original.rgb * vec3(0.52, 0.65, 0.77), vec3(luminance * 0.62), 0.24);
	float source = smoothstep(0.12, 0.6, original.r - original.b * 0.5);
	vec3 quarantined = cold + source * vec3(0.29, 0.01, 0.005);
	float scan = sin(UV.y * 650.0 - TIME * 2.0) * 0.006;
	COLOR = vec4(quarantined + scan, original.a) * COLOR;
}
