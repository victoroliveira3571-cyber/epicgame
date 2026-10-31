extends Node

## Motor da história (autoload `Story`). Guarda tudo em GameState.story (vai junto no save):
## nomes, capítulo, passo atual, escolhas, rank, pets, créditos de estudo, passes de pedágio,
## horas de foco e o Caderno. As conversas com os personagens passam por `talk(npc_id)`.
## Textos em StoryData.gd; roteiro em EPICGAME/ROTEIRO_COMPLETO.md.

signal changed

var _busy: bool = false     # uma conversa por vez


# ================================================================== Estado
func st() -> Dictionary:
	return GameState.story


func started() -> bool:
	return bool(st().get("started", false))


func step() -> String:
	return String(st().get("step", ""))


func chapter() -> int:
	return int(st().get("chapter", 1))


func flag(key: String, default: Variant = false) -> Variant:
	return (st().get("flags", {}) as Dictionary).get(key, default)


func set_flag(key: String, value: Variant = true) -> void:
	var f: Dictionary = st().get("flags", {})
	f[key] = value
	st()["flags"] = f
	_save()


func set_step(s: String) -> void:
	st()["step"] = s
	_save()
	Audio.sfx2("ding", -8.0, 0.0)
	HUD.show_toast("Novo objetivo: " + objective_text(), UI.C_ORANGE_L)


func _save() -> void:
	GameState.save_game()
	changed.emit()
	GameState.stats_changed.emit()


## Começa um jogo novo com os nomes escolhidos na criação do personagem.
func start_new_game(hero: String, father: String, mother: String, gender: String) -> void:
	GameState.story = {
		"started": true, "hero": hero, "father": father, "mother": mother, "gender": gender,
		"chapter": 1, "step": "c1_casa", "flags": {}, "rank": 0, "pets": [], "pet": "",
		"credits": 1, "credit_min": 0, "focus_min": 0, "passes": {}, "cards": [], "bank": {},
		"worries": [], "herbs": 0, "pages": 0,
	}
	_save()


# ================================================================== Textos
func hero_name() -> String:
	return String(st().get("hero", "Aventureiro"))


func fmt(text: String) -> String:
	var t := text
	t = t.replace("{heroi}", hero_name())
	t = t.replace("{pai}", String(st().get("father", "meu pai")))
	t = t.replace("{mae}", String(st().get("mother", "Mãe")))
	var fem := String(st().get("gender", "m")) == "f"
	t = t.replace("{o}", "a" if fem else "o").replace("{O}", "A" if fem else "O").replace("{e}", "a" if fem else "e")
	t = t.replace("{ervas}", str(mini(int(st().get("herbs", 0)), 5)))
	t = t.replace("{paginas}", str(mini(int(st().get("pages", 0)), 3)))
	t = t.replace("{horas}", _hours_text())
	if t.contains("{dica_marta}"):
		t = t.replace("{dica_marta}", StoryData.MARTA_TIPS[randi() % StoryData.MARTA_TIPS.size()])
	if t.contains("{dica_lin}"):
		t = t.replace("{dica_lin}", StoryData.LIN_TIPS[randi() % StoryData.LIN_TIPS.size()])
	return t


func _hours_text() -> String:
	var h := focus_hours()
	return str(int(h)) if absf(h - round(h)) < 0.05 else ("%.1f" % h).replace(".", ",")


func objective_text() -> String:
	return fmt(String(StoryData.OBJECTIVES.get(step(), "")))


func chapter_title() -> String:
	var c: Dictionary = StoryData.CHAPTERS.get(chapter(), {})
	return "%s: %s" % [c.get("title", ""), c.get("name", "")] if not c.is_empty() else ""


func start_chapter(n: int) -> void:
	st()["chapter"] = n
	_save()
	var c: Dictionary = StoryData.CHAPTERS.get(n, {})
	Audio.jingle("success2", -4.0)
	HUD.floor_banner(String(c.get("title", "")), String(c.get("name", "")))


# ================================================================== Foco, créditos e pedágios
func focus_minutes() -> int:
	return int(st().get("focus_min", 0))


func focus_hours() -> float:
	return float(focus_minutes()) / 60.0


func credits() -> int:
	return int(st().get("credits", 0))


## Chamado ao concluir (ou finalizar) um foco: soma as horas e dá 1 crédito a cada 60 min.
func add_focus_minutes(minutes: int) -> int:
	if not started() or minutes <= 0:
		return 0
	st()["focus_min"] = focus_minutes() + minutes
	var bank := int(st().get("credit_min", 0)) + minutes
	var gained := bank / Data.MINUTES_PER_CREDIT
	st()["credit_min"] = bank % Data.MINUTES_PER_CREDIT
	if gained > 0:
		st()["credits"] = credits() + gained
		HUD.show_toast("+%d crédito%s de estudo! (total %d)" % [gained, "s" if gained > 1 else "", credits()], UI.C_ENERGY)
		Audio.sfx("star", -4.0)
	Recall.release_waiting()
	_save()
	return gained


