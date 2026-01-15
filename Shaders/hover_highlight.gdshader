shader_type canvas_item;

uniform vec4 clr : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int type : hint_enum("Disable", "Round", "Square") = 2;
uniform float thickness = 2.0;
uniform int glow_layers = 3;
uniform float glow_falloff = 0.5;

// Pulse settings
uniform float pulse_speed = 2.0; // How fast it pulses (cycles per second)
uniform float pulse_intensity = 0.5; // How much it pulses (0.0 = no pulse, 1.0 = full pulse)
uniform float pulse_thickness_range = 0.3; // How much thickness varies (0.0-1.0)

const vec2[8] DIRECTIONS = {
	vec2(1.0, 0.0),
	vec2(0.0, 1.0),
	vec2(-1.0, 0.0),
	vec2(0.0, -1.0),
	vec2(1.0, 1.0),
	vec2(-1.0, 1.0),
	vec2(-1.0, -1.0),
	vec2(1.0, -1.0)
};

float gtz(float input) { return max(0.0, sign(input)); }

float check(sampler2D tex, vec2 from, vec2 size, float dist) {
	float result = 0.0;
	for (int i = 0; i < 4 * type; i++) {
		result += texture(tex, from + DIRECTIONS[i] * size * dist).a;
	}
	return gtz(result);
}

void fragment() {
	float is_transparent = 1.0 - gtz(COLOR.a);

	if (is_transparent > 0.0) {
		// Calculate pulse factor (0.0 to 1.0, oscillating)
		float pulse = (sin(TIME * pulse_speed * 6.28318) * 0.5 + 0.5);

		// Apply pulse to thickness and intensity
		float current_thickness = thickness * (1.0 + pulse * pulse_thickness_range);
		float intensity_multiplier = 1.0 + pulse * pulse_intensity;

		float glow_intensity = 0.0;

		for (int layer = 1; layer <= glow_layers; layer++) {
			float layer_dist = current_thickness * float(layer) / float(glow_layers);
			float layer_alpha = pow(1.0 - (float(layer - 1) / float(glow_layers)), 1.0 / glow_falloff);

			glow_intensity += check(TEXTURE, UV, TEXTURE_PIXEL_SIZE, layer_dist) * layer_alpha;
		}

		glow_intensity = min(1.0, glow_intensity / float(glow_layers)) * intensity_multiplier;
		COLOR = mix(COLOR, clr, glow_intensity);
	}
}