shader_type spatial;
render_mode cull_disabled;

uniform float boil = 1.0;

void vertex() {
	VERTEX.xy += vec2(
		sin(VERTEX.y * 43.0 + TIME * 9.0) + sin(VERTEX.z * 37.0 - TIME * 7.0),
		cos(VERTEX.x * 39.0 - TIME * 8.0) + cos(VERTEX.z * 41.0 + TIME * 6.0)
	) * 0.006 * boil;
}

void fragment() {
	ALBEDO = vec3(0.05, 0.05, 0.06);
	ROUGHNESS = 1.0;
}
