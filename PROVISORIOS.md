# Peças provisórias — o que trocar quando os packs novos chegarem

Este arquivo lista tudo que foi **adaptado** com os recursos que o projeto já tem, só para a história
funcionar. Quando um pack novo for comprado ou baixado, procure aqui o que ele substitui, troque a peça e
apague a linha (ou marque como ✅).

Regra que valeu até aqui: nada de arte desenhada à mão "do zero" para o jogo final. O que está abaixo é
montagem com peças dos packs (Ninja Adventure, Kenney Tiny Town, LPC, Pixel Crawler, Dungeon Tileset II) ou
desenho gerado por script (`tools/gen_*.py`). **Tudo isso é provisório.**

Como achar no código: cada item abaixo tem o arquivo e a função. Também dá para buscar `PROVISÓRIO`,
`Provisórios` ou `v3.7` no código.

---

## 1. Cenários (mapas)

| Peça provisória | Onde | Feita com | Trocar por |
|---|---|---|---|
| Penhascos da floresta (platô norte e Rochedo da Borda) | `scripts/world/TileComposer.gd` → `cliffs()`, `relief()`; `scripts/world/Forest.gd` → `_build_masks()` | TilesetRelief do Ninja (bloco de terra, linhas 5..9), com o "chão" lilás/areia apagado | Tileset de penhasco/terraço com grama em cima e escadas próprias (ex.: Pixel Lands, Mana Seed, Cozy/Serene Village) |
| Escadarias nos penhascos | `Forest.gd` → `_stamp_structures()`; `TileComposer.bridge_image(true, …)` | A ponte de pedra do TilesetHouse em pé (degraus = tábuas) | Escadas de pedra de penhasco do pack novo |
| Cascata | `Forest.gd` → `_build_terrain()` (`FALLS_SHADER`) | Tile de água do TilesetWater rolando num shader + partículas de espuma | Tiles animados de cachoeira (topo, queda, espuma) |
| Pontes de madeira da floresta | `Forest.gd` → `_stamp_structures()` | Ponte do TilesetHouse girada 90° | Ponte horizontal desenhada para isso |
| Manchas de grama escura e canteiros de flores | `TileComposer._grass_patches()`, `compose_forest()` | Tiles de grama/flor do Ninja com opacidade por ruído | Autotile de grama alta/escura do pack novo |
| Borda de mata fechada | `TileComposer.compose_forest()` (escurecimento) + `Forest._build_decor()` | Escurecimento por código + árvores do Ninja | Tile de copa de floresta densa (borda "preta" das referências) |
| Muralha, portão com torres e castelo de Pedralta | `scripts/world/BuildingFactory.gd` → `_wall()`, `_gatehouse()`, `_castle()`; `scripts/world/City.gd` → `_build_fort()`, `_build_castle()` | Peças de castelo do Kenney Tiny Town | Pack de castelo/fortaleza (torres altas, bandeiras, fosso, portão) |
| Fosso e ponte de pedra de Pedralta | `City.gd` → `_build_masks()`, `_stamp_fort_bridge()` | Água do Ninja + ponte de pedra do TilesetHouse | Fosso e ponte do pack de castelo |
| Hortas (canteiros) | `City.gd` → `_build_gardens()`; `Interior._tileset_prop()` ("plot_w_h") | TilesetField do Ninja (terra) + arbustos de fruta como mudas | Pack de fazenda (canteiros, mudas, plantações em fases) |
| Entrada da masmorra | `scripts/world/Town.gd` → `_build_gate()` | Arco de pedra do TilesetHouse + escada do Ninja + caixotes/pedras | Fachada de masmorra/caverna (como nas referências: templo de pedra ou boca na rocha) |
| Vila da Neve e Oásis inteiros | `scripts/story/CityData.gd` (`vila_neve`, `oasis`) | Chão de neve/areia do Ninja, casas do Kenney, pedras/árvores do Ninja | Packs de neve e de deserto |
| Boca da caverna do Pé Grande | `City.gd` → `CaveMouth` | Sombra elíptica escura entre pedras | Entrada de caverna do pack de neve |
| Estrada da emboscada | `CityData.gd` (`estrada`) | Grama + trilha do Ninja | Tileset de estrada/campo aberto |
| Centro de Treinamento (Pedralta) | `scripts/story/ArmyStory.gd` → `decorate()` | Bonecos de treino gerados por script (`p_boneco_treino`) | Bonecos e alvos de um pack de quartel |
| Jardim da Academia | `CityData.gd` (`academia`), `scripts/story/AcademyStory.gd` | Cerca do Kenney + grama do Ninja | Jardim com canteiros e cerca viva |

## 2. Interiores

| Peça provisória | Onde | Feita com | Trocar por |
|---|---|---|---|
| Paredes internas (cômodos da estalagem) | `scripts/world/Interior.gd` → `PARTITIONS`, `_draw_partitions()` | Textura da parede de cima repetida + viga escura desenhada por código | Tileset de interior com paredes internas e portas |
| Raios de sol nas janelas | `Interior.gd` → `sunbeam()` | Polígono de luz aditiva (efeito) | Pode ficar (é efeito), ou trocar por luz pintada do pack |
| Gato da loja e pets dormindo | `Interior.gd` → `sleeping_pet()` | 1º quadro do sprite do Ninja + respiração por tween | Sprites de animal dormindo |
| Plaquinhas de seção ("Espadas", "Quarto 1"…) | `Interior.gd` → `_section_label()` | Texto | Placas desenhadas do pack |
| Móveis `p_*`, `furn_*`, `placa_*`, `lampiao`, `cadeira`, `quadro_missoes`, `divisoria_*` | `assets/custom/props/` | **Desenho gerado por script** (`tools/gen_props.py`, `gen_props2.py`, `gen_props_lab.py`, `gen_divisorias.py`) | Pack de móveis de interior (ferraria, loja de armas, costura, cozinha, laboratório, biblioteca) |
| Móveis `lpc_*` | `assets/custom/props/` | Recortes do LPC (`tools/build_lpc_furniture.py`) | Podem ficar; trocar se o pack novo tiver estilo melhor |
| Berço do prólogo | `scripts/story/Prologue.gd` | Cama pequena com manta | Berço de verdade |

