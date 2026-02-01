shader_type canvas_item;

uniform float breath_speed = 0.8;
uniform float breath_strength_min = 0.005;
uniform float breath_strength_max = 0.009;
uniform float variation_speed = 0.3;
uniform vec2 face_center = vec2(0.5, 0.5);
uniform float face_radius = 0.5;

float circle_mask(vec2 uv, vec2 center, float radius) {
	float d = distance(uv, center);
	return 1.0 - smoothstep(radius * 0.6, radius, d);
}

void fragment() {
	vec2 uv = UV;
	float face_m = circle_mask(uv, face_center, face_radius);
	float dist = distance(uv, face_center);
	float falloff = exp(-dist * dist * 6.0);
	
	// Create natural variation between min and max strength
	float variation = (sin(TIME * variation_speed) + 1.0) / 2.0;
	float breath_strength = mix(breath_strength_min, breath_strength_max, variation);
	
	float breath = sin(TIME * breath_speed) * breath_strength * face_m * falloff;
	vec2 breath_disp = vec2(0.0, breath);
	vec2 final_uv = uv + breath_disp;
	
	// Fix: Don't multiply by COLOR - just get the texture
	vec4 tex_color = texture(TEXTURE, final_uv);
	COLOR = tex_color;
}