shader_type canvas_item;
// O mapa (M): onde o grupo ainda não andou fica coberto pelo papel do mapa; a borda entre o
// visto e o não visto é suave (a máscara pequena é lida com filtro linear).

uniform sampler2D revelado : filter_linear;
uniform vec4 papel : source_color = vec4(0.84, 0.76, 0.60, 1.0);
uniform vec4 sombra_papel : source_color = vec4(0.70, 0.61, 0.46, 1.0);

void fragment() {
	vec4 mapa = texture(TEXTURE, UV);
	float r = texture(revelado, UV).r;
	float visto = smoothstep(0.3, 0.7, r);
	// Na beira do que foi visto o papel escurece um pouco (parece tinta borrada).
	vec4 cor_papel = mix(papel, sombra_papel, smoothstep(0.0, 0.3, r) * (1.0 - visto));
	COLOR = vec4(mix(cor_papel.rgb, mapa.rgb, visto), 1.0);
}