## Minutos que faltam para o próximo crédito.
func minutes_to_next_credit() -> int:
	return Data.MINUTES_PER_CREDIT - int(st().get("credit_min", 0))


func has_pass(key: String) -> bool:
	return String((st().get("passes", {}) as Dictionary).get(key, "")) == Time.get_date_string_from_system()


## Paga o pedágio de hoje. Devolve false se faltar crédito.
func buy_pass(key: String, cost: int) -> bool:
	if has_pass(key):
		return true
	if credits() < cost:
		return false
	st()["credits"] = credits() - cost
	var p: Dictionary = st().get("passes", {})
	p[key] = Time.get_date_string_from_system()
	st()["passes"] = p
	Audio.sfx("coin_big", -6.0)
	HUD.show_toast("Pedágio pago: -%d crédito%s. Passe válido até a meia-noite." % [cost, "s" if cost > 1 else ""], UI.C_ENERGY)
	_save()
	return true


# ================================================================== Rank e pets
func rank() -> int:
	return int(st().get("rank", 0))


func rank_name() -> String:
	return "Rank " + Data.RANKS[clampi(rank(), 0, Data.RANKS.size() - 1)]


func set_rank(r: int) -> void:
	st()["rank"] = r
	_save()
	Audio.jingle("levelup", -4.0)
	HUD.show_toast("Você agora é %s!" % rank_name(), UI.C_GOLD)


func pets() -> Array:
	return st().get("pets", [])


func active_pet() -> String:
	return String(st().get("pet", ""))


func give_pet(id: String) -> void:
	var p: Array = pets()
	if not p.has(id):
		p.append(id)
	st()["pets"] = p
	st()["pet"] = id
	GameState.mark_dirty()
	_save()
	Audio.jingle("success", -4.0)
	_refresh_pet()


func set_pet(id: String) -> void:
	if id != "" and not pets().has(id):
		return
	st()["pet"] = id
	GameState.mark_dirty()
	_save()
	_refresh_pet()


func _refresh_pet() -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p != null:
		Pet.attach_to(p)


# ================================================================== Acesso
func boss_ready(boss_id: String) -> bool:
	return focus_hours() + 0.0001 >= float(Data.boss_def(boss_id).get("gate_hours", 0))


func floor_unlocked(floor_n: int) -> bool:
	if Data.STORY_FLOORS.has(floor_n):
		return chapter() >= int(Data.STORY_FLOORS[floor_n]["chapter"])
	return chapter() >= 6 and GameState.best_floor >= floor_n - 1


func zone_unlocked(zone: String) -> bool:
	return rank() >= int(Data.FOREST_ZONES[zone]["rank"])


# ================================================================== Conversas
## Mostra um diálogo (id de StoryData.DIALOGS ou lista de falas) e espera terminar.
func say(id_or_lines: Variant) -> void:
	await HUD.dialogue(id_or_lines)


func is_busy() -> bool:
	return _busy


## Conversa com um personagem da história. Decide a fala pelo passo atual.
func talk(npc: String) -> void:
	if _busy:
		return
	_busy = true
	await _talk(npc)
	_busy = false


func _talk(npc: String) -> void:
	var s := step()
	match npc:
		"mae":
			if s == "c1_casa":
				await say("c1_despedida")
				set_flag("bussola")
				set_step("c1_marta")
			else:
				await say("mae_livre")
		"marta":
			if s == "c1_marta":
				await say("c1_marta")
				GameState.add_xp(20, false)
				set_step("c1_guilda")
			elif s == "c2_marta":
				await say("c2_marta")
				start_chapter(3)
				set_step("c3_lin")
			else:
				await say("marta_dica")
		"helena":
			await _talk_helena(s)
		"osvaldo":
			await _talk_osvaldo()
		"pietro":
			await _talk_pietro(s)
		"lin":
			await _talk_lin(s)
		"ivo":
			await say("ivo_livre")
		_:
			pass


func _talk_helena(s: String) -> void:
	match s:
		"c1_marta", "c1_casa":
			await say([["helena", "Bem-vindo! A Dona Marta, da pousada, sempre manda os novatos para cá. Passe lá primeiro."]])
		"c1_guilda":
			await say("c1_guilda")
			HUD.open_window("classe")
		"c1_volta":
			var n := mini(GameState.count_item("erva_azul"), 5)
			if n > 0:
				GameState.remove_item("erva_azul", n)
			await say("c1_entrega")
			GameState.add_gold(60)
			GameState.add_xp(80, false)
			start_chapter(2)
			set_step("c2_exame")
		"c2_exame":
			await say("c2_exame")
			set_step("c2_pena")
		"c2_entrega":
			await say("c2_entrega")
			set_rank(1)
			GameState.add_gold(80)
			set_step("c2_pietro")
		"c3_volta":
			await say("c3_volta")
			start_chapter(4)
			set_step("c4_torneio")
		"c4_torneio":
			await say("c4_torneio")
			Game.start_duel("ivo_duelo")
		_:
			await say("helena_livre")


