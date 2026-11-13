shader_type canvas_item;
// Miolo dos chãos (L41): os pixels marcados com magenta puro no atlas das bordas viram a
// textura grande do chão, presa ao MUNDO (não ao bloco), repetida em espelho (emenda nunca
// aparece e o desenho só se repete a cada 2 texturas). As bordas e o contorno vêm do atlas.

uniform sampler2D preenchimento : filter_nearest, repeat_disable;
// Pixels da arte por unidade do mundo (as peças entram com escala 0,25).
uniform float pixels_por_unidade = 4.0;

varying vec2 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy * pixels_por_unidade;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Marca do atlas: vermelho e azul no máximo; o verde guarda o sombreado das bolinhas da
	// borda (copiado da grama do pacote): tom = verde x 4 (1 = sem sombra).
	if (c.a > 0.99 && c.r > 0.99 && c.b > 0.99 && c.g < 0.6) {
		float tom = c.g * 4.0;
		vec2 tam = vec2(textureSize(preenchimento, 0));
		vec2 p = mod(floor(mundo + vec2(0.001)), tam * 2.0);
		p = mix(p, tam * 2.0 - 1.0 - p, step(tam, p));
		// clamp: o mod de ponto flutuante às vezes devolve o próprio 2 x tam (fora da textura).
		vec4 t = texelFetch(preenchimento, clamp(ivec2(p), ivec2(0), ivec2(tam) - 1), 0);
		COLOR = vec4(t.rgb * tom, 1.0);
	} else {
		COLOR = c;
	}
}
