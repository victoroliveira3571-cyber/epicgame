class_name StoryV4
extends RefCounted

## v3.7: textos e dados da história v4 (HISTORIA_V4.md): prólogo e infância, Ato 2 na Academia primária de
## aventureiros (Filus), Formatura, bifurcação Guilda x Exército e o caminho do exército de Rocuetos.
## Mesmo formato de fala do StoryData (["quem", "texto"], narr, think:, mem:, tip:, escolhas).
## Mundo: o continente de Vicerus. Filus = reino do estudo (Academia de Fontelúcida); Masmoreum = país das
## masmorras (a masmorra fica sob Focus Town, cidade de fronteira); Rocuetos = reino militar, capital Pedralta;
## a Costa = Porto Névoa. A casa da família fica na floresta entre Filus e Masmoreum.

# ================================================================== Passos, títulos e objetivos
## Títulos do cartão do capítulo para as fases novas (os capítulos 1 a 6 continuam em StoryData.CHAPTERS).
const PHASES := {
	"prologo": {"title": "Prólogo", "name": "Outra vida"},
	"academia": {"title": "Ato 2", "name": "A Academia de Fontelúcida"},
	"exercito": {"title": "Exército de Rocuetos", "name": "Patente: %s"},
	"fim_b": {"title": "Epílogo", "name": "O Marquês de Vicerus"},
}

const OBJECTIVES := {
	"p_prologo": "Assista às lembranças da sua infância",
	"a_casa": "Converse com {mae} antes de partir para a Academia",
	"a_viagem": "Vá a Focus Town e pegue a carruagem do Tobias (leste da cidade) até a Academia",
	"a_matricula": "Matricule-se: fale com a Reitora Aurora, na frente da Reitoria",
	"a_aula": "Primeira aula: fale com Mestre Lin, no Salão dos Mestres",
	"a_jardim": "{missao_jardim}",
	"a_formatura": "Formatura: estude 2 horas seguidas no Pomodoro ({sequencia}) e fale com a Reitora",
	"a_escolha": "Fale com a Reitora Aurora: Guilda dos Aventureiros ou Exército de Rocuetos?",
	"b_alistar": "Vá a Pedralta (carruagem do Tobias) e apresente-se à Comandante Brígida",
	"b_missao": "{missao_exercito}",
	"b_cruzada_final": "Cruzada final: fale com a Comandante Brígida em Pedralta ({horas}/8 h de foco)",
	"fim_b": "Fim do caminho do Exército. Você é Marquês de Rocuetos.",
}

## Onde cada passo se cumpre (id do local no mapa da cena; ver map_landmarks de Town/City/Forest).
const TARGETS := {
	"a_viagem": "estacao", "a_matricula": "reitoria", "a_aula": "classe", "a_formatura": "reitoria", "a_escolha": "reitoria",
	"b_alistar": "estacao", "b_cruzada_final": "centro_treino",
}

# ================================================================== Prólogo (cutscenes top-down)
const BERCO := [
	["narr", "Uma luz morna. Vozes que você ainda não entende. O cheiro de lenha queimando."],
	["think:heroi", "Onde... eu estou? Essas mãos pequenas... são minhas?"],
	["mae@happy", "Olhe, {pai}. El{e} abriu os olhos."],
	["pai", "Bem-vind{o}, pequen{o}. Bem-vind{o} a Vicerus."],
	["think:heroi", "Vicerus? Eu me lembro de outro mundo. Prédios, telas, uma sala de aula cheia... Eu me lembro de tudo."],
	["think:heroi", "Eu morri? Ou só... recomecei?"],
	["mae", "Está olhando para você como quem entende cada palavra."],
	["pai@happy", "Talvez entenda. Os bebês sabem mais do que a gente pensa."],
	["narr", "A luz fica branca. Você entende, sem que ninguém explique: esta é outra vida."],
]

