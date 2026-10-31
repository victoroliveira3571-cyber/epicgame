class_name Street
extends RefCounted

## Gente comum de Focus Town (e dos caminhos): ao apertar [E] perto de quem não é da história, a pessoa
## conta um pedaço curto da própria história e fecha com uma frase motivacional ligada a ela. A mesma
## pessoa (identificada por sheet + ponto de origem) só conta a história inteira na primeira vez; depois
## conversa curto, com outra frase. Falas aparecem com o nome da pessoa (speaker "rua_<persona>_<n>").

const MOTTOS_REPEAT := [
	"Hoje, só um bloco a mais que ontem. Isso já é vencer.",
	"Quem volta ao assunto amanhã lembra dele no mês que vem.",
	"Não espere vontade: comece cinco minutos e a vontade aparece.",
	"Errar na revisão é melhor do que acertar por sorte na prova.",
	"Descanso também é parte do estudo. Respire.",
	"O que você escreve com as próprias palavras, você não esquece.",
]

## [nome, ofício, [história em 2 a 3 falas], frase motivacional]
const PERSONAS := [
	["Tavinho", "entregador", ["Eu era o mais lento da vila. Perdia toda corrida de entrega.", "Aí passei a anotar o caminho de volta de cabeça, sem olhar o mapa. Em um mês virei o mais rápido."], "Quem treina de memória não precisa de mapa."],
	["Dona Lúcia", "doceira", ["Minha primeira receita queimou três vezes seguidas. Quase fechei a banca.", "Resolvi repetir uma receita por dia, só uma, até acertar. Hoje a fila dá a volta na praça."], "Uma coisa por dia, repetida, vence mil coisas de uma vez."],
	["Seu Amaro", "pescador", ["Passei dois invernos sem pegar nada no lago. Todo mundo me dizia para desistir.", "No terceiro, entendi onde os peixes ficavam de madrugada. Valeu esperar."], "Paciência bem direcionada é estratégia."],
	["Bia", "aprendiz de cartógrafa", ["Desenhei o mapa da cidade errado umas vinte vezes. O mestre rasgava todos, sorrindo.", "No vigésimo primeiro, ele pendurou na parede. Sem dizer nada."], "O vigésimo primeiro desenho só existe por causa dos vinte primeiros."],
	["Zeca", "lenhador", ["Eu cortava lenha sem pensar, de qualquer jeito. Vivia com dor nas costas.", "Um velho me ensinou a respirar em cada golpe. Cortei mais e cansei menos."], "Ritmo vence força."],
	["Madalena", "tecelã", ["Aprendi a tecer com minha avó, mas esqueci metade do ponto depois que ela se foi.", "Fui reaprendendo fio por fio, anotando tudo. Agora ensino as meninas da rua."], "Se você esqueceu, não perdeu: só precisa reconstruir."],
	["Rui", "ajudante de ferreiro", ["Queimei a mão no primeiro dia e jurei nunca mais chegar perto da forja.", "Voltei na semana seguinte com luvas e perguntas. O Brás só riu e me passou o martelo."], "Medo some quando você volta com preparo."],
	["Sofia", "menina curiosa", ["Eu perguntava tudo para todo mundo. Diziam que eu era chata.", "Hoje sou a única que sabe por que o céu escurece antes da chuva."], "Perguntar bem é a metade de aprender."],
	["Velho Tadeu", "contador de causos", ["Perdi a visão de um olho e achei que não ia mais ler. Os livros eram minha vida.", "Aprendi a escutar: gravo as histórias na cabeça e conto de novo. Ficaram melhores."], "Se um caminho fecha, estude por outro."],
	["Helga", "guarda-livros", ["Na primeira prova da Guilda eu travei e entreguei em branco.", "Fiz de novo no ano seguinte, com resumo de uma página só. Passei em segundo lugar."], "Resuma até caber na palma da mão."],
	["Nando", "cavalariço", ["Meu cavalo me derrubou catorze vezes no mesmo dia.", "Na décima quinta, eu já sabia o que ele faria antes de ele fazer."], "Cair é só coletar informação."],
	["Irene", "boticária", ["Misturei duas ervas erradas e dormi um dia inteiro. Acordei com a ideia de etiquetar tudo.", "Hoje minha prateleira é a mais organizada de Focus Town."], "Organização é estudo que você faz uma vez só."],
	["Caio", "aprendiz de arqueiro", ["Errei mil flechas no mesmo alvo. Contei todas, para ver se melhorava.", "Na milésima e primeira, acertei o centro. Só acertei porque contei."], "O que se mede melhora."],
	["Dona Cora", "lavadeira", ["Trabalhei vinte anos sem saber ler. Pedia aos outros para ler as cartas dos meus filhos.", "Aos cinquenta, entrei na biblioteca e pedi um livro de crianças. Li a primeira página chorando."], "Nunca é tarde para a primeira página."],
	["Beto", "tocador de flauta", ["Aprendi uma música inteira ouvindo uma vez só. Não consegui tocar de novo no dia seguinte.", "Aí aprendi a tocar um trecho por vez, todo dia, e hoje toco sem pensar."], "Pedaço pequeno, todo dia, vira música inteira."],
	["Lívia", "estudante de rotas", ["Eu estudava dez horas seguidas e não guardava nada.", "Troquei por quatro blocos de vinte e cinco minutos com pausa. Guardo mais e canso menos."], "Foco curto e bem feito vence maratona confusa."],
	["Dagoberto", "ex-aventureiro", ["Perdi três dentes e um dedo na masmorra por entrar sem saber o padrão do chefe.", "Hoje estudo cada inimigo antes de lutar. Meu único dedo de reserva agradece."], "Quem estuda o adversário luta menos e vence mais."],
	["Marina", "pintora", ["Meu primeiro quadro ficou tão feio que escondi no porão.", "Anos depois, desenterrei e comparei com o mais novo. Chorei de ver o quanto eu andei."], "Guarde o começo: ele prova o caminho."],
	["Otto", "relojoeiro", ["Concertei um relógio errado por uma semana, e ele funcionava lindo... para o horário errado.", "Aprendi: antes de consertar, confira se entendeu o problema."], "Entender vem antes de executar."],
	["Tereza", "vendedora de frutas", ["Eu decorava preços com rimas bobas. Todo mundo ria.", "Mas nunca errei um troco. Hoje ensino as rimas para as crianças."], "Se a lembrança é boba, é a mais difícil de perder."],
	["Gil", "vigia noturno", ["Dormi no posto uma noite e jurei nunca mais.", "Agora estudo de madrugada, em blocos curtos. O sono vem na hora certa."], "Disciplina é cuidar do corpo para a mente trabalhar."],
	["Júlia", "mensageira", ["Já errei a casa de entrega por confundir duas ruas parecidas.", "Faço o caminho de cabeça de novo antes de dormir. Não errei mais."], "Revisar antes de dormir fixa o dia."],
	["Mestre Quincas", "afinador de alaúdes", ["Passei anos achando que tinha ouvido ruim.", "Era só falta de treino. Dez minutos por dia por cinco anos e agora afino de olhos fechados."], "Treino pequeno, constância grande."],
	["Dona Nilda", "padeira", ["O fermento morreu na primeira semana. Chorei junto da massa.", "Anotei cada passo da receita. Nunca mais morreu."], "Registrar o processo é estudar o próprio erro."],
]


