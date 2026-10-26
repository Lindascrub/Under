shader_type canvas_item;
// Toglie il colore: chi è grigio in un mondo colorato (Fermo), o il mondo quando si spegne.
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float darken : hint_range(0.0, 1.0) = 0.15;
// il grigio di ognuno: un po' più caldo, più freddo, più chiaro (data/looks.json)
uniform vec3 tint = vec3(1.0);
// le persone (scripts/looks.gd): un grigio che tiene il contrasto e un filo del colore di prima,
// così restano sbiadite ma riconoscibili. 0 = il grigio piatto di sempre.
uniform float person : hint_range(0.0, 1.0) = 0.0;
uniform float keep_color : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	// un grigio chiaro e stanco, non un'ombra nera
	vec3 flat_grey = vec3(0.32 + g * 0.6) * (1.0 - darken);
	vec3 faded = mix(vec3(g), c.rgb, keep_color) * 0.92 + 0.024;
	vec3 grey = clamp(mix(flat_grey, faded, person) * tint, 0.0, 1.0);
	COLOR = vec4(mix(c.rgb, grey, amount), c.a);
}
