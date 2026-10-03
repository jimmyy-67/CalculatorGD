shader_type canvas_item;

uniform float wobble_px = 2.0;
uniform float speed = 1.0;

void vertex() {
	VERTEX.x += (sin(VERTEX.y * 0.33 + TIME * 9.0) * 1.8
		+ sin(VERTEX.y * 0.11 + TIME * 7.0) * 0.9) * wobble_px * 0.5 * speed;
	VERTEX.y += (sin(VERTEX.x * 0.31 + TIME * 8.0) * 1.8
		+ sin(VERTEX.x * 0.13 + TIME * 6.0) * 0.9) * wobble_px * 0.5 * speed;
}
