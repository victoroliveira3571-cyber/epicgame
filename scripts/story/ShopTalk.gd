class_name ShopTalk
extends RefCounted

## Donos dos estabelecimentos: na primeira conversa cada um apresenta o negócio, explica os
## serviços e conta um pedaço da história de Focus Town (flag "intro_<id>"). Depois, conversa
## curta com uma fala sorteada. Os rostos e o nome vêm de StoryData.SPEAKERS / Looks.

const INTROS := {
	"ferreiro": [
		["narr", "O calor da fornalha bate no rosto. Um homem largo, de bigode enorme, larga o martelo na bigorna."],
		["ferreiro@happy", "Ei! Cuidado com as faíscas. Sou o Brás, ferreiro de Focus Town há trinta invernos."],
		["ferreiro", "Aqui eu aprimoro armas e armaduras. Traga ouro e as barras de metal que caem na masmorra, e eu deixo seu equipamento mais forte."],
		["ferreiro", "Cada nível de aprimoramento pede um pouco mais. Não dá para pular etapas: metal bom é metal batido muitas vezes."],
		["ferreiro", "Esta forja foi acesa no dia em que a cidade nasceu. Os primeiros estudiosos diziam que o ferro daqui guardava a forma que recebia."],
		["ferreiro@sad", "Depois que o Rei Demônio levou as páginas, o metal da masmorra começou a vir mais frio. Até o fogo parece esquecer."],
		["tip:ferreiro", "Prática espaçada: um pouco por dia rende mais do que tudo de uma vez. Lâmina e memória se forjam do mesmo jeito."],
		["ferreiro@happy", "Pronto, falei demais. Quando quiser aprimorar, é só chegar no balcão."],
	],
	"armeiro": [
		["narr", "Espadas brilham nos suportes. Atrás da vitrine, um senhor de colete vinho alisa o bigode."],
		["armeiro@happy", "Bem-vind{o} à Loja de Armas do Otávio! Espadas, adagas, cajados e arcos, tudo testado por mim mesmo."],
		["armeiro", "Vendo equipamento por tier. Quanto mais você sobe de nível, mais peças boas eu libero aqui no balcão."],
		["armeiro", "Arma, capacete, armadura, escudo, botas e amuleto. O que você vestir aparece em você, então escolha com estilo."],
		["armeiro", "Meu avô abriu esta loja quando a Guilda ainda era uma cabana. Naquela época, aventureiro comprava espada fiado e pagava com mapas."],
		["armeiro", "Aquele escudo da parede foi do primeiro Rank S da cidade. Ninguém lembra o nome dele. Sumiu junto com as páginas."],
		["armeiro@happy", "Escolha com calma. Arma boa na mão de quem não treina é só enfeite."],
	],
	"costureira": [
		["narr", "Rolos de tecido por todo lado. Uma moça de óculos de gatinho tira um alfinete da boca."],
		["costureira@happy", "Ah, cliente! Desculpe a bagunça, tecido não se arruma sozinho. Sou a Rosa."],
		["costureira", "Faço roupas, capas e consertos. As roupas novas você compra com fichas de estilo, que ganha estudando no Pomodoro."],
		["costureira", "Aqui no ateliê também tem um guarda-roupa. E se quiser mudar o cabelo ou o rosto, use o espelho de casa."],
		["costureira", "Essa roca era da minha mãe. Metade de Focus Town já vestiu alguma coisa que saiu daqui."],
		["costureira@sad", "Antes da Névoa, os estudantes vinham de longe com cachecóis nas cores das suas escolas. Ainda guardo alguns, esperando eles voltarem."],
		["costureira@happy", "Passe sempre que quiser conversar. Linha e agulha também precisam de companhia."],
	],
	"estalajadeiro": [
		["narr", "Cheiro de lenha e de sopa. Um homem ruivo enxuga um caneco atrás do balcão."],
		["estalajadeiro@happy", "Opa! Estalagem do Viajante, a seu dispor. Bento é o nome."],
		["estalajadeiro", "Viajantes descansam aqui antes de seguir para a floresta. Os quartos vivem cheios, mas a conversa é de graça."],
		["estalajadeiro", "Quem passa traz notícia. Ontem um mercador jurou ter visto luzes no fundo da Mata Profunda."],
		["estalajadeiro", "Focus Town cresceu em volta de uma biblioteca antiga. A estrada até aqui foi feita pelos estudantes, pedra por pedra."],
		["estalajadeiro@happy", "Sente, esquente as mãos. E se ouvir alguma história boa lá fora, volte para me contar."],
	],
	"mestre_cla": [
		["narr", "O salão cheira a madeira encerada. Um mestre de rabo de cavalo cruza os braços e observa você."],
		["mestre_cla", "Silêncio ao entrar. Este é o Salão do Clã, e eu sou o Mestre Daichi."],
		["mestre_cla", "Treinamos o corpo para que a mente aguente. Uma luta é igual a uma prova: quem treinou com calma não entra em pânico."],
		["mestre_cla", "Este salão foi erguido por guerreiros que vieram a Focus Town aprender a ler. Viraram mestres das duas coisas."],
		["tip:mestre_cla", "Antes de uma prova, durma bem e faça uma revisão curta. Cansaço apaga mais do que a Névoa."],
		["mestre_cla", "Se quiser pôr à prova o que aprendeu, a Arena aceita duelos contra outros aventureiros. Fica a leste da Guilda."],
	],
	"bibliotecaria": [
		["narr", "Prateleiras até o teto. Uma senhora de óculos levanta os olhos do livro e sorri."],
		["bibliotecaria@happy", "Bem-vind{o} à Biblioteca de Focus Town. Fale baixinho, sim? Eu sou a Celeste."],
		["bibliotecaria", "As mesas são livres: sente, abra o Pomodoro e estude no silêncio. Ninguém incomoda quem está focado aqui."],
		["bibliotecaria", "Esta biblioteca é mais velha que a cidade. As pessoas vieram morar em volta dela, e não o contrário."],
		["bibliotecaria@sad", "Quando a Névoa chegou, muitas prateleiras ficaram em branco. Os livros continuam aqui, mas as páginas sumiram."],
		["bibliotecaria", "Só que, cada vez que alguém termina uma sessão de estudo nesta sala, parece que uma letra volta. Pode ser impressão de velha."],
	],
	"arena": [
		["narr", "Areia batida, arquibancadas de pedra e o eco de espadas. Uma mulher ruiva de braços cruzados vem na sua direção."],
		["arena@happy", "Ora, ora! Cara nova na Arena! Sou a Bruna, organizo os duelos."],
		["arena", "Aqui aventureiros se enfrentam em duelos limpos. Ninguém morre: quando a vida de alguém chega no fim, a luta para."],
		["arena", "Cada vitória dá ouro, experiência e prestígio. Com prestígio você sobe de rank na Arena: Bronze, Prata, Ouro, Platina e Lenda."],
		["arena", "Quanto mais alto o seu rank, mais fortes os oponentes e melhores os prêmios. Perder custa só um pouco de prestígio."],
		["arena", "A Arena foi construída depois do primeiro Torneio das Guildas. O nome do campeão estava gravado no portão... até a Névoa apagar."],
		["tip:arena", "Duelo é leitura do adversário: observe o golpe dele antes de atacar e role (R) no momento certo."],
		["arena@happy", "Quando estiver pront{o}, fale comigo na placa de inscrição."],
	],
}

