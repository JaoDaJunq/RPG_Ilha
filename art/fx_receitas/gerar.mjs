// Gera as receitas de efeito do Ilha Viva a partir dos exemplos do Pixelbolt, trocando as
// cores pelas do Tiny Swords (fogo: #484444 #955c3c #cf8935 #ffdc00 #ffffff; gelo: tons
// azul-esverdeados do pacote) e deixando só a direção "para a direita" (o jogo gira).
// Uso (da raiz):  node art/fx_receitas/gerar.mjs <pasta do Pixelbolt>
import fs from "node:fs";
import path from "node:path";

const pb = process.argv[2];
const ler = (n) => JSON.parse(fs.readFileSync(path.join(pb, "examples", n), "utf8"));
const salvar = (n, j) => fs.writeFileSync(path.join("art/fx_receitas", n), JSON.stringify(j, null, 2) + "\n");
const FOGO = { W: "#ffffff", y: "#ffdc00", o: "#cf8935", r: "#955c3c", R: "#484444" };
// Na bola de fogo, sem o cinza-escuro (a cauda ficava suja): o tom mais escuro é o marrom.
const FOGO_CLARO = { W: "#ffffff", y: "#ffdc00", o: "#cea554", r: "#cf8935", R: "#955c3c" };
const FUMACA = { s: "#ced9e0", S: "#a7abb4", k: "#7c7c86", d: "#484444" };
const GELO = { W: "#ffffff", p: "#c6f0db", c: "#9cbeaa", b: "#4697ac", B: "#485884", n: "#161c2e", s: "#5e5455" };
const GOLPE = { k: "#161c2e", b: "#485884", B: "#485884", c: "#4697ac", p: "#c6f0db", W: "#ffffff", y: "#ffdc00", Y: "#ffdc00", o: "#cf8935", O: "#cf8935" };

function so_direita(efeito) {
  if (efeito.turn) efeito.turn.angles = [0];
}

// 1) Bola de fogo: a do exemplo, maior (o projétil tem ~17 px de mundo).
const bola = ler("fireball.fx.json");
bola.name = "bola_de_fogo";
bola.palette = { ...FOGO_CLARO };
for (const e of Object.values(bola.effects)) so_direita(e);
salvar("bola_de_fogo.fx.json", bola);

// 2) Explosão da bola de fogo.
const exp = ler("fire-explosion.fx.json");
exp.name = "explosao";
exp.palette = { ...exp.palette, ...FOGO, ...FUMACA };
salvar("explosao.fx.json", exp);

// 3) Gelo: projétil (lança) e impacto (congelar).
const gelo = ler("ice-spells.fx.json");
gelo.name = "gelo";
gelo.palette = { ...GELO };
for (const k of Object.keys(gelo.effects)) if (!["projectile", "impact"].includes(k)) delete gelo.effects[k];
for (const e of Object.values(gelo.effects)) so_direita(e);
salvar("gelo.fx.json", gelo);

// 4) Golpe giratório e acerto.
const golpe = ler("slash-hit.fx.json");
golpe.name = "golpe";
golpe.palette = { ...golpe.palette, ...GOLPE };
for (const e of Object.values(golpe.effects)) so_direita(e);
salvar("golpe.fx.json", golpe);
console.log("receitas em art/fx_receitas/");

// Aumenta a geometria de um efeito (posições, larguras, raios, velocidades), mantendo o
// tamanho do pixel: a peça fica maior com o MESMO pixel do pacote (nada é esticado).
function aumentar(receita, k) {
  const v = (x) => (Array.isArray(x) ? x.map((n) => (typeof n === "number" ? n * k : n)) : typeof x === "number" ? x * k : x);
  receita.width = Math.round(receita.width * k);
  receita.height = Math.round(receita.height * k);
  if (receita.anchor) receita.anchor = v(receita.anchor).map(Math.round);
  for (const e of Object.values(receita.effects)) {
    if (e.turn?.about) e.turn.about = v(e.turn.about);
    for (const l of e.layers || []) for (const c of ["at", "to", "width", "wavelength", "radius"]) if (c in l) l[c] = v(l[c]);
    for (const m of e.emitters || []) {
      for (const c of ["at", "speed"]) if (c in m) m[c] = v(m[c]);
      if (m.area) m.area = v(m.area).map(Math.round);  // a área tem de ser inteira
      if (m.trail?.length) m.trail.length = Math.round(m.trail.length * k);
    }
  }
  return receita;
}

const bola2 = aumentar(JSON.parse(fs.readFileSync("art/fx_receitas/bola_de_fogo.fx.json", "utf8")), 2);
salvar("bola_de_fogo.fx.json", bola2);
const gelo2 = JSON.parse(fs.readFileSync("art/fx_receitas/gelo.fx.json", "utf8"));
delete gelo2.effects.impact;
gelo2.name = "lanca_gelo";
salvar("lanca_gelo.fx.json", aumentar(gelo2, 1.5));
const impacto = JSON.parse(fs.readFileSync("art/fx_receitas/gelo.fx.json", "utf8"));
delete impacto.effects.projectile;
impacto.name = "gelo_impacto";
salvar("gelo_impacto.fx.json", impacto);
fs.unlinkSync("art/fx_receitas/gelo.fx.json");
console.log("bola de fogo 2x, lança 1,5x");

