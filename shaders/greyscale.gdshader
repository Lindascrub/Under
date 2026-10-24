shader_type canvas_item;
// Toglie il colore: chi è grigio in un mondo colorato (Fermo), o il mondo quando si spegne.
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float darken : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	// un grigio chiaro e stanco, non un'ombra nera
	g = 0.32 + g * 0.6;
	vec3 grey = vec3(g) * (1.0 - darken);
	COLOR = vec4(mix(c.rgb, grey, amount), c.a);
}
