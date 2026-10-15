shader_type canvas_item;
// Toglie colore al mondo man mano che sale il LV (più sfrutti, più tutto diventa grigio).

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(c.rgb, vec3(g) * 0.95, amount), 1.0);
}
