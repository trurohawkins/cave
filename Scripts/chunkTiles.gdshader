shader_type canvas_item;

uniform int lightCount = 2;
//player light
uniform vec2 playerPos;
uniform float playerRadius;
uniform vec3 playerColor;

uniform vec2 lightPos[16];
uniform float lightRadii[16];// = 300.0;
uniform vec3 lightColors[16];
uniform vec3 ambientColor = vec3(0.1, 0, 0);

uniform vec2 tileSize = vec2(32.0, 32.0);
uniform vec2 tileMapOrigin = vec2(0.0, 0.0);
uniform mat3 cameraMatrix;
uniform vec2 viewport_size;

uniform mat4 inv_projection;
uniform mat4 camera_transform;

uniform vec2 camera_position;
uniform vec2 camera_zoom;
uniform vec2 screen_size;
uniform float camera_rotation;

mat2 rotation(float a) {
	float s = sin(a);
	float c = cos(a);
	return mat2(vec2(c, -s), vec2(s, c));
}
	
vec2 screen_to_world(vec2 screen_pos) {
    // Shift origin to screen center
    vec2 centered = (screen_pos - screen_size * 0.5);

    // Apply zoom (camera zoom acts inversely)
    centered /= camera_zoom;

    // Apply rotation (inverse rotation of camera)
    float c = cos(camera_rotation);
    float s = sin(camera_rotation);
    mat2 rot_inv = mat2(vec2(c, s), vec2(-s, c));
    centered = rot_inv * centered;

    // Add camera position
    return camera_position + centered;
}

vec3 checkLight(vec2 pos, vec2 light, float radius, vec3 color) {
	float dist = distance(pos, light);
	float factor = clamp(1.0 - dist / radius, 0.0, 1.0);
	return color * factor;
}

void fragment() {
	vec2 world_pos = screen_to_world(FRAGCOORD.xy);
	//vec2 local_pos = floor((world_pos / tileSize)
	vec2 tile_uv = floor(world_pos / tileSize);
	vec2 tileCenter = (tile_uv  + vec2(0.5)) * tileSize;// + tileMapOrigin;
    // Visualize world position (scaled down)
    //COLOR = vec4(fract(world_pos * 0.01), 0.0, 1.0);
	vec4 baseColor = texture(TEXTURE, UV);
	vec3 lighting = ambientColor + checkLight(tileCenter, playerPos, playerRadius, playerColor);
	
	for (int i = 0; i < lightCount; i++) {
		lighting += checkLight(tileCenter, lightPos[i], lightRadii[i], lightColors[i]);
	}
	lighting = clamp(lighting, vec3(0.0), vec3(1.0));
	COLOR = vec4(baseColor.rgb * lighting, baseColor.a) * COLOR;
	//vec4 shadow = COLOR * factor;
	//COLOR = vec4(FRAGCOORD.xy / vec2(1280.0, 720.0), 0.0, 1.0);//
	//COLOR = vec4(shadow.rgb, 1.0);///lightPos.x/200.0);
}
	/*
	vec3 screenPos = vec3(FRAGCOORD.x, FRAGCOORD.y, 1.0);
	vec2 worldPos = (cameraMatrix * screenPos).xy;
	
	//vec2 worldPos = FRAGCOORD.xy;
	vec2 localPos = worldPos - tileMapOrigin;
	vec2 tileIndex = floor(worldPos / tileSize);
	vec2 tileCenter = (tileIndex  + vec2(0.5)) * tileSize + tileMapOrigin;

	//vec2 worldPos = vec2(0.0, 0.0);
	    // Convert SCREEN_UV (0–1) to pixel coordinates
    vec2 screen_pos = SCREEN_UV * viewport_size;
    // Apply the 2D screen→world transform
    vec3 world = cameraMatrix * vec3(screen_pos, 1.0);
    vec2 world_pos = world.xy;
	*/
	/*
	vec2 screen_pos = (SCREEN_UV * screen_size;
	vec2 world_pos = (screen_pos * camera_zoom) + camera_position - (screen_size * 0.5 * camera_zoom);
	*/
	/*
	vec2 screen_pos = (SCREEN_UV - 0.5) * screen_size;
	vec2 world_pos = camera_position + rotation(camera_rotation) * (screen_pos * camera_zoom);
	vec2 map_space_pos = rotation(-camera_rotation) * (world_pos - tileMapOrigin);
	
	vec2 tileIndex = floor(map_space_pos / tileSize);
	vec2 tileCenterMap = (tileIndex + vec2(0.5)) * tileSize;
	vec2 tileCenter = tileMapOrigin + rotation(camera_rotation) * tileCenterMap;//(tileIndex + vec2(0.5)) * tileSize + tileMapOrigin;
	//vec2 tileCenter = camera_position + rotation(camera_rotation) * (tileMapOrigin + tileCenterMap - camera_position);
	*/
    //vec2 screen_pos = SCREEN_UV * vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);
//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
