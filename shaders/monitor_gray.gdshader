shader_type canvas_item;

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float shade = dot(pixel.rgb, vec3(0.30, 0.59, 0.11));
	COLOR = vec4(vec3(shade * 0.92, shade * 0.94, shade), pixel.a);
}
