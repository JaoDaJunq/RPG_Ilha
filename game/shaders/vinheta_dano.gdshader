shader_type canvas_item;
// Vinheta vermelha da vida baixa e dos golpes (efeito de interface em tela cheia):
// centro transparente, bordas vermelhas. `intensidade` vai de 0 (nada) a 1 (borda cheia).

uniform vec4 cor : source_color = vec4(0.72, 0.0, 0.03, 1.0);
uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
// Até onde o centro fica limpo (0 = o centro todo, 1 = só as pontas das bordas).
uniform float miolo : hint_range(0.0, 1.0) = 0.42;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	// Distância "quadrada arredondada": 1 no meio de cada borda, ~1,3 nos cantos.
	float d = pow(pow(abs(p.x), 2.5) + pow(abs(p.y), 2.5), 1.0 / 2.5);
	float borda = smoothstep(miolo, 1.15, d);
	COLOR = vec4(cor.rgb, borda * borda * intensidade);
}
