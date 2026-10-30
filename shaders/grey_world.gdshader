shader_type canvas_item;
// Toglie colore al mondo man mano che sale il LV (più sfrutti, più tutto diventa grigio).
// keep_rect (in coordinate dello schermo, 0..1): lì il colore resta (il tabellone rosso del Mercato),
// tranne sui pixel del giocatore che ci passa davanti (hole_*: il suo fotogramma di adesso).

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 keep_rect = vec4(0.0);
uniform vec4 hole_rect = vec4(0.0);
uniform sampler2D hole_tex : filter_nearest;
uniform vec4 hole_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool hole_flip = false;

bool inside(vec2 uv, vec4 r) {
	return r.z > 0.0 && uv.x >= r.x && uv.y >= r.y && uv.x < r.x + r.z && uv.y < r.y + r.w;
}

bool on_player(vec2 uv) {
	if (!inside(uv, hole_rect)) {
		return false;
	}
	vec2 local = (uv - hole_rect.xy) / hole_rect.zw;
	if (hole_flip) {
		local.x = 1.0 - local.x;
	}
	return texture(hole_tex, hole_region.xy + local * hole_region.zw).a > 0.1;
}

void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float a = (inside(SCREEN_UV, keep_rect) && !on_player(SCREEN_UV)) ? 0.0 : amount;
	COLOR = vec4(mix(c.rgb, vec3(g) * 0.95, a), 1.0);
}
