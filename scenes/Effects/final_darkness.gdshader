shader_type canvas_item;
render_mode unshaded;

uniform float darkness : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(1.35, 1.0);
	float edge = smoothstep(0.12, 0.78, length(p));
	// A soft inward fade. At 1 even the center is completely black.
	float opacity = clamp(darkness + edge * darkness * (1.0 - darkness) * 1.8, 0.0, 1.0);
	COLOR = vec4(0.0, 0.0, 0.0, opacity);
}
