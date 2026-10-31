shader_type canvas_item;

// Troca as cores marcadas pelo tools/build_lpc_world.py: pixel com B = 254 e G = canal
// (1 pele, 2 olhos, 3 cabelo, 4 cor da peça) usa o tom R/32 da linha do canal na rampa.
uniform sampler2D ramp : filter_nearest;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	ivec3 b = ivec3(round(c.rgb * 255.0));
	if (b.b == 254 && b.g >= 1 && b.g <= 4) {
		int idx = clamp(b.r / 32, 0, 5);
		vec4 r = texelFetch(ramp, ivec2(idx, b.g), 0);
		COLOR = vec4(r.rgb, c.a);
	} else {
		COLOR = c;
	}
}
