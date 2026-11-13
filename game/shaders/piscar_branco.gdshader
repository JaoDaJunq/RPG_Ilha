shader_type canvas_item;
// Piscar branco ao apanhar (ReacaoGolpe): mistura a cor do desenho com branco, mantendo o
// contorno e a transparência. `branco` vai de 0 (normal) a 1 (silhueta branca).

uniform float branco : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(c.rgb, vec3(1.0), branco), c.a);
}
