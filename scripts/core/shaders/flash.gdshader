shader_type canvas_item;
// Blends the sprite toward a flat color. Used for hit flashes.

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Multiplying by COLOR keeps the modulate of the sprite and its parents (the invulnerability blink).
	COLOR = vec4(mix(tex.rgb, flash_color.rgb, flash_amount), tex.a) * COLOR;
}
