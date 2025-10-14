shader_type canvas_item;

uniform float desaturation : hint_range(0.0, 1.0);// 0 full color, 1, greyscale

void fragment() {
	vec4 texColor = texture(TEXTURE, UV);
	//float gray = dot(texColor.rgb, vec3(0.299, 0.587, 0.114));
	float gray = dot(texColor.rgb, vec3(0.3, 0.257, 0.05));
	texColor.rgb = mix(texColor.rgb, vec3(gray), desaturation);
	COLOR = texColor;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
