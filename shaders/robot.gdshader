shader_type canvas_item;
// Trasforma un personaggio in "robot": metallo freddo e linee di scansione.
// amount = 0 -> persona normale, amount = 1 -> robot rivelato (finale ricco).

uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 metal = vec3(0.55, 0.66, 0.80) * (0.35 + g);
	float scan = 0.82 + 0.18 * sin(FRAGCOORD.y * 2.0 + TIME * 6.0);
	COLOR = vec4(mix(c.rgb, metal * scan, amount), c.a);
}
