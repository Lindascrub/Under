shader_type canvas_item;
// Il capo: colori saturi che girano come un'insegna. Il più colorato di tutti.

uniform float speed = 0.35;

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float g = dot(t.rgb, vec3(0.299, 0.587, 0.114));
	vec3 c = mix(vec3(g), t.rgb, 2.2);
	float a = TIME * speed * 6.2831 + UV.y * 3.0;
	vec3 k = vec3(0.57735);
	c = c * cos(a) + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - cos(a));
	COLOR = vec4(clamp(c, 0.0, 1.0), t.a) * COLOR;
}
