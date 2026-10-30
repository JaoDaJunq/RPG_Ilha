shader_type canvas_item;
// Chão com divisas suaves entre água, areia, terra e grama.
//
// A textura do sprite (TEXTURE) é o MAPA: 1 pixel por tile. Canal R = chão do tile
// (0 água, 1/3 areia, 2/3 grama, 1 terra), G = bloco com flores, B = água congelada.
// Cada pixel da arte decide o chão "misturando" os 4 tiles em volta (com curva suave e
// um pouco de ruído). Assim a divisa sai arredondada e orgânica, sem degraus de tile.
// As cores vêm todas da arte do chão (chao.png); aqui só se escurece a beirada.

uniform sampler2D chao_tex : filter_nearest;  // chao.png: 6 blocos de 32x32 lado a lado
uniform sampler2D gelo_tex : filter_nearest;
uniform sampler2D cobertura : filter_nearest;
uniform sampler2D mapa : filter_nearest;  // o mesmo mapa do sprite (TEXTURE)
uniform vec2 gelo_origem = vec2(224.0, 16.0);
uniform float tile = 16.0;
// Quanto a divisa ondula (0 = curva lisa) e o tamanho das ondas, em pixels da arte.
uniform float ondulacao = 0.5;
uniform float tamanho_onda = 9.0;
uniform vec4 espuma : source_color = vec4(0.92, 0.98, 1.0, 1.0);

// Altura de cada chão: o mais alto ganha a beirada escura.
const float AGUA = 0.0;
const float AREIA = 1.0;
const float TERRA = 2.0;
const float GRAMA = 3.0;
// Blocos na folha chao.png.
const float B_GRAMA = 0.0;
const float B_FLORES = 1.0;
const float B_TERRA = 2.0;
const float B_AREIA = 3.0;
const float B_AGUA = 4.0;

float acaso(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(acaso(i), acaso(i + vec2(1.0, 0.0)), f.x),
			mix(acaso(i + vec2(0.0, 1.0)), acaso(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec4 tile_em(vec2 cel) {
	ivec2 tam = textureSize(mapa, 0);
	return texelFetch(mapa, clamp(ivec2(cel), ivec2(0), tam - 1), 0);
}

// Quanto o tile e os vizinhos são (x) areia ou mais alto, (y) grama ou terra, (z) terra.
// Vem já "borrado" do jogo (world.gd), para a escada de tiles virar uma curva longa.
vec3 niveis(vec2 cel) {
	ivec2 tam = textureSize(cobertura, 0);
	return texelFetch(cobertura, clamp(ivec2(cel), ivec2(0), tam - 1), 0).rgb;
}

float altura(vec2 p) {
	vec2 c = p / tile - 0.5;
	vec2 i = floor(c);
	vec2 f = c - i;
	f = f * f * (3.0 - 2.0 * f);
	vec3 cob = mix(mix(niveis(i), niveis(i + vec2(1.0, 0.0)), f.x),
			mix(niveis(i + vec2(0.0, 1.0)), niveis(i + vec2(1.0, 1.0)), f.x), f.y);
	vec2 q = p / tamanho_onda;
	vec3 limite = 0.5 + (vec3(ruido(q), ruido(q + 37.0), ruido(q + 71.0)) - 0.5) * ondulacao;
	if (cob.x <= limite.x) return AGUA;
	if (cob.y <= limite.y) return AREIA;
	if (cob.z <= limite.z) return GRAMA;
	return TERRA;
}

vec4 cor_do_chao(float h, vec2 p) {
	vec4 t = tile_em(floor(p / tile));
	float bloco = B_AGUA;
	if (h == AGUA && t.b > 0.5) {
		return texture(gelo_tex, (gelo_origem + mod(p, tile)) / vec2(textureSize(gelo_tex, 0)));
	} else if (h == AREIA) {
		bloco = B_AREIA;
	} else if (h == TERRA) {
		bloco = B_TERRA;
	} else if (h == GRAMA) {
		bloco = t.g > 0.5 ? B_FLORES : B_GRAMA;
	}
	vec2 uv = (vec2(bloco * 32.0, 0.0) + mod(p, 32.0)) / vec2(textureSize(chao_tex, 0));
	return texture(chao_tex, uv);
}

void fragment() {
	vec2 tam = vec2(textureSize(mapa, 0));
	vec2 p = floor(UV * tam * tile) + 0.5;  // centro do pixel da arte
	float h = altura(p);
	vec4 cor = cor_do_chao(h, p);
	float dir = altura(p + vec2(1.0, 0.0));
	float esq = altura(p - vec2(1.0, 0.0));
	float sul = altura(p + vec2(0.0, 1.0));
	float norte = altura(p - vec2(0.0, 1.0));
	float mais_baixo = min(min(dir, esq), min(sul, norte));
	float mais_alto = max(max(dir, esq), max(sul, norte));
	if (mais_baixo < h) {
		cor.rgb *= 0.74;  // beirada do chão mais alto
	} else if (h == AGUA) {
		mais_alto = max(mais_alto, max(altura(p - vec2(0.0, 2.0)),
				max(altura(p + vec2(2.0, 0.0)), altura(p - vec2(2.0, 0.0)))));
		if (mais_alto > AGUA) {
			cor = mix(cor, espuma, 0.85);  // espuma na beira da água
		}
	} else if (max(norte, altura(p - vec2(0.0, 2.0))) > h) {
		cor.rgb *= 0.86;  // sombrinha embaixo da beirada
	}
	COLOR = cor;
}