const INTROS_LAB := {
	"cientista": [
		["narr", "Um estalo, uma nuvem verde e um cheiro de ovo queimado. No meio da fumaça, um senhor de cabelo arrepiado tosse e sorri."],
		["cientista@happy", "Cof! Cof! Visitante! Bem-vind{o} ao Laboratório do Dr. Faísca! Não repare a explosão, ela é decorativa."],
		["cientista", "Aqui eu transformo o que os monstros deixam para trás em coisas úteis: gosma, pelo, asa, osso, essência da Névoa e cristal arcano."],
		["cientista", "Com eles eu faço poções de cura, tônicos que turbinam seu estudo e... meus favoritos... LIVROS DE MAGIA!"],
		["cientista@happy", "O Tônico da Memória dá mais XP nas suas próximas sessões de foco. Mas atenção: só funciona se você ESTUDAR. Ciência não faz milagre!"],
		["cientista", "E os livros só saem do forno se você tiver horas de foco suficientes. Magia de verdade se escreve com estudo de verdade."],
		["tip:cientista", "Recuperação ativa: depois de estudar, feche o livro e tente explicar o assunto com as suas palavras. É o meu experimento favorito."],
		["cientista@happy", "Use a bancada aqui do lado. E não toque no frasco rosa. Ninguém sabe o que ele faz. Nem ele."],
	],
	"pipeta": [
		["pipeta@happy", "Oi! Eu sou a Pipeta, assistente oficial, anotadora oficial e apagadora de incêndios oficial."],
		["pipeta", "O doutor é brilhante, mas esquece o que fez cinco minutos atrás. Por isso eu anoto TUDO."],
		["tip:pipeta", "Anotar com as próprias palavras é metade do aprendizado. Copiar é só transferir tinta."],
		["pipeta@happy", "Se precisar de ingredientes: slimes dão gosma, lobos dão pelo, morcegos dão asa e esqueletos dão osso. Cristal, só com sorte ou de monstro elite!"],
	],
	"tonico": [
		["tonico@happy", "E aí! Tonico. Eu carrego caixas, mexo o caldeirão e provo as poções antes de todo mundo."],
		["tonico", "Uma vez provei uma poção de invisibilidade. Ninguém me viu por três dias. Ou ninguém quis me ver, não sei."],
		["tonico@happy", "Dica de quem já explodiu muita coisa: um passo de cada vez. Erva primeiro, gosma depois. Nunca o contrário."],
	],
}