const PAI_ESTUDA_1 := [
	["narr", "O {pai} passava as noites à mesa, entre livros, pergaminhos e um mapa de estrelas."],
	["think:heroi", "Ele estuda como quem procura alguma coisa."],
]
const PAI_ESTUDA_2 := [
	["pai", "Quer ver? Este é um mapa das estrelas. Cada uma tem um nome, e cada nome conta uma história."],
	["heroi", "Me ensina?"],
	["pai@happy", "Um pouco por dia. A cabeça aprende melhor assim, devagar e sempre."],
]
const PAI_ESTUDA_3 := [
	["narr", "Com o tempo, você copiava as anotações dele, letra por letra, sem que ele pedisse."],
	["pai", "Se um dia eu esquecer alguma coisa, você me lembra?"],
	["heroi", "Eu lembro por nós dois."],
]

## Montagem 2: o herói treina com a arma da classe (a frase muda com a família da arma).
const TREINO := {
	"sword": "Você cresceu batendo uma espada de madeira, talhada pelo {pai}, no toco de árvore do quintal.",
	"dagger": "Você cresceu com duas adagas de madeira e passos que nem os pássaros ouviam.",
	"bow": "Você cresceu com um arco de galho e flechas sem ponta, mirando as pinhas mais altas.",
	"staff": "Você cresceu com um cajado de galho torto e os livros do {pai} abertos no chão.",
	"shield": "Você cresceu atrás de um escudo feito de tampa de barril, aprendendo que defender também é lutar.",
}
const TREINO_FIM := [
	["mae", "Cada dia mais parecid{o} com ele."],
	["think:heroi", "Neste mundo, quem estuda fica forte. Eu já sei como estudar. Só preciso de tempo."],
]

const SAIDA_PAI := [
	["narr", "Uma tarde de chuva. A mochila do {pai} estava pronta ao lado da porta havia três dias."],
	["pai", "Preciso ir. A masmorra de Masmoreum guarda uma resposta que eu procuro há anos."],
	["mae@sad", "Você disse que a última viagem seria a última."],
	["pai", "E esta é. Eu volto antes de as chuvas acabarem. Prometo."],
	["narr", "Ele se ajoelha na sua frente e abre a sua mão."],
	["pai", "Guarde isto para mim. É a minha bússola de latão: ela nunca aponta para o lugar errado."],
	["pai@happy", "Quando eu voltar, você me mostra o caminho de casa."],
	["heroi", "Você promete que volta?"],
	["pai", "Eu prometo que vou tentar com tudo o que eu sei. É a promessa mais honesta que eu tenho."],
]
const SAIDA_PAI_FIM := [
	["narr", "Ele não voltou."],
	["mae@sad", "Vamos guardar a bússola até você crescer. Ela espera com a gente."],
	["narr", "{mae} guarda a bússola numa caixa de madeira, em cima da lareira. Os anos passam."],
]

## A despedida da mãe agora é a saída para a Academia (reaproveita os ramos e as bênçãos de c1_despedida).
const DESPEDIDA_ABERTURA := [
	["narr", "Manhã. A casa de madeira fica no meio das árvores, entre Filus e Masmoreum. {mae} está na varanda, com a agulha parada na costura."],
	["mae", "Você já arrumou a mochila?"],
	["heroi", "Quase. Hoje eu vou para a Academia de Fontelúcida. Quero ser aventureir{o}, mas primeiro preciso estudar."],
	["mae", "Eu sei. Só não sei se eu estou pronta para isso."],
]
const SAIDA_CASA := [
	["narr", "Você segue a trilha de terra até Focus Town, a cidade na fronteira de Masmoreum. A carruagem do Tobias leva os novos alunos até a Academia."],
]

