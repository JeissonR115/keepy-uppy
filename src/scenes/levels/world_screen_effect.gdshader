shader_type canvas_item;

uniform float pixel_block_size : hint_range(1.0, 8.0, 1.0) = 3.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 block_size = SCREEN_PIXEL_SIZE * max(pixel_block_size, 1.0);
	vec2 sample_uv = floor(SCREEN_UV / block_size) * block_size + block_size * 0.5;
	COLOR = texture(screen_texture, sample_uv);
}
