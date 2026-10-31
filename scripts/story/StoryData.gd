class_name StoryData
extends RefCounted

## Textos da história (capítulos 1 a 5): falantes, diálogos, objetivos e o banco de cartas
## dos chefes. Roteiro completo em EPICGAME/ROTEIRO_COMPLETO.md.
##
## Formato de uma fala (Array de entradas):
##   ["marta", "texto"]                fala com retrato
##   ["narr", "texto"]                 narração (sem retrato)
##   ["tip:marta", "texto"]            dica de estudo (caixa de dica)
##   ["mem:pai", "texto"]              memória (tom sépia)
##   ["boss:rei", "texto"]             fala de chefe (borda vermelha)
##   {"choice": ["A", "B"], "key": "x"} escolha do jogador (guarda o índice em flags[key])
## {heroi}, {pai} e {mae} viram os nomes escolhidos pelo jogador; {o}/{O} e {e} seguem o tratamento
## escolhido (o/a, O/A, e/a: "querid{o}", "ess{e}").

const SPEAKERS := {
	"narr": {"name": ""},
	"heroi": {"name": "{heroi}"},
	"mae": {"name": "{mae}"},
	"pai": {"name": "{pai}"},
	"marta": {"name": "Dona Marta"},
	"helena": {"name": "Helena"},
	"osvaldo": {"name": "Osvaldo"},
	"pietro": {"name": "Pietro"},
	"ivo": {"name": "Ivo"},
	"lin": {"name": "Mestre Lin"},
	"aldric": {"name": "Aldric"},
	"vizinho": {"name": "Vizinho"},
	"espirito": {"name": "Espírito do Caçador"},
	"sentinela": {"name": "Sentinela de Pedra"},
	"bibliotecario": {"name": "Bibliotecário Corrompido"},
	"cavaleiro": {"name": "Cavaleiro Sem Nome"},
	"rei": {"name": "Rei Demônio"},
	"corvin": {"name": "Corvin"},
	"brisa": {"name": "Brisa"},
	"lumen": {"name": "Lúmen"},
	"airevis": {"name": "Airevis"},
	"espelho": {"name": "Espelho"},
	"ferreiro": {"name": "Brás, o ferreiro"},
	"armeiro": {"name": "Otávio, o armeiro"},
	"costureira": {"name": "Rosa, a costureira"},
	"estalajadeiro": {"name": "Bento"},
	"mestre_cla": {"name": "Mestre Daichi"},
	"bibliotecaria": {"name": "Dona Celeste"},
	"arena": {"name": "Bruna, mestra da Arena"},
}

const CHAPTERS := {
	1: {"title": "Capítulo 1", "name": "A Trilha das Ervas"},
	2: {"title": "Capítulo 2", "name": "A Névoa sob as Raízes"},
	3: {"title": "Capítulo 3", "name": "As Páginas da Masmorra"},
	4: {"title": "Capítulo 4", "name": "O Juramento Quebrado"},
	5: {"title": "Capítulo 5", "name": "O Trono Sem Luz"},
	6: {"title": "Epílogo", "name": "Fim da Parte 1"},
}

## Objetivo mostrado no HUD para cada passo da história.
const OBJECTIVES := {
	"c1_casa": "Converse com {mae} antes de partir",
	"c1_marta": "Vá à Pousada Pão Quente falar com Dona Marta",
	"c1_guilda": "Registre-se na Guilda dos Aventureiros (fale com Helena)",
	"c1_portao": "Vá à Trilha da Floresta (oeste da cidade) e fale com Osvaldo",
	"c1_ervas": "Colha ervas na Borda da Floresta ({ervas}/5)",
	"c1_marca": "Siga Corvin até a árvore marcada (norte da Borda)",
	"c1_volta": "Volte à Guilda e entregue as ervas a Helena",
	"c2_exame": "Fale com Helena: exame de Rank E",
	"c2_pena": "Exame: traga a Pena Dourada da Clareira das Casas",
	"c2_entrega": "Volte à Guilda com a Pena Dourada",
	"c2_pietro": "Encontre Pietro no acampamento da Clareira",
	"c2_brisa": "Siga a trilha da loba ao sul da Clareira",
	"c2_lin": "Encontre Mestre Lin na ponte da Mata Profunda",
	"c2_carta": "Escreva o que pesa na cabeça no Caderno (tecla N)",
	"c2_ruinas": "Entre nas Ruínas sob as Raízes (oeste da Mata)",
	"c2_sentinela": "Derrote a Sentinela de Pedra ({horas}/2 h de foco)",
	"c2_marta": "Volte à Pousada Pão Quente",
	"c3_lin": "Fale com Mestre Lin na Guilda",
	"c3_paginas": "Ache 3 páginas no andar 1 da masmorra ({paginas}/3) e volte a Lin",
	"c3_exame": "Exame de Rank D: derrote o Bibliotecário no andar 2 ({horas}/4 h de foco)",
	"c3_volta": "Volte à Guilda e conte tudo a Helena",
	"c4_torneio": "Fale com Helena: Torneio das Guildas",
	"c4_pietro": "Fale com Pietro na Guilda",
	"c4_cavaleiro": "Desça até o andar 4 e enfrente o Cavaleiro Sem Nome ({horas}/6 h de foco)",
	"c4_volta": "Volte à Guilda e fale com Mestre Lin",
	"c5_trono": "Desça ao andar 5 e enfrente o Rei Demônio ({horas}/8 h de foco)",
	"fim": "Parte 1 concluída. As Profundezas (andar 6+) estão abertas.",
}