# ================================================================== Ato 2: Academia primária (Filus)
const COCHEIRO_BOLSA := [
	["cocheiro", "Aluno nov{o} da Academia? A bolsa de Fontelúcida paga a sua viagem. Suba!"],
]
const MATRICULA := [
	["reitora", "Bem-vind{o} à Academia primária de aventureiros de Fontelúcida, o coração do reino de Filus."],
	["reitora", "Aqui ninguém pega numa missão antes de abrir um livro. Cada missão do jardim só abre depois de horas de estudo de verdade."],
	["heroi", "Horas de estudo valem mais que força?"],
	["reitora@happy", "Valem mais que força bruta. Força sem estudo quebra no primeiro erro. Estudo sem prática não sai do papel. Aqui você faz os dois."],
	["narr", "Um rapaz de cabelo branco com pontas azuis e uma luva só cruza o pátio rindo."],
	["ivo", "Mais um que acha que livro mata monstro. Eu sou Ivo. Lembre o nome: vai ouvir muito na formatura."],
	["reitora", "Ivo, para a aula. E você: o Mestre Lin espera os novatos no Salão dos Mestres."],
]
const AULA := [
	["lin", "Sente-se. Uma pergunta antes de tudo: por que você quer ser aventureir{o}?"],
	{"choice": ["Para encontrar meu pai.", "Para ficar forte.", "Ainda não sei."], "key": "lin_motivo"},
	["lin", "Toda resposta honesta serve. O que importa é saber que ela muda com o tempo."],
	["lin", "As missões do jardim abrem com estudo: meia hora de foco para a primeira, uma hora para a segunda, uma hora e meia para a terceira."],
	["tip:lin", "Sessões de foco curtas e regulares (como o Pomodoro de 25 minutos) ajudam a começar e a manter o ritmo. Contam as horas de foco concluídas, somadas desde a matrícula."],
	["lin", "Vocês vão em grupo. Aprendam a lutar ao lado de alguém, não só na frente de alguém."],
]

## Missões do jardim: [horas de foco exigidas, monstro, quantidade, título, falas de abertura, falas do fim].
const JARDIM := [
	{"hours": 0.5, "monster": "slime", "count": 5, "title": "Gosmas no canteiro",
		"allies": ["nina", "tome"],
		"start": [
			["lin", "Gosmas invadiram o canteiro de ervas. Nada perigoso, mas sujam tudo. Vá com a Nina e o Tomé."],
			["nina@happy", "Oi! Eu sou a Nina, magia de luz. O Tomé é de espada, mas tem medo de gosma."],
			["tome", "Não é medo. É respeito. Elas grudam."],
		],
		"end": [
			["nina@happy", "Cinco gosmas e nenhuma no meu cabelo. Recorde!"],
			["tome", "Você luta olhando para os lados, como se a gente importasse. Obrigado."],
			["lin", "Bom trabalho. Quem luta junto aprende o dobro."],
		]},
	{"hours": 1.0, "monster": "rato", "count": 8, "title": "Ratos na estufa",
		"allies": ["nina", "tome"], "rival": true,
		"start": [
			["lin", "Ratos na estufa, roendo as mudas de sálvia. O grupo do Ivo também vai. Não é competição."],
			["ivo", "Para você não é. Para mim, é. Quem limpar mais ganha o respeito do jardim."],
			["nina", "Ele sempre faz isso. Ignora."],
		],
		"end": [
			["ivo", "Tá, você foi rápid{o}. Sorte de novato."],
			["nina@anger", "Sorte é ter estudado uma hora antes de vir, Ivo. Você estudou?"],
			["ivo", "...Isso não é da sua conta."],
			["lin", "Rivalidade é um bom combustível, desde que não queime quem está do seu lado."],
		]},
	{"hours": 1.5, "monster": "slime_verde", "count": 1, "title": "O Slime-Rei do jardim",
		"allies": ["nina", "tome", "ivo"], "boss": true,
		"start": [
			["lin", "O Slime-Rei acordou no fundo do jardim. Ele é grande, mas lento. Ivo, você vai com eles."],
			["ivo", "Eu dou conta sozinho."],
			["lin", "Eu sei que você acha isso. É exatamente por isso que você vai com eles."],
		],
		"end": [
			["ivo", "Eu... não pedi ajuda."],
			["heroi", "Eu sei. Ajudei mesmo assim."],
			["ivo", "...Obrigado. Não conta para ninguém."],
			["lin", "Agora vocês estão prontos para a última prova da Academia: a Formatura."],
		]},
]

