shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_tex : source_color, filter_linear;
uniform float strength = 0.12;
void vertex() {
	float m = clamp(VERTEX.y * 0.5, 0.0, 1.0);
	VERTEX.x += sin(TIME * 1.6 + VERTEX.z * 0.7 + VERTEX.x) * strength * m;
	VERTEX.z += cos(TIME * 1.2 + VERTEX.x * 0.7) * strength * m;
}
void fragment() {
	vec4 c = texture(albedo_tex, UV);
	if (c.a < 0.5) discard;
	ALBEDO = c.rgb;
}
