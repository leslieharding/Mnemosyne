shader_type canvas_item;

uniform vec2 mouse_screen_pos;
uniform float hovering;
uniform float intensity = 8.0;

void vertex() {
	// Get vertex position in texture coordinates (0-1 range)
	vec2 normalized_vertex = VERTEX / vec2(100.0, 140.0);
	
	// Calculate distance from this vertex to mouse position
	// mouse_screen_pos is already normalized to card space
	vec2 to_mouse = mouse_screen_pos - normalized_vertex;
	float dist = length(to_mouse);
	
	// Create a falloff - vertices closer to mouse are displaced more
	// Using inverse square falloff for smooth effect
	float falloff = 1.0 / (1.0 + dist * dist * 2.0);
	
	// Direction from vertex toward mouse (normalized)
	vec2 direction = dist > 0.0 ? normalize(to_mouse) : vec2(0.0);
	
	// Displace vertex toward mouse, multiplied by hovering to enable/disable
	VERTEX += direction * falloff * intensity * hovering;
}