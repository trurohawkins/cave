shader_type canvas_item;
uniform vec2 lightPos;
uniform float lightRadius;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	//vec4 texColor = texture(TEXTURE, UV);
	vec4 baseColor = COLOR;
	//Cinvert UV to world position
	vec2 worldPos = vec2(FRAGCOORD.x, FRAGCOORD.y);
	
	float dist = distance(worldPos, lightPos);
	float factor = 1.0;//clamp(1.0 - dist / lightRadius, 0.0, 1.0);
	
	//COLOR = vec4(1.0, 1.0, 1.0, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
