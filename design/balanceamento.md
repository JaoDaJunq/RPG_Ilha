# Balanceamento (31/10/2026)

Pedido do João: coletar com a mão tem de ser bem demorado; cada ferramenta melhor, mais rápido.
Tempo de cada golpe = `tempo_segurar` do recurso × força do personagem (`Ficha.tempo_coleta`, de 0,6 a 1,3) ÷ `poder` da ferramenta certa na mão.

## Coleta (personagem de Força 5)

| Recurso | Golpes | Mão | Madeira | Pedra |
|---|---|---|---|---|
| Árvore (`tempo_segurar` 3,0) | 3 | 9 s | 4,5 s (machado, poder 2,0) | 2,5 s (machado, poder 3,6) |
| Pedra (`tempo_segurar` 4,0) | 4 | 16 s | 5 s (picareta, poder 3,2) | 3 s (picareta, poder 5,3) |

Machado não ajuda a minerar e picareta não ajuda a cortar.

## Combate

- Slime: 4 de vida, 12 de dano no pulo (o da noite: 6,4 de vida e 18 de dano).
- Golpe: 1 × força × espada → mão e espada de madeira (1,3): 4 golpes; espada de pedra (1,6): 3; espada de ferro (2,0, só o Guerreiro começa com ela): 2.
- Jogador: 40 + 10 × Vitalidade de vida (90 a 120 no começo).
- Animais: galinha e coelho 2 de vida, ovelha 4, javali 7 (o javali revida com 10 de dano).
- Cabeçada (31/10/2026): slime e javali acertam uma vez e quicam ~12 px para trás; o slime espera 0,8 s e o javali ~1 s antes de atacar de novo. Quem apanha dá um passo para trás (9 px), fica vermelho e encolhido, a tela treme de leve e fica 0,5 s protegido. Abaixo de 40% de vida as bordas da tela ficam vermelhas (e pulsam mais quanto menor a vida).
- Dificuldade do mundo (`World.dificuldade`: 0 fácil, 1 normal, 2 difícil): dano de slime e javali x0,6 / x1 / x1,5; vida máxima de slimes e animais x0,8 / x1 / x1,3.

## Comida e cura

- Gosma curativa (2 gel de slime): +30. Carne assada (carne crua na fogueira): +25. Carne crua: +5. Ovo: +3.

## Habilidades (4 por classe, Q R T E)

| Classe | Q | R | T | E |
|---|---|---|---|---|
| Guerreiro | Investida | Giro | Bloqueio (6 mana, 10 s; 3 s com 60% menos dano) | Fúria (8 mana, 14 s; 5 s com +50% dano e +25% velocidade) |
| Mago | Bola de fogo | Lança de gelo | Raio (10 mana, 3 s; atordoa 1,2 s) | Nova de gelo (12 mana, 8 s; congela em volta) |
| Arqueiro | Tiro carregado | Armadilha | Chuva de flechas (10 mana, 6 s) | Bomba (9 mana, 5 s; explode em área, queima árvores) |