# ============================================================================ Diálogos
const DIALOGS := {
	# --------------------------------------------------------------------- Capítulo 1
	"c1_despedida": [
		["narr", "Manhã. A casa de madeira fica no meio das árvores. {mae} está na varanda, costurando."],
		["mae", "Você já arrumou a mochila?"],
		["heroi", "Quase. Vou à cidade me registrar na Guilda."],
		["mae", "Eu sei. Só não sei se eu estou pronta para isso."],
		{"choice": ["Eu volto logo.", "Ainda não sei se quero ir."], "key": "despedida"},
		["mae", "Seu pai também dizia que voltava logo. Ele saiu numa tarde de chuva, lembra?"],
		["heroi", "Eu lembro. Dizem que ele morreu na masmorra, mas ninguém viu."],
		["mae", "Boatos andam rápido, e ninguém viu o corpo. Eu prefiro achar que ele ainda está em algum lugar."],
		["narr", "{mae} pega uma bússola de latão numa caixa de madeira."],
		["mae", "Era do {pai}. Ela nunca aponta para o lugar errado. Leve com você."],
		["narr", "Você recebeu a Bússola de Latão."],
		["mae", "E não esqueça: quando estiver cansado, descanse, mas não deixe de estudar. Seu pai achava que a cabeça aprende melhor um pouco por dia."],
	],
	"c1_saida": [
		["narr", "Você segue a trilha de terra até Focus Town. A bússola pesa no bolso."],
	],
	"c1_marta": [
		["narr", "Um cheiro de pão quente sai da cozinha. Dona Marta está atrás do balcão."],
		["marta", "Bem-vind{o}, querid{o}! Você deve ser da família que mora na floresta. Sente-se, tome um chá."],
		["heroi", "Obrigado. Vim me registrar na Guilda."],
		["marta", "Ótima ideia. Mas antes, uma coisa. Você sabe como estudar de verdade?"],
		{"choice": ["Eu releio tudo.", "Eu tento lembrar sem olhar."], "key": "marta_estudo"},
		["marta", "Reler dá uma sensação boa de aprender, mas fixa pouco. Tentar lembrar é o que funciona."],
		["tip:marta", "Recuperação ativa: feche o livro e tente lembrar os pontos principais antes de reler. É a técnica com mais evidência entre as comparadas por pesquisadores (Dunlosky e colegas, 2013)."],
		["marta", "Seu pai usava esse truque. Ele dizia que cada lembrança difícil de trazer de volta fica mais forte da próxima vez."],
		["heroi", "Ele estudava também?"],
		["marta", "Mais do que todo mundo nesta cidade. Por isso eu acredito que ele não desapareceu por acaso. Agora vá: a Guilda fica ao norte da praça."],
	],
	"c1_guilda": [
		["narr", "O salão da Guilda é grande e cheio de cartazes de missões. Helena está na mesa de registro."],
		["helena", "Nov{o} aventureir{o}? Nome e classe, por favor."],
		["heroi", "{heroi}."],
		["helena", "Certo. Agora escolha sua classe. A arma que você recebe depende dela."],
	],
	"c1_guilda2": [
		["helena", "Pronto. Cartão Rank F. Essa arma é de madeira, então não espere milagres. Todo aventureiro começa assim."],
		["narr", "Você recebeu o cartão Rank F da Guilda."],
		["helena", "Sua primeira missão é simples: colha cinco ervas na Borda da Floresta."],
		["heroi", "Só isso?"],
		["helena", "Só isso para começar. Ah, e tem o pedágio: entrar na floresta custa 1 crédito de estudo. Crédito não é ouro. Cada 45 minutos de foco concluídos no Pomodoro valem 1 crédito."],
		["helena@happy", "Como é a sua primeira missão, a Guilda te deu 1 crédito de cortesia. Ele já está no seu cartão. Os próximos, você conquista estudando."],
		["tip:helena", "Créditos de estudo: 45 minutos de foco concluídos = 1 crédito. Cada entrada na floresta ou na masmorra custa 1, e morrer tira 1 (o saldo pode ficar negativo). Abra o Pomodoro com a tecla P."],
		["helena", "A trilha fica no fim da avenida, a oeste. O Osvaldo cuida do portão."],
	],
	"c1_osvaldo_sem": [
		["osvaldo", "Quem quer passar paga um crédito. Sem crédito, sem passagem."],
		["osvaldo", "Ah, você ainda não estudou o bastante. Não se preocupe, todo mundo começa assim."],
		["tip:osvaldo", "Espaçamento: estudar um pouco todo dia vale mais do que muito num dia só. O cérebro guarda melhor quando você volta ao assunto em dias diferentes."],
		["osvaldo", "Volte com 1 crédito: 45 minutos de foco no Pomodoro (P)."],
	],
	"c1_osvaldo_paga": [
		["osvaldo", "Um crédito, certinho. Lembre: cada vez que entrar, é um crédito."],
		["osvaldo", "Boa caminhada. E cuidado com os lobos jovens: são curiosos, mas mordem."],
	],
	"c1_pietro": [
		["pietro", "Ei! Você pode me ajudar? Esse lobo quer minha caça e eu não consigo afastá-lo sozinho!"],
	],
	"c1_pietro2": [
		["pietro", "Ufa! Obrigado. Eu sou Pietro, caçador da região. Você é nov{o} por aqui?"],
		["heroi", "Sou. Estou procurando algo sobre meu pai."],
		["pietro", "Seu pai? Qual o nome dele?"],
		["heroi", "{pai}."],
		["pietro", "Não me lembro desse nome. Mas se ele passou por esta trilha, deixou sinal. Os velhos caçadores marcavam o caminho nas árvores."],
		["narr", "Um corvo pousa no galho acima de você e olha fixo para a bússola."],
		["pietro", "Esse é o Corvin. Anda por aqui há dias, seguindo os caçadores. Parece que gostou de você."],
		["corvin", "Krá!"],
		["narr", "Corvin agora acompanha você. Ele ataca inimigos e recolhe o que cai deles. (Pets: tecla C)"],
		["pietro", "Termine de colher as ervas. Depois siga o Corvin: ele sabe onde fica a árvore antiga, ao norte."],
	],
	"c1_marca": [
		["narr", "Corvin pousa numa árvore antiga, coberta de musgo. Na casca há uma seta gravada apontando para o norte e um símbolo igual ao da bússola."],
		["heroi", "Esse símbolo... é igual ao da bússola."],
		["narr", "A bússola brilha. Uma névoa cinza sobe do chão e dela surge uma figura transparente, de chapéu de caçador."],
		["boss:espirito", "Quem ativou a marca? Ninguém passa por aqui sem antes estudar."],
		["heroi", "Eu só queria saber para onde meu pai foi."],
		["boss:espirito", "Seu pai também disse isso. Mostre que aprendeu o bastante."],
	],
	"c1_espirito_vitoria": [
		["boss:espirito", "Você lembrou o caminho. Pouca gente consegue isso."],
		["narr", "O espírito se desfaz em partículas azuis e deixa uma lembrança para trás."],
		["mem:pai", "O norte guarda a resposta. Quem chegar lá não volta do mesmo jeito."],
		["heroi", "Pai..."],
		["narr", "A bússola aponta para o norte. Ao longe, uma névoa cinza cobre as copas das árvores."],
		["corvin", "Krá!"],
		["heroi", "Eu sei. A resposta está lá. Mas primeiro, as ervas para a Helena."],
	],
	"c1_entrega": [
		["helena", "Cinco ervas, perfeitas. Missão cumprida, Rank F. Aqui está sua recompensa."],
		["narr", "Pietro entra no salão e acena."],
		["pietro", "Você encontrou a marca, não foi? Então o próximo passo é a Névoa. Mas antes, descanse. Estudar também cansa."],
	],
	# --------------------------------------------------------------------- Capítulo 2
	"c2_exame": [
		["helena", "Exame de Rank E. Pegue a Pena Dourada que deixamos na Clareira das Casas e traga de volta."],
		["narr", "Um rapaz de cabelo branco, com uma luva só, se aproxima."],
		["ivo", "Você é aquel{e} que a Helena chamou de \"{o} estudios{o}\"? Não faça essa cara. Eu não preciso de sorte, eu tenho vento."],
		["heroi", "Você vai fazer o exame também?"],
		["ivo", "Vou fazer o exame e depois te mostrar como se faz."],
		["helena", "Ivo, quieto. Podem ir. A Clareira fica depois da Borda da Floresta, a oeste."],
	],
	"c2_pena": [
		["narr", "A Pena Dourada brilha entre as raízes."],
		["ivo", "Ah, não! Por um segundo! Da próxima vez eu chego antes, estudioso."],
	],
	"c2_entrega": [
		["helena", "A Pena Dourada. Exame aprovado: agora você é Rank E."],
		["narr", "Você subiu para o Rank E. A Mata Profunda e o Pântano estão liberados."],
		["helena", "Pietro pediu ajuda no acampamento da Clareira. Parece que tem um lobo rondando as casas."],
	],
	"c2_pietro": [
		["pietro", "Você chegou rápido. Bom. Uma loba anda rondando as casas à noite. Precisamos dela longe daqui."],
		["heroi", "Ela atacou alguém?"],
		["pietro", "Atacou meu cachorro no mês passado. A toca fica ao sul da clareira."],
		{"choice": ["Vou lá e resolvo.", "Vou com calma e observo primeiro."], "key": "pietro_calma"},
		["pietro", "Cuidado. Lobo protegendo a toca não recua."],
	],
	"c2_brisa": [
		["narr", "Atrás de um tronco caído, uma loba cinzenta rosna. Atrás dela, três filhotes se encolhem."],
		["brisa", "Grrr..."],
		["heroi", "Ela não está atacando. Está protegendo os filhotes."],
		{"choice": ["Poupar a loba.", "Enfrentar a loba."], "key": "brisa_luta"},
	],
	"c2_brisa_poupa": [
		["narr", "Você abaixa a arma. A loba olha para você, depois para os filhotes, e se aproxima devagar."],
		["pietro", "Hum. Sua escolha. Se ela quiser ficar, que fique."],
		["narr", "Brisa agora acompanha você. Escolha qual pet levar na janela do Personagem (C)."],
		["pietro", "Mestre Lin passou procurando por você. Está na ponte da Mata Profunda, a oeste."],
	],
	"c2_brisa_luta": [
		["pietro", "Ela não é um monstro comum. Se for lutar, termine logo."],
	],
	"c2_brisa_derrota": [
		["narr", "A loba foge com os filhotes para dentro da mata. O silêncio pesa."],
		["pietro", "Pronto. As casas estão seguras. Aqui, pelo serviço."],
		["pietro", "Mestre Lin passou procurando por você. Está na ponte da Mata Profunda, a oeste."],
	],
	"c2_lin": [
		["narr", "Um homem de barba longa está sentado na ponte, lendo um livro velho."],
		["lin", "Você deve ser parente de {pai}. Sente-se. Antes de qualquer coisa, respire."],
		["tip:lin", "Respire três vezes, devagar, soltando o ar mais longo do que o puxou. Isso acalma o corpo antes de estudar. A pesquisa mostra efeito pequeno a moderado da meditação no estresse. Não é milagre, mas começar calmo ajuda."],
		["heroi", "Você conhecia meu pai?"],
		["lin", "Estudamos juntos. Ele achava que a Névoa não era só um clima ruim. Ela come páginas, e às vezes as lembranças de quem chega perto demais."],
		["heroi", "Como se protege disso?"],
		["lin", "Cabeça cheia não guarda nada. Por isso eu te dou isto: um Caderno. Não é para estudar, é para esvaziar a mente."],
		["tip:lin", "Caderno (tecla N): escreva livremente o que te preocupa, irrita ou cansa. Nada fica salvo. Escrever antes de estudar ajuda a tirar a preocupação da cabeça e liberar atenção."],
		["lin", "Escreva alguma coisa agora, qualquer coisa. Depois encontre as ruínas sob a árvore gigante, a oeste da Mata."],
	],
	"c2_lin_ok": [
		["lin", "Ótimo. Mais leve, não? Quando a cabeça encher de novo, volte ao Caderno."],
		["lin", "As ruínas ficam a oeste, sob a árvore gigante. A Sentinela de Pedra guarda a porta. Ela só luta com quem já estudou 2 horas."],
	],
	"c2_ruinas": [
		["narr", "Paredes de pedra com pinturas de pessoas sem rosto, carregando livros."],
		["heroi", "Essas pessoas não têm rosto."],
		["lin", "Porque a Névoa apagou os rostos delas. Perderam o que sabiam e foram esquecidas. A Sentinela está no fim do salão."],
	],
	"c2_sentinela": [
		["boss:sentinela", "Para passar, responda. E depois, lute."],
	],
	"c2_sentinela_vitoria": [
		["narr", "A pedra se parte e um cristal pequeno cai no chão. Ao tocá-lo, uma lembrança aparece."],
		["mem:pai", "A Névoa não queima. Ela apaga. Se alguém a vencer, precisa lembrar de si mesmo primeiro."],
		["mem:lin", "Vamos selar a entrada agora. Se falhar, a Névoa desce para a masmorra."],
		["narr", "Do cristal sobe uma névoa leve, que não ataca. Ela gira em volta de você."],
		["airevis", "Você me libertou. Posso ajudar, mas preciso que você lembre de mim."],
		["narr", "Airevis, o espírito da névoa, agora acompanha você."],
		["lin", "Você viu. A selagem falhou comigo também. A Névoa desceu para a masmorra sob a cidade."],
		["lin", "Volte à cidade e descanse. A Dona Marta vai querer saber de você."],
	],
	"c2_marta": [
		["narr", "Dona Marta serve chá. Pietro entra, tirando o chapéu."],
		["marta", "Pietro, você sempre volta com cara de quem não dormiu."],
		["pietro", "A Clareira está mais calma, Marta. Graças a ess{e} aventureir{o} aqui."],
		["marta", "Eu sabia. Ess{e} aventureir{o} tem bom coração, como o pai."],
		["pietro", "O {pai} não voltou das últimas vezes, Marta."],
		["marta", "Por isso eu falo. Quem não volta, às vezes só está esperando alguém perguntar por ele."],
		["tip:marta", "Dormir ajuda a fixar o que você estudou: o sono consolida a memória. Estudar até tarde e cortar o sono costuma sair caro."],
		["marta", "Mestre Lin está na Guilda, perto da escada da masmorra. Ele quer falar com você."],
	],
	# --------------------------------------------------------------------- Capítulo 3
	"c3_lin": [
		["lin", "Antes de descer, preciso de uma coisa. Três páginas estão no primeiro andar, perdidas entre as galerias. Traga-as."],
		["heroi", "Por que você não vai?"],
		["lin", "A Névoa me reconhece e me apaga. Você ainda não."],
		["tip:lin", "Caixa de preocupações: antes de um foco, escreva o que está pesando na cabeça e feche. Escrever sobre preocupações teve efeito pequeno, mas real, na ansiedade antes de provas. Fica no Pomodoro."],
		["lin", "Cada entrada na masmorra custa 1 crédito, e descer a escada também. Se cair lá dentro, perde um. Planeje seus focos."],
	],
	"c3_lin_volta": [
		["lin", "As três páginas. Obrigado."],
		["narr", "Uma coruja pousa no ombro de Mestre Lin, olha para você e muda de ombro."],
		["lumen", "Hu. Hu. Eu sou Lúmen. Carrego o que é esquecido."],
		["lin", "Ela escolheu você. Leve-a."],
		["narr", "Lúmen agora acompanha você."],
		["helena", "E o exame de Rank D começa agora: o Bibliotecário Corrompido guarda o andar 2. Derrote-o."],
		["tip:marta", "Intercalar: misturar tipos de problema dentro da mesma matéria ajuda a escolher o método certo (evidência moderada). Misturar matérias diferentes na mesma sessão não tem esse efeito."],
	],
	"c3_ivo": [
		["ivo", "Ajuda! Estou preso!"],
		["narr", "Ivo está sob uma estante que caiu. Ele tenta levantar a madeira."],
		{"choice": ["Ajudar Ivo.", "Seguir em frente."], "key": "ivo_ajuda"},
	],
	"c3_ivo_ajuda": [
		["ivo", "Você... não precisava. Mas obrigado. Eu vou te dever uma."],
	],
	"c3_ivo_segue": [
		["ivo", "Claro. {O} estudios{o} vai só pegar a página e sumir."],
	],
	"c3_bibliotecario": [
		["narr", "Livros voam pelo ar. Um homem alto, de manto feito de páginas soltas, vira o rosto para você."],
		["boss:bibliotecario", "Leia comigo. Uma página, uma frase. Complete o que eu apaguei."],
	],
	"c3_bibliotecario_vitoria": [
		["narr", "O Bibliotecário solta um caderno velho. A capa tem as iniciais de {pai}."],
		["narr", "Nas páginas há desenhos de um círculo de magia e uma frase: \"Guardar o saber dentro de si. Quem guarda não é apagado.\""],
		["mem:pai", "Se o Rei me levar as páginas, eu levo as páginas comigo. Ele não consegue apagar o que está na cabeça de quem estuda."],
		["heroi", "Ele tentou proteger todo mundo."],
		["lumen", "Hu. O caderno fala de um último andar. E de um nome riscado: Aldric."],
		["narr", "Você foi aprovado no exame: agora é Rank D."],
	],
	"c3_volta": [
		["helena", "Rank D! E esse caderno... Aldric era o parceiro de expedição do seu pai."],
		["helena", "Daqui a pouco começa o Torneio das Guildas. Fale comigo quando estiver pronto."],
	],
	# --------------------------------------------------------------------- Capítulo 4
	"c4_torneio": [
		["helena", "Torneio das Guildas! Quem vencer hoje sobe para Rank C. Primeira rodada: {heroi} contra Ivo!"],
		["ivo", "Chegou a hora, estudios{o}. Espero que você tenha estudado mais do que eu."],
	],
	"c4_ivo_vitoria": [
		["ivo", "Você ganhou por pouco. Eu estudei para isso... e ainda perdi."],
		["heroi", "Você estudou?"],
		["ivo", "Comecei depois do andar 1. Acho que você sabe por quê."],
		["helena", "Vitória! {heroi} agora é Rank C."],
		["narr", "Você subiu para o Rank C."],
	],
	"c4_ivo_ajudou": [
		["ivo", "Você me ajudou lá embaixo. Eu não esqueço."],
	],
	"c4_ivo_nao": [
		["ivo", "Lá embaixo você só fez o que precisava. Agora eu entendo."],
	],
	"c4_pietro": [
		["pietro", "Você venceu. Bom. Eu tenho notícias."],
		["heroi", "Que notícias?"],
		["pietro", "Um cavaleiro sem nome foi visto nas correntes do andar 4. Tinha uma marca de corrente no pulso. E perguntou pelo {pai}."],
		["tip:marta", "Elaboração: explique com suas palavras por que a resposta está certa. Perguntar \"por quê?\" tem evidência moderada."],
		["pietro", "Vá com cuidado. E estude antes de descer: não é só a força que faz alguém voltar."],
	],
	"c4_espelhos": [
		["narr", "Corredores de espelhos. Em um, você desistiu. Em outro, está ferido e sozinho. No terceiro, você sorri com um livro na mão."],
		["espelho", "Você não precisa lembrar de tudo. Basta lembrar o próximo passo."],
	],
	"c4_cavaleiro": [
		["narr", "Correntes pendem do teto. No fim do corredor, uma armadura escura está sentada numa cadeira de pedra."],
		["boss:cavaleiro", "Não... passe. Eu não lembro o seu nome. Nem o meu. Se você lembrar algo do {pai}, talvez eu lembre também."],
	],
	"c4_cavaleiro_vitoria": [
		["boss:cavaleiro", "Aldric. Meu nome é Aldric."],
		["narr", "Uma lembrança enche o corredor: um acampamento antigo, dois homens em volta de uma fogueira."],
		["mem:pai", "Vamos guardar o saber juntos, Aldric. Se o Rei tentar apagar um, o outro lembra."],
		["mem:aldric", "E se ele nos separar?"],
		["mem:pai", "Então eu entro no último andar e troco meu lugar pelo seu."],
		["aldric", "Ele fez isso. Trocou o lugar dele pelo meu. Está preso lá embaixo, como guardião das páginas. Ainda respira. Mas não é mais quem era."],
	],
	"c4_volta": [
		["lin", "Eu senti a Névoa. Ela chegou ao último andar."],
		["lin", "Antes de descer, sente-se. Respire. Depois escreva o que te preocupa e deixe no papel."],
		["tip:lin", "Escrita para acalmar: escrever por alguns minutos, com honestidade, sobre o que preocupa teve efeito pequeno a moderado na ansiedade em estudos. Funciona melhor como hábito curto do que como solução única."],
		["lin", "O Rei Demônio exige 8 horas de foco de quem quer enfrentá-lo. E lembre: cada andar que descer custa 1 crédito."],
	],
	# --------------------------------------------------------------------- Capítulo 5
	"c5_escada": [
		["ivo", "Eu não estudei para ser herói. Eu estudei porque você estudava, e eu não queria ficar para trás."],
		["heroi", "Então vem comigo."],
		["ivo", "Vou segurar as sombras aqui na escada. Mas se você errar a primeira pergunta do Rei, eu não vou te salvar."],
	],
	"c5_rei": [
		["narr", "O ar é frio e cheira a papel queimado. Estantes vazias. No trono, uma figura de coroa de ferro."],
		["boss:rei", "Você veio. Sabe quantos vieram antes de você?"],
		["heroi", "Muitos, imagino."],
		["boss:rei", "Todos. E todos esqueceram o que estudaram. Eu guardei o saber de Focus Town para que ninguém mais precisasse lembrar de nada."],
		["heroi", "Você roubou o conhecimento da cidade."],
		["boss:rei", "Guardei. O preço era só a memória de quem estudava. Um preço justo, não acha?"],
		{"choice": ["Não é justo.", "Você é um ladrão."], "key": "rei_resposta"},
		["boss:rei", "Então lute. Vamos ver o que você lembra."],
	],
	"c5_rei_fase2": [
		["boss:rei", "Onde eu estou? Você lembra? Ou só vê o que quer?"],
	],
	"c5_rei_fase3": [
		["boss:rei", "Esqueça seu nome. Esqueça quem te ensinou a estudar."],
		["tip:marta", "Recuperação ativa: feche os olhos e diga o que você sabe."],
		["tip:lin", "Respire. Escreva o que te preocupa. Volte à luta."],
	],
	"c5_vitoria": [
		["boss:rei", "Você... lembrou. Eu não esperava isso."],
		["narr", "O Rei se desfaz em fumaça e páginas. Uma luz fraca volta às estantes."],
		["narr", "No trono, uma figura se levanta. Olhos cinzentos, barba curta, um chapéu de viagem caído no chão."],
		["pai", "Você veio."],
		["heroi", "Pai..."],
		["pai", "Eu não sei se lembro de você por inteiro. A Névoa me apagou devagar, e eu só guardei o suficiente para te reconhecer."],
		["aldric", "Ele ainda respira. E ainda lembra de você."],
		["pai", "Agora você precisa descobrir quem eu era antes da Névoa."],
		["narr", "A bússola de latão aponta para o norte, para fora da masmorra. A névoa some, mas o céu continua cinza."],
		["narr", "A história do Rei Demônio acabou. A do seu pai está apenas começando. Fim da Parte 1."],
		["narr", "Você subiu para o Rank B. As Profundezas (andar 6 em diante) estão abertas."],
	],
	# --------------------------------------------------------------------- Falas repetíveis
	"marta_dica": [
		["marta", "Quer uma dica, querid{o}?"],
		["tip:marta", "{dica_marta}"],
	],
	"lin_dica": [
		["lin", "Sente-se um pouco."],
		["tip:lin", "{dica_lin}"],
	],
	"helena_livre": [
		["helena", "A Guilda está de portas abertas. Missões no quadro, e a escada da masmorra fica no canto."],
	],
	"pietro_livre": [
		["pietro", "A floresta muda todo dia. Ervas novas, bichos novos. Volte sempre."],
	],
	"ivo_livre": [
		["ivo", "Hoje eu fiz dois focos de 25 minutos. Não conta pra ninguém."],
	],
	"mae_livre": [
		["mae", "Você voltou! Coma alguma coisa e descanse um pouco antes de sair de novo."],
	],
	"sem_horas": [
		["narr", "Uma força antiga recusa a luta. Você precisa de {exige} horas de foco acumuladas (você tem {horas})."],
		["narr", "Estude no Pomodoro (P) e volte depois."],
	],
	"casa_pai": [
		["narr", "A casa abandonada tem cheiro de papel úmido. Na porta, alguém riscou o nome {pai}."],
		["narr", "Num baú, você encontra uma página do diário: \"Hoje a Névoa apagou o nome do Aldric do mural da Guilda. Ninguém percebeu. Eu percebi.\""],
	],
}

