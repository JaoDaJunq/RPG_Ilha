# L30 · Sprite completo (piloto): Humano Guerreiro animado nas 3 vistas

**Por quê (12/11/2026):** o personagem agora é só raça + classe (sem roupas, cabelos ou rostos trocáveis). Então cada personagem volta a ser **desenhado INTEIRO em cada quadro**, como as unidades do Tiny Swords. Isso deixa o desenho mais bonito do que as peças montadas. O L15 já tinha mostrado esse caminho funcionando para o perfil. Agora são as 3 vistas e a mão vazia.

**Piloto:** só o Humano Guerreiro. Se o João aprovar, os outros 19 seguem o mesmo texto.

**Anexar, nesta ordem:**
1. `art/sprites/tiny/candidatos/l29_humano_guerreiro_perfil.png` e `l29_humano_guerreiro_frente_costas.png`: **quem é o personagem**. O MESMO humano (rosto, cabelo castanho, pele pêssego) com a MESMA roupa do guerreiro (elmo de ferro redondo com tira de couro, túnica vermelho-escura com cota de malha curta, cinto marrom com fivela, sapatilhas claras), nas 3 vistas.
2. `art/sprites/tiny/referencias/estilo_ilustracao.png`: **o acabamento** (traço, cor chapada, contorno grosso).
3. `art/prompts/reguas/personagens_4x.png`: **as proporções e as poses** das unidades do Tiny Swords.

## Texto (o mesmo nas 3 folhas, trocando só a VISTA)

```text
TAREFA: uma folha de ANIMAÇÃO de UM personagem (o Humano Guerreiro das imagens 1), em ILUSTRAÇÃO 2D limpa (NÃO pixel art), no acabamento da imagem 2, com as proporções das unidades do Tiny Swords da imagem 3. O personagem é desenhado INTEIRO em cada quadro (cabeça, corpo, braços, mãos, pernas e pés juntos, como as unidades do Tiny Swords), NÃO em peças soltas.
Imagem 1536x1024, grade de 3 colunas x 2 linhas, células de 512x512, UM quadro por célula, todos na VISTA: <VISTA>.
1) PARADO.
2) PARADO RESPIRANDO: igual ao 1, com o corpo 3% mais baixo e os ombros um pouco para baixo.
3) ANDANDO, passo A: uma perna à frente, a outra atrás; os braços balançam ao contrário das pernas.
4) ANDANDO, passo B: o contrário do passo A.
5) GOLPE, preparação: o braço da frente puxado para trás e para cima, com a mão fechada (como quem vai bater com algo que segura).
6) GOLPE, ataque: o braço da frente esticado para a frente e para baixo, no fim do golpe, com a mão fechada.

FAÇA:
- O MESMO personagem em todos os quadros: mesma roupa, cores, rosto, cabelo, tamanho e proporções. Só muda a pose.
- Mesmo tamanho em todos os quadros: cerca de 380 px de altura em pé, os pés sempre na mesma linha, 40 px acima do fundo da célula, centralizado. A cabeça tem o mesmo tamanho em todos os quadros.
- Proporções do Tiny Swords: cabeça grande e redonda (quase metade da altura), corpo curto e roliço, bracinhos e perninhas curtos, mãos redondas.
- Roupa SEM MANGAS compridas: a túnica e a cota acabam no ombro; os braços aparecem de fora.
- A MÃO DA FRENTE (a mais perto de quem olha, que bate no golpe) sempre FECHADA E VAZIA, bem visível, como se segurasse um cabo invisível. O jogo põe a arma nessa mão.
- Cores chapadas com UM tom de sombra suave (cel shading), cores apagadas do Tiny Swords, contorno #161c2e grosso (cerca de 5 px) e uniforme em volta de tudo e entre as partes.
- Formas grandes e simples, poucos detalhes, rosto simples (olhos pequenos escuros).

NÃO FAÇA:
- NÃO desenhe arma, escudo na mão, ferramenta nem nada segurado: as mãos ficam vazias.
- NÃO desenhe pixel art nem "cara de pixel": é ilustração lisa (a gente transforma em pixel depois).
- NÃO separe o corpo em peças nem desenhe mãos soltas sem braço.
- NÃO desenhe rastro, linha de velocidade, poeira, brilho, sombra no chão, chão, cenário, texto, número ou moldura.
- NÃO deixe partes finas demais: tudo grosso e legível quando ficar pequeno.
- NÃO mude o tamanho do personagem entre os quadros, nem a altura dos pés.
- NÃO encoste na borda da célula; nada atravessa para a célula vizinha.

NÃO SIGA:
- NÃO siga as mãozinhas soltas nem o corpo sem braços das imagens 1 (elas servem só para saber o rosto, o cabelo e a roupa).
- NÃO siga anime nem "chibi de olhos enormes": rosto simples como o do Tiny Swords.
```

## As 3 folhas

| Saída (em `art/sprites/tiny/candidatos/`) | <VISTA> |
|---|---|
| `l30_humano_guerreiro_perfil.png` | DE PERFIL, olhando para a DIREITA (a mão da frente é a direita do desenho) |
| `l30_humano_guerreiro_frente.png` | DE FRENTE, olhando para quem joga (a mão da frente é a que fica à DIREITA de quem olha a imagem) |
| `l30_humano_guerreiro_costas.png` | DE COSTAS (vemos a nuca, as costas da túnica e o elmo por trás; a mão da frente é a que fica à DIREITA de quem olha a imagem) |

## Depois de gerar

Salvar só nos 3 caminhos acima. Não mexer em `game/` nem em nenhum outro arquivo. Responder com os caminhos e o tamanho de cada imagem.

## Outras raças na forma guerreira (12/11/2026, em paralelo ao humano)

O João pediu para fazer junto o Ogro, o Elfo e o Anão Guerreiro. Mesmo texto e mesmas regras, trocando só isto:
- **Imagens 1:** `art/sprites/tiny/candidatos/l29_<raca>_guerreiro_perfil.png` e `l29_<raca>_guerreiro_frente_costas.png` (o rosto, o cabelo, a pele e a roupa de guerreiro DAQUELA raça).
- No texto, "o Humano Guerreiro" vira "o <Raça> Guerreiro". O corpo segue a raça das imagens 1 (o ogro é mais largo e verde, com presas; o elfo tem orelhas pontudas; o anão é baixo, largo e barbudo). A altura de ~380 px continua sendo do humano: o anão fica um pouco mais baixo e o ogro um pouco mais largo, com os pés na mesma linha.
- **Saída:** `art/sprites/tiny/candidatos/l30_<raca>_guerreiro_<vista>.png` (raca = ogro, elfo, anao).