const CHATS := {
	"ferreiro": ["Ferro frio não aceita forma. Esquente antes!", "Trouxe barras? O balcão é ali.", "Uma batida por dia. É assim com tudo."],
	"armeiro": ["Chegou mercadoria nova, dá uma olhada.", "Quem compra escudo nunca se arrepende.", "Já subiu de nível? Talvez eu tenha liberado algo."],
	"costureira": ["Que tal uma roupa nova? As fichas de estilo vêm do estudo.", "Essa cor fica ótima em você.", "Volte sempre, a linha não acaba."],
	"estalajadeiro": ["Notícia fresca: o Pântano está cheio de névoa hoje.", "Quer um caneco? Por conta da casa.", "Viajante cansado é viajante distraído."],
	"mestre_cla": ["Respire. Golpeie. Respire.", "A Arena espera quem treinou.", "Disciplina é fazer mesmo sem vontade."],
	"bibliotecaria": ["Shhh. As mesas estão livres.", "Uma página por vez, querid{o}.", "Hoje uma letra voltou para o livro de geografia!"],
	"arena": ["Pronto para mais um duelo?", "Seu prestígio está subindo, hein!", "Na Arena, quem hesita cai."],
	"cientista": ["Eureka! Ah não, era só um soluço.", "Trouxe gosma? Eu amo gosma.", "Hoje nada explodiu. Ainda."],
	"pipeta": ["Anotei sua última visita. E a anterior.", "O doutor está de bom humor: o cabelo ainda está em pé.", "Óculos no rosto, sempre!"],
	"tonico": ["Quer provar algo? Eu já provei, tá seguro. Acho.", "Minha mão está verde há uma semana.", "Caixa pesada, coração leve!"],
}


