shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float inner_stroke_thickness = 1.0;
uniform float inner_stroke_opacity = 1.0;
uniform float inside_opacity = 0.0;
uniform float frequency = 8.0;
uniform float phase_speed = 1.0;

void fragment() {
	vec4 inner_stroke;
	vec4 circle_outline;
	
	// INNER STROKE
	float radius = inner_stroke_thickness / float(textureSize(TEXTURE, 0).x);
	float minAlpha = 1.0;
	
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 offset = vec2(float(x), float(y)) * radius;
			float sampleAlpha = texture(TEXTURE, UV + offset).a;
			minAlpha = min(minAlpha, sampleAlpha);
		}
	}
	
	float originalAlpha = texture(TEXTURE, UV).a;
	
	if (originalAlpha > minAlpha) {
		float innerStrokeAlpha = originalAlpha * (originalAlpha - minAlpha) * inner_stroke_opacity;
		inner_stroke = vec4(1.0, 1.0, 1.0, innerStrokeAlpha);
	} else {
		float insideAlpha = originalAlpha * inside_opacity;
		inner_stroke = vec4(1.0, 1.0, 1.0, insideAlpha);
	}
	
	// CIRCLE OUTLINE
	vec2 pos = UV - vec2(0.5);
	float outer_radius = inner_stroke_thickness / 2.0;
	float inner_radius = outer_radius - inner_stroke_thickness;
	float outer_circle = step(length(pos), outer_radius);
	float inner_circle = step(length(pos), inner_radius);
	
	float angle = atan(pos.y, pos.x);
	if (angle < 0.0) {
		angle += 2.0 * PI;
	}
	
	float wave = 0.5 * sin(frequency * angle + TIME * phase_speed) + 0.5;
	float ring = outer_circle - inner_circle;
	ring *= step(0.5, wave);
	
	circle_outline = vec4(color.rgb, ring * color.a);
	
	COLOR = inner_stroke * circle_outline;
}