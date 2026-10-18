shader_type canvas_item;

// Reads the already-rendered screen below this ColorRect
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// 0 = fully grayscale, 1 = original color
uniform float saturation : hint_range(0.0, 1.0) = 0.45;

// Optional color tint to make the scene feel colder/duller
uniform vec4 tint : source_color = vec4(0.5, 0.55, 0.65, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.25;

void fragment() {
    vec4 screen_color = texture(screen_texture, SCREEN_UV);

    // Standard luminance calculation
    float gray = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));

    // Mix between grayscale and original color
    vec3 desaturated = mix(vec3(gray), screen_color.rgb, saturation);

    // Optional cold/dull tint
    vec3 final_color = mix(desaturated, desaturated * tint.rgb, tint_strength);

    COLOR = vec4(final_color, screen_color.a);
}