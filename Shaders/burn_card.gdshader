shader_type canvas_item;

uniform vec2 position = vec2(0.5, 0.5);
uniform float radius = 0.0;
uniform float borderWidth = 0.02;
uniform float burnMult = 0.135;
uniform sampler2D noiseTexture;
uniform vec4 burnColor : source_color = vec4(1.0, 0.4, 0.0, 1.0);

void fragment() {
	float dist = length(position - UV) + (texture(noiseTexture, UV).r) * burnMult;
	COLOR.rgb = mix(COLOR.rgb, burnColor.rgb, float(dist<radius+borderWidth));
	COLOR.a *= 1.0-(float(dist<radius));
}