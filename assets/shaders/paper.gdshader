shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform vec4 paper_color : source_color = vec4(0.949, 0.933, 0.886, 1.0);
uniform float sway = 1.0;

void vertex() {
	float hang = clamp(-VERTEX.y / 1.9, 0.0, 1.0);
	float tm = TIME * 5.0;
	float w1 = sin(VERTEX.y * 6.0 + tm + VERTEX.x * 2.0);
	float w2 = sin(VERTEX.y * 13.0 - tm * 1.7 + VERTEX.x * 5.0);
	VERTEX.z += (w1 * 0.05 + w2 * 0.02) * hang * sway;
	VERTEX.x += cos(VERTEX.y * 4.0 + tm * 0.8) * 0.04 * hang * sway;
}

void fragment() {
	ALBEDO = paper_color.rgb;
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
}