// 5) Efeitos das habilidades 3 e 4 (01/11): escudo (Bloqueio), aura de fogo (Fúria),
//    raio caindo (Raio) e anel de gelo (Nova de gelo). A Fúria usa o círculo de fogo no chão.
const AZUL = { d: "#161c2e", n: "#485884", b: "#4697ac", c: "#c6f0db", W: "#ffffff" };
const escudo = ler("shield.fx.json");
escudo.name = "escudo";
escudo.palette = { ...AZUL };
salvar("escudo.fx.json", aumentar(escudo, 2.5));

const furia = ler("fire-spells.fx.json");
furia.name = "furia";
furia.palette = { ...furia.palette, ...FOGO, ...FUMACA };
for (const k of Object.keys(furia.effects)) if (k !== "area") delete furia.effects[k];
salvar("furia.fx.json", aumentar(furia, 2));

const raio = ler("lightning-strike.fx.json");
raio.name = "raio";
raio.palette = { g: "#484444", v: "#955c3c", b: "#cf8935", c: "#ffdc00", W: "#ffffff" };
salvar("raio.fx.json", aumentar(raio, 1.5));

const nova = ler("ice-spells.fx.json");
nova.name = "nova_gelo";
nova.palette = { ...GELO };
for (const k of Object.keys(nova.effects)) if (k !== "area") delete nova.effects[k];
salvar("nova_gelo.fx.json", aumentar(nova, 2.5));
console.log("receitas novas: escudo, furia, raio, nova_gelo");

// 6) Fogueira do acampamento (L37, 13/11): as chamas em laço sobre a lenha e as pedras da arte
//    (game/assets/sprites/tiny/fogueira_base.png), com faíscas subindo de vez em quando. É a
//    simulação de fogo do exemplo "campfire", sem a lenha desenhada (a lenha é a da arte; aqui
//    ela só segura o fogo, invisível), nas cores do Tiny Swords e sem a fumaça cinza.
const fogueira = ler("campfire.fluid.json");
fogueira.name = "fogueira";
fogueira.width = 40;
fogueira.height = 56;
// k, b e B só desenham os obstáculos invisíveis (a lenha e o chão).
// As cores das chamas são as da fogueira desenhada (L12): vermelho, laranja, amarelo e creme.
fogueira.palette = { R: "#cc5050", r: "#f6703e", y: "#ffdc00", W: "#f9f4a9", k: "#161c2e", b: "#5c3a2c", B: "#8a5a3c" };
const ef = fogueira.effects.campfire;
delete fogueira.effects.campfire;
fogueira.effects.fogo = ef;
ef.frames = 8;
ef.duration = 110;
ef.seed = 5;
ef.dissipation = 0.09;
ef.cooling = 0.26;
ef.buoyancy = 0.6;
ef.vorticity = 0.65;
fogueira.symbols.lenha = [
  "..kk........kk..",
  ".kBBkk....kkBBk.",
  "..kkbbBkkBbbkk..",
  "....kkbbbbkk....",
  "......kkkk......"
];
delete fogueira.symbols.logs;
fogueira.symbols.ground = ["k".repeat(40), "k".repeat(40)];
ef.obstacles = [{ symbol: "lenha", x: 12, y: 49, draw: "none" }, { symbol: "ground", x: 0, y: 54, draw: "none" }];
ef.emitters[0].at = [20, 50];
ef.emitters[0].radius = 7;
ef.emitters[0].temperature = 1.1;
ef.emitters[0].velocity = [0, -1.8];
ef.emitters[1].at = [20, 38];
ef.emitters[1].radius = 3;
ef.emitters[1].sparks.count = 0.25;
ef.emitters[1].sparks.life = [8, 16];
ef.emitters[1].sparks.colors = ["W", "y", "y", "r"];
ef.look = [{ field: "temperature", colors: ["R", "r", "y", "W"], thresholds: [0.3, 0.42, 0.64, 0.98], dither: 0 }];
salvar("fogueira.fluid.json", fogueira);
console.log("receita nova: fogueira");

// 7) Faíscas da fogueira (L37): na comparação lado a lado, as chamas desenhadas pelo Codex
//    (l37_chamas_v1) ficaram mais bonitas que as simuladas acima; o Pixelbolt fica com as
//    faíscas, que sobem mais alto que as chamas, numa volta mais longa (24 quadros), para
//    não parecerem repetidas. Só as faíscas: sem o fogo (temperatura zero, nada desenhado).
const faiscas = JSON.parse(JSON.stringify(fogueira));
faiscas.name = "faiscas";
faiscas.height = 72;
const fa = faiscas.effects.fogo;
delete faiscas.effects.fogo;
faiscas.effects.faiscas = fa;
fa.frames = 24;
fa.seed = 9;
fa.obstacles = [];
fa.emitters = [{
  name: "faiscas",
  at: [20, 58],
  radius: 4,
  rate: 1,
  sparks: { count: 0.15, life: [10, 18], colors: ["W", "y", "y", "r"], trail: true, angle: [258, 282], speed: [2.2, 3.4], drag: 0.06 }
}];
fa.look = [{ field: "temperature", colors: ["r"], thresholds: [0.5], dither: 0 }];
salvar("faiscas.fluid.json", faiscas);
console.log("receita nova: faiscas");