## Dicas que Dona Marta e Mestre Lin repetem fora da história (sorteadas).
const MARTA_TIPS := [
	"Recuperação ativa: antes de reler, feche o livro e tente lembrar. Testar-se tem mais evidência do que reler ou destacar.",
	"Espaçamento: revise o mesmo assunto em dias diferentes. Um pouco por dia vale mais do que tudo na véspera.",
	"Intercalar dentro da mesma matéria ajuda a escolher o método certo. Misturar matérias diferentes não tem esse efeito.",
	"Elaboração: pergunte \"por que isso é verdade?\" e explique com suas palavras.",
	"Dormir ajuda a fixar o que você estudou. Cortar o sono para estudar mais costuma sair caro.",
	"Reler e destacar dão sensação de aprender, mas fixam pouco. Feche o livro e tente lembrar.",
]
const LIN_TIPS := [
	"Respire três vezes, devagar, soltando o ar mais longo do que o puxou. Começar calmo ajuda a prestar atenção.",
	"Mindfulness: observe a respiração e os pensamentos sem julgar. A pesquisa mostra efeito pequeno a moderado no estresse.",
	"Escreva o que te preocupa na caixa de preocupações do Pomodoro e feche. Depois volte ao estudo.",
	"Cabeça cheia? Escreva tudo no Caderno, solte a página e volte ao foco.",
	"Se a cabeça fugir durante o foco, perceba e volte. Voltar é o treino, não o fracasso.",
]