## 3. Personagens, monstros e chefes

| Peça provisória | Onde | Feita com | Trocar por |
|---|---|---|---|
| Herói adolescente no prólogo | `Prologue.gd` | Herói adulto em escala 0,9 | Corpo adolescente do LPC/pack de personagens (referência "tamanhos de corpo") |
| Pé Grande (chefe) | `scripts/core/Data.gd` (`pe_grande`), `scripts/entities/Boss.gd` (shader `whiten`) | Guaxinim Gigante do Ninja tingido de branco | Iéti/Pé Grande (ex.: pack de monstros Elthen) |
| Bruxo do Submundo | `scripts/story/SideQuests.gd` | Necromante do Dungeon Tileset II ampliado | Chefe necromante de verdade |
| Colegas da Academia, soldados, Brígida | `scripts/entities/Ally.gd` → `look_of()`, `ArmyStory.brigida_look()` | Peças LPC já baixadas | Podem ficar (LPC); trocar se vier pack de NPCs com mais variedade |
| Rei de Rocuetos | Não aparece (o castelo é fechado) | — | Quando houver sprite de rei + sala do trono, abrir o castelo |

## 4. Itens, armas e efeitos

| Peça provisória | Onde | Feita com | Trocar por |
|---|---|---|---|
| **Ícones e sprites de armas** (você já disse que estão pobres) | `assets/ninja/weapons/`, `scripts/core/Data.gd` (ícones), `scripts/core/LpcW.gd` (arma na mão) | Armas 16 px do Ninja + armas LPC | Pack de armas estilizadas por material/tier (referência "armas estilizadas"), com versão na mão e ícone |
| Brilho dos tiers 5–7 (aura) | `scripts/entities/Player.gd` → `_refresh_aura()` | Partículas + luz por código | Efeito de aura animado de um pack de VFX |
| Ícones de armadura por tier | `scripts/core/LpcW.gd` (ícone montado do LPC) | Recorte do personagem LPC | Pack de ícones de armadura (referência "ícones de armadura") |

## 5. Mini-jogos (ofícios)

| Peça provisória | Onde | Feita com | Trocar por |
|---|---|---|---|
| Turno na cozinha | `scripts/minigames/KitchenShift.gd` | Estações do Pixel Crawler + comida dos packs 64 Food/Ninja + clientes LPC | Pode ficar; trocar estações por um pack de cozinha/restaurante se vier |
| Turno na forja (ritmo na bigorna) | `scripts/minigames/ForgeShift.gd` | Fornalha/bigorna do Pixel Crawler + barras de ritmo desenhadas por código | Interface de ritmo desenhada + animação do ferreiro |
| Fórmula Secreta (laboratório) | `scripts/ui/windows/MiniLabWindow.gd` | Poções dos packs + interface por código | Ícones de ingredientes/caldeirão de um pack de alquimia |
| Ateliê (costura) | `scripts/ui/windows/MiniSewWindow.gd` | Manequim LPC + agulha/linha desenhadas por código | Interface de costura desenhada |

## 6. Telas e sons

| Peça provisória | Onde | Feita com | Trocar por |
|---|---|---|---|
| Paisagens da escolha de classe | `assets/custom/paisagem/` | Script (`tools/gen_paisagem.py`) | Fundos pintados |
| Cenários do Pomodoro (estudo, cafeteria, cela…) | `assets/custom/pomodoro/` | Script (`tools/gen_pomodoro_*.py`) | Fundos pintados do pack de cenas de estudo |
| Sons de ambiente do Pomodoro | `assets/audio/pomodoro/`, `scripts/core/PomoSound.gd` | Sintetizados (`tools/gen_pomodoro_sfx.py`) | Sons gravados (chuva, cafeteria, lareira) |
| Mapa-múndi em pergaminho | `scripts/ui/windows/WorldMapWindow.gd` | Desenhado por código com ícones dos packs | Mapa pintado (referência "mapa em pergaminho") |
| Chão das masmorras | `assets/dungeon/` | Script (`tools/gen_dungeon_tiles.py`) | Tileset de masmorra por bioma (referência "templo de lava") |
| Calçada de pedra das cidades | `assets/custom/tiles/TilesetFloorStone.png` | Script (`tools/gen_stone_path.py`) | Autotile de calçada do pack |

---

## Como trocar uma peça (passo a passo)

1. Coloque o pack em `assets/<nome_do_pack>/` (sem espaços no nome).
2. Rode o Godot uma vez (ou `--headless --import`) para importar as imagens.
3. Prop solto (móvel, árvore, prédio): troque o nome do prop onde ele é usado (veja a coluna "Onde"). Se o
   nome for mantido igual, basta pôr o PNG novo em `assets/custom/props/<nome>.png`; ele tem prioridade
   sobre o Ninja (`Interior.prop_tex`).
4. Tileset (chão, penhasco, água): troque o caminho em `TileComposer.gd` e ajuste as coordenadas dos tiles.
5. Rode os testes de `dev/scenarios/` (`v37_floresta`, `v37_reinos`, `interiores_shot`, `v37_world`…) para
   tirar prints e conferir.
