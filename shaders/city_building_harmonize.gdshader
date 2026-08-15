shader_type canvas_item;

uniform float saturation : hint_range(0.0, 1.5) = 0.82;
uniform float brightness : hint_range(0.0, 1.5) = 0.96;
uniform vec3 city_tint : source_color = vec3(1.0, 0.97, 0.92);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 harmonized = mix(vec3(luminance), source.rgb, saturation);
	harmonized *= city_tint * brightness;
	COLOR = vec4(harmonized, source.a) * COLOR;
}