# ============================================================================ Cartas dos chefes
## Banco embutido (MECANICAS_RECUPERACAO.md). k: palavras-chave; "a|b" = alternativas.
const CARDS_BANK := [   # Sentinela: lacuna com banco de palavras
	{"q": "Para fixar um assunto, feche o livro e tente ____ o que leu.", "a": "lembrar", "opts": ["lembrar", "reler", "destacar"]},
	{"q": "Estudar um pouco por dia vale mais do que tudo na ____.", "a": "véspera", "opts": ["véspera", "biblioteca", "praça"]},
	{"q": "Reler e ____ o texto dão sensação de aprender, mas fixam pouco.", "a": "destacar", "opts": ["destacar", "testar", "explicar"]},
	{"q": "A Névoa não queima. Ela ____.", "a": "apaga", "opts": ["apaga", "cura", "voa"]},
	{"q": "Dormir bem ajuda o cérebro a ____ o que você estudou.", "a": "fixar", "opts": ["fixar", "esquecer", "misturar"]},
	{"q": "A marca do pai na árvore apontava para o ____.", "a": "norte", "opts": ["norte", "sul", "leste"]},
	{"q": "Explicar com suas palavras por que algo é verdade se chama ____.", "a": "elaboração", "opts": ["elaboração", "decoreba", "sorte"]},
	{"q": "Antes de estudar, respirar devagar ajuda a ____ o corpo.", "a": "acalmar", "opts": ["acalmar", "cansar", "apressar"]},
	{"q": "Testar-se é a técnica de estudo com mais ____ entre as comparadas.", "a": "evidência", "opts": ["evidência", "cores", "páginas"]},
	{"q": "Errar uma pergunta mostra o que você precisa ____ de novo.", "a": "revisar", "opts": ["revisar", "esconder", "apagar"]},
]
const CARDS_TYPE := [   # Bibliotecário: completar a lacuna digitando
	{"q": "Distribuir o estudo em vários dias se chama ____.", "a": "espaçamento", "k": ["espacamento|espacar|espacado"]},
	{"q": "Tentar lembrar sem olhar o livro é a recuperação ____.", "a": "ativa", "k": ["ativa"]},
	{"q": "Misturar tipos de problema da mesma matéria se chama ____.", "a": "intercalação", "k": ["intercal"]},
	{"q": "O caderno do pai fala em guardar o saber dentro de ____.", "a": "si", "k": ["si|mim|voce"]},
	{"q": "A Névoa apaga páginas e ____ de quem chega perto.", "a": "lembranças", "k": ["lembranca|memoria|lembrancas"]},
	{"q": "Escrever o que preocupa antes de estudar ajuda a acalmar a ____.", "a": "mente", "k": ["mente|cabeca"]},
	{"q": "Foco em blocos com pausas curtas é a técnica ____.", "a": "pomodoro", "k": ["pomodoro"]},
	{"q": "Explicar algo com as próprias palavras é fazer uma ____.", "a": "elaboração", "k": ["elabora"]},
	{"q": "Escrever no Caderno ajuda a esvaziar a ____ antes de estudar.", "a": "mente", "k": ["mente|cabeca"]},
	{"q": "O Rei Demônio espera no ____ Sem Luz.", "a": "trono", "k": ["trono"]},
]
const CARDS_FREE := [   # Cavaleiro e Rei (perguntas livres)
	{"q": "Por que testar-se funciona melhor do que reler?", "a": "Porque o esforço de lembrar fortalece a memória.", "k": ["lembr|memoria|recuper"]},
	{"q": "O que é espaçamento?", "a": "Estudar o mesmo assunto em dias diferentes.", "k": ["dia|tempo|espac"]},
	{"q": "Intercalar funciona melhor dentro da mesma matéria ou entre matérias diferentes?", "a": "Dentro da mesma matéria.", "k": ["mesma"]},
	{"q": "Por que dormir ajuda no estudo?", "a": "O sono ajuda a fixar (consolidar) a memória.", "k": ["fix|consolid|memoria|guard"]},
	{"q": "O que fazer quando errar uma pergunta de estudo?", "a": "Ver a resposta certa e revisar de novo depois.", "k": ["revis|rever|estud|repet"]},
	{"q": "Qual era o juramento do pai e de Aldric?", "a": "Guardar o saber juntos.", "k": ["guard|proteg", "junt"]},
	{"q": "O que a Névoa faz com as páginas?", "a": "Apaga.", "k": ["apag"]},
	{"q": "O que é elaboração?", "a": "Explicar com suas palavras por que algo é verdade.", "k": ["explic|palavra|porque|por que"]},
	{"q": "Para que serve a caixa de preocupações?", "a": "Tirar as preocupações da cabeça e voltar a estudar.", "k": ["preocupa|cabeca|calm|acalm"]},
	{"q": "O que a bússola de latão sempre aponta?", "a": "O norte.", "k": ["norte"]},
	{"q": "Cite uma técnica para acalmar antes de estudar.", "a": "Respirar devagar, meditar ou escrever o que preocupa.", "k": ["respir|medit|escrev|mindful"]},
	{"q": "Por que reler não basta?", "a": "Porque reconhecer o texto não é o mesmo que lembrar.", "k": ["lembr|reconhec|memoria"]},
	{"q": "O que Lúmen carrega?", "a": "O que é esquecido.", "k": ["esquec"]},
	{"q": "Para que serve o Caderno do herói?", "a": "Escrever livremente e esvaziar a cabeça.", "k": ["escrev|desabaf|cabeca|mente|esvazi"]},
	{"q": "O que o Rei Demônio diz que fez com o saber da cidade?", "a": "Guardou (roubou) o conhecimento.", "k": ["guard|roub|tir"]},
]
