shader_type canvas_item;
uniform vec2 lightPos = vec2(450.0, 230.0);
uniform float lightRadius = 300.0;

void fragment() {
	//vec4 texColor = texture(TEXTURE, UV);
	vec2 worldPos = vec2(FRAGCOORD.x, FRAGCOORD.y);
	float dist = distance(worldPos, lightPos);
	float factor = clamp(dist / lightRadius, 0.0, 1.0);
	factor = smoothstep(lightRadius, lightRadius * 0.8, dist);
	factor = 1.0 - factor;
	vec4 shadow = COLOR * factor;
	COLOR = vec4(shadow.rgb, 1.0);///lightPos.x/200.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
