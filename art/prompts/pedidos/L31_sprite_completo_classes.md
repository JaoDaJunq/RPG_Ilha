# L31 · Sprite completo: as outras 4 classes das 4 raças (16 personagens)

**Por quê (12/11/2026):** o João aprovou o modelo dos guerreiros do L30 ("ficou bem o que eu queria"). Agora são o Mago, o Arqueiro, o Ladino e o Clérigo de cada raça: Humano, Ogro, Elfo e Anão.

**O texto é o do L30** (`L30_sprite_completo_piloto.md`): mesma grade, mesmos 6 quadros, mesmas regras FAÇA / NÃO FAÇA / NÃO SIGA. Muda só o personagem: "o Humano Guerreiro" vira "o <Raça> <Classe>", com o corpo da raça (o ogro é mais largo e verde, com presas; o elfo tem orelhas pontudas; o anão é baixo, largo e barbudo) e a roupa da classe vista nas imagens 1.

## Ordem para cada personagem

1. **Perfil primeiro.** Anexar:
   1. `art/sprites/tiny/candidatos/l29_<raca>_<classe>_perfil.png` e `l29_<raca>_<classe>_frente_costas.png`: quem é o personagem (rosto, cabelo, pele, roupa da classe).
   2. `art/sprites/tiny/candidatos/l30_<raca>_guerreiro_perfil.png`: o MESMO traço, tamanho, proporções e as mesmas 6 poses, já aprovados. Copiar o corpo e as poses, trocando só a roupa e o chapéu pelos da classe.
   3. `art/sprites/tiny/referencias/estilo_ilustracao.png` e `art/prompts/reguas/personagens_4x.png`.
2. **Frente e costas depois.** Anexar primeiro o perfil recém-feito (`l31_<raca>_<classe>_perfil.png`), depois `l30_<raca>_guerreiro_<vista>.png` (as mesmas poses vistas de frente ou de costas), e depois `l29_<raca>_<classe>_frente_costas.png`.

## Por classe

| Classe | Roupa (siga as imagens 1) | Mão da frente |
|---|---|---|
| Mago | túnica/manto de mago SEM MANGAS compridas, chapéu de mago | fechada e vazia (o jogo põe o cajado) |
| Arqueiro | colete e capuz de arqueiro, aljava nas costas (pode aparecer) | fechada e vazia (o jogo põe o arco). NÃO desenhe arco nem flecha na mão |
| Ladino | colete escuro, capuz ou lenço de ladino | AS DUAS mãos fechadas e vazias (o jogo põe uma adaga em cada) |
| Clérigo | túnica de clérigo com detalhe sagrado, sem mangas compridas | fechada e vazia (o jogo põe a maça) |

No quadro 5 (golpe, preparação), o braço da frente sobe BEM ALTO, com a mão fechada acima do ombro, igual ao L30.

## Saída

`art/sprites/tiny/candidatos/l31_<raca>_<classe>_<vista>.png` (vista = perfil, frente, costas). 1536x1024, 3x2 células de 512, fundo magenta chapado `#FF00FF`.
