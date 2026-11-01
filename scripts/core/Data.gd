extends Node

## Dados estáticos do jogo: classes, itens, monstros, biomas, missões, talentos,
## mobília... Tudo que é "tabela" mora aqui, para balancear sem mexer na lógica.
## Autoload: acessível em qualquer script como `Data`.

const TILE := 16

# ------------------------------------------------------------------ Raridades
const RARITY_NAMES := ["Comum", "Incomum", "Raro", "Épico", "Lendário", "Mítico", "Divino", "Supremo"]
const RARITY_COLORS := [
	Color("c9c4b8"), Color("7ed957"), Color("5aa9ff"), Color("b57aff"), Color("ffb23e"), Color("ff5a4d"), Color("4de8d0"), Color("fff3a0"),
]
# Cor aplicada (modulate) sobre os ícones de equipamento conforme o nível do item.
const TIER_TINTS := [
	Color(0.80, 0.62, 0.42), Color(0.82, 0.84, 0.88), Color(0.55, 0.72, 1.0),
	Color(0.78, 0.58, 1.0), Color(1.0, 0.84, 0.40), Color(1.0, 0.48, 0.42),
	Color(0.45, 1.0, 0.85), Color(1.0, 0.96, 0.62),
]
# v2.8: 8 tiers de material: Madeira > Pedra > Ferro > Ouro > Diamante > Obsidiana > Adamantium > Supremo
const TIER_NAMES := ["Madeira", "Pedra", "Ferro", "Ouro", "Diamante", "Obsidiana", "Adamantium", "Supremo"]
const TIER_UNLOCK_LEVEL := [1, 5, 10, 18, 28, 45, 70, 100]

# --------------------------------------------------------------------- Classes
# weapon: família de arma que a classe usa. ranged: ataque à distância.
const CLASSES := {
	"cavaleiro": {
		"name": "Cavaleiro", "sheet": "Knight", "weapon": "sword", "ranged": false, "skill": "giro",
		"hp": 120, "atk": 12, "def": 3, "speed": 68.0, "crit": 5,
		"hp_lv": 10.0, "atk_lv": 1.6, "passive_text": "+10% de vida máxima",
		"desc": "Guerreiro equilibrado. Aguenta bastante dano e acerta em arco.",
	},
	"paladino": {
		"name": "Paladino", "sheet": "KnightGold", "weapon": "sword", "ranged": false, "skill": "luz",
		"hp": 140, "atk": 10, "def": 4, "speed": 64.0, "crit": 3,
		"hp_lv": 12.0, "atk_lv": 1.3, "passive_text": "Regenera vida aos poucos",
		"desc": "Resistente e abençoado. Cura a si mesmo e castiga os inimigos.",
	},
	"assassino": {
		"name": "Assassino", "sheet": "NinjaDark", "weapon": "dagger", "ranged": false, "skill": "sombra",
		"hp": 80, "atk": 16, "def": 1, "speed": 80.0, "crit": 14,
		"hp_lv": 6.0, "atk_lv": 2.2, "passive_text": "Golpes críticos causam mais dano",
		"desc": "Rápido e letal, mas frágil. Quem erra o rolamento, sente.",
	},
	"escudeiro": {
		"name": "Escudeiro", "sheet": "Boy", "weapon": "sword", "ranged": false, "skill": "muralha",
		"hp": 100, "atk": 8, "def": 6, "speed": 66.0, "crit": 3,
		"hp_lv": 9.0, "atk_lv": 1.1, "passive_text": "+25% de defesa",
		"desc": "Quase impossível de derrubar. Ataca devagar, mas nunca recua.",
	},
	"mago": {
		"name": "Mago", "sheet": "SorcererBlack", "weapon": "staff", "ranged": true, "skill": "meteoro",
		"hp": 70, "atk": 14, "def": 0, "speed": 66.0, "crit": 6,
		"hp_lv": 5.0, "atk_lv": 2.0, "passive_text": "Magias atravessam 1 inimigo",
		"desc": "Dano à distância devastador. Precisa manter distância.",
	},
	"arqueiro": {
		"name": "Arqueiro", "sheet": "Hunter", "weapon": "bow", "ranged": true, "skill": "chuva",
		"hp": 90, "atk": 11, "def": 1, "speed": 72.0, "crit": 10,
		"hp_lv": 7.0, "atk_lv": 1.7, "passive_text": "Flechas voam mais rápido e longe",
		"desc": "Mira precisa e mobilidade. Mata de longe sem se expor.",
	},
}

const WEAPON_FAMILY_NAMES := {"sword": "Armas pesadas", "dagger": "Lâminas leves", "staff": "Cajados", "bow": "Arcos"}

# ---------------------------------------------------------------------- Skills
# cd = recarga em segundos. icon = caminho em assets/ninja/skill_icons/
const SKILLS := {
	"giro": {"name": "Giro Cortante", "icon": "spell/Cut", "cd": 6.0,
		"desc": "Gira a lâmina e acerta todos ao redor (180% de dano) com empurrão."},
	"luz": {"name": "Luz Sagrada", "icon": "spell/Heal", "cd": 12.0,
		"desc": "Cura 30% da vida máxima e fere inimigos próximos (120%)."},
	"sombra": {"name": "Investida Sombria", "icon": "spell/Camouflage", "cd": 5.0,
		"desc": "Avança atravessando inimigos, imune, causando 220% de dano."},
	"muralha": {"name": "Muralha", "icon": "spell/DefenseUpgrade", "cd": 10.0,
		"desc": "Por 4s recebe 70% menos dano e empurra quem se aproxima."},
	"meteoro": {"name": "Explosão Arcana", "icon": "spell/Explosion", "cd": 6.0,
		"desc": "Detona uma explosão na direção da mira (260% de dano em área)."},
	"chuva": {"name": "Chuva de Flechas", "icon": "items/Arrow", "cd": 5.0,
		"desc": "Dispara 7 flechas em leque (100% de dano cada)."},
	# ---- ativas liberadas pela progressão (nível 10 = tecla R, nível 30 = tecla X).
	# kind: nova (área em volta), blast (área na mira, com atraso), dash (avanço), fan (projéteis em
	# leque), buff (efeito em você). Os números ficam aqui para balancear sem mexer no Player.
	"sismico": {"name": "Golpe Sísmico", "icon": "spell/RockSpike", "cd": 9.0, "kind": "blast", "anim": "slash",
		"dist": 34.0, "radius": 34.0, "mult": 2.2, "kb": 150.0, "delay": 0.1, "fx": "rock", "color": Color(1, 0.9, 0.75),
		"desc": "Racha o chão à frente: 220% de dano em área e empurrão."},
	"grito": {"name": "Grito de Guerra", "icon": "spell/AttackUpgrade", "cd": 18.0, "kind": "nova", "anim": "spellcast",
		"radius": 44.0, "mult": 0.8, "kb": 220.0, "fx": "boost", "color": Color(1, 0.75, 0.5), "buff": "forca", "buff_time": 8.0,
		"desc": "Empurra todos em volta (80%) e dá Força (+15% de ataque) por 8s."},
	"martelo": {"name": "Martelo da Justiça", "icon": "spell/BookLight", "cd": 9.0, "kind": "blast", "anim": "spellcast",
		"dist": 80.0, "radius": 30.0, "mult": 2.4, "kb": 120.0, "delay": 0.3, "fx": "thunder", "color": Color(1, 0.95, 0.6),
		"desc": "Um raio sagrado cai no inimigo mais próximo: 240% de dano em área."},
	"egide": {"name": "Égide", "icon": "spell/DefenseUpgrade", "cd": 20.0, "kind": "buff", "anim": "spellcast",
		"buff": "couraca", "buff_time": 8.0, "heal_pct": 0.2, "fx": "shield", "color": Color(1, 0.95, 0.7),
		"desc": "Cura 20% da vida e dá Couraça (+25% de defesa) por 8s."},
	"kunais": {"name": "Leque de Kunais", "icon": "items/Kunai", "cd": 6.0, "kind": "fan", "anim": "slash",
		"count": 5, "spread": 56.0, "mult": 0.9, "proj": "ARROW", "speed": 280.0, "range": 0.6,
		"desc": "Arremessa 5 kunais em leque (90% de dano cada)."},
	"danca": {"name": "Dança das Lâminas", "icon": "spell/Cut", "cd": 12.0, "kind": "nova", "anim": "slash",
		"radius": 36.0, "mult": 2.8, "kb": 90.0, "fx": "circular", "color": Color(0.8, 0.6, 1.0), "invuln": 0.4,
		"desc": "Gira imune por um instante: 280% de dano em todos em volta."},
	"investida": {"name": "Investida de Escudo", "icon": "items/Guard", "cd": 8.0, "kind": "dash", "anim": "thrust",
		"mult": 1.6, "speed": 300.0, "desc": "Avança com o escudo, atravessando e empurrando (160% de dano)."},
	"provocar": {"name": "Provocação", "icon": "spell/Counter", "cd": 16.0, "kind": "nova", "anim": "spellcast",
		"radius": 56.0, "mult": 0.5, "kb": 280.0, "fx": "boost", "color": Color(0.7, 0.85, 1.0), "buff": "couraca", "buff_time": 6.0,
		"desc": "Empurra longe quem está perto (50%) e dá Couraça (+25% de defesa) por 6s."},
	"nova_gelida": {"name": "Nova Gélida", "icon": "spell/BookIce", "cd": 8.0, "kind": "nova", "anim": "spellcast",
		"radius": 46.0, "mult": 1.7, "kb": 140.0, "fx": "circle", "color": Color(0.6, 0.85, 1.0),
		"desc": "Explosão de gelo em volta de você: 170% de dano e empurrão."},
	"meteoros": {"name": "Chuva de Meteoros", "icon": "spell/Fireball", "cd": 16.0, "kind": "blast", "anim": "thrust",
		"dist": 90.0, "radius": 30.0, "mult": 1.8, "kb": 120.0, "delay": 0.35, "fx": "explosion", "color": Color(1, 0.7, 0.5), "repeat": 3,
		"desc": "Três meteoros caem perto da mira (180% de dano cada)."},
	"perfurante": {"name": "Flecha Perfurante", "icon": "spell/MagicWeapon", "cd": 7.0, "kind": "fan", "anim": "shoot",
		"count": 1, "spread": 0.0, "mult": 3.2, "proj": "ARROW", "speed": 380.0, "range": 1.1, "pierce": 6,
		"desc": "Uma flecha que atravessa até 6 inimigos (320% de dano)."},
	"recuo": {"name": "Salto e Mira", "icon": "items/Boot", "cd": 12.0, "kind": "dash", "anim": "shoot",
		"mult": 0.0, "speed": -280.0, "buff": "foco", "buff_time": 6.0,
		"desc": "Salta para trás, imune, e ganha Foco (+12% de velocidade, +5% de crítico) por 6s."},
	# ---- magias dos Livros de Magia do laboratório (tecla Z, uma por vez)
	"chamas": {"name": "Bola de Fogo", "icon": "spell/Fireball", "cd": 7.0, "kind": "blast", "anim": "spellcast",
		"dist": 90.0, "radius": 28.0, "mult": 2.0, "kb": 120.0, "delay": 0.25, "fx": "explosion", "color": Color(1, 0.6, 0.3),
		"desc": "Uma bola de fogo explode no inimigo mais próximo: 200% de dano em área."},
	"gelo": {"name": "Lanças de Gelo", "icon": "spell/BookIce", "cd": 6.0, "kind": "fan", "anim": "spellcast",
		"count": 3, "spread": 22.0, "mult": 1.4, "proj": "ARROW", "speed": 300.0, "range": 0.8,
		"desc": "Três lanças de gelo em leque (140% de dano cada)."},
	"raio": {"name": "Relâmpago", "icon": "spell/BookThunder", "cd": 9.0, "kind": "blast", "anim": "spellcast",
		"dist": 100.0, "radius": 26.0, "mult": 2.6, "kb": 90.0, "delay": 0.2, "fx": "thunder", "color": Color(0.8, 0.9, 1.0),
		"desc": "Um raio cai do céu no inimigo mais próximo: 260% de dano."},
	"cura": {"name": "Bênção Curativa", "icon": "spell/Heal", "cd": 20.0, "kind": "buff", "anim": "spellcast",
		"buff": "regen", "buff_time": 6.0, "heal_pct": 0.35, "fx": "shield", "color": Color(0.7, 1.0, 0.7),
		"desc": "Cura 35% da vida e dá Regeneração por 6s."},
}

