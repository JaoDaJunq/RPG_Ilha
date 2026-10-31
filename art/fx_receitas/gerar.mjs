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