const FORMATURA_INICIO := [
	["lin", "A Formatura não tem monstro. Tem você e o tempo: duas horas seguidas de foco."],
	["lin", "Pausas curtas entre um Pomodoro e outro não quebram a sequência. Descartar ou parar o foco antes da hora, sim."],
	["tip:lin", "Respiração antes de estudar: inspire em 4 tempos, segure 4, solte em 6, por um minuto. Técnicas de atenção plena têm efeito pequeno a moderado no estresse: o objetivo é começar com a mente calma, não fazer milagre."],
	["lin", "Quando terminar, fale com a Reitora. Ela vai saber."],
]
const FORMATURA_FALTA := [
	["reitora", "Sua melhor sequência até agora foi de {sequencia}. A Formatura pede 2 horas seguidas."],
	["reitora", "Se cansar, a Dona Marta, da pousada de Focus Town, conhece bons truques para recomeçar."],
]
const MARTA_FORMATURA := [
	["marta", "Formatura da Academia? Eu lembro do seu pai suando na dele."],
	["tip:marta", "Recuperação ativa ajuda a manter o foco: a cada Pomodoro, feche o material e tente lembrar os pontos principais antes de seguir. Lembrar dá trabalho, e é esse trabalho que fixa."],
	["marta@happy", "E coma alguma coisa antes. Ninguém estuda duas horas de barriga vazia."],
]
const FORMATURA_OK := [
	["reitora@happy", "Duas horas seguidas. Está no registro, com a sua letra no recall. Parabéns: você está formad{o}."],
	["narr", "Nina pula de alegria. Tomé aplaude. Ivo cruza os braços, mas está sorrindo de canto."],
	["lin", "Agora vem a pergunta que ninguém responde por você."],
]
const ESCOLHA := [
	["reitora", "Quem se forma em Fontelúcida escolhe um caminho. Os dois servem Vicerus. Nenhum é menor."],
	["reitora", "A Guilda dos Aventureiros: cavernas, masmorras, riqueza e a liberdade de seguir as pistas que quiser. As pistas do seu pai passam pela masmorra de Masmoreum."],
	["reitora", "O Exército do rei, em Rocuetos: centro de treinamento em Pedralta, armaduras do reino, incursões e cruzadas. Quem sobe nas patentes pode chegar à nobreza."],
	{"choice": ["Guilda dos Aventureiros (história principal)", "Exército de Rocuetos"], "key": "caminho"},
]
const ESCOLHA_GUILDA := [
	["reitora", "A Guilda. Seu pai também escolheu a estrada. Vá a Focus Town: a Dona Marta e a Helena estão esperando os formados."],
	["ivo", "Guilda também? Ótimo. Lá eu te passo de verdade."],
	["lin", "Eu passo pela Guilda de vez em quando. Estude todo dia, {heroi}."],
]
const ESCOLHA_EXERCITO := [
	["reitora", "O Exército. Disciplina, armadura e um reino inteiro nas costas. Pedralta é a capital militar de Rocuetos."],
	["tome", "Eu também vou para o Exército! Pelo menos lá ninguém joga gosma."],
	["lin", "No campo de batalha, lembre da respiração. E estude todo dia, {heroi}."],
	["narr", "A carruagem do Tobias leva recrutas de graça até Pedralta."],
]

