shader_type canvas_item;

// Wipe parameters
uniform int wipe_direction : hint_range(0, 3) = 0; // 0=North, 1=East, 2=South, 3=West
uniform vec4 old_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 new_color : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Highlight line
uniform float line_thickness : hint_range(0.0, 0.1) = 0.03;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 base_texture = texture(TEXTURE, UV);
	
	// Skip transparent pixels
	if (base_texture.a < 0.01) {
		discard;
	}
	
	// Calculate position along wipe direction (0.0 to 1.0)
	float wipe_pos;
	if (wipe_direction == 0) {
		// North to South: BOTTOM to TOP (swapped)
		wipe_pos = 1.0 - UV.y;
	} else if (wipe_direction == 1) {
		// East to West: left to right
		wipe_pos = UV.x;
	} else if (wipe_direction == 2) {
		// South to North: TOP to BOTTOM (swapped)
		wipe_pos = UV.y;
	} else {
		// West to East: right to left
		wipe_pos = 1.0 - UV.x;
	}
	
	// Choose color based on whether we've been wiped yet
	vec3 color;
	if (wipe_pos < progress) {
		// This part has been wiped - show new color
		color = new_color.rgb;
	} else {
		// Not wiped yet - show old color
		color = old_color.rgb;
	}
	
	// Add bright line at the wipe boundary
	float dist_from_line = abs(wipe_pos - progress);
	float line_alpha = smoothstep(line_thickness, 0.0, dist_from_line);
	
	// Mix in the white line
	color = mix(color, line_color.rgb, line_alpha);
	
	// Apply color to texture while keeping its luminosity
	vec3 final_color = mix(base_texture.rgb, color, 0.75);
	
	COLOR = vec4(final_color, base_texture.a);
}