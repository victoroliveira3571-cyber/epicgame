class_name CityData
extends RefCounted

## v3.2: as três cidades depois da Parte 1 (Porto Névoa, Pedralta, Academia de Fontelúcida). Dados dos mapas,
## falas e o fragmento de memória do pai de cada uma. O cenário que monta tudo é scripts/world/City.gd.
## Inspiração: Ragnarok Online (cada cidade com cara e função própria) e Mushoku Tensei (crescer estudando).

const ORDER := ["porto", "pedralta", "academia"]
const FRAGMENT_HOURS := {"porto": 9.0, "pedralta": 10.0, "academia": 12.0}

## Retângulos [x0, y0, x1, y1] em tiles. `paths` = caminho principal; `water` = mar/lago; `piers` = tábuas sobre a água.
const CITIES := {
	"porto": {
		"name": "Porto Névoa", "subtitle": "O mar guarda o que a névoa levou",
		"W": 60, "H": 44, "base_row": 12, "tint": Color(0.95, 0.98, 1.05), "path_origin": Vector2i(0, 0), "path_set": "floor",
		"music": "town", "ambience": "amb_margem",
		"exit": "west", "spawn": Vector2i(4, 25),
		"paths": [[0, 24, 59, 26], [18, 27, 19, 36], [40, 27, 41, 36]],
		"water": [[0, 36, 59, 43], [0, 33, 6, 36], [53, 33, 59, 36]],
		"piers": [[18, 36, 19, 41], [40, 36, 41, 40], [27, 36, 28, 39]],
		"buildings": [
			{"id": "loja", "title": "Mercado do Porto", "prop": "b_casa_empena", "tile": [12, 24]},
			{"id": "restaurante", "title": "Taverna da Maré", "prop": "b_padaria", "tile": [24, 24]},
			{"id": "guilda", "title": "Guilda do Porto", "prop": "h_salao_madeira", "tile": [34, 24]},
			{"id": "capitao", "title": "Casa do Capitão", "prop": "b_estalagem", "tile": [46, 24], "closed": true},
			{"id": "casa_p1", "title": "Casa de Pescador", "prop": "k_tijolo_vermelho_5", "tile": [10, 33], "closed": true},
			{"id": "casa_p2", "title": "Armazém", "prop": "k_tijolo_cinza_7", "tile": [50, 33], "closed": true},
			{"id": "casa_p3", "title": "Casa da Rede", "prop": "k_tijolo_vermelho_6", "tile": [10, 19], "closed": true},
			{"id": "casa_p4", "title": "Casa do Farol", "prop": "k_pedra_cinza_5", "tile": [30, 18], "closed": true},
			{"id": "casa_p5", "title": "Casa das Velas", "prop": "k_tijolo_cinza_5", "tile": [52, 19], "closed": true},
		],
		"npcs": [
			{"sheet": "OldMan", "tile": [47, 27], "talk": "capitao", "title": "Capitão Maré"},
			{"sheet": "Villager", "tile": [20, 38], "lines": ["O mar traz gente e leva histórias.", "Hoje a névoa chegou cedo."]},
			{"sheet": "Villager3", "tile": [41, 37], "lines": ["Peixe fresco! Quer? Não, é para o gato.", "O Capitão guarda um diário velho."]},
			{"sheet": "Woman", "tile": [30, 27], "mode": "wander", "lines": ["A Taverna da Maré tem o melhor caldo.", "Barco que sai sem estudo volta sem rota."]},
			{"sheet": "Child", "tile": [16, 28], "mode": "wander", "lines": ["Eu vi uma sereia! Quase.", "Quando eu crescer vou ser capitão."]},
		],
		"decor": [
			["i_barrel", [21, 34]], ["i_barrel2", [22, 34]], ["i_crate", [38, 34]], ["i_crate", [39, 35]], ["i_sack", [30, 28]],
			["n_arvore_redonda", [4, 30]], ["n_arvores_trio", [56, 29]], ["n_arbusto2", [8, 28]], ["n_arbusto4", [52, 28]],
			["i_board", [29, 27]], ["k_cerca_3", [14, 33]], ["k_placa", [17, 27]], ["n_pedra_cinza", [3, 38]], ["n_pedra_cinza_g", [57, 40]],
			["barco_vela_marrom", [24, 41]], ["barco_vela_azul", [49, 40]], ["barco_remo", [12, 40]], ["barco_caiaque", [34, 42]], ["barco_remo", [45, 38]],
		],
		"anim": [
			{"sheet": "pc_grill1.png", "fw": 64, "fh": 64, "cols": 4, "from": 0, "n": 4, "fps": 5.0, "tile": [21, 29]},
			{"sheet": "pc_fire1.png", "fw": 32, "fh": 48, "cols": 4, "from": 0, "n": 4, "fps": 8.0, "tile": [37, 30]},
		],
		"label": Color("cfe8ff"),
	},
	"pedralta": {
		"name": "Pedralta", "subtitle": "Onde o martelo conta o tempo",
		"W": 56, "H": 46, "base_row": 19, "tint": Color(0.93, 0.97, 1.06), "path_origin": Vector2i(0, 7), "path_set": "stone",
		"music": "town", "ambience": "",
		"exit": "south", "spawn": Vector2i(28, 37),
		"paths": [[27, 27, 29, 45], [10, 26, 46, 28], [27, 11, 29, 26], [24, 12, 32, 13]],
		# v3.7 (referências do Victor): Pedralta é a capital de Rocuetos. Muralha com portão, fosso e ponte no sul;
		# castelo do rei no fim da avenida norte, com estátuas; hortas ao lado das casas.
		"fort": {"wall_y": 40, "gate_x": 27, "moat": true, "flag": "FlagRed",
			"guard_lines": ["Boas-vindas a Pedralta, capital de Rocuetos.", "Arma na bainha dentro dos muros.", "O portão fecha quando o sino da forja para."]},
		"castle": {"tile": [28, 11], "w": 15, "title": "Castelo de Rocuetos", "flag": "FlagRed", "statues": [[23, 14], [33, 14]],
			"guard_lines": ["O rei só recebe com audiência marcada.", "Promoções saem da Comandante Brígida, não daqui.", "Nem pense em subir nas ameias."]},
		"gardens": [[12, 33, 4, 3, "n_frutas_bush3"], [36, 35, 4, 3, "n_frutas_bush1"]],
		"water": [],
		"piers": [],
		"buildings": [
			{"id": "forja", "title": "Grande Forja", "prop": "b_forja", "tile": [14, 26]},
			{"id": "laboratorio", "title": "Laboratório de Cristais", "prop": "b_casa_empena", "tile": [24, 26], "tint": [0.75, 0.95, 1.0]},
			{"id": "loja", "title": "Armeiro Granito", "prop": "k_pedra_cinza_6", "tile": [37, 26]},
			{"id": "mestre", "title": "Casa do Mestre Granito", "prop": "k_pedra_cinza_5", "tile": [46, 26], "closed": true},
			{"id": "casa_q1", "title": "Casa de Mineiro", "prop": "k_pedra_cinza_5", "tile": [8, 36], "closed": true},
			{"id": "casa_q2", "title": "Casa do Forjador", "prop": "k_pedra_cinza_6", "tile": [44, 38], "closed": true},
			{"id": "casa_q3", "title": "Casa do Lenhador", "prop": "k_tijolo_cinza_5", "tile": [8, 20], "closed": true},
			{"id": "casa_q4", "title": "Alojamento", "prop": "k_pedra_cinza_5", "tile": [47, 20], "closed": true},
		],
		"npcs": [
			{"sheet": "Caveman", "tile": [44, 28], "talk": "granito", "title": "Mestre Granito"},
			{"sheet": "Villager2", "tile": [20, 28], "lines": ["O ferro de Pedralta canta quando bate.", "Frio? Aqui o frio é sócio da forja."]},
			{"sheet": "OldMan3", "tile": [36, 28], "mode": "wander", "lines": ["Meu pai minerava, meu avô também.", "Obsidiana só abre para quem tem paciência."]},
			{"sheet": "Boy", "tile": [30, 31], "mode": "wander", "lines": ["Quero aprender a forjar!", "Quebrei três martelos. Só!"]},
		],
		"decor": [
			["n_pinheiros_trio", [6, 20], [0.85, 0.95, 1.0]], ["n_pinheiros_trio", [48, 20], [0.85, 0.95, 1.0]], ["n_arvore_pinheiro", [5, 32], [0.85, 0.95, 1.0]],
			["n_arvore_pinheiro", [50, 36], [0.85, 0.95, 1.0]], ["n_pedra_cinza_g", [10, 8]], ["n_pedra_cinza_g", [17, 6]], ["n_pedra_cinza_g", [40, 7]],
			["n_pedra_cinza_alta", [18, 10]], ["n_pedra_cinza_alta", [39, 10]], ["n_pedra_cinza_g", [46, 10]], ["n_pedra_cinza_g", [4, 12]],
			["i_barrel", [12, 27]], ["i_crate", [35, 27]], ["i_board", [22, 27]], ["k_cerca_4", [30, 24]], ["k_placa", [31, 27]],
		],
		"ore": [["barra_mithril", "Mithril", [20, 13]], ["barra_mithril", "Mithril", [36, 14]], ["barra_obsidiana", "Obsidiana", [14, 17]],
			["barra_obsidiana", "Obsidiana", [42, 17]], ["barra_adamantium", "Adamantium", [44, 5]]],
		"anim": [
			{"sheet": "pc_furnace_iron3.png", "fw": 48, "fh": 64, "cols": 2, "from": 0, "n": 4, "fps": 5.0, "tile": [11, 29]},
			{"sheet": "pc_anvil1.png", "fw": 64, "fh": 80, "cols": 8, "from": 0, "n": 14, "fps": 7.0, "tile": [19, 30]},
		],
		"label": Color("27406a"),
	},
	"academia": {
		"name": "Academia de Fontelúcida", "subtitle": "Quem pergunta bem já aprendeu metade",
		"W": 56, "H": 60, "base_row": 12, "tint": Color(0.96, 0.97, 1.04), "path_origin": Vector2i(0, 7), "path_set": "stone",
		"music": "town", "ambience": "",
		"exit": "east", "spawn": Vector2i(52, 24),
		# v3.7: trilha até o Jardim da Academia (linhas 48 a 56, ao sul da cerca da linha 47; AcademyStory)
		"paths": [[0, 24, 55, 26], [26, 12, 29, 23], [14, 27, 15, 40], [40, 27, 41, 48], [20, 18, 35, 20]],
		"water": [[24, 31, 31, 36]],
		"piers": [],
		"buildings": [
			{"id": "biblioteca", "title": "Grande Biblioteca", "prop": "b_salao_vermelho", "tile": [27, 12], "interior": "biblioteca", "tint": [0.72, 0.86, 1.0]},
			{"id": "guilda", "title": "Secretaria da Academia", "prop": "h_salao_madeira", "tile": [12, 24]},
			{"id": "classe", "title": "Salão dos Mestres", "prop": "b_salao_vermelho", "tile": [42, 24], "tint": [0.9, 0.85, 1.0]},
			{"id": "reitoria", "title": "Reitoria", "prop": "k_pedra_cinza_7", "tile": [19, 19], "closed": true},
			{"id": "dorm", "title": "Dormitório", "prop": "k_tijolo_cinza_6", "tile": [8, 38], "closed": true},
			{"id": "dorm2", "title": "Alojamento dos Mestres", "prop": "k_tijolo_vermelho_5", "tile": [22, 38], "closed": true},
			{"id": "casa_a1", "title": "Casa do Bibliotecário", "prop": "k_pedra_cinza_5", "tile": [8, 19], "closed": true},
			{"id": "casa_a2", "title": "Casa dos Alunos", "prop": "k_tijolo_vermelho_6", "tile": [46, 19], "closed": true},
			{"id": "restaurante", "title": "Refeitório", "prop": "b_padaria", "tile": [46, 38]},
		],
		"npcs": [
			{"sheet": "Woman", "tile": [22, 21], "talk": "reitora", "title": "Reitora Aurora"},
			{"sheet": "Boy", "tile": [18, 28], "mode": "wander", "lines": ["Estou revisando! Ou fingindo.", "O recall de ontem foi cruel."]},
			{"sheet": "Villager4", "tile": [34, 28], "mode": "wander", "lines": ["Pergunta boa vale mais que resposta pronta.", "Cheguei cedo para a prova de amanhã."]},
			{"sheet": "OldMan", "tile": [34, 22], "mode": "wander", "lines": ["Dormir bem faz parte da lição.", "Já viu o jardim das perguntas?"]},
			{"sheet": "Child", "tile": [28, 29], "mode": "wander", "lines": ["Por que o céu é azul? Ninguém sabe me dizer direito.", "Eu quero ser professora!"]},
		],
		"decor": [
			["h_estatua_grande_verde", [24, 22]], ["h_estatua_grande_verde", [31, 22]], ["h_estatua_pequena", [26, 28]], ["h_estatua_pequena", [29, 28]],
			["n_arvore_redonda", [6, 20]], ["n_arvore_grande", [50, 20]], ["n_arvores_trio", [6, 32]], ["n_arvore_redonda2", [50, 32]],
			["n_flor_margarida", [20, 30]], ["n_flor_trevo", [36, 30]], ["i_stool", [17, 25]], ["i_stool", [38, 25]], ["k_cerca_3", [32, 37]], ["k_placa", [28, 27]],
			# Jardim da Academia (canteiros e árvores nas bordas)
			["n_flor_margarida", [8, 50]], ["n_flor_trevo", [10, 52]], ["n_flor_margarida", [16, 54]], ["n_flor_trevo", [24, 50]],
			["n_flor_margarida", [30, 55]], ["n_flor_trevo", [47, 51]], ["n_flor_margarida", [50, 55]], ["n_arbusto2", [6, 55]],
			["n_arbusto4", [20, 49]], ["n_arbusto2", [34, 50]], ["n_arbusto4", [45, 56]], ["n_arvore_redonda", [3, 49]],
			["n_arvore_redonda2", [53, 49]], ["n_arvores_trio", [12, 57]], ["n_arvore_redonda", [38, 57]], ["k_placa", [42, 46]],
		],
		"anim": [
			{"sheet": "pc_alchemy1.png", "fw": 32, "fh": 64, "cols": 6, "from": 0, "n": 6, "fps": 4.0, "tile": [22, 29]},
			{"sheet": "pc_alchemy1.png", "fw": 32, "fh": 64, "cols": 6, "from": 6, "n": 20, "fps": 7.0, "tile": [34, 29]},
		],
		"label": Color("e4dcff"),
	},
	# v3.7 (história v4): lugares novos, PROVISÓRIOS (seção 15): montados com o chão de neve e de areia do próprio
	# tileset do jogo, casas do Kenney e pedras/árvores do Ninja Adventure, até entrarem os packs de neve e deserto.
	"vila_neve": {
		"name": "Vila da Neve", "subtitle": "Onde o frio ensina paciência",
		"W": 40, "H": 34, "base_row": 19, "tint": Color(0.92, 0.96, 1.08), "path_origin": Vector2i(0, 7), "path_set": "stone",
		"music": "town_night", "ambience": "",
		"exit": "south", "spawn": Vector2i(20, 30),
		"paths": [[19, 8, 20, 33], [8, 18, 32, 19]],
		"water": [],
		"piers": [],
		"buildings": [
			{"id": "casa_n1", "title": "Casa do Ancião", "prop": "k_pedra_cinza_5", "tile": [12, 18], "closed": true},
			{"id": "casa_n2", "title": "Casa do Lenhador", "prop": "k_tijolo_cinza_5", "tile": [28, 18], "closed": true},
			{"id": "casa_n3", "title": "Casa da Peleteira", "prop": "k_pedra_cinza_5", "tile": [10, 26], "closed": true},
			{"id": "casa_n4", "title": "Armazém de Gelo", "prop": "k_tijolo_cinza_6", "tile": [30, 26], "closed": true},
		],
		"npcs": [
			{"sheet": "OldMan3", "tile": [16, 20], "talk": "anciao", "title": "Ancião Bóris"},
			{"sheet": "Villager2", "tile": [24, 21], "mode": "wander", "lines": ["Desde que o Pé Grande desceu, ninguém sobe a trilha.", "O chá de pinheiro esquenta até a alma."]},
			{"sheet": "Woman", "tile": [26, 28], "mode": "wander", "lines": ["Levaram meu irmão para a caverna. Ele ainda respira, eu sinto.", "Neve nova apaga pegadas. Neve velha guarda."]},
		],
		"decor": [
			["n_pinheiros_trio", [4, 10], [0.85, 0.95, 1.0]], ["n_pinheiros_trio", [35, 10], [0.85, 0.95, 1.0]], ["n_arvore_pinheiro", [6, 24], [0.85, 0.95, 1.0]],
			["n_arvore_pinheiro", [35, 22], [0.85, 0.95, 1.0]], ["n_arvore_pinheiro", [4, 30], [0.85, 0.95, 1.0]], ["n_arvore_pinheiro", [36, 30], [0.85, 0.95, 1.0]],
			["n_pedra_cinza_g", [15, 5]], ["n_pedra_cinza_alta", [17, 4]], ["n_pedra_cinza_alta", [23, 4]], ["n_pedra_cinza_g", [25, 5]],
			["n_pedra_cinza", [13, 7]], ["n_pedra_cinza", [27, 7]], ["i_barrel", [22, 20]], ["i_crate", [33, 27]], ["k_cerca_4", [20, 23]],
		],
		"cave": [20, 6],
		"label": Color("27406a"),
	},
	"oasis": {
		"name": "Oásis de Areia Doce", "subtitle": "A parada das rotas de comércio",
		"W": 44, "H": 34, "base_row": 5, "tint": Color(1.04, 1.0, 0.94), "path_origin": Vector2i(0, 0), "path_set": "floor",
		"music": "town", "ambience": "amb_margem",
		"exit": "west", "spawn": Vector2i(3, 18),
		"paths": [[0, 17, 43, 18], [21, 7, 22, 16]],
		"water": [[16, 21, 27, 27]],
		"piers": [],
		"buildings": [
			{"id": "loja", "title": "Bazar das Caravanas", "prop": "b_casa_empena", "tile": [12, 16], "tint": [1.0, 0.92, 0.78]},
			{"id": "restaurante", "title": "Tenda do Chá", "prop": "b_padaria", "tile": [30, 16], "tint": [1.0, 0.92, 0.78]},
			{"id": "casa_o1", "title": "Casa do Mercador", "prop": "k_tijolo_vermelho_5", "tile": [21, 7], "closed": true, "tint": [1.0, 0.9, 0.75]},
			{"id": "casa_o2", "title": "Estábulo das Caravanas", "prop": "k_tijolo_vermelho_6", "tile": [37, 29], "closed": true, "tint": [1.0, 0.9, 0.75]},
		],
		"npcs": [
			{"sheet": "Villager4", "tile": [14, 19], "lines": ["Sal, seda e livros: o oásis vende tudo que atravessa o deserto.", "Viu algum mapa antigo? Pago bem."]},
			{"sheet": "OldMan2", "tile": [32, 19], "mode": "wander", "lines": ["Água é o ouro daqui.", "Um viajante de bússola de latão passou por aqui há muitos anos. Bebeu três chás e foi para o norte."]},
			{"sheet": "Woman", "tile": [22, 29], "mode": "wander", "lines": ["A miragem mostra o que você quer ver. Estudar mostra o que é.", "À noite o deserto conta estrelas."]},
		],
		"decor": [
			["n_arvore_seca", [14, 22]], ["n_arvore_seca", [29, 21]], ["n_arvore_seca", [15, 28]], ["n_arvore_seca", [28, 28]],
			["n_pedra_marrom_g", [5, 8]], ["n_pedra_marrom_alta", [38, 9]], ["n_pedra_marrom", [8, 28]], ["n_pedra_marrom_g", [40, 22]],
			["i_barrel", [18, 19]], ["i_crate", [26, 19]], ["i_sack", [27, 20]], ["k_placa", [6, 16]],
		],
		"label": Color("6a3a10"),
	},
	# v3.7: estrada entre os reinos, onde a carruagem sofre emboscada (Game.travel_road). Saída a leste = destino.
	"estrada": {
		"name": "Estrada entre os reinos", "subtitle": "Emboscada! Monstros no caminho",
		"W": 48, "H": 22, "base_row": 12, "tint": Color(0.98, 1.0, 0.95), "path_origin": Vector2i(0, 7), "path_set": "floor",
		"music": "ambience_nature", "ambience": "",
		"exit": "east", "spawn": Vector2i(4, 11),
		"paths": [[0, 10, 47, 12]],
		"water": [],
		"piers": [],
		"buildings": [],
		"npcs": [],
		"decor": [
			["n_arvore_redonda", [6, 5]], ["n_arvores_trio", [14, 4]], ["n_arvore_grande", [24, 5]], ["n_arvore_redonda2", [34, 4]],
			["n_arvores_trio_b", [42, 5]], ["n_arvore_redonda3", [9, 17]], ["n_arvore_pinheiro", [19, 18]], ["n_arvores_trio", [30, 17]],
			["n_arvore_redonda", [40, 18]], ["n_pedra_cinza_g", [12, 14]], ["n_pedra_marrom", [27, 8]], ["n_arbusto3", [36, 14]],
			["n_toco1", [21, 14]], ["n_mato2", [16, 8]], ["n_mato4", [44, 14]],
		],
		"label": Color("d9ffc2"),
	},
}

const SPEAKERS := {
	"cocheiro": {"name": "Tobias, o cocheiro"},
	"capitao": {"name": "Capitão Maré"},
	"granito": {"name": "Mestre Granito"},
	"reitora": {"name": "Reitora Aurora"},
}

## Fragmento de memória do pai de cada cidade: [fala de abertura (sem horas), memória (sepia), reflexão do herói].
const FRAGMENTS := {
	"porto": {
		"title": "Diário do Porto",
		"intro": [
			["capitao", "Você tem os olhos dele. Cinzentos, teimosos. Seu pai passou por este cais numa manhã de névoa."],
			["capitao", "Deixou um diário comigo. Disse: 'se eu esquecer, que alguém me lembre de voltar'. Eu guardei no cofre, e só entrego a quem provar que aprende."],
		],
		"locked": [["capitao", "Ainda não, jovem. Meu cofre só abre para quem estudou %s horas. Volte quando o relógio disser."]],
		"memory": [
			["mem:pai", "Dia 9. A névoa engoliu o farol de novo. Hoje esqueci o nome da rua onde nasci, mas lembrei do rosto da minha esposa."],
			["mem:pai", "Desenhei a criança dormindo na rede, as mãos fechadas em torno de um livro. Preciso voltar antes de esquecer essa também."],
			["narr", "Entre as páginas, um desenho a lápis: um {o} menin{o} dormindo com um livro no peito. É você."],
			["heroi", "Ele lembrou de mim. Mesmo apagado, ele escreveu que ia voltar."],
			["capitao", "Quem desenha uma coisa dessas não esqueceu de verdade. Leve o diário, e a cabeça erguida."],
		],
		"reward_text": "Fragmento do Porto: +1 fragmento, um equipamento raro e 1 crédito.",
	},
	"pedralta": {
		"title": "Martelo do Pai",
		"intro": [
			["granito", "Seu pai tinha mãos de escrivão e teimosia de ferreiro. Chegou aqui querendo forjar um martelo e saiu com uma lição."],
			["granito", "Guardei o martelo dele atrás da bigorna. Só entrego a quem aprendeu a esperar o metal esquentar, o tempo certo."],
		],
		"locked": [["granito", "Metal frio não se dobra, jovem. Estude %s horas e a gente conversa de novo."]],
		"memory": [
			["mem:pai", "Primeira regra do ferreiro: o metal só obedece quando está no ponto. Pressa quebra, paciência dobra."],
			["mem:pai", "Aprendi com ele que estudar é igual: um pouco por dia, no calor certo, e depois deixar esfriar. Escrevi isso para a minha esposa."],
			["narr", "O cabo do martelo tem um nome gravado, riscado à faca: o seu."],
			["heroi", "Ele entalhou meu nome. Antes da névoa, ele já pensava em mim."],
			["granito", "Faça o que ele fez: bata no ponto, devagar. Pedralta aprende com você, e você com Pedralta."],
		],
		"reward_text": "Fragmento de Pedralta: +1 fragmento, um equipamento raro e 1 crédito.",
	},
	"academia": {
		"title": "Tese do Pai",
		"intro": [
			["reitora", "Fontelúcida tem um corredor com a tese de cada aluno. A de um certo estudante, de cabelo desgrenhado, ninguém conseguiu repor no lugar."],
			["reitora", "O título é 'A cabeça aprende melhor um pouco por dia'. Era seu pai, não era? A Névoa quase apagou até as páginas."],
		],
		"locked": [["reitora", "A tese só sai do cofre da Reitoria para quem provou constância: %s horas de foco. Estude e volte."]],
		"memory": [
			["mem:pai", "Conclusão: a memória não está nos livros nem na cabeça, está no caminho entre os dois, repetido todos os dias."],
			["mem:pai", "Se a Névoa apagar o caminho, que alguém o refaça por mim, passo a passo. Essa é a prova de que ele existiu."],
			["narr", "Na última página, a letra mudou, mais trêmula: 'Filho, se estiver lendo isto, continue. O resto é consequência.'"],
			["heroi", "Ele escreveu isso para mim. Eu estou refazendo o caminho."],
			["reitora", "Então a tese está completa. Leve com você; e volte quando quiser perguntar algo que ninguém soube responder."],
		],
		"reward_text": "Fragmento da Academia: +1 fragmento, um equipamento raro e 1 crédito.",
	},
}

const COCHEIRO_NO := [["cocheiro", "Por enquanto só levo quem já terminou a Parte 1. Volte depois de enfrentar o Rei Demônio, jovem."]]


static func get_city(id: String) -> Dictionary:
	return CITIES.get(id, {})


static func tint_of(a: Array) -> Color:
	return Color(a[0], a[1], a[2]) if a.size() >= 3 else Color.WHITE