## Colegas e aliados das batalhas em grupo (visual LPC pelo LpcW).
const COLEGAS := {
	"nina": {"name": "Nina", "body": "female", "hair": "cab_longo", "hair_pal": "blonde", "torso": "blusa_ombro", "torso_color": "white",
		"weapon": "staff", "kind": "ranged", "dmg": 0.6},
	"tome": {"name": "Tomé", "body": "male", "hair": "cab_liso", "hair_pal": "redhead", "torso": "camiseta", "torso_color": "green",
		"weapon": "sword", "kind": "melee", "dmg": 0.7},
	"ivo": {"name": "Ivo", "look": "ivo", "weapon": "", "kind": "ranged", "dmg": 0.9},
	"soldado": {"name": "Soldado", "body": "male", "hair": "cab_liso", "hair_pal": "dark_brown", "torso": "camiseta", "torso_color": "red",
		"weapon": "spear", "kind": "melee", "dmg": 0.8, "gear": {"armor": 1, "helmet": 1, "boots": 1}},
}

# ================================================================== Caminho do Exército (Rocuetos)
const PATENTES := ["Recruta", "Soldado", "Cabo", "Sargento", "Tenente", "Capitão", "Barão", "Visconde", "Conde", "Marquês"]
## Missão para subir da patente i para i+1: horas de foco, tipo (patrulha = monstros numa zona da floresta;
## cruzada = duelo contra um chefe), alvo e falas. Cada cruzada traz uma pista pequena do pai.
const MISSOES_EXERCITO := [
	{"hours": 0.5, "kind": "patrulha", "zone": "borda", "count": 8, "title": "Patrulha na Borda da Floresta",
		"brief": [["brigida", "Recruta, sua primeira patrulha: oito monstros na Borda da Floresta. A estrada para Filus precisa ficar limpa."]]},
	{"hours": 1.5, "kind": "patrulha", "zone": "clareira", "count": 10, "title": "Escolta da Clareira",
		"brief": [["brigida", "Os caçadores da Clareira das Casas pediram escolta. Dez monstros a menos e eles voltam a caçar em paz."]]},
	{"hours": 2.5, "kind": "patrulha", "zone": "mata", "count": 12, "title": "Incursão na Mata Profunda",
		"brief": [["brigida", "Incursão na Mata Profunda: doze monstros. A sua insígnia abre a cerca da Guilda."]]},
	{"hours": 3.5, "kind": "patrulha", "zone": "pantano", "count": 12, "title": "Incursão no Pântano da Névoa",
		"brief": [["brigida", "O Pântano da Névoa engole patrulhas. Doze monstros e volte inteir{o}."]]},
	{"hours": 4.5, "kind": "patrulha", "zone": "ruinas", "count": 10, "title": "Reconhecimento das Ruínas",
		"brief": [["brigida", "Reconhecimento nas Ruínas sob as Raízes. Dez guardiões de pedra e um relatório na minha mesa."]]},
	{"hours": 5.5, "kind": "cruzada", "boss": "ogro_ancestral", "title": "Cruzada contra o Ogro Ancestral",
		"brief": [["brigida", "Capitão, sua primeira cruzada: o Ogro Ancestral desceu das montanhas. O rei quer a cabeça dele, e um nome novo para quem trouxer."]],
		"clue": [["soldado", "Um velho veterano me contou: anos atrás, um estudioso de bússola de latão pediu abrigo no nosso acampamento. Seguia para Masmoreum."]]},
	{"hours": 6.5, "kind": "cruzada", "boss": "zumbi_colossal", "title": "Cruzada contra o Zumbi Colossal",
		"brief": [["brigida", "Barão, há um colosso de carne morta nas Catacumbas Geladas. Leve os seus homens e a sua coragem."]],
		"clue": [["narr", "No acampamento das Catacumbas, uma tábua riscada à faca: um mapa de estrelas, igual ao que o {pai} desenhava."]]},
	{"hours": 7.5, "kind": "cruzada", "boss": "demonio_abissal", "title": "Cruzada contra o Demônio Abissal",
		"brief": [["brigida", "Visconde, o Demônio Abissal abriu uma fenda na fronteira. Feche a fenda; o reino lembra de quem fecha fendas."]],
		"clue": [["narr", "Entre os destroços, uma página queimada com a letra do {pai}: 'a Névoa não queima, ela apaga'. Só isso. O resto virou cinza."]]},
	{"hours": 8.0, "kind": "cruzada", "boss": "orc_senhor", "title": "Cruzada contra o Senhor da Guerra Orc",
		"brief": [["brigida", "Conde, o Senhor da Guerra Orc reuniu as tribos. Esta é a cruzada que faz um Marquês."]],
		"clue": [["narr", "O Senhor da Guerra carregava um amuleto roubado de um viajante: dentro, um desenho a lápis de uma criança dormindo com um livro no peito."]]},
]