## Depois da apresentação: conversa curta com um menu "o que você gostaria?".
## [rótulo do serviço, ação] (ação: id de janela do HUD, ou "heal", "study", "tip").
const MENU := {
	"ferreiro": ["Aprimorar equipamento", "forja"],
	"armeiro": ["Ver o balcão de armas", "loja"],
	"costureira": ["Abrir o guarda-roupa", "guarda_roupa"],
	"estalajadeiro": ["Descansar um pouco (vida cheia)", "heal"],
	"mestre_cla": ["Uma dica de treino", "tip"],
	"bibliotecaria": ["Sentar para estudar", "study"],
	"arena": ["Inscrever-me num duelo", "arena"],
	"cientista": ["Usar a bancada de preparos", "laboratorio"],
	"pipeta": ["Quais monstros dão cada ingrediente?", "tip_lab"],
	"tonico": ["Usar a bancada de preparos", "laboratorio"],
}
const LORE := {
	"ferreiro": ["Meu avô dizia que o ferro lembra cada martelada. Eu acredito.", "Um aprendiz me perguntou quanto tempo leva para ficar bom. Respondi: o mesmo que a lâmina leva para esfriar bem."],
	"armeiro": ["Um aventureiro me trouxe uma espada rachada e jurou que ela salvou a vida dele. Guardei no cofre.", "A melhor venda do mês foi um escudo para um rapaz que só queria sobreviver à primeira masmorra."],
	"costureira": ["Fiz um manto para uma maga que nunca voltou da Mata. Ainda mantenho a linha da mesma cor.", "Uma menina me pediu um vestido 'de estudar'. Era azul e cheio de bolsos."],
	"estalajadeiro": ["Um viajante dormiu aqui três dias seguidos só para terminar um livro. Pagou com um mapa.", "No inverno passado, o Pântano soltou uma névoa que cheirava a tinta. Ninguém soube explicar."],
	"mestre_cla": ["Já tive um aluno que lutava sem ler o adversário. Aprendeu a ler no pior dia da vida dele.", "O verdadeiro golpe secreto é voltar amanhã."],
	"bibliotecaria": ["Alguém deixou um marcador de página com a letra 'Z' e a frase 'continuo amanhã'. Está lá até hoje.", "Já vi um estudante dormir em cima de um livro e acordar sabendo a primeira página. Lenda, claro."],
	"cientista": ["Meu primeiro experimento transformou meu gato em... um gato mais bravo. Foi um começo.", "Inventei uma poção de lembrar onde deixei os óculos. Ela estava nos meus óculos."],
	"pipeta": ["Uma vez o doutor tentou criar um livro que estuda sozinho. Ele dormiu em cima do livro.", "Meu caderno de anotações tem mais páginas que a biblioteca. Quase."],
	"tonico": ["Eu era lenhador. Um dia um raio caiu no meu machado e o doutor me contratou na hora.", "Já fui sapo por dez minutos. Não recomendo, mas a vista é bonita."],
	"arena": ["Já perdi um duelo por me achar invencível. O rival me ofereceu a mão depois. Foi a melhor lição.", "A torcida da Arena cresce com o prestígio. Dizem que na lenda lota até o telhado."],
}


static func talk(id: String) -> void:
	if Story.is_busy() or HUD.is_dialogue_open():
		return
	var intro: Array = INTROS.get(id, INTROS_LAB.get(id, []))
	if not Story.flag("intro_" + id) and not intro.is_empty():
		Story.set_flag("intro_" + id)
		await Story.say(intro)
		return
	var greet: Array = CHATS.get(id, ["..."])
	var service: Array = MENU.get(id, ["", ""])
	var options: Array = []
	if str(service[0]) != "":
		options.append(str(service[0]))
	options.append("Conte-me uma história")
	options.append("Só estou passando")
	await Story.say([[id, str(greet[randi() % greet.size()]) + " O que gostaria?"], {"choice": options, "key": "shop_menu"}])
	var picked := int(Story.flag("shop_menu", options.size() - 1))
	var has_service := str(service[0]) != ""
	if has_service and picked == 0:
		await _do_service(id, str(service[1]))
	elif picked == (1 if has_service else 0):
		var lore: Array = LORE.get(id, ["..."])
		await Story.say([[id, str(lore[randi() % lore.size()])]])
	else:
		await Story.say([[id, "Até logo. A porta está sempre aberta."]])


static func _do_service(id: String, action: String) -> void:
	match action:
		"heal":
			GameState.full_heal()
			Audio.wake_up()
			await Story.say([[id, "Sente aí, esquente as mãos. Pronto: vida cheia."]])
		"tip":
			await Story.say([["tip:" + id, "Treino e estudo pedem o mesmo: começar pequeno, repetir e descansar. Dormir bem fixa o que você aprendeu."]])
		"tip_lab":
			await Story.say([[id, "Slimes, kappas e axolotes: gosma. Lobos, ursos e ratos: pelo. Morcegos e aranhas: asa. Esqueletos e crânios: osso. Névoa, sombra e chama: essência. Cristal: sorte ou elite!"]])
		"study":
			await Story.say([[id, "A mesa livre é a sua. Sente e abra o Pomodoro."]])
			HUD.open_pomodoro_at("livraria")
		_:
			HUD.open_window(action)
