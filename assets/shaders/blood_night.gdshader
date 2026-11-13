shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 hero_center = vec2(0.5, 0.5);

void fragment() {
	vec3 scene = texture(screen_texture, SCREEN_UV).rgb;
	float light = dot(scene, vec3(0.2126, 0.7152, 0.0722));
	vec3 night = mix(vec3(light) * vec3(0.22, 0.38, 0.65), scene * vec3(0.35, 0.53, 0.76), 0.65);
	// Retain warm lit windows; the whole district still reads as night.
	float warm = smoothstep(0.08, 0.3, scene.r - scene.b) * smoothstep(0.3, 0.7, light);
	night = mix(night, scene * vec3(0.85, 0.65, 0.48), warm * 0.65);
	vec2 from_hero = (UV - hero_center) * vec2(1.78, 0.55);
	float glow = exp(-dot(from_hero, from_hero) * 90.0);
	night = mix(night, scene * vec3(1.15, 0.78, 0.73), glow * 0.9);
	night += vec3(0.13, 0.006, 0.012) * glow;
	float vignette = smoothstep(0.85, 0.2, length((UV - 0.5) * vec2(1.2, 1.0)));
	night *= mix(0.65, 1.0, vignette);
	COLOR = vec4(mix(scene, night, strength), 1.0);
}