# ------------------------------------------------------------- Progressão de habilidades
# A cada 10 níveis a classe ganha uma habilidade nova, automaticamente:
#   "active": ativa nova numa tecla (R no nível 10, X no 30)
#   "passive": bônus permanente nos atributos (mesmas chaves dos buffs; hp_pct = % de vida, cdr = recarga menor)
#   "mastery": fortalece uma ativa (+30% de dano, -20% de recarga)
const SKILL_KEYS := {"skill": "Q", "skill2": "R", "skill3": "X", "skill_book": "Z"}
const MASTERY_DMG := 1.3
const MASTERY_CD := 0.8
const SKILL_LEVELS := [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
const CLASS_PROGRESSION := {
	"cavaleiro": [
		{"type": "active", "slot": "skill2", "skill": "sismico"},
		{"type": "passive", "name": "Pele de Aço", "icon": "items/Armor", "stat": {"hp_pct": 0.08}, "desc": "+8% de vida máxima."},
		{"type": "active", "slot": "skill3", "skill": "grito"},
		{"type": "passive", "name": "Braço Firme", "icon": "items/Kunai", "stat": {"atk_pct": 0.08}, "desc": "+8% de ataque."},
		{"type": "mastery", "slot": "skill", "desc": "Giro Cortante: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Veterano", "icon": "items/Guard", "stat": {"def_pct": 0.10, "cdr": 0.05}, "desc": "+10% de defesa e -5% de recarga."},
		{"type": "mastery", "slot": "skill2", "desc": "Golpe Sísmico: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Coração de Leão", "icon": "spell/Heal", "stat": {"hp_pct": 0.10, "regen": 0.8}, "desc": "+10% de vida e +0,8 de regeneração."},
		{"type": "mastery", "slot": "skill3", "desc": "Grito de Guerra: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Lenda do Reino", "icon": "spell/Upgrade", "stat": {"atk_pct": 0.15, "hp_pct": 0.15}, "desc": "+15% de ataque e +15% de vida."},
	],
	"paladino": [
		{"type": "active", "slot": "skill2", "skill": "martelo"},
		{"type": "passive", "name": "Bênção", "icon": "spell/Heal", "stat": {"regen": 0.6}, "desc": "+0,6 de regeneração."},
		{"type": "active", "slot": "skill3", "skill": "egide"},
		{"type": "passive", "name": "Fé Inabalável", "icon": "items/Guard", "stat": {"def_pct": 0.10}, "desc": "+10% de defesa."},
		{"type": "mastery", "slot": "skill", "desc": "Luz Sagrada: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Aura Santa", "icon": "spell/OrbLight", "stat": {"hp_pct": 0.10, "cdr": 0.05}, "desc": "+10% de vida e -5% de recarga."},
		{"type": "mastery", "slot": "skill2", "desc": "Martelo da Justiça: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Mão Justa", "icon": "spell/AttackUpgrade", "stat": {"atk_pct": 0.10}, "desc": "+10% de ataque."},
		{"type": "mastery", "slot": "skill3", "desc": "Égide: -20% de recarga."},
		{"type": "passive", "name": "Santo Guerreiro", "icon": "spell/Upgrade", "stat": {"regen": 1.5, "hp_pct": 0.15, "def_pct": 0.10}, "desc": "+15% de vida, +10% de defesa e +1,5 de regeneração."},
	],
	"assassino": [
		{"type": "active", "slot": "skill2", "skill": "kunais"},
		{"type": "passive", "name": "Olhar Frio", "icon": "spell/Vision", "stat": {"crit": 5.0}, "desc": "+5% de crítico."},
		{"type": "active", "slot": "skill3", "skill": "danca"},
		{"type": "passive", "name": "Passos Leves", "icon": "items/Boot", "stat": {"speed_pct": 0.08}, "desc": "+8% de velocidade."},
		{"type": "mastery", "slot": "skill", "desc": "Investida Sombria: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Veneno", "icon": "spell/Death", "stat": {"atk_pct": 0.10, "cdr": 0.05}, "desc": "+10% de ataque e -5% de recarga."},
		{"type": "mastery", "slot": "skill2", "desc": "Leque de Kunais: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Golpe Mortal", "icon": "spell/Cut", "stat": {"crit_dmg": 0.3, "crit": 4.0}, "desc": "+30% de dano crítico e +4% de crítico."},
		{"type": "mastery", "slot": "skill3", "desc": "Dança das Lâminas: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Fantasma", "icon": "spell/Camouflage", "stat": {"atk_pct": 0.15, "crit": 6.0, "speed_pct": 0.06}, "desc": "+15% de ataque, +6% de crítico e +6% de velocidade."},
	],
	"escudeiro": [
		{"type": "active", "slot": "skill2", "skill": "investida"},
		{"type": "passive", "name": "Couro Grosso", "icon": "items/Armor", "stat": {"def_pct": 0.10}, "desc": "+10% de defesa."},
		{"type": "active", "slot": "skill3", "skill": "provocar"},
		{"type": "passive", "name": "Raiz", "icon": "items/Guard", "stat": {"hp_pct": 0.10}, "desc": "+10% de vida."},
		{"type": "mastery", "slot": "skill", "desc": "Muralha: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Contra-ataque", "icon": "spell/Counter", "stat": {"atk_pct": 0.10, "cdr": 0.05}, "desc": "+10% de ataque e -5% de recarga."},
		{"type": "mastery", "slot": "skill2", "desc": "Investida de Escudo: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Bastião", "icon": "spell/DefenseUpgrade", "stat": {"def_pct": 0.15, "regen": 0.6}, "desc": "+15% de defesa e +0,6 de regeneração."},
		{"type": "mastery", "slot": "skill3", "desc": "Provocação: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Fortaleza Viva", "icon": "spell/Upgrade", "stat": {"def_pct": 0.20, "hp_pct": 0.20}, "desc": "+20% de defesa e +20% de vida."},
	],
	"mago": [
		{"type": "active", "slot": "skill2", "skill": "nova_gelida"},
		{"type": "passive", "name": "Mente Afiada", "icon": "spell/BookThunder", "stat": {"atk_pct": 0.08}, "desc": "+8% de ataque."},
		{"type": "active", "slot": "skill3", "skill": "meteoros"},
		{"type": "passive", "name": "Concentração", "icon": "spell/Vision", "stat": {"cdr": 0.08}, "desc": "-8% de recarga das habilidades."},
		{"type": "mastery", "slot": "skill", "desc": "Explosão Arcana: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Escudo Arcano", "icon": "spell/OrbWater", "stat": {"hp_pct": 0.12, "def_pct": 0.10}, "desc": "+12% de vida e +10% de defesa."},
		{"type": "mastery", "slot": "skill2", "desc": "Nova Gélida: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Erudito", "icon": "spell/BookLight", "stat": {"atk_pct": 0.10, "xp_pct": 0.05}, "desc": "+10% de ataque e +5% de XP."},
		{"type": "mastery", "slot": "skill3", "desc": "Chuva de Meteoros: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Sábio Lendário", "icon": "spell/Upgrade", "stat": {"atk_pct": 0.18, "cdr": 0.07}, "desc": "+18% de ataque e -7% de recarga."},
	],
	"arqueiro": [
		{"type": "active", "slot": "skill2", "skill": "perfurante"},
		{"type": "passive", "name": "Mira Firme", "icon": "spell/Vision", "stat": {"crit": 5.0}, "desc": "+5% de crítico."},
		{"type": "active", "slot": "skill3", "skill": "recuo"},
		{"type": "passive", "name": "Corda Tensa", "icon": "items/Arrow", "stat": {"atk_pct": 0.08}, "desc": "+8% de ataque."},
		{"type": "mastery", "slot": "skill", "desc": "Chuva de Flechas: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Andarilho", "icon": "items/Boot", "stat": {"speed_pct": 0.08, "hp_pct": 0.08}, "desc": "+8% de velocidade e +8% de vida."},
		{"type": "mastery", "slot": "skill2", "desc": "Flecha Perfurante: +30% de dano, -20% de recarga."},
		{"type": "passive", "name": "Olho de Águia", "icon": "spell/LuckUpgrade", "stat": {"crit": 5.0, "crit_dmg": 0.25}, "desc": "+5% de crítico e +25% de dano crítico."},
		{"type": "mastery", "slot": "skill3", "desc": "Salto e Mira: -20% de recarga."},
		{"type": "passive", "name": "Arqueiro Lendário", "icon": "spell/Upgrade", "stat": {"atk_pct": 0.15, "crit": 6.0, "cdr": 0.05}, "desc": "+15% de ataque, +6% de crítico e -5% de recarga."},
	],
}

# ------------------------------------------------------------- Promoção de classe
# Nos níveis 25, 50, 75 e 100 abre uma Prova de Promoção na Guilda. Ela conta a partir de quando
# abre: monstros derrotados, minutos de foco e chefes. Concluída, a Helena promove: título novo e
# bônus em ataque, defesa e vida (acumula).
const PROMOTION_LEVELS := [25, 50, 75, 100]
const PROMOTION_TRIALS := [
	{"monsters": 40, "focus": 120, "bosses": 0},
	{"monsters": 80, "focus": 240, "bosses": 1},
	{"monsters": 120, "focus": 360, "bosses": 2},
	{"monsters": 160, "focus": 480, "bosses": 3},
]
const PROMOTION_BONUS := {"atk_pct": 0.05, "def_pct": 0.05, "hp_pct": 0.05}   # por promoção
const PROMOTION_TITLES := {
	"cavaleiro": ["Cavaleiro de Elite", "Guardião Real", "Campeão do Reino", "Lenda Andante"],
	"paladino": ["Cruzado", "Templário", "Arauto da Luz", "Santo Guerreiro"],
	"assassino": ["Sombra", "Lâmina Noturna", "Mestre das Sombras", "Fantasma Lendário"],
	"escudeiro": ["Guarda de Ferro", "Bastião", "Muralha Viva", "Fortaleza Lendária"],
	"mago": ["Feiticeiro", "Arquimago", "Mestre Arcano", "Sábio Lendário"],
	"arqueiro": ["Patrulheiro", "Atirador de Elite", "Olho de Águia", "Arqueiro Lendário"],
}

# --------------------------------------------------------------------- Talentos
# Cada ponto de talento dá o bônus abaixo.
const TALENTS := {
	"forca": {"name": "Força", "icon": "items/Kunai", "desc": "+2 de ataque", "atk": 2.0},
	"vigor": {"name": "Vigor", "icon": "items/Armor", "desc": "+14 de vida máxima", "hp": 14.0},
	"guarda": {"name": "Guarda", "icon": "items/Guard", "desc": "+1 de defesa", "def": 1.0},
	"destreza": {"name": "Destreza", "icon": "items/Boot", "desc": "+0,8 de velocidade e +0,5% de crítico", "speed": 0.8, "crit": 0.5},
	"sorte": {"name": "Sorte", "icon": "items/Ring", "desc": "+1% de ouro e +0,6% de chance de drop", "luck": 1.0},
}
const TALENT_ORDER := ["forca", "vigor", "guarda", "destreza", "sorte"]
const TALENT_POINTS_PER_LEVEL := 2

# ----------------------------------------------------------------------- Buffs
const BUFFS := {
	"forca": {"name": "Força", "icon": "items/Kunai", "desc": "+15% de ataque", "atk_pct": 0.15},
	"foco": {"name": "Foco", "icon": "items/Boot", "desc": "+12% de velocidade, +5% de crítico", "speed_pct": 0.12, "crit": 5.0},
	"couraca": {"name": "Couraça", "icon": "items/Guard", "desc": "+25% de defesa", "def_pct": 0.25},
	"regen": {"name": "Regeneração", "icon": "spell/Heal", "desc": "Recupera 1,5 de vida por segundo", "regen": 1.5},
	"sabedoria": {"name": "Sabedoria", "icon": "spell/Vision", "desc": "+20% de XP", "xp_pct": 0.20},
	"banquete": {"name": "Banquete", "icon": "job/Dish", "desc": "+20% de ataque e +10% de defesa", "atk_pct": 0.20, "def_pct": 0.10},
	"muralha": {"name": "Muralha", "icon": "spell/DefenseUpgrade", "desc": "Recebe 70% menos dano", "dmg_taken_mult": 0.30},
}

# ----------------------------------------------------------------- Itens (DB)
# id -> {name, kind, slot, tier, rarity, icon, tint, atk, hp, def, speed, crit, luck,
#        price, desc, family, heal, hunger, buff, buff_time, shop_level}
var ITEMS: Dictionary = {}
var SHOP_ORDER: Array = []  # ids do equipamento de loja, por nível

const EQUIP_SLOTS := ["weapon", "helmet", "armor", "shield", "boots", "amulet"]
const SLOT_NAMES := {"weapon": "Arma", "helmet": "Capacete", "armor": "Armadura", "shield": "Escudo",
	"boots": "Botas", "amulet": "Amuleto"}
const SLOT_ICONS := {"weapon": "weapons/Sword_icon", "helmet": "skill_icons/items/Helmet", "armor": "skill_icons/items/Armor",
	"shield": "skill_icons/items/Guard", "boots": "skill_icons/items/Boot", "amulet": "skill_icons/items/Amulet"}

const WEAPON_TABLE := {
	"sword": [
		["espada_madeira", "Espada de Madeira", "Club"], ["espada_ferro", "Espada de Pedra", "Sword"],
		["espada_aco", "Espada de Ferro", "Sword2"], ["montante", "Montante de Ouro", "BigSword"],
		["machado_runico", "Machado de Diamante", "Axe"], ["martelo_real", "Martelo de Obsidiana", "Hammer"],
		["espada_adamantium", "Espada de Adamantium", "BigSword"], ["espada_suprema", "Espada Suprema", "Sword2"],
	],
	"dagger": [
		["osso_afiado", "Adaga de Madeira", "Bone"], ["ninjaku", "Adaga de Pedra", "Ninjaku"],
		["sai_aco", "Adaga de Ferro", "Sai"], ["katana", "Katana de Ouro", "Katana"],
		["florete", "Florete de Diamante", "Rapier"], ["lamina_sombria", "Lâmina de Obsidiana", "Sword2"],
		["adaga_adamantium", "Adaga de Adamantium", "Katana"], ["adaga_suprema", "Adaga Suprema", "Rapier"],
	],
	"staff": [
		["graveto_magico", "Graveto de Madeira", "Stick"], ["varinha", "Varinha de Pedra", "MagicWand"],
		["livro_feitico", "Livro de Ferro", "Book"], ["tridente_arcano", "Tridente de Ouro", "Fork"],
		["cajado_ancestral", "Cajado de Diamante", "Lance2"], ["varinha_estelar", "Varinha de Obsidiana", "MagicWand"],
		["cajado_adamantium", "Cajado de Adamantium", "Lance2"], ["cajado_supremo", "Cajado Supremo", "MagicWand"],
	],
	"bow": [
		["arco_curto", "Arco de Madeira", "Bow"], ["arco_longo", "Arco de Pedra", "Bow2"],
		["arco_composto", "Arco de Ferro", "Bow"], ["arco_cacador", "Arco de Ouro", "Bow2"],
		["arco_elfico", "Arco de Diamante", "Bow"], ["arco_estelar", "Arco de Obsidiana", "Bow2"],
		["arco_adamantium", "Arco de Adamantium", "Bow2"], ["arco_supremo", "Arco Supremo", "Bow"],
	],
}
const WEAPON_ATK := [5, 10, 17, 27, 40, 58, 85, 125]
const WEAPON_CRIT := {"sword": 0, "dagger": 2, "staff": 1, "bow": 1}

const ARMOR_TABLE := {
	"helmet": [["capuz_couro", "Capuz de Madeira"], ["capacete_ferro", "Elmo de Pedra"], ["elmo_aco", "Elmo de Ferro"],
		["elmo_mithril", "Elmo de Ouro"], ["elmo_runico", "Elmo de Diamante"], ["coroa_draconica", "Elmo de Obsidiana"],
		["elmo_adamantium", "Elmo de Adamantium"], ["coroa_suprema", "Coroa do Rei Divino"]],
	"armor": [["armadura_couro", "Armadura de Madeira"], ["cota_malha", "Armadura de Pedra"], ["peitoral_aco", "Armadura de Ferro"],
		["couraca_mithril", "Armadura de Ouro"], ["couraca_runica", "Armadura de Diamante"], ["couraca_draconica", "Armadura de Obsidiana"],
		["couraca_adamantium", "Armadura de Adamantium"], ["armadura_suprema", "Armadura do Rei Divino Galáctico"]],
	"shield": [["escudo_couro", "Escudo de Madeira"], ["escudo_ferro", "Escudo de Pedra"], ["escudo_aco", "Escudo de Ferro"],
		["escudo_mithril", "Escudo de Ouro"], ["escudo_runico", "Escudo de Diamante"], ["escudo_draconico", "Escudo de Obsidiana"],
		["escudo_adamantium", "Escudo de Adamantium"], ["escudo_supremo", "Escudo Supremo"]],
	"boots": [["botas_couro", "Botas de Madeira"], ["botas_ferro", "Botas de Pedra"], ["botas_aco", "Botas de Ferro"],
		["botas_mithril", "Botas de Ouro"], ["botas_runicas", "Botas de Diamante"], ["botas_draconicas", "Botas de Obsidiana"],
		["botas_adamantium", "Botas de Adamantium"], ["botas_supremas", "Botas Supremas"]],
	"amulet": [["amuleto_madeira", "Amuleto de Madeira"], ["amuleto_cobre", "Amuleto de Pedra"], ["amuleto_prata", "Amuleto de Ferro"],
		["amuleto_ouro", "Amuleto de Ouro"], ["amuleto_runico", "Amuleto de Diamante"], ["amuleto_draconico", "Amuleto de Obsidiana"],
		["amuleto_adamantium", "Amuleto de Adamantium"], ["amuleto_supremo", "Amuleto Supremo"]],
}
const ARMOR_DEF := {"helmet": [1, 2, 4, 6, 9, 13, 19, 28], "armor": [2, 4, 7, 11, 16, 23, 34, 50], "shield": [2, 3, 5, 8, 12, 17, 25, 37],
	"boots": [0, 1, 2, 3, 5, 7, 10, 14], "amulet": [0, 0, 0, 0, 0, 0, 0, 0]}
const ARMOR_HP := {"helmet": [4, 8, 14, 22, 34, 50, 72, 105], "armor": [8, 16, 28, 44, 66, 95, 140, 205], "shield": [6, 10, 18, 28, 42, 60, 88, 130],
	"boots": [0, 0, 0, 0, 0, 0, 0, 0], "amulet": [0, 0, 0, 0, 0, 0, 0, 0]}
const BOOT_SPEED := [2.0, 3.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0]
const AMULET_CRIT := [2.0, 3.0, 4.5, 6.5, 9.0, 12.0, 15.0, 18.0]
const AMULET_LUCK := [1.0, 2.0, 3.5, 5.0, 7.0, 10.0, 13.0, 16.0]
const TIER_PRICE := [30, 90, 260, 700, 1800, 4500, 11000, 28000]
# v3.5: ícone do amuleto por tier (Kyrise's 16x16 RPG Icon Pack, assets/custom/icons_k): o resto do equipamento usa o desenho do herói
const AMULET_ICONS := ["necklace_01a", "necklace_01b", "necklace_02b", "necklace_02d", "necklace_01c", "necklace_03e", "necklace_03a", "necklace_03d"]
const SLOT_PRICE_MULT := {"weapon": 1.3, "helmet": 0.7, "armor": 1.2, "shield": 0.9, "boots": 0.6, "amulet": 1.0}

const UPGRADE_MAX := 5
const UPGRADE_STAT_BONUS := 0.12  # por nível de aprimoramento, sobre os atributos base
const MATERIALS := {
	"barra_cobre": {"name": "Barra de Cobre", "icon": "items/resource/BarCopper", "price": 12, "tier": 0},
	"barra_ferro": {"name": "Barra de Ferro", "icon": "items/resource/BarIron", "price": 30, "tier": 1},
	"barra_prata": {"name": "Barra de Prata", "icon": "items/resource/BarSilver", "price": 80, "tier": 2},
	"barra_ouro": {"name": "Barra de Ouro", "icon": "items/resource/BarGold", "price": 160, "tier": 3},
	"barra_mithril": {"name": "Barra de Mithril", "icon": "items/resource/BarMithril", "price": 320, "tier": 4},
	"barra_obsidiana": {"name": "Barra de Obsidiana", "icon": "res://assets/custom/icons_k/crystal_01i.png", "price": 640, "tier": 5},
	"barra_adamantium": {"name": "Barra de Adamantium", "icon": "res://assets/custom/icons_k/gem_01a.png", "price": 1300, "tier": 6},
	"gema_verde": {"name": "Gema Verde", "icon": "items/resource/GemGreen", "price": 60, "tier": 1},
	"gema_roxa": {"name": "Gema Roxa", "icon": "items/resource/GemPurple", "price": 120, "tier": 2},
	"gema_vermelha": {"name": "Gema Vermelha", "icon": "items/resource/GemRed", "price": 240, "tier": 3},
	"gema_amarela": {"name": "Gema Amarela", "icon": "items/resource/GemYellow", "price": 480, "tier": 4},
}
# ------------------------------------------------------------------- Laboratório (Dr. Faísca)
# Ingredientes que os monstros soltam (Loot.drop_from_enemy) e receitas da bancada (LabWindow).
const LAB_MATERIALS := {
	"gosma": {"name": "Gosma Viscosa", "icon": "res://assets/custom/icons/gosma.png", "price": 6, "tier": 0},
	"pelo": {"name": "Pelo de Fera", "icon": "res://assets/custom/icons/pelo.png", "price": 7, "tier": 0},
	"asa": {"name": "Asa de Morcego", "icon": "res://assets/custom/icons/asa.png", "price": 9, "tier": 0},
	"osso": {"name": "Fragmento de Osso", "icon": "res://assets/custom/icons/osso.png", "price": 9, "tier": 0},
	"essencia": {"name": "Essência da Névoa", "icon": "res://assets/custom/icons/essencia.png", "price": 14, "tier": 1},
	"cristal": {"name": "Cristal Arcano", "icon": "res://assets/custom/icons/cristal.png", "price": 40, "tier": 2},
}
const LAB_DROP := {
	"slime": "gosma", "slime_verde": "gosma", "kappa": "gosma", "axolote": "gosma", "polvo": "gosma", "polvo_vermelho": "gosma",
	"lagarto": "gosma", "cobra": "gosma", "reptil": "gosma",
	"rato": "pelo", "lobo_jovem": "pelo", "lobo": "pelo", "lobo_sombra": "pelo", "urso": "pelo", "guaxinim": "pelo", "fera": "pelo",
	"morcego": "asa", "aranha": "asa", "espirito": "asa",
	"esqueleto": "osso", "cranio": "osso", "guardiao": "osso", "ciclope": "osso",
	"cogumelo": "essencia", "chama": "essencia", "demonio": "essencia", "nevoa": "essencia", "sombra": "essencia", "pagina": "essencia",
}
const LAB_DROP_CHANCE := 0.4
const LAB_CRYSTAL_CHANCE := 0.04       # elites: 0.3
# Itens novos do laboratório. kind tonic = efeito no estudo; book = ensina uma magia (tecla Z).
const LAB_ITEMS := {
	"tonico_memoria": {"name": "Tônico da Memória", "icon": "res://assets/custom/icons/tonico_memoria.png", "price": 60, "kind": "tonic", "sessions": 3, "pct": 0.25,
		"desc": "+25% de XP nas próximas 3 sessões de foco do Pomodoro."},
	"elixir_sabedoria": {"name": "Elixir da Sabedoria", "icon": "res://assets/custom/icons/elixir_sabedoria.png", "price": 45, "kind": "tonic", "buff": "sabedoria", "buff_time": 600.0,
		"desc": "Buff Sabedoria (+20% de XP) por 10 min."},
	"livro_chamas": {"name": "Livro de Magia: Chamas", "icon": "res://assets/custom/icons/livro_chamas.png", "price": 150, "kind": "book", "spell": "chamas",
		"desc": "Ensina Bola de Fogo (tecla Z)."},
	"livro_gelo": {"name": "Livro de Magia: Gelo", "icon": "res://assets/custom/icons/livro_gelo.png", "price": 150, "kind": "book", "spell": "gelo",
		"desc": "Ensina Lanças de Gelo (tecla Z)."},
	"livro_raio": {"name": "Livro de Magia: Raio", "icon": "res://assets/custom/icons/livro_raio.png", "price": 220, "kind": "book", "spell": "raio",
		"desc": "Ensina Relâmpago (tecla Z)."},
	"livro_cura": {"name": "Livro de Magia: Cura", "icon": "res://assets/custom/icons/livro_cura.png", "price": 180, "kind": "book", "spell": "cura",
		"desc": "Ensina Bênção Curativa (tecla Z)."},
}
## [resultado, quantidade, {ingrediente: qtd}, horas de foco exigidas (livros: estudo de verdade), fala do Dr. Faísca]
const LAB_RECIPES := [
	["pocao_vida", 2, {"erva_azul": 2, "gosma": 1}, 0, "Borbulhou verde! Isso é bom. Acho."],
	["pocao_media", 1, {"erva_azul": 2, "gosma": 2, "pelo": 2}, 0, "Cheira a cachorro molhado, mas cura que é uma beleza."],
	["pocao_grande", 1, {"erva_azul": 3, "essencia": 2, "cristal": 1}, 0, "ELIXIR VITAL! Pipeta, anota isso antes que eu esqueça!"],
	["tonico_memoria", 1, {"asa": 2, "essencia": 1, "erva_azul": 1}, 1, "Tônico da Memória: beba e estude. Ele só funciona se você ESTUDAR, viu?"],
	["elixir_sabedoria", 1, {"pelo": 2, "asa": 1}, 0, "Sabedoria engarrafada! Tem gosto de biblioteca."],
	["livro_chamas", 1, {"essencia": 3, "osso": 2, "cristal": 1}, 2, "O livro pegou fogo sozinho. Exatamente como planejado. Quase."],
	["livro_gelo", 1, {"gosma": 3, "asa": 2, "cristal": 1}, 2, "Brr! As páginas congelaram. Leia com luvas."],
	["livro_cura", 1, {"erva_azul": 4, "pelo": 2, "cristal": 1}, 3, "Um livro que abraça de volta. Não pergunte."],
	["livro_raio", 1, {"osso": 3, "essencia": 2, "cristal": 2}, 4, "KABUM! Meu cabelo ficou assim por causa desse livro."],
]

# Material exigido para aprimorar até o nível indicado (1..5) e quantidade.
const UPGRADE_MATERIAL := ["barra_cobre", "barra_cobre", "barra_ferro", "barra_prata", "barra_ouro"]
const UPGRADE_MATERIAL_QTY := [1, 2, 3, 3, 4]

# Poções e comidas. heal_pct = % da vida máxima; heal = valor fixo mínimo.
const CONSUMABLES := {
	"pocao_vida": {"name": "Poção de Vida Pequena", "icon": "res://assets/custom/icons/pocao_vida.png", "price": 20, "heal_pct": 0.30, "heal": 35,
		"desc": "Recupera 30% da vida máxima (mín. 35)."},
	"pocao_media": {"name": "Poção de Vida", "icon": "res://assets/custom/icons/pocao_media.png", "price": 70, "heal_pct": 0.60, "heal": 90,
		"desc": "Recupera 60% da vida máxima (mín. 90).", "shop_level": 8},
	"pocao_grande": {"name": "Elixir Vital", "icon": "res://assets/custom/icons/pocao_grande.png", "price": 180, "heal_pct": 1.0, "heal": 200,
		"desc": "Recupera toda a vida.", "shop_level": 20},
	"pao": {"name": "Pão", "icon": "items/food/Honey", "price": 8, "hunger": 35, "desc": "Mata a fome (+35)."},
	"onigiri": {"name": "Onigiri", "icon": "items/food/Onigiri", "price": 6, "hunger": 25, "desc": "Lanche simples (+25 de fome)."},
	"macarrao": {"name": "Macarrão Quente", "icon": "items/food/Noodle", "price": 40, "hunger": 45, "buff": "forca", "buff_time": 300.0,
		"desc": "+45 de fome. Buff Força por 5 min."},
	"sushi": {"name": "Sushi", "icon": "items/food/Sushi", "price": 45, "hunger": 30, "buff": "foco", "buff_time": 300.0,
		"desc": "+30 de fome. Buff Foco por 5 min."},
	"espeto": {"name": "Espeto Defumado", "icon": "items/food/Yakitori", "price": 45, "hunger": 35, "buff": "couraca", "buff_time": 300.0,
		"desc": "+35 de fome. Buff Couraça por 5 min."},
	"camarao": {"name": "Camarão Frito", "icon": "items/food/Shrimp", "price": 50, "hunger": 30, "buff": "regen", "buff_time": 300.0,
		"desc": "+30 de fome. Buff Regeneração por 5 min."},
	"peixe": {"name": "Peixe Grelhado", "icon": "items/food/Fish", "price": 80, "hunger": 40, "buff": "sabedoria", "buff_time": 600.0,
		"desc": "+40 de fome. Buff Sabedoria por 10 min.", "shop_level": 6},
	"banquete": {"name": "Banquete do Guerreiro", "icon": "items/food/Beaf", "price": 120, "hunger": 60, "buff": "banquete", "buff_time": 600.0,
		"desc": "+60 de fome. Buff Banquete por 10 min.", "shop_level": 12},
}
const RESTAURANT_MENU := ["pao", "onigiri", "macarrao", "sushi", "espeto", "camarao", "peixe", "banquete"]
const SHOP_POTIONS := ["pocao_vida", "pocao_media", "pocao_grande"]

# Prioridade de comida quando aperta [F]: usa a mais simples primeiro.
const FOOD_PRIORITY := ["pao", "onigiri", "macarrao", "sushi", "espeto", "camarao", "peixe", "banquete"]


func _init() -> void:
	_build_items()


func _build_items() -> void:
	ITEMS.clear()
	for family in WEAPON_TABLE:
		var rows: Array = WEAPON_TABLE[family]
		for t in rows.size():
			var row: Array = rows[t]
			var item := {
				"id": row[0], "name": row[1], "kind": "equip", "slot": "weapon", "tier": t, "family": family,
				"icon": "weapons/%s_icon" % row[2], "hand": ("weapons/%s" if family == "bow" else "weapons/%s_hand") % row[2],
				"tint": TIER_TINTS[t] if (t >= 2 and row[2] in ["Bow", "Bow2", "MagicWand", "Sword2"]) or t >= 6 else Color.WHITE,
				"atk": float(WEAPON_ATK[t]), "crit": float(WEAPON_CRIT[family] * (t + 1)) * 0.6,
				"price": int(TIER_PRICE[t] * SLOT_PRICE_MULT["weapon"]),
			}
			if family == "dagger":
				item["atk"] = float(WEAPON_ATK[t]) * 0.9
				item["crit"] = float(2 + t * 2)
			ITEMS[item["id"]] = item
	for slot in ARMOR_TABLE:
		var rows2: Array = ARMOR_TABLE[slot]
		for t in rows2.size():
			var row2: Array = rows2[t]
			var it := {
				"id": row2[0], "name": row2[1], "kind": "equip", "slot": slot, "tier": t,
				"icon": SLOT_ICONS[slot], "tint": TIER_TINTS[t],
				"def": float(ARMOR_DEF[slot][t]), "hp": float(ARMOR_HP[slot][t]),
				"price": int(TIER_PRICE[t] * SLOT_PRICE_MULT[slot]),
			}
			if slot == "boots":
				it["speed"] = BOOT_SPEED[t]
			if slot == "amulet":
				it["icon"] = "res://assets/custom/icons_k/%s.png" % AMULET_ICONS[t]
				it["tint"] = Color.WHITE
				it["crit"] = AMULET_CRIT[t]
				it["luck"] = AMULET_LUCK[t]
			ITEMS[it["id"]] = it
	for mid in MATERIALS:
		var m: Dictionary = MATERIALS[mid]
		ITEMS[mid] = {"id": mid, "name": m["name"], "kind": "material", "tier": m["tier"], "icon": m["icon"], "price": m["price"],
			"tint": m.get("tint", Color.WHITE), "desc": "Material de aprimoramento (Ferreiro)."}
	for lid in LAB_MATERIALS:
		var lm: Dictionary = LAB_MATERIALS[lid]
		ITEMS[lid] = {"id": lid, "name": lm["name"], "kind": "material", "tier": lm["tier"], "icon": lm["icon"], "price": lm["price"],
			"desc": "Ingrediente de laboratório (Dr. Faísca)."}
	for li in LAB_ITEMS:
		var it3: Dictionary = LAB_ITEMS[li].duplicate()
		it3["id"] = li
		it3["tier"] = 1
		ITEMS[li] = it3
	ITEMS["erva_azul"] = {"id": "erva_azul", "name": "Erva Medicinal", "kind": "material", "tier": 0, "icon": "res://assets/custom/icons/erva_azul.png", "price": 4,
		"desc": "Erva medicinal da floresta. As lojas compram."}
	for cid in CONSUMABLES:
		var c: Dictionary = CONSUMABLES[cid].duplicate()
		c["id"] = cid
		c["kind"] = "potion" if c.has("heal_pct") else "food"
		c["tier"] = 0
		ITEMS[cid] = c
	for it2 in ITEMS.values():
		if it2["kind"] == "equip":
			it2["rarity"] = int(it2["tier"])
			it2["desc"] = _equip_desc(it2)
		elif not it2.has("rarity"):
			it2["rarity"] = 0
	SHOP_ORDER.clear()
	for slot2 in EQUIP_SLOTS:
		pass


func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


func item_name(item_id: String) -> String:
	var it: Dictionary = ITEMS.get(item_id, {})
	return it.get("name", item_id)


func is_equipment(item_id: String) -> bool:
	return ITEMS.get(item_id, {}).get("kind", "") == "equip"


func slot_of(item_id: String) -> String:
	return ITEMS.get(item_id, {}).get("slot", "")


func _equip_desc(it: Dictionary) -> String:
	var parts: Array[String] = []
	if it.get("atk", 0.0) > 0.0:
		parts.append("+%d ataque" % int(round(it["atk"])))
	if it.get("hp", 0.0) > 0.0:
		parts.append("+%d vida" % int(round(it["hp"])))
	if it.get("def", 0.0) > 0.0:
		parts.append("+%d defesa" % int(round(it["def"])))
	if it.get("speed", 0.0) > 0.0:
		parts.append("+%d velocidade" % int(round(it["speed"])))
	if it.get("crit", 0.0) > 0.0:
		parts.append("+%s%% crítico" % _fmt(it["crit"]))
	if it.get("luck", 0.0) > 0.0:
		parts.append("+%s%% sorte" % _fmt(it["luck"]))
	return ", ".join(parts)


func _fmt(v: float) -> String:
	if absf(v - round(v)) < 0.05:
		return str(int(round(v)))
	return ("%.1f" % v).replace(".", ",")


## Equipamentos que a classe pode usar em um slot (arma depende da família).
func class_can_use(class_id: String, item_id: String) -> bool:
	var it: Dictionary = ITEMS.get(item_id, {})
	if it.get("kind", "") != "equip":
		return false
	if it["slot"] != "weapon":
		return true
	return CLASSES.get(class_id, {}).get("weapon", "") == it.get("family", "")


## Equipamentos de loja que a classe pode comprar, por tier.
func shop_equipment(class_id: String, tier: int) -> Array:
	var out: Array = []
	for slot in EQUIP_SLOTS:
		for it in ITEMS.values():
			if it["kind"] == "equip" and it["slot"] == slot and int(it["tier"]) == tier and class_can_use(class_id, it["id"]):
				out.append(it["id"])
	return out


func max_tier_for_level(level: int) -> int:
	var t := 0
	for i in TIER_UNLOCK_LEVEL.size():
		if level >= TIER_UNLOCK_LEVEL[i]:
			t = i
	return t


# ----------------------------------------------------------------- Progressão
func xp_for_level(level: int) -> int:
	return int(90.0 * pow(float(level), 1.25))


func class_base_hp(class_id: String, level: int) -> float:
	var c: Dictionary = CLASSES[class_id]
	return float(c["hp"]) + float(c["hp_lv"]) * float(level - 1)


func class_base_atk(class_id: String, level: int) -> float:
	var c: Dictionary = CLASSES[class_id]
	return float(c["atk"]) + float(c["atk_lv"]) * float(level - 1)


# -------------------------------------------------------------------- Monstros
# behavior: melee | charger | ranged | flyer | hopper
# hp/dmg/xp/gold são valores base do andar 1 (escalam com o andar).
const MONSTERS := {
	"slime": {"name": "Slime", "sheet": "Slime", "hp": 22, "dmg": 6, "speed": 26.0, "behavior": "hopper", "xp": 5, "gold": [2, 6], "radius": 5.0},
	"slime_verde": {"name": "Slime Verde", "sheet": "Slime3", "hp": 30, "dmg": 8, "speed": 28.0, "behavior": "hopper", "xp": 7, "gold": [3, 8], "radius": 5.0},
	"rato": {"name": "Rato", "sheet": "Mouse", "hp": 14, "dmg": 5, "speed": 52.0, "behavior": "melee", "xp": 4, "gold": [1, 4], "radius": 4.0},
	"morcego": {"name": "Morcego", "sheet": "BlueBat", "hp": 12, "dmg": 5, "speed": 56.0, "behavior": "flyer", "xp": 5, "gold": [1, 5], "radius": 4.0},
	"cogumelo": {"name": "Cogumelo", "sheet": "Mushroom", "hp": 28, "dmg": 7, "speed": 22.0, "behavior": "ranged", "xp": 7, "gold": [2, 7], "radius": 5.0, "proj": "spore", "range": 90.0, "cooldown": 2.4},
	"esqueleto": {"name": "Esqueleto", "sheet": "Skeleton", "kind": "char", "hp": 42, "dmg": 11, "speed": 36.0, "behavior": "melee", "xp": 11, "gold": [4, 11], "radius": 5.0},
	"cranio": {"name": "Crânio Flutuante", "sheet": "Skull", "hp": 30, "dmg": 12, "speed": 40.0, "behavior": "charger", "xp": 12, "gold": [4, 11], "radius": 5.0},
	"espirito": {"name": "Espírito", "sheet": "Spirit", "hp": 26, "dmg": 11, "speed": 30.0, "behavior": "ranged", "xp": 12, "gold": [5, 12], "radius": 5.0, "proj": "orb", "range": 100.0, "cooldown": 2.0},
	"aranha": {"name": "Aranha", "sheet": "SpiderRed", "hp": 34, "dmg": 11, "speed": 58.0, "behavior": "melee", "xp": 12, "gold": [4, 11], "radius": 5.0},
	"lagarto": {"name": "Lagarto", "sheet": "Lizard", "hp": 52, "dmg": 14, "speed": 38.0, "behavior": "charger", "xp": 15, "gold": [6, 14], "radius": 5.0},
	"kappa": {"name": "Kappa", "sheet": "KappaGreen", "hp": 58, "dmg": 15, "speed": 34.0, "behavior": "ranged", "xp": 19, "gold": [8, 18], "radius": 5.0, "proj": "water", "range": 96.0, "cooldown": 2.2},
	"cobra": {"name": "Cobra", "sheet": "Snake", "hp": 40, "dmg": 16, "speed": 54.0, "behavior": "melee", "xp": 18, "gold": [7, 16], "radius": 5.0},
	"polvo": {"name": "Polvo Verde", "sheet": "GreenOctopus", "hp": 66, "dmg": 16, "speed": 30.0, "behavior": "hopper", "xp": 20, "gold": [8, 18], "radius": 5.0},
	"reptil": {"name": "Réptil", "sheet": "Reptile", "hp": 70, "dmg": 18, "speed": 40.0, "behavior": "charger", "xp": 22, "gold": [9, 20], "radius": 5.0},
	"chama": {"name": "Chama Viva", "sheet": "Flam", "hp": 54, "dmg": 20, "speed": 36.0, "behavior": "ranged", "xp": 26, "gold": [10, 22], "radius": 5.0, "proj": "fire", "range": 104.0, "cooldown": 1.8},
	"ciclope": {"name": "Ciclope", "sheet": "Cyclope", "hp": 110, "dmg": 24, "speed": 30.0, "behavior": "charger", "xp": 34, "gold": [12, 28], "radius": 6.0},
	"fera": {"name": "Fera", "sheet": "Beast", "hp": 84, "dmg": 22, "speed": 50.0, "behavior": "melee", "xp": 30, "gold": [11, 25], "radius": 6.0},
	"polvo_vermelho": {"name": "Polvo Rubro", "sheet": "RedOctopus", "hp": 90, "dmg": 24, "speed": 32.0, "behavior": "hopper", "xp": 32, "gold": [12, 26], "radius": 5.0},
	"demonio": {"name": "Olho Maligno", "sheet": "Eye", "hp": 70, "dmg": 24, "speed": 34.0, "behavior": "ranged", "xp": 33, "gold": [12, 26], "radius": 5.0, "proj": "orb", "range": 110.0, "cooldown": 1.6},
	# --- floresta (a força vem do "poder" da zona, ver FOREST_ZONES)
	"lobo_jovem": {"name": "Lobo Jovem", "sheet": "Beast2", "hp": 26, "dmg": 7, "speed": 50.0, "behavior": "melee", "xp": 6, "gold": [2, 6], "radius": 5.0, "scale": 0.85},
	"lobo": {"name": "Lobo Cinzento", "sheet": "Beast2", "hp": 40, "dmg": 10, "speed": 54.0, "behavior": "melee", "xp": 9, "gold": [3, 8], "radius": 5.0},
	"lobo_sombra": {"name": "Lobo-Sombra", "sheet": "Beast2", "hp": 46, "dmg": 12, "speed": 46.0, "behavior": "charger", "xp": 12, "gold": [4, 10], "radius": 5.0, "tint": Color(0.45, 0.4, 0.62)},
	"urso": {"name": "Urso da Mata", "sheet": "Bear", "hp": 64, "dmg": 13, "speed": 34.0, "behavior": "charger", "xp": 13, "gold": [5, 12], "radius": 6.0, "scale": 1.1},
	"guaxinim": {"name": "Guaxinim Ladrão", "sheet": "Racoon", "hp": 28, "dmg": 8, "speed": 58.0, "behavior": "melee", "xp": 8, "gold": [5, 12], "radius": 5.0},
	"axolote": {"name": "Sapo do Pântano", "sheet": "Axolot", "hp": 40, "dmg": 11, "speed": 30.0, "behavior": "hopper", "xp": 11, "gold": [4, 10], "radius": 5.0},
	"nevoa": {"name": "Espírito da Névoa", "sheet": "Spirit2", "hp": 30, "dmg": 11, "speed": 30.0, "behavior": "ranged", "xp": 12, "gold": [4, 10], "radius": 5.0, "proj": "orb", "range": 100.0, "cooldown": 2.2, "tint": Color(0.75, 0.8, 0.95, 0.85)},
	"guardiao": {"name": "Guardião de Pedra", "sheet": "Statue", "kind": "char", "hp": 70, "dmg": 13, "speed": 26.0, "behavior": "melee", "xp": 14, "gold": [5, 12], "radius": 6.0, "tint": Color(0.75, 0.78, 0.82)},
	"pagina": {"name": "Página Viva", "sheet": "Larva", "hp": 24, "dmg": 9, "speed": 48.0, "behavior": "flyer", "xp": 8, "gold": [3, 8], "radius": 4.0, "tint": Color(1.0, 0.95, 0.8)},
	"sombra": {"name": "Sombra Esquecida", "sheet": "Skeleton", "kind": "char", "hp": 52, "dmg": 14, "speed": 38.0, "behavior": "melee", "xp": 13, "gold": [5, 12], "radius": 5.0, "tint": Color(0.5, 0.45, 0.65)},
	# --- v3.4: monstros do Dungeon Tileset II (0x72, CC0)
	"duende": {"name": "Duende Ladrão", "kind": "dt2", "dt2": "duende", "hp": 24, "dmg": 8, "speed": 52.0, "behavior": "melee", "xp": 9, "gold": [4, 12], "radius": 5.0},
	"zumbi": {"name": "Zumbi", "kind": "dt2", "dt2": "zumbi", "hp": 58, "dmg": 12, "speed": 22.0, "behavior": "melee", "xp": 11, "gold": [4, 11], "radius": 5.0},
	"necromante": {"name": "Necromante", "kind": "dt2", "dt2": "necromante", "hp": 34, "dmg": 13, "speed": 28.0, "behavior": "ranged", "xp": 14, "gold": [6, 14], "radius": 5.0, "proj": "orb", "range": 120.0, "cooldown": 2.6},
	"lodoso": {"name": "Lodoso", "kind": "dt2", "dt2": "lodoso", "hp": 42, "dmg": 10, "speed": 26.0, "behavior": "hopper", "xp": 9, "gold": [3, 9], "radius": 5.0},
	"pantaneiro": {"name": "Pantaneiro", "kind": "dt2", "dt2": "pantaneiro", "hp": 38, "dmg": 11, "speed": 30.0, "behavior": "ranged", "xp": 11, "gold": [4, 10], "radius": 5.0, "proj": "spore", "range": 100.0, "cooldown": 2.2},
	"lesma": {"name": "Lesma Gigante", "kind": "dt2", "dt2": "lesma", "hp": 30, "dmg": 7, "speed": 18.0, "behavior": "hopper", "xp": 7, "gold": [2, 7], "radius": 5.0},
	"diabrete": {"name": "Diabrete", "kind": "dt2", "dt2": "diabrete", "hp": 28, "dmg": 11, "speed": 48.0, "behavior": "charger", "xp": 12, "gold": [5, 12], "radius": 5.0},
	"chort": {"name": "Chort", "kind": "dt2", "dt2": "chort", "hp": 52, "dmg": 14, "speed": 38.0, "behavior": "melee", "xp": 14, "gold": [6, 14], "radius": 5.0},
	"orc_guerreiro": {"name": "Orc Guerreiro", "kind": "dt2", "dt2": "orc_guerreiro", "hp": 66, "dmg": 15, "speed": 32.0, "behavior": "melee", "xp": 16, "gold": [7, 16], "radius": 5.0},
	"orc_mascarado": {"name": "Orc Mascarado", "kind": "dt2", "dt2": "orc_mascarado", "hp": 54, "dmg": 14, "speed": 44.0, "behavior": "charger", "xp": 15, "gold": [6, 15], "radius": 5.0},
	"orc_xama": {"name": "Orc Xamã", "kind": "dt2", "dt2": "orc_xama", "hp": 40, "dmg": 13, "speed": 28.0, "behavior": "ranged", "xp": 15, "gold": [6, 15], "radius": 5.0, "proj": "orb", "range": 115.0, "cooldown": 2.3},
	"ogro": {"name": "Ogro", "kind": "dt2", "dt2": "ogro", "hp": 100, "dmg": 18, "speed": 26.0, "behavior": "melee", "xp": 22, "gold": [10, 22], "radius": 8.0},
	"wogol": {"name": "Wogol", "kind": "dt2", "dt2": "wogol", "hp": 56, "dmg": 14, "speed": 36.0, "behavior": "melee", "xp": 15, "gold": [6, 15], "radius": 5.0},
	"zumbi_gelo": {"name": "Zumbi Gélido", "kind": "dt2", "dt2": "zumbi_gelo", "hp": 64, "dmg": 14, "speed": 24.0, "behavior": "melee", "xp": 14, "gold": [6, 14], "radius": 5.0},
	"zumbi_pequeno": {"name": "Zumbi Pequeno", "kind": "dt2", "dt2": "zumbi_pequeno", "hp": 30, "dmg": 9, "speed": 34.0, "behavior": "melee", "xp": 8, "gold": [3, 8], "radius": 4.0},
	"anjo": {"name": "Anjo Caído", "kind": "dt2", "dt2": "anjo", "hp": 36, "dmg": 13, "speed": 42.0, "behavior": "flyer", "xp": 14, "gold": [6, 14], "radius": 5.0},
	"abobora": {"name": "Abóbora Maldita", "kind": "dt2", "dt2": "abobora", "hp": 46, "dmg": 12, "speed": 30.0, "behavior": "melee", "xp": 12, "gold": [5, 12], "radius": 5.0},
	"doutor": {"name": "Doutor Maluco", "kind": "dt2", "dt2": "doutor", "hp": 40, "dmg": 12, "speed": 26.0, "behavior": "ranged", "xp": 13, "gold": [5, 13], "radius": 5.0, "proj": "orb", "range": 110.0, "cooldown": 2.4},
	"lesminha": {"name": "Lesminha", "kind": "dt2", "dt2": "lesminha", "hp": 20, "dmg": 6, "speed": 22.0, "behavior": "hopper", "xp": 6, "gold": [2, 6], "radius": 4.0},
}

# Chefes: sprites em tiras horizontais. frames = quantidade; w = largura de cada quadro.
# anims: nome -> [arquivo, largura do quadro, nº de quadros, fps, loop]
const BOSSES := {
	"slime_gigante": {"name": "Slime Gigante", "folder": "GiantSlime", "hp": 420, "dmg": 16, "speed": 22.0, "xp": 160, "gold": [60, 90], "radius": 15.0,
		"patterns": ["slam", "summon", "burst"], "anims": {"idle": ["Idle", 62, 5, 6], "walk": ["Idle", 62, 5, 8], "hit": ["Hit", 62, 5, 10]}, "summon": "slime"},
	"ciclope_demoniaco": {"name": "Ciclope Demoníaco", "folder": "DemonCyclop", "hp": 760, "dmg": 24, "speed": 28.0, "xp": 300, "gold": [110, 160], "radius": 14.0,
		"patterns": ["charge", "burst", "slam"], "anims": {"idle": ["Idle", 50, 5, 6], "walk": ["Walk", 50, 6, 9], "hit": ["Hit", 50, 3, 10]}, "summon": "cranio"},
	"sapo_gigante": {"name": "Sapo Gigante", "folder": "GiantFrog", "hp": 1150, "dmg": 30, "speed": 30.0, "xp": 480, "gold": [160, 230], "radius": 14.0,
		"patterns": ["slam", "burst", "summon"], "anims": {"idle": ["Idle", 40, 5, 6], "walk": ["Idle", 40, 5, 8], "hit": ["Hit", 40, 3, 10]}, "summon": "kappa"},
	"tengu_rubro": {"name": "Tengu Rubro", "folder": "TenguRed", "hp": 1700, "dmg": 38, "speed": 34.0, "xp": 720, "gold": [240, 340], "radius": 15.0,
		"patterns": ["charge", "burst", "summon", "slam"], "anims": {"idle": ["Idle", 82, 6, 6], "walk": ["Walk", 82, 10, 9], "hit": ["Hit", 82, 8, 10]}, "summon": "chama"},
	"samurai_azul": {"name": "Samurai Gigante", "folder": "GiantBlueSamurai", "hp": 2300, "dmg": 46, "speed": 34.0, "xp": 1000, "gold": [320, 450], "radius": 15.0,
		"patterns": ["charge", "slam", "burst"], "anims": {"idle": ["Idle", 48, 12, 7], "walk": ["Walk", 48, 12, 10], "hit": ["Hit", 48, 8, 10]}, "summon": "fera"},
	"ogro_ancestral": {"name": "Ogro Ancestral", "dt2": "ogro", "scale": 2.4, "hp": 950, "dmg": 27, "speed": 28.0, "xp": 380, "gold": [130, 190], "radius": 18.0,
		"patterns": ["slam", "charge", "burst"], "anims": {}, "summon": "orc_guerreiro"},
	"zumbi_colossal": {"name": "Zumbi Colossal", "dt2": "zumbi_grande", "scale": 2.4, "hp": 1450, "dmg": 34, "speed": 24.0, "xp": 600, "gold": [200, 290], "radius": 18.0,
		"patterns": ["slam", "summon", "burst"], "anims": {}, "summon": "zumbi", "tint": Color(0.85, 1.0, 0.85)},
	"demonio_abissal": {"name": "Demônio Abissal", "dt2": "demonio_grande", "scale": 2.4, "hp": 2000, "dmg": 42, "speed": 34.0, "xp": 850, "gold": [280, 390], "radius": 18.0,
		"patterns": ["charge", "burst", "summon", "slam"], "anims": {}, "summon": "diabrete"},
	"orc_senhor": {"name": "Senhor da Guerra Orc", "dt2": "ogro", "scale": 2.6, "hp": 2600, "dmg": 50, "speed": 32.0, "xp": 1150, "gold": [360, 500], "radius": 19.0,
		"patterns": ["charge", "slam", "burst", "summon"], "anims": {}, "summon": "orc_mascarado", "tint": Color(1.0, 0.75, 0.7)},
	"guaxinim_gigante": {"name": "Guaxinim Gigante", "folder": "GiantRacoon", "hp": 2900, "dmg": 54, "speed": 32.0, "xp": 1300, "gold": [400, 560], "radius": 14.0,
		"patterns": ["slam", "burst", "summon", "charge"], "anims": {"idle": ["Idle", 60, 6, 6], "walk": ["Idle", 60, 6, 8], "hit": ["Idle", 60, 6, 10]}, "summon": "ciclope"},
}
const BOSS_ORDER := ["slime_gigante", "ciclope_demoniaco", "ogro_ancestral", "sapo_gigante", "zumbi_colossal", "tengu_rubro", "demonio_abissal", "samurai_azul", "orc_senhor", "guaxinim_gigante"]

# Chefes da história. "char" = usa a folha de personagem (4 direções) ampliada por "scale".
# gate_hours: horas de foco acumuladas para o chefe aceitar a luta. quiz: formato das perguntas
# (ver Recall.gd): "" = sem perguntas, "bank" = lacuna com banco de palavras, "type" = digitar a
# palavra, "free" = pergunta livre do Caderno.
const STORY_BOSSES := {
	"espirito_cacador": {"name": "Espírito do Caçador", "folder": "GiantSpirit", "hp": 150, "dmg": 8, "speed": 26.0, "xp": 90, "gold": [30, 50], "radius": 13.0,
		"patterns": ["charge", "burst", "summon"], "anims": {"idle": ["Idle", 50, 5, 6], "walk": ["Idle", 50, 5, 8], "hit": ["Hit", 50, 5, 10]}, "summon": "lobo_jovem",
		"tint": Color(0.75, 1.0, 0.85, 0.85), "gate_hours": 1, "quiz": "", "power": 2},
	"sentinela": {"name": "Sentinela de Pedra", "char": "Statue", "scale": 2.4, "hp": 330, "dmg": 13, "speed": 20.0, "xp": 260, "gold": [60, 90], "radius": 13.0,
		"patterns": ["slam", "burst", "summon"], "summon": "guardiao", "tint": Color(0.8, 0.82, 0.86), "gate_hours": 2, "quiz": "bank", "power": 6},
	"bibliotecario": {"name": "Bibliotecário Corrompido", "char": "NinjaMageBlack", "scale": 2.2, "hp": 450, "dmg": 17, "speed": 30.0, "xp": 420, "gold": [80, 120], "radius": 12.0,
		"patterns": ["burst", "summon", "charge"], "summon": "pagina", "gate_hours": 4, "quiz": "type", "power": 8},
	"ivo_duelo": {"name": "Ivo, o Vento", "char": "NinjaBlue2", "scale": 1.5, "hp": 380, "dmg": 15, "speed": 46.0, "xp": 300, "gold": [60, 90], "radius": 8.0,
		"patterns": ["charge", "burst", "charge"], "summon": "", "gate_hours": 0, "quiz": "", "power": 9},
	"cavaleiro_sem_nome": {"name": "Cavaleiro Sem Nome", "char": "Knight", "scale": 2.3, "hp": 600, "dmg": 21, "speed": 32.0, "xp": 600, "gold": [110, 160], "radius": 12.0,
		"patterns": ["charge", "slam", "burst"], "summon": "sombra", "tint": Color(0.55, 0.52, 0.62), "gate_hours": 6, "quiz": "free", "power": 10},
	"rei_demonio": {"name": "Rei Demônio", "char": "DemonRed", "scale": 2.7, "hp": 800, "dmg": 25, "speed": 32.0, "xp": 1200, "gold": [200, 300], "radius": 14.0,
		"patterns": ["slam", "charge", "burst", "summon"], "summon": "sombra", "gate_hours": 8, "quiz": "free", "power": 12},
}


func boss_def(boss_id: String) -> Dictionary:
	if STORY_BOSSES.has(boss_id):
		return STORY_BOSSES[boss_id]
	return BOSSES.get(boss_id, {})


# ------------------------------------------------------------------- Ranks e créditos
const RANKS := ["F", "E", "D", "C", "B", "A", "S"]
const MINUTES_PER_CREDIT := 45     # 1 crédito de estudo = 45 min de foco concluído

# ------------------------------------------------------------------- Masmorra da história
# Os 5 andares da história. "power" = força dos monstros (equivale ao andar antigo).
# Depois do Rei Demônio abrem as Profundezas (andar 6 em diante, chefes a cada 5 andares).
const STORY_FLOORS := {
	1: {"name": "Galerias Úmidas", "style": 0, "music": "dungeon1", "power": 7, "enemies": ["morcego", "cogumelo", "aranha", "pagina"], "chapter": 3},
	2: {"name": "Biblioteca Subterrânea", "style": 1, "music": "dungeon2", "power": 8, "enemies": ["pagina", "espirito", "cranio"], "boss": "bibliotecario", "chapter": 3},
	3: {"name": "Salas de Espelho", "style": 1, "music": "dungeon2", "power": 9, "enemies": ["espirito", "sombra", "cranio", "aranha"], "chapter": 4},
	4: {"name": "Corredor das Correntes", "style": 2, "music": "dungeon3", "power": 10, "enemies": ["sombra", "esqueleto", "lagarto", "cobra"], "boss": "cavaleiro_sem_nome", "chapter": 4},
	5: {"name": "Trono Sem Luz", "style": 3, "music": "dungeon4", "power": 12, "enemies": ["sombra", "chama", "demonio"], "boss": "rei_demonio", "chapter": 5},
}
const STORY_LAST_FLOOR := 5
const MAX_TOLL := 5


func floor_power(floor_n: int) -> int:
	if STORY_FLOORS.has(floor_n):
		return int(STORY_FLOORS[floor_n]["power"])
	return floor_n + 7


## Nome, estilo, música, monstros e chefe de um andar (história ou Profundezas).
func floor_info(floor_n: int) -> Dictionary:
	if STORY_FLOORS.has(floor_n):
		return STORY_FLOORS[floor_n]
	var b: Dictionary = biome_for_floor(floor_n)
	var out := {"name": "Profundezas - %s" % b["name"], "style": b["style"], "music": b["music"], "power": floor_power(floor_n),
		"enemies": b["enemies"], "chapter": 6}
	if floor_n % 5 == 0:
		out["boss"] = boss_for_floor(floor_n)
	return out


## Pedágio para entrar no andar: sempre ENTRY_COST.
func floor_toll(_floor_n: int) -> int:
	return ENTRY_COST


# ------------------------------------------------------------------- Viagens
# Toda entrada na floresta ou na masmorra (e cada escada) custa ENTRY_COST crédito, sempre.
# Créditos só vêm de foco (MINUTES_PER_CREDIT). Morrer tira DEATH_CREDIT_LOSS; o saldo pode ficar
# negativo e o foco seguinte paga a dívida antes de liberar novas entradas.
const ENTRY_COST := 1
const DEATH_CREDIT_LOSS := 1


## Custo de uma viagem (fixo; os parâmetros ficam por compatibilidade com quem chama).
func travel_cost(_base: int = 1, _entries_before: int = 0) -> int:
	return ENTRY_COST


# ------------------------------------------------------------------- Floresta
# Zonas da floresta (ver Forest.gd). power = força dos monstros; rank = rank mínimo para entrar.
const FOREST_ZONES := {
	"borda": {"name": "Borda da Floresta", "power": 1, "rank": 0, "enemies": ["slime", "lobo_jovem", "cogumelo"]},
	"clareira": {"name": "Clareira das Casas", "power": 3, "rank": 0, "enemies": ["lobo", "guaxinim", "esqueleto", "urso"]},
	"mata": {"name": "Mata Profunda", "power": 5, "rank": 1, "enemies": ["aranha", "lobo_sombra", "nevoa", "morcego"]},
	"pantano": {"name": "Pântano da Névoa", "power": 6, "rank": 1, "enemies": ["axolote", "cobra", "kappa", "nevoa"]},
	"ruinas": {"name": "Ruínas sob as Raízes", "power": 6, "rank": 1, "enemies": ["guardiao", "cranio"]},
}

# ------------------------------------------------------------------- Pets
# bonus: somado aos atributos (mesmas chaves de GameState._compute_stats). grow: por capítulo concluído.
const PETS := {
	"corvin": {"name": "Corvin", "kind": "animal", "sheet": "Parrot", "tint": Color(0.32, 0.3, 0.4), "attack": "dive",
		"bonus": {"crit": 3.0, "luck": 5.0}, "desc": "Corvo esperto. +3% de crítico e mais chance de item raro.", "face": "animals/Parrot_face.png"},
	"brisa": {"name": "Brisa", "kind": "monster", "sheet": "Beast2", "tint": Color(1.15, 1.15, 1.3), "attack": "bite",
		"bonus": {"atk_pct": 0.06, "hp": 10.0}, "grow": {"atk_pct": 0.02}, "desc": "Loba leal. +6% de ataque e +10 de vida; fica mais forte a cada capítulo.", "face": "monsters/Beast2_face.png"},
	"lumen": {"name": "Lúmen", "kind": "monster", "sheet": "Owl2", "tint": Color.WHITE, "attack": "orb",
		"bonus": {"xp_pct": 0.10, "focus_xp_pct": 0.05}, "desc": "Coruja sábia. +10% de XP em combate e +5% nas sessões de foco.", "face": "monsters/Owl2_face.png"},
	"airevis": {"name": "Airevis", "kind": "monster", "sheet": "Spirit2", "tint": Color(0.8, 0.88, 1.0, 0.8), "attack": "orb",
		"bonus": {"regen": 0.6, "hp": 8.0}, "desc": "Espírito da névoa. Regenera 0,6 de vida por segundo e +8 de vida.", "face": "monsters/Spirit2_face.png"},
}
const PET_ORDER := ["corvin", "brisa", "lumen", "airevis"]

# Biomas: 4 camadas de 5 andares. floor_style escolhe a paleta do chão/parede.
const BIOMES := [
	{"name": "Caverna Úmida", "music": "dungeon1", "style": 0, "enemies": ["slime", "rato", "morcego", "cogumelo"], "boss_color": Color.WHITE},
	{"name": "Cripta Esquecida", "music": "dungeon2", "style": 1, "enemies": ["esqueleto", "cranio", "espirito", "aranha", "lagarto", "duende", "zumbi", "necromante"], "boss_color": Color.WHITE},
	{"name": "Pântano Sombrio", "music": "dungeon3", "style": 2, "enemies": ["kappa", "cobra", "polvo", "reptil", "slime_verde", "lodoso", "pantaneiro", "lesma"], "boss_color": Color.WHITE},
	{"name": "Forja Infernal", "music": "dungeon4", "style": 3, "enemies": ["chama", "ciclope", "fera", "polvo_vermelho", "demonio", "diabrete", "chort"], "boss_color": Color.WHITE},
	{"name": "Fortaleza Orc", "music": "dungeon3", "style": 2, "enemies": ["orc_guerreiro", "orc_mascarado", "orc_xama", "ogro", "wogol"], "boss_color": Color.WHITE},
	{"name": "Catacumbas Geladas", "music": "dungeon2", "style": 1, "enemies": ["zumbi_gelo", "zumbi_pequeno", "anjo"], "boss_color": Color.WHITE},
	{"name": "Jardim Maldito", "music": "dungeon1", "style": 0, "enemies": ["abobora", "doutor", "lesminha"], "boss_color": Color.WHITE},
]


func biome_for_floor(floor_n: int) -> Dictionary:
	return BIOMES[((floor_n - 1) / 5) % BIOMES.size()]


func is_boss_floor(floor_n: int) -> bool:
	return floor_n % 5 == 0


func boss_for_floor(floor_n: int) -> String:
	return BOSS_ORDER[((floor_n / 5) - 1) % BOSS_ORDER.size()]


# Equilíbrio: a força dos monstros depende do ANDAR, não do bioma. Cada monstro vale
# (valor dele / média do seu bioma) x base x curva do andar. Assim monstros diferentes
# continuam variados, mas não há saltos de dificuldade ao trocar de bioma.
# Valores calibrados com a simulação de progressão (nível ~ andar, ver PROGRESSO.md).
const ENEMY_BASE := {"hp": 36.0, "dmg": 5.0, "xp": 5.5, "gold": 4.0}
const BOSS_HP_MULT := 4.0
const BOSS_DMG_MULT := 0.85
const BOSS_XP_MULT := 3.0
const BOSS_GOLD_MULT := 0.4


func floor_scale_hp(floor_n: int) -> float:
	return 1.0 + 0.24 * float(floor_n - 1)


func floor_scale_dmg(floor_n: int) -> float:
	return 1.0 + 0.16 * float(floor_n - 1)


func floor_scale_reward(floor_n: int) -> float:
	return pow(float(maxi(floor_n, 1)), 1.05)


## Valor relativo de um monstro dentro do bioma dele (1.0 = média). stat: hp | dmg | xp | gold.
func monster_rel(monster_id: String, stat: String) -> float:
	var biome_list: Array = []
	for b in BIOMES:
		if monster_id in b["enemies"]:
			biome_list = b["enemies"]
			break
	if biome_list.is_empty():
		return 1.0
	var total := 0.0
	for id in biome_list:
		total += _monster_stat_value(id, stat)
	return _monster_stat_value(monster_id, stat) / (total / float(biome_list.size()))


func _monster_stat_value(monster_id: String, stat: String) -> float:
	var m: Dictionary = MONSTERS[monster_id]
	if stat == "gold":
		return (float(m["gold"][0]) + float(m["gold"][1])) / 2.0
	return float(m[stat])


# --------------------------------------------------------------------- Missões
# stat: contador do GameState. reward: gold/xp/energy/item.
const MISSIONS := [
	{"id": "m1", "title": "Primeiros Passos", "desc": "Complete 1 sessão de foco", "stat": "focus_sessions", "goal": 1, "reward": {"gold": 10, "xp": 10}},
	{"id": "m2", "title": "Disciplina", "desc": "Complete 5 sessões de foco", "stat": "focus_sessions", "goal": 5, "reward": {"gold": 30, "xp": 30}},
	{"id": "m3", "title": "Ganhando Fama", "desc": "Alcance o nível 3", "stat": "level", "goal": 3, "reward": {"gold": 25}},
	{"id": "m4", "title": "Pé-de-Meia", "desc": "Tenha 50 de ouro", "stat": "gold", "goal": 50, "reward": {"xp": 15}},
	{"id": "m5", "title": "Maratonista", "desc": "Complete 10 sessões de foco", "stat": "focus_sessions", "goal": 10, "reward": {"gold": 60, "xp": 60}},
	{"id": "m6", "title": "Caçador", "desc": "Derrote 1 monstro na masmorra", "stat": "monsters", "goal": 1, "reward": {"gold": 15}},
	{"id": "m7", "title": "Exterminador", "desc": "Derrote 5 monstros na masmorra", "stat": "monsters", "goal": 5, "reward": {"gold": 40}},
	{"id": "m8", "title": "Veterano", "desc": "Alcance o nível 5", "stat": "level", "goal": 5, "reward": {"xp": 30}},
	{"id": "m9", "title": "Descendo a Escada", "desc": "Chegue ao andar 3 da masmorra", "stat": "best_floor", "goal": 3, "reward": {"gold": 50, "item": "pocao_vida"}},
	{"id": "m10", "title": "Matador de Slimes", "desc": "Derrote 50 monstros", "stat": "monsters", "goal": 50, "reward": {"gold": 120, "xp": 80}},
	{"id": "m11", "title": "Abre-Baús", "desc": "Abra 5 baús", "stat": "chests", "goal": 5, "reward": {"gold": 60}},
	{"id": "m12", "title": "Primeira Vitória", "desc": "Derrote seu primeiro chefe", "stat": "bosses", "goal": 1, "reward": {"gold": 150, "xp": 120, "item": "pocao_media"}},
	{"id": "m13", "title": "Hábito Forte", "desc": "Marque hábitos 10 vezes", "stat": "habit_marks", "goal": 10, "reward": {"gold": 80, "xp": 40}},
	{"id": "m14", "title": "Ferreiro Cliente", "desc": "Aprimore um equipamento", "stat": "upgrades", "goal": 1, "reward": {"gold": 70}},
	{"id": "m15", "title": "Mestre Cuca", "desc": "Coma 5 pratos do Restaurante", "stat": "meals", "goal": 5, "reward": {"gold": 60}},
	{"id": "m16", "title": "Profundezas", "desc": "Chegue ao andar 4", "stat": "best_floor", "goal": 4, "reward": {"gold": 160, "xp": 150}},
	{"id": "m17", "title": "Foco Inabalável", "desc": "Complete 25 sessões de foco", "stat": "focus_sessions", "goal": 25, "reward": {"gold": 250, "xp": 200}},
	{"id": "m18", "title": "Caçador de Chefes", "desc": "Derrote 2 chefes", "stat": "bosses", "goal": 2, "reward": {"gold": 300, "xp": 250}},
	{"id": "m19", "title": "Lenda Viva", "desc": "Alcance o nível 15", "stat": "level", "goal": 15, "reward": {"gold": 400}},
	{"id": "m20", "title": "Abismo", "desc": "Chegue ao andar 10 (Profundezas)", "stat": "best_floor", "goal": 10, "reward": {"gold": 600, "xp": 500}},
]

# Missões diárias: 3 sorteadas por dia. {stat, goal, titulo}
const DAILY_TEMPLATES := [
	{"id": "d_focus1", "title": "Foco do dia", "desc": "Complete 1 sessão de foco", "stat": "focus_sessions", "goal": 1, "reward": {"gold": 25, "xp": 30}},
	{"id": "d_focus3", "title": "Dia produtivo", "desc": "Complete 3 sessões de foco", "stat": "focus_sessions", "goal": 3, "reward": {"gold": 80, "xp": 100}},
	{"id": "d_kill15", "title": "Caçada", "desc": "Derrote 15 monstros", "stat": "monsters", "goal": 15, "reward": {"gold": 50, "xp": 60}},
	{"id": "d_kill30", "title": "Limpeza geral", "desc": "Derrote 30 monstros", "stat": "monsters", "goal": 30, "reward": {"gold": 100, "xp": 120}},
	{"id": "d_chest2", "title": "Caçador de tesouros", "desc": "Abra 2 baús", "stat": "chests", "goal": 2, "reward": {"gold": 45, "xp": 40}},
	{"id": "d_habit3", "title": "Rotina em dia", "desc": "Marque 3 hábitos", "stat": "habit_marks", "goal": 3, "reward": {"gold": 40, "xp": 50}},
	{"id": "d_herb", "title": "Herborista", "desc": "Colha 4 ervas na floresta", "stat": "herbs", "goal": 4, "reward": {"gold": 40, "xp": 60}},
	{"id": "d_boss", "title": "Caça ao chefe", "desc": "Derrote 1 chefe", "stat": "bosses", "goal": 1, "reward": {"gold": 120, "xp": 150}},
	{"id": "d_meal", "title": "Hora do rango", "desc": "Coma 1 prato do Restaurante", "stat": "meals", "goal": 1, "reward": {"gold": 30, "xp": 30}},
]

# --------------------------------------------------------------------- Mobília
# Móveis comprados ficam guardados até você colocá-los na casa (modo Decorar, tecla V). Os de bônus
# valem desde a compra. icon: textura do móvel. flat: fica no chão (tapetes) e gira de 90 em 90 graus.
# wall: móvel de parede (lareira, estante, troféus, relógio, cômoda): só desliza ao longo da parede de cima.
const FURNITURE := {
	"cama": {"name": "Cama Confortável", "price": 60, "desc": "+15 de vida máxima.", "stat": {"hp": 15.0}, "icon": "furn_cama"},
	"mesa": {"name": "Mesa de Jantar", "price": 100, "desc": "A fome diminui 60% mais devagar.", "stat": {"hunger_mult": 0.4}, "icon": "furn_mesa"},
	"estante": {"name": "Estante de Livros", "price": 120, "desc": "+5% de XP.", "stat": {"xp_pct": 0.05}, "icon": "furn_estante", "wall": true},
	"planta": {"name": "Vaso de Planta", "price": 80, "desc": "Regenera 0,4 de vida por segundo.", "stat": {"regen": 0.4}, "icon": "furn_planta"},
	"tapete": {"name": "Tapete Dourado", "price": 150, "desc": "+5% de ouro.", "stat": {"gold_pct": 0.05}, "icon": "furn_tapete", "flat": true},
	"lareira": {"name": "Lareira", "price": 200, "desc": "Regenera 0,6 de vida por segundo.", "stat": {"regen": 0.6}, "icon": "furn_lareira", "wall": true},
	"trofeu": {"name": "Armário de Troféus", "price": 250, "desc": "+3% de crítico.", "stat": {"crit": 3.0}, "icon": "furn_trofeu", "wall": true},
	"relogio": {"name": "Relógio Antigo", "price": 300, "desc": "+10% de XP nas sessões de foco.", "stat": {"focus_xp_pct": 0.10}, "icon": "furn_relogio", "wall": true},
	# só decoração (sem bônus): para montar a casa do seu jeito no modo Decorar
	"poltrona": {"name": "Poltrona de Leitura", "price": 70, "desc": "Decoração.", "stat": {}, "icon": "lpc_poltrona"},
	"sofa": {"name": "Sofá", "price": 110, "desc": "Decoração.", "stat": {}, "icon": "lpc_sofa"},
	"comoda": {"name": "Cômoda", "price": 90, "desc": "Decoração.", "stat": {}, "icon": "lpc_comoda", "wall": true},
	"tapete_azul": {"name": "Tapete Azul", "price": 60, "desc": "Decoração (fica no chão, gira).", "stat": {}, "icon": "p_tapete_azul", "flat": true},
	"tatame": {"name": "Tatame", "price": 50, "desc": "Decoração (fica no chão, gira).", "stat": {}, "icon": "p_tatame", "flat": true},
	"vaso_flores": {"name": "Vaso de Flores", "price": 30, "desc": "Decoração.", "stat": {}, "icon": "p_vaso_flores"},
	"planta_pequena": {"name": "Planta Pequena", "price": 25, "desc": "Decoração.", "stat": {}, "icon": "p_planta_pequena"},
	"lampiao": {"name": "Lampião", "price": 45, "desc": "Decoração (ilumina).", "stat": {}, "icon": "lampiao", "light": true},
	# pacotes LPC de móveis (31/10/2026), reduzidos à metade por tools/build_lpc_furniture.py
	"sofa_veludo": {"name": "Sofá de Veludo", "price": 130, "desc": "Decoração.", "stat": {}, "icon": "lpc_sofa_veludo"},
	"sofa_imperial": {"name": "Sofá Imperial", "price": 180, "desc": "Decoração.", "stat": {}, "icon": "lpc_sofa_imperial"},
	"banco_estofado": {"name": "Banco Estofado", "price": 60, "desc": "Decoração.", "stat": {}, "icon": "lpc_banco_estofado"},
	"cadeira": {"name": "Cadeira Entalhada", "price": 45, "desc": "Decoração.", "stat": {}, "icon": "lpc_cadeira"},
	"pufe": {"name": "Pufe", "price": 30, "desc": "Decoração.", "stat": {}, "icon": "lpc_pufe"},
	"abajur": {"name": "Abajur", "price": 55, "desc": "Decoração (ilumina).", "stat": {}, "icon": "lpc_abajur", "light": true},
	"armario": {"name": "Armário Vermelho", "price": 100, "desc": "Decoração.", "stat": {}, "icon": "lpc_armario", "wall": true},
	"louceiro": {"name": "Louceiro", "price": 110, "desc": "Decoração.", "stat": {}, "icon": "lpc_louceiro", "wall": true},
	"lareira_tijolos": {"name": "Lareira de Tijolos", "price": 140, "desc": "Decoração (ilumina).", "stat": {}, "icon": "lpc_lareira_tijolos", "wall": true, "light": true},
	"barris": {"name": "Pilha de Barris", "price": 70, "desc": "Decoração.", "stat": {}, "icon": "lpc_barris"},
	"mesa_toalha": {"name": "Mesa com Toalha", "price": 90, "desc": "Decoração.", "stat": {}, "icon": "lpc_mesa_toalha"},
	"mesa_redonda": {"name": "Mesa Redonda", "price": 80, "desc": "Decoração.", "stat": {}, "icon": "lpc_mesa_redonda"},
	"mesa_centro": {"name": "Mesa de Centro", "price": 40, "desc": "Decoração.", "stat": {}, "icon": "lpc_mesa_centro"},
	# v2.9: divisórias para repartir a sala (têm colisão; cada peça tem 3 tiles de largura)
	"divisoria_madeira": {"name": "Divisória de Madeira", "price": 50, "desc": "Parede baixa para dividir cômodos.", "stat": {}, "icon": "divisoria_madeira"},
	"divisoria_pedra": {"name": "Divisória de Pedra", "price": 90, "desc": "Parede baixa de pedra para dividir cômodos.", "stat": {}, "icon": "divisoria_pedra"},
}
const FURNITURE_ORDER := ["cama", "mesa", "estante", "planta", "tapete", "lareira", "trofeu", "relogio",
	"poltrona", "sofa", "comoda", "tapete_azul", "tatame", "vaso_flores", "planta_pequena", "lampiao",
	"sofa_veludo", "sofa_imperial", "banco_estofado", "cadeira", "pufe", "abajur", "armario", "louceiro", "lareira_tijolos",
	"barris", "mesa_toalha", "mesa_redonda", "mesa_centro", "divisoria_madeira", "divisoria_pedra"]

# ---------------------------------------------------------------------- Energia
const ENERGY_MAX := 10
const ENERGY_DAILY_MIN := 3
const ENERGY_PER_FOCUS := 2
const RECALL_MIN_CHARS := 120   # mínimo de caracteres do recall escrito no fim de cada foco
const FOCUS_MIN_SESSION := 10   # foco finalizado antes da hora conta como sessão (missões) a partir daqui (min)
const ENERGY_PER_HABIT := 1
const ENERGY_PER_RUN := 1

# ------------------------------------------------------------------------ Hábitos
const HABIT_SLOTS := 5
const HABIT_MAX := 12
const HABIT_DIFF_NAMES := ["Fácil", "Médio", "Difícil"]
const HABIT_DIFF_MULT := [0.7, 1.0, 1.6]   # XP e ouro proporcionais à dificuldade do hábito