## Persona pelo visual: PERSONAS alterna masculino (índices pares) e feminino (ímpares); criança = Sofia (7).
static func persona_index(key: String, female: bool = false, child: bool = false) -> int:
	if child:
		return 7
	var pool: Array = []
	for i in PERSONAS.size():
		if (i % 2 == 1) == female and i != 7:
			pool.append(i)
	return pool[absi(key.hash()) % pool.size()]


static func is_female(npc: Node2D) -> bool:
	var sheet := str(npc.get("look_key")) if str(npc.get("look_key")) != "" else str(npc.get("sheet"))
	if Looks.has(sheet):
		return str(Looks.of(sheet).get("body", "male")) == "female"
	return sheet in ["Woman", "Villager3", "Villager4", "Girl"]


static func is_child(npc: Node2D) -> bool:
	return str(npc.get("sheet")) == "Child"


static func key_of(npc: Node2D) -> String:
	var home := npc.get("home") as Vector2 if npc.get("home") != null else npc.position
	return "%s@%d,%d" % [str(npc.get("sheet")), int(home.x), int(home.y)]


## Dicionário de falantes dinâmico: "rua_<persona>_<n>" -> nome da pessoa.
static func speaker_info(who: String) -> Dictionary:
	if not who.begins_with("rua_"):
		return {}
	var parts := who.split("_")
	var idx := clampi(int(parts[1]) if parts.size() > 1 else 0, 0, PERSONAS.size() - 1)
	return {"name": str(PERSONAS[idx][0])}


static func talk(npc: Node2D) -> void:
	if Story.is_busy() or HUD.is_dialogue_open():
		return
	var key := key_of(npc)
	var idx := persona_index(key, is_female(npc), is_child(npc))
	var p: Array = PERSONAS[idx]
	var who := "rua_%d_%d" % [idx, absi(key.hash()) % 997]
	npc.add_to_group("speaker_" + who)
	var seen: Dictionary = Story.st().get("street_seen", {})
	var times := int(seen.get(key, 0))
	seen[key] = times + 1
	Story.st()["street_seen"] = seen
	var lines: Array = []
	if times == 0:
		lines.append([who, "Ora, um aventureiro. Sou %s, %s por aqui." % [p[0], p[1]]])
		for l in p[2]:
			lines.append([who, str(l)])
		lines.append(["tip:" + who, str(p[3])])
	else:
		lines.append([who + "@happy", ["De novo por aqui? Gosto de gente que volta.", "Olha só quem apareceu!", "Já ia me esquecer de você. Brincadeira."][randi() % 3]])
		lines.append(["tip:" + who, str(MOTTOS_REPEAT[randi() % MOTTOS_REPEAT.size()])])
	Story._busy = true
	await Story.say(lines)
	Story._busy = false
	if is_instance_valid(npc):
		npc.remove_from_group("speaker_" + who)
		if npc is NPC:
			(npc as NPC).talking = false
