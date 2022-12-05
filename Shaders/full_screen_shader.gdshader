shader_type canvas_item;

void fragment() {
	vec4 background = texture(SCREEN_TEXTURE, SCREEN_UV);
	float avg = (background.r + background.g + background.b) / 3.0;
	COLOR = vec4(vec3(avg), 1.0);
}