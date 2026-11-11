shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_block_size : hint_range(1.0, 12.0, 1.0) = 3.0;

void fragment() {
	vec2 block_uv = SCREEN_PIXEL_SIZE * pixel_block_size;
	vec2 sample_uv = (floor(SCREEN_UV / block_uv) + vec2(0.5)) * block_uv;
	vec4 color = textureLod(screen_texture, clamp(sample_uv, vec2(0.0), vec2(1.0)), 0.0);
	if (color.a > 0.0001) {
		color.rgb /= color.a;
	}
	COLOR *= color;
}
