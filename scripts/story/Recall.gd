class_name Recall
extends RefCounted

## Perguntas de recuperação ativa (MECANICAS_RECUPERACAO.md): corrige respostas por
## palavras-chave, guarda as caixas de revisão (estilo Leitner) e escolhe as cartas dos chefes.
## Cartas do jogador ficam em GameState.story["cards"]; as do banco embutido guardam só a caixa
## em GameState.story["bank"].

## Dias até a carta voltar, por caixa (1..5). A caixa 1 volta na próxima sessão de foco concluída.
const BOX_DAYS := [0, 0, 2, 4, 8, 16]
const MAX_BOX := 5

const _ACCENTS := {"á": "a", "à": "a", "â": "a", "ã": "a", "ä": "a", "é": "e", "ê": "e", "è": "e", "í": "i", "î": "i",
	"ó": "o", "ô": "o", "õ": "o", "ö": "o", "ú": "u", "ü": "u", "ç": "c", "ñ": "n"}


## Minúsculas, sem acentos, sem pontuação e sem espaços repetidos.
static func norm(text: String) -> String:
	var s := text.to_lower()
	var out := ""
	for ch in s:
		var c: String = _ACCENTS.get(ch, ch)
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
		else:
			out += " "
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.strip_edges()


static func lev(a: String, b: String) -> int:
	var n := a.length()
	var m := b.length()
	if n == 0:
		return m
	if m == 0:
		return n
	var prev: Array = []
	for j in m + 1:
		prev.append(j)
	for i in range(1, n + 1):
		var cur: Array = [i]
		for j in range(1, m + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			cur.append(mini(mini(int(prev[j]) + 1, int(cur[j - 1]) + 1), int(prev[j - 1]) + cost))
		prev = cur
	return int(prev[m])


## Palavras-chave da carta: as que o jogador escreveu, ou as palavras longas da resposta.
static func keys_of(card: Dictionary) -> Array:
	var k: Array = card.get("k", [])
	var out: Array = []
	for item in k:
		if String(item).strip_edges() != "":
			out.append(String(item))
	if not out.is_empty():
		return out
	for w in norm(String(card.get("a", ""))).split(" ", false):
		if w.length() >= 4 and not out.has(w):
			out.append(w)
	if out.is_empty():
		out.append(norm(String(card.get("a", ""))))
	return out


static func _key_matches(key: String, answer_n: String, words: PackedStringArray) -> bool:
	for alt_raw in key.split("|", false):
		var alt := norm(alt_raw)
		if alt == "":
			continue
		if (" " + answer_n + " ").contains(" " + alt) or (alt.length() >= 3 and answer_n.contains(alt)):
			return true
		if alt.length() > 4:
			for w in words:
				if lev(w.substr(0, alt.length()), alt) <= 1:
					return true
	return false


## Resultado: {"result": "full" | "partial" | "wrong", "hit": n, "total": n}.
static func grade(answer: String, card: Dictionary) -> Dictionary:
	var a := norm(answer)
	if a == "":
		return {"result": "wrong", "hit": 0, "total": 1}
	if card.has("opts"):
		var ok := a == norm(String(card["a"]))
		return {"result": "full" if ok else "wrong", "hit": 1 if ok else 0, "total": 1}
	var keys := keys_of(card)
	var words := a.split(" ", false)
	var hit := 0
	for k in keys:
		if _key_matches(String(k), a, words):
			hit += 1
	var total := keys.size()
	var result := "wrong"
	if hit >= total:
		result = "full"
	elif hit * 2 >= total and hit > 0:
		result = "partial"
	return {"result": result, "hit": hit, "total": total}


## Dica gradual: nível 1 = primeira letra de cada palavra-chave; nível 2 = primeira palavra da resposta.
static func hint(card: Dictionary, level: int) -> String:
	if level <= 1:
		var parts: Array[String] = []
		for k in keys_of(card):
			var first := String(k).split("|")[0].strip_edges()
			if first != "":
				parts.append(first.substr(0, 1).to_upper() + "...")
		return "Começa com: " + ", ".join(parts)
	var words := String(card.get("a", "")).split(" ", false)
	return "Primeira palavra: " + (words[0] if words.size() > 0 else "")


# ================================================================== Revisão (caixas)
static func _today() -> String:
	return Time.get_date_string_from_system()


static func _date_plus(days: int) -> String:
	var t := Time.get_unix_time_from_system() + days * 86400.0
	return Time.get_date_string_from_unix_time(int(t))


static func _bank_key(fmt: String, index: int) -> String:
	return "%s_%d" % [fmt, index]


## Estado de revisão de uma carta ({box, due, wait}). Cartas do jogador guardam isso nelas mesmas.
static func _state_of(card: Dictionary) -> Dictionary:
	if card.get("src", "") == "bank":
		var bank: Dictionary = GameState.story.get("bank", {})
		return bank.get(card["key"], {"box": 1, "due": "", "wait": false})
	return card


static func is_due(card: Dictionary) -> bool:
	var s := _state_of(card)
	if bool(s.get("wait", false)):
		return false
	var due := String(s.get("due", ""))
	return due == "" or due <= _today()


static func box_of(card: Dictionary) -> int:
	return int(_state_of(card).get("box", 1))


## Acerto sobe uma caixa; erro volta para a caixa 1 (e espera a próxima sessão de foco).
static func record(card: Dictionary, result: String) -> void:
	var s := _state_of(card).duplicate()
	var box := int(s.get("box", 1))
	if result == "full":
		box = mini(box + 1, MAX_BOX)
		s["wait"] = false
	elif result == "partial":
		s["wait"] = false
	else:
		box = 1
		s["wait"] = true
	s["box"] = box
	s["due"] = _date_plus(BOX_DAYS[box]) if box > 1 else _today()
	if card.get("src", "") == "bank":
		var bank: Dictionary = GameState.story.get("bank", {})
		bank[card["key"]] = {"box": s["box"], "due": s["due"], "wait": s["wait"]}
		GameState.story["bank"] = bank
	else:
		for c in GameState.story.get("cards", []):
			if c.get("id", "") == card.get("id", ""):
				c["box"] = s["box"]
				c["due"] = s["due"]
				c["wait"] = s["wait"]
	GameState.save_game()


## Uma sessão de foco concluída libera as cartas que estavam esperando.
static func release_waiting() -> void:
	for c in GameState.story.get("cards", []):
		c["wait"] = false
	var bank: Dictionary = GameState.story.get("bank", {})
	for k in bank:
		bank[k]["wait"] = false


# ================================================================== Escolha das cartas
static func _from_list(list: Array, fmt: String) -> Array:
	var out: Array = []
	for i in list.size():
		var c: Dictionary = list[i].duplicate(true)
		c["src"] = "bank"
		c["key"] = _bank_key(fmt, i)
		c["fmt"] = fmt
		out.append(c)
	return out


static func user_cards() -> Array:
	var out: Array = []
	for c in GameState.story.get("cards", []):
		var d: Dictionary = c
		d["src"] = "user"
		d["fmt"] = "free"
		out.append(d)
	return out


## Cartas da revisão de hoje (do jogador): vencidas primeiro, caixa mais baixa primeiro.
static func due_user_cards() -> Array:
	var out: Array = []
	for c in user_cards():
		if is_due(c):
			out.append(c)
	out.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return box_of(x) < box_of(y))
	return out


