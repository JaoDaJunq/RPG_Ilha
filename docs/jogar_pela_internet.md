# Jogar pela internet com amigos

O jogo conecta direto de um PC para o outro (o anfitrião abre a porta **7777**, UDP). Na mesma casa ou Wi-Fi isso já funciona. Pela internet, o jeito mais fácil sem mexer no roteador é uma **rede virtual**: todos entram nela e o jogo acha que estão na mesma casa.

## Opção 1: Hamachi (já instalado no PC do João)

1. **Anfitrião:** abra o Hamachi, clique em ligar, depois em **Rede → Criar nova rede**. Dê um nome (ex.: `ilha-viva-joao`) e uma senha.
2. **Amigos:** instalam o Hamachi (gratuito, até 5 pessoas por rede) e entram em **Rede → Entrar em rede existente** com o nome e a senha.
3. **Anfitrião:** abre o jogo e clica em **Hospedar para amigos**. O menu mostra os IPs; o do Hamachi começa com **25.** (ex.: 25.34.240.240).
4. **Amigos:** digitam esse IP 25.x no campo do menu e clicam em **Entrar**.

## Opção 2: Radmin VPN (gratuito, sem limite de pessoas)

Mesmo passo a passo do Hamachi: um cria a rede (nome e senha), os outros entram, e usa-se o IP que o Radmin mostra (também começa com 26. ou 25.).

## Opção 3: Tailscale (gratuito, mais moderno)

Cada um instala o Tailscale e entra com a mesma conta de grupo (ou o anfitrião convida os amigos). O IP do anfitrião começa com **100.**.

## Se não conectar

- **Firewall do Windows:** na primeira vez que o anfitrião hospeda, o Windows pergunta se o Godot pode usar a rede. Marque **as duas opções** (rede privada **e** pública: o Hamachi costuma ser tratado como pública) e clique em Permitir. Se a pergunta não apareceu: Painel de Controle → Firewall do Windows → Permitir um aplicativo → marcar o Godot nas duas colunas.
- Conferir que os dois estão **ligados** na rede virtual (bolinha verde no Hamachi).
- Conferir que o amigo digitou o IP **da rede virtual** (25.x no Hamachi), não o da casa (192.168.x).
- O anfitrião precisa estar **dentro do jogo** (já clicou em Hospedar) antes do amigo clicar em Entrar.

## O que foi testado

- Dois jogos na mesma máquina conectando pelo 127.0.0.1 (teste automático `rede_smoke`).
- **Ainda não foi testado** com outra pessoa de verdade, nem pelo Hamachi. O primeiro teste com um amigo vai mostrar se falta algo (atraso, firewall).