const ALISTAMENTO := [
	["brigida", "Formad{o} de Fontelúcida? Ótimo. Aqui é Pedralta, capital militar de Rocuetos. Eu sou a Comandante Brígida."],
	["brigida", "No Exército você sobe por patentes: Recruta, Soldado, Cabo, Sargento, Tenente, Capitão. Depois, a nobreza: Barão, Visconde, Conde e Marquês."],
	["brigida", "Cada patente pede estudo e uma missão cumprida. Soldado que não estuda vira estatística."],
	["tip:brigida", "As missões do Exército pedem horas de foco acumuladas e uma patrulha ou cruzada. A insígnia do Exército vale como passe nas trilhas da floresta."],
	["brigida", "O Exército também tem ofícios: o Laboratório de Cristais e a Grande Forja, aqui mesmo em Pedralta."],
]
const PROMOVIDO := "Promovid{o} a %s!"
const CRUZADA_FINAL := [
	["brigida", "Marquês. Rocuetos lhe deve terras, e o rei cumpre o que deve: a sua terra fica ao sul, com vista para Filus."],
	["brigida", "Mas antes da festa, a última ordem. O exército marcha até Masmoreum. O Rei Demônio vai cair pelas mãos de Rocuetos."],
	["narr", "Tambores. Estandartes vermelhos. Mil botas na estrada de pedra. Tomé acena da segunda fileira."],
	["heroi", "Pai, se você passou por aqui... eu estou indo pelo mesmo caminho. Com um exército inteiro."],
]
const CRUZADA_FINAL_FALTA := [
	["brigida", "A cruzada final pede 8 horas de foco acumuladas, Marquês. Um general cansado perde exércitos."],
]
const VITORIA_B := [
	["narr", "O Rei Demônio cai diante dos estandartes de Rocuetos. A névoa se desfaz sobre Masmoreum."],
	["narr", "Você procura no trono, nas estantes vazias, em cada sala. O {pai} não está lá."],
	["heroi", "Eu não descobri o que aconteceu com você. Mas eu vim até o fim."],
	["narr", "Meses depois. Uma casa grande ao sul de Rocuetos, com vista para os campos de Filus. {mae} rega um jardim enorme."],
	["mae@happy", "Uma casa com janela para o sol. Seu pai ia rir de mim, toda chique."],
	["heroi", "Você merece cada janela, mãe."],
	["mae", "E você merece descansar. Mas eu te conheço: amanhã está estudando de novo."],
	["narr", "Fim do caminho do Exército. Você é Marquês de Rocuetos. A bússola de latão continua apontando para Masmoreum."],
]

const SPEAKERS := {
	"nina": {"name": "Nina"},
	"tome": {"name": "Tomé"},
	"brigida": {"name": "Comandante Brígida"},
	"soldado": {"name": "Veterano de Rocuetos"},
}


# ================================================================== Funções
static func objective(step: String) -> String:
	return str(OBJECTIVES.get(step, ""))


static func target(step: String) -> String:
	return str(TARGETS.get(step, ""))


static func has_step(step: String) -> bool:
	return OBJECTIVES.has(step)


static func patente_name(i: int) -> String:
	return PATENTES[clampi(i, 0, PATENTES.size() - 1)]