## `n` cartas para um chefe. Prioriza as de caixa baixa (o que está sendo esquecido).
static func pick(fmt: String, n: int) -> Array:
	var pool: Array = []
	match fmt:
		"bank":
			pool = _from_list(StoryData.CARDS_BANK, "bank")
		"type":
			pool = _from_list(StoryData.CARDS_TYPE, "type")
		_:
			pool = user_cards()
			if pool.size() < n:
				var extra := _from_list(StoryData.CARDS_FREE, "free")
				extra.shuffle()
				pool.append_array(extra.slice(0, n - pool.size() + 2))
	pool.shuffle()
	pool.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return box_of(x) < box_of(y))
	return pool.slice(0, mini(n, pool.size()))


# ================================================================== Caderno
static func add_card(question: String, answer: String, keywords: String) -> void:
	var cards: Array = GameState.story.get("cards", [])
	var k: Array = []
	for part in keywords.split(",", false):
		var p := part.strip_edges()
		if p != "":
			k.append(p)
	cards.append({
		"id": "c%d_%d" % [Time.get_unix_time_from_system(), randi() % 1000],
		"q": question.strip_edges(), "a": answer.strip_edges(), "k": k, "box": 1, "due": "", "wait": false,
	})
	GameState.story["cards"] = cards
	GameState.save_game()


static func remove_card(card_id: String) -> void:
	var cards: Array = GameState.story.get("cards", [])
	for i in range(cards.size() - 1, -1, -1):
		if cards[i].get("id", "") == card_id:
			cards.remove_at(i)
	GameState.save_game()
