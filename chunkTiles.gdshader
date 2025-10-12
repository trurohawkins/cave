shader_type canvas_item;
uniform vec2 lightPos = vec2(800.0, 200.0);
uniform float lightRadius = 1500.0;

void fragment() {
	//vec4 texColor = texture(TEXTURE, UV);
	vec2 light = vec2(450.0, 230.0);
	float radius = 300.0;
	vec2 worldPos = vec2(FRAGCOORD.x, FRAGCOORD.y);
	//vec2 worldPos = vec2(0.0, 0.0);
	
	float dist = distance(worldPos, light);
	float factor = clamp(1.0 - dist / radius, 0.0, 1.0);
	vec4 shadow = COLOR * factor;
	//COLOR = vec4(FRAGCOORD.xy / vec2(1280.0, 720.0), 0.0, 1.0);//
	COLOR = vec4(shadow.rgb, 1.0);///lightPos.x/200.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