## Chamado pela janela de classe depois da escolha.
func on_class_chosen() -> void:
	if step() != "c1_guilda":
		return
	_busy = true
	await say("c1_guilda2")
	_busy = false
	set_step("c1_portao")


func _talk_osvaldo() -> void:
	if not GameState.has_chosen_class():
		await say([["osvaldo", "Sem cartão da Guilda, sem floresta. Registre-se primeiro, jovem."]])
		return
	if has_pass("floresta"):
		await say("osvaldo_passe")
		Game.go_to_forest("town")
		return
	if credits() >= 1:
		if flag("osvaldo_pago"):
			await say([["osvaldo", "Um crédito, por favor. Pagou, passa o dia todo."]])
		else:
			await say("c1_osvaldo_paga")
			set_flag("osvaldo_pago")
		buy_pass("floresta", 1)
		Game.go_to_forest("town")
		return
	await say("c1_osvaldo_sem")
	HUD.show_toast("Faltam %d min de foco para o próximo crédito." % minutes_to_next_credit(), UI.C_ENERGY)


func _talk_pietro(s: String) -> void:
	match s:
		"c2_pietro":
			await say("c2_pietro")
			set_step("c2_brisa")
		"c4_pietro":
			await say("c4_pietro")
			set_step("c4_cavaleiro")
		_:
			await say("pietro_livre")


func _talk_lin(s: String) -> void:
	match s:
		"c2_lin":
			await say("c2_lin")
			if not flag("caderno_escrito"):
				set_step("c2_carta")
			else:
				await say("c2_lin_ok")
				set_step("c2_ruinas")
		"c2_carta":
			await say([["lin", "Abra o Caderno com a tecla N e escreva o que estiver na sua cabeça. Ninguém vai ler."]])
		"c3_lin":
			await say("c3_lin")
			set_step("c3_paginas")
		"c3_paginas":
			if int(st().get("pages", 0)) >= 3:
				await say("c3_lin_volta")
				give_pet("lumen")
				set_step("c3_exame")
			else:
				await say([["lin", "Ainda faltam páginas. Elas brilham no chão do andar 1."]])
		"c4_volta":
			await say("c4_volta")
			start_chapter(5)
			set_step("c5_trono")
		_:
			await say("lin_dica")


# ================================================================== Eventos do mundo
func on_card_created() -> void:
	on_notebook_written()


## O jogador escreveu no Caderno (escrita livre). Conta só para a história, o texto não é guardado.
func on_notebook_written() -> void:
	if flag("caderno_escrito"):
		return
	set_flag("caderno_escrito")
	if step() == "c2_carta":
		set_step("c2_ruinas")
		HUD.show_toast("Cabeça mais leve. Mestre Lin aprovaria.", UI.C_GOOD)


func on_herb() -> void:
	GameState.bump("herbs")
	if step() == "c1_ervas":
		st()["herbs"] = int(st().get("herbs", 0)) + 1
		_save()
		_check_c1_ervas()


func _check_c1_ervas() -> void:
	if step() == "c1_ervas" and int(st().get("herbs", 0)) >= 5 and pets().has("corvin"):
		set_step("c1_marca")


func on_corvin() -> void:
	give_pet("corvin")
	_check_c1_ervas()


func on_page() -> void:
	st()["pages"] = int(st().get("pages", 0)) + 1
	_save()
	HUD.show_toast("Página encontrada (%d/3)" % mini(int(st()["pages"]), 3), UI.C_GOLD)
	if int(st()["pages"]) >= 3:
		HUD.show_toast("Volte e entregue as páginas a Mestre Lin (Guilda).", UI.C_ORANGE_L)


## Chefe da história derrotado: diálogo, recompensa e próximo passo.
func on_boss_defeated(boss_id: String) -> void:
	_busy = true
	await get_tree().create_timer(1.2).timeout
	match boss_id:
		"espirito_cacador":
			await say("c1_espirito_vitoria")
			set_step("c1_volta")
		"sentinela":
			await say("c2_sentinela_vitoria")
			give_pet("airevis")
			set_step("c2_marta")
		"bibliotecario":
			await say("c3_bibliotecario_vitoria")
			set_rank(2)
			set_step("c3_volta")
		"ivo_duelo":
			await say("c4_ivo_vitoria")
			await say("c4_ivo_ajudou" if int(flag("ivo_ajuda", 1)) == 0 else "c4_ivo_nao")
			set_rank(3)
			set_step("c4_pietro")
		"cavaleiro_sem_nome":
			await say("c4_cavaleiro_vitoria")
			set_step("c4_volta")
		"rei_demonio":
			await say("c5_vitoria")
			set_rank(4)
			start_chapter(6)
			set_step("fim")
	_busy = false


## Testes antigos (dev/scenarios): jogo com a história concluída, tudo liberado e créditos sobrando.
func dev_start() -> void:
	start_new_game("Teste", "Pai", "Mãe", "m")
	st()["chapter"] = 6
	st()["step"] = "fim"
	st()["rank"] = 4
	st()["credits"] = 99
	st()["focus_min"] = 600
	_save()
