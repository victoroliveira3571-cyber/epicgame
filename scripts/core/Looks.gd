class_name Looks
extends RefCounted

## Aparência LPC de cada personagem (ver DESIGN_NPCS_E_FLORESTA.md). `of(key)` aceita o id de um
## personagem da história, um dono de loja ou o nome antigo da folha do Ninja Adventure (os NPCs
## da cidade continuam sendo criados por esse nome). Ver LpcW.gd para o formato do look.


static func _l(body: String, head: String, skin: String, eyes: String, hair_pal: String, hair: String,
		torso: Array, legs: Array, feet: Array, extra: Dictionary = {}) -> Dictionary:
	var eq := {"torso": torso[0], "pernas": legs[0], "pes": feet[0]}
	var colors := {torso[0]: torso[1], legs[0]: legs[1], feet[0]: feet[1]}
	if hair != "":
		eq["cabelo"] = hair
	for slot in ["barba", "cabeca", "oculos", "mascara"]:
		if extra.has(slot):
			var v: Array = extra[slot]
			eq[slot] = v[0]
			if v.size() > 1:
				colors[v[0]] = v[1]
	var out := {"body": body, "head": head, "skin": skin, "eyes": eyes, "hair_pal": hair_pal,
		"brows": extra.get("brows", "thin" if body == "female" else "thick"), "equip": eq, "colors": colors,
		"extras": extra.get("extras", []), "weapon": extra.get("weapon", ""), "gear": extra.get("gear", {})}
	for k in ["wrinkles", "scale", "expr"]:
		if extra.has(k):
			out[k] = extra[k]
	return out


static var _presets: Dictionary = {}


static func presets() -> Dictionary:
	if not _presets.is_empty():
		return _presets
	var p := {}
	# ---- história
	p["mae"] = _l("female", "human_female", "light", "green", "chestnut", "cab_preso_baixo",
		["npc_torso_clothes_blouse_longsleeve", "rose"], ["npc_legs_skirt_straight", "brown"], ["sapatilha", "leather"],
		{"extras": [["npc_torso_aprons_apron_half", "white"]]})
	p["pai"] = _l("male", "human_male", "light", "gray", "dark_brown", "cab_repartido",
		["camisa_social", "tan"], ["calca_larga", "brown"], ["bota", "leather"],
		{"barba": ["bar_aparada"], "cabeca": ["bonnie", "walnut"], "extras": [["npc_torso_clothes_vest", "forest"], ["npc_belt_leather", "leather"]]})
	p["marta"] = _l("female", "elderly_female", "light", "brown", "gray", "cab_coque",
		["npc_torso_clothes_blouse_longsleeve", "lavender"], ["npc_legs_skirt_belle", "maroon"], ["sapatilha", "brown"],
		{"oculos": ["oc_meia_lua"], "wrinkles": true, "extras": [["npc_torso_aprons_apron_full", "rose"]]})
	p["helena"] = _l("female", "human_female", "amber", "blue", "black", "cab_rabo_alto",
		["camisa_social", "navy"], ["npc_legs_skirt_straight", "navy"], ["sapato_amarrar", "black"],
		{"oculos": ["oc_redondo"], "extras": [["npc_torso_jacket_tabard", "blue"]]})
	p["osvaldo"] = _l("male", "plump", "taupe", "brown", "gray", "cab_careca",
		["moletom", "bluegray"], ["calca", "walnut"], ["bota", "black"],
		{"barba": ["bar_cheia"], "cabeca": ["capuz_saco", "maroon"], "wrinkles": true})
	p["pietro"] = _l("male", "gaunt", "olive", "brown", "dark_brown", "cab_baguncado",
		["manga_longa", "forest"], ["calca", "brown"], ["bota_dobra", "leather"],
		{"barba": ["bar_por_fazer"], "weapon": "bow", "extras": [["npc_cape_solid", "leather"], ["npc_quiver", ""], ["npc_belt_leather", "leather"]]})
	p["ivo"] = _l("male", "human_male", "light", "blue", "white", "cab_espetado",
		["camiseta_v", "sky"], ["calca", "navy"], ["bota", "navy"],
		{"weapon": "dagger", "extras": [["npc_cape_trim", "blue"], ["npc_arms_gloves", "navy"]]})
	p["lin"] = _l("male", "elderly_male", "light", "gray", "white", "cab_coque",
		["manga_longa", "bluegray"], ["calca_larga", "slate"], ["sandalia", "brown"],
		{"barba": ["npc_beards_winter"], "weapon": "staff", "wrinkles": true,
		"extras": [["npc_cape_solid", "forest"], ["npc_belt_robe", "green"]]})
	p["aldric"] = _l("male", "human_male", "bronze", "gray", "dark_gray", "cab_raspado",
		["manga_longa", "black"], ["calca", "black"], ["bota", "black"],
		{"barba": ["bar_por_fazer"], "weapon": "sword", "gear": {"armor": 4, "helmet": 4, "boots": 3},
		"extras": [["npc_cape_tattered", "charcoal"]]})
	p["vizinho"] = _l("male", "human_male", "brown", "brown", "black", "cab_cacheado",
		["camiseta_botao", "green"], ["calca_dobra", "tan"], ["sapato", "brown"])
	# ---- donos de lojas e casas
	p["ferreiro"] = _l("male", "plump", "bronze", "brown", "black", "cab_careca",
		["regata", "charcoal"], ["calca", "brown"], ["bota", "black"],
		{"barba": ["npc_beards_bigstache"], "extras": [["npc_torso_aprons_apron", "leather"], ["npc_arms_gloves", "leather"]]})
	p["armeiro"] = _l("male", "human_male", "olive", "green", "chestnut", "cab_topete",
		["camisa_social", "white"], ["calca_social", "charcoal"], ["bota_dobra", "leather"],
		{"barba": ["bar_guidao"], "extras": [["npc_torso_clothes_vest", "maroon"], ["npc_belt_formal", "black"]]})
	p["costureira"] = _l("female", "human_female", "black", "brown", "dark_brown", "cab_cachos_longos",
		["npc_torso_clothes_corset", "purple"], ["npc_legs_skirt_belle", "lavender"], ["sapatilha", "purple"],
		{"extras": [["npc_neck_scarf", "pink"]], "oculos": ["oc_gatinho"]})
	p["estalajadeiro"] = _l("male", "plump", "amber", "brown", "redhead", "cab_desalinhado",
		["camiseta", "white"], ["calca", "brown"], ["sapato", "brown"],
		{"barba": ["bar_bigodao"], "extras": [["npc_torso_aprons_apron", "white"], ["npc_torso_aprons_suspenders", "maroon"]]})
	p["mestre_cla"] = _l("male", "human_male", "amber", "brown", "black", "cab_rabo",
		["manga_longa", "maroon"], ["bombacha", "black"], ["sandalia", "black"],
		{"barba": ["bar_guidao"], "weapon": "sword", "extras": [["npc_belt_sash", "black"]]})
	p["bibliotecaria"] = _l("female", "elderly_female", "olive", "gray", "white", "cab_chanel",
		["npc_torso_clothes_blouse_longsleeve", "teal"], ["npc_legs_skirt_straight", "navy"], ["sapatilha", "black"],
		{"oculos": ["oc_gatinho"], "wrinkles": true, "extras": [["npc_neck_necklace_simple", ""]]})
	p["guarda"] = _l("male", "human_male", "brown", "brown", "black", "cab_raspado",
		["manga_longa", "maroon"], ["calca", "black"], ["bota", "black"],
		{"weapon": "spear", "gear": {"armor": 2, "helmet": 1, "boots": 0}})
	p["recepcionista"] = _l("male", "elderly_male", "taupe", "brown", "gray", "cab_careca",
		["camisa_social", "white"], ["calca_social", "navy"], ["sapato", "black"],
		{"barba": ["npc_beards_french"], "wrinkles": true, "extras": [["npc_torso_jacket_frock", "navy"]]})
	p["bibliotecario"] = _l("male", "gaunt", "zombie", "gray", "white", "cab_desalinhado",
		["manga_longa", "tan"], ["calca_larga", "charcoal"], ["sandalia", "black"],
		{"weapon": "s_staff", "expr": "closed", "wrinkles": true,
		"extras": [["npc_cape_tattered", "white"], ["npc_belt_robe", "tan"], ["npc_neck_scarf", "white"]]})
	# ---- laboratório (aliados cômicos)
	p["cientista"] = _l("male", "elderly_male", "light", "blue", "white", "cab_afro",
		["camisa_social", "white"], ["calca_social", "slate"], ["sapato", "black"],
		{"barba": ["npc_beards_bigstache", "white"], "oculos": ["oc_redondo"], "wrinkles": true,
		"extras": [["npc_torso_jacket_trench", "white"], ["npc_belt_formal", "black"]]})
	p["pipeta"] = _l("female", "human_female", "amber", "green", "pink", "cab_coque_alto",
		["camiseta", "teal"], ["calca", "navy"], ["bota", "black"],
		{"oculos": ["oc_nerd"], "extras": [["npc_torso_aprons_apron_full", "white"], ["npc_arms_gloves", "green"]]})
	p["tonico"] = _l("male", "plump", "olive", "brown", "ginger", "cab_baguncado",
		["camiseta", "orange"], ["calca_larga", "brown"], ["bota", "brown"],
		{"barba": ["bar_por_fazer"], "oculos": ["oc_escuro"], "extras": [["npc_torso_aprons_overalls", "leather"]]})
	p["rei_demonio"] = _l("muscular", "human_male", "lavender", "red", "black", "cab_raspado",
		["regata", "black"], ["calca", "maroon"], ["bota", "black"],
		{"weapon": "waraxe", "cabeca": ["coroa", "gold"],
		"extras": [["npc_cape_tattered", "maroon"], ["npc_belt_leather", "black"], ["npc_head_horns_demon"],
		["npc_wings_bat", "maroon"], ["npc_tail_lizard"]]})   # chifres, asas e cauda (pacotes LPC de 31/10/2026)
	p["bruna"] = _l("female", "human_female", "amber", "green", "carrot", "cab_rabo_alto",
		["regata", "maroon"], ["calca", "leather"], ["bota", "black"],
		{"weapon": "spear", "gear": {"armor": 1, "boots": 2}, "extras": [["npc_cape_trim", "red"], ["npc_belt_leather", "leather"]]})
	# ---- aventureiros (Guilda, Arena)
	p["aventureira_maga"] = _l("female", "human_female", "taupe", "purple", "platinum", "cab_longo",
		["npc_torso_clothes_robe", "purple"], ["calca", "black"], ["sapatilha", "purple"],
		{"cabeca": ["chapeu_mago", "purple"], "weapon": "staff"})
	p["aventureiro_samurai"] = _l("male", "human_male", "amber", "brown", "black", "cab_coque_alto",
		["manga_longa", "red"], ["bombacha", "charcoal"], ["sandalia", "black"],
		{"weapon": "sword", "gear": {"armor": 3, "boots": 1}, "extras": [["npc_belt_sash", "red"]]})
	p["aventureira_lutadora"] = _l("female", "human_female", "brown", "orange", "redhead", "cab_rabo",
		["regata", "red"], ["legging", "black"], ["bota", "black"],
		{"weapon": "dagger", "gear": {"armor": 1, "boots": 2}})
	p["aventureiro_cacador"] = _l("male", "human_male", "light", "green", "blonde", "cab_bagunca2",
		["manga_longa", "green"], ["calca", "tan"], ["bota_dobra", "brown"],
		{"weapon": "bow", "extras": [["npc_quiver", ""], ["npc_cape_solid", "forest"]]})
	# ---- moradores (nomes antigos das folhas do Ninja Adventure)
	p["Villager"] = _l("male", "human_male", "light", "blue", "light_brown", "cab_repartido",
		["camiseta", "orange"], ["calca", "navy"], ["sapato", "brown"])
	p["Villager2"] = _l("female", "human_female", "amber", "green", "redhead", "cab_tranca",
		["npc_torso_clothes_blouse", "green"], ["npc_legs_skirt_straight", "tan"], ["sapatilha", "brown"])
	p["Villager3"] = p["vizinho"]
	p["Villager5"] = _l("female", "human_female", "bronze", "brown", "black", "cab_afro",
		["camiseta_v", "yellow"], ["calca_dobra", "blue"], ["sapatilha", "white"])
	p["Child"] = _l("female", "human_female", "olive", "brown", "dark_brown", "cab_marias",
		["camiseta", "pink"], ["short", "blue"], ["sapatilha", "red"], {"scale": 0.8})
	p["OldMan"] = _l("male", "elderly_male", "light", "blue", "white", "cab_careca",
		["cardigan", "brown"], ["calca", "gray"], ["pantufa", "maroon"], {"barba": ["bar_bigode"], "wrinkles": true})
	p["OldMan3"] = p["recepcionista"]
	p["OldWoman"] = p["marta"]
	p["Woman"] = _l("female", "human_female", "taupe", "brown", "chestnut", "cab_ondulado",
		["npc_torso_clothes_blouse", "white"], ["npc_legs_skirt_belle", "red"], ["sapatilha", "red"],
		{"extras": [["npc_torso_aprons_apron_half", "white"]]})
	p["Villager4"] = p["armeiro"]
	p["Villager6"] = p["costureira"]
	p["Caveman"] = p["ferreiro"]
	p["Master"] = p["lin"]
	p["Hunter"] = p["pietro"]
	p["NinjaBlue2"] = p["ivo"]
	p["Princess"] = p["helena"]
	p["Noble"] = p["pai"]
	p["Knight"] = p["aldric"]
	p["Samurai"] = p["mestre_cla"]
	p["SorcererOrange"] = p["aventureira_maga"]
	p["FighterRed"] = p["aventureira_lutadora"]
	_presets = p
	return p


static func has(key: String) -> bool:
	return presets().has(key)


static func of(key: String) -> Dictionary:
	return (presets().get(key, presets()["Villager"]) as Dictionary).duplicate(true)


## Personagem que fala na história -> chave do look ("" = não é humano: usa o rosto antigo).
const SPEAKER_LOOK := {
	"mae": "mae", "pai": "pai", "marta": "marta", "helena": "helena", "osvaldo": "osvaldo",
	"pietro": "pietro", "ivo": "ivo", "lin": "lin", "aldric": "aldric", "vizinho": "vizinho",
	"cavaleiro": "aldric", "ferreiro": "ferreiro", "armeiro": "armeiro", "costureira": "costureira",
	"estalajadeiro": "estalajadeiro", "mestre_cla": "mestre_cla", "bibliotecaria": "bibliotecaria",
	"recepcionista": "recepcionista", "rei": "rei_demonio", "cientista": "cientista", "pipeta": "pipeta", "tonico": "tonico", "guarda": "guarda", "arena": "bruna", "bibliotecario": "bibliotecario",
}


## Quem fala e não é humano (ou é chefe): o retrato vem do mesmo desenho do mundo.
const SPEAKER_BOSS := {"espirito": "espirito_cacador", "sentinela": "sentinela", "rei": "rei_demonio",
	"cavaleiro": "cavaleiro_sem_nome", "bibliotecario": "bibliotecario"}


## Fonte única do retrato de quem fala: {look, tint} para personagens LPC ou {face, tint} para os
## demais. `live` = o personagem que está no mapa agora (se houver): o retrato usa o look dele.
static func speaker_visual(who: String, live: LpcActor = null) -> Dictionary:
	var tint := Color.WHITE
	var boss_id: String = SPEAKER_BOSS.get(who, "")
	var b: Dictionary = Data.boss_def(boss_id) if boss_id != "" else {}
	if not b.is_empty():
		var t: Color = b.get("tint", Color.WHITE)
		tint = Color(t.r, t.g, t.b, 1.0)
	if who == "heroi" or who == "espelho":
		return {"look": hero(), "tint": tint}
	if live != null and not live.look.is_empty():
		var lk := live.look.duplicate(true)
		lk.erase("scale")
		return {"look": lk, "tint": tint}
	var key: String = SPEAKER_LOOK.get(who, "")
	if key != "":
		return {"look": of(key), "tint": tint}
	if Data.PETS.has(who):
		var pet: Dictionary = Data.PETS[who]
		var pt: Color = pet.get("tint", Color.WHITE)
		return {"face": Pix.tex(str(pet["face"])), "tint": Color(pt.r, pt.g, pt.b, 1.0)}
	if not b.is_empty():
		var rel := "bosses/%s_Faceset.png" % b["folder"] if b.has("folder") else "chars/%s_face.png" % b.get("char", "")
		return {"face": Pix.tex(rel), "tint": tint}
	return {}


## Visual do herói no mundo: roupas do guarda-roupa + aparência + equipamento + arma da classe.
static func hero() -> Dictionary:
	var lk: Dictionary = GameState.look.duplicate(true)
	if lk.is_empty():
		lk = LpcW.default_look()
		if str(Story.st().get("gender", "m")) == "f":
			lk = LpcW.default_look("female")
	var gear := {}
	for slot in ["armor", "helmet", "boots", "shield"]:
		var id: String = GameState.equipped.get(slot, "")
		if id != "":
			gear[slot] = int(Data.get_item(id).get("tier", 0))
	if lk.get("hide_helmet", false):
		gear.erase("helmet")
	lk["gear"] = gear
	lk["weapon"] = ""
	lk.erase("weapon_pal")
	var wid: String = GameState.equipped.get("weapon", "")
	if GameState.has_chosen_class() and wid != "":
		var v: Array = WEAPON_VISUALS.get(wid, [str(Data.CLASSES[GameState.player_class]["weapon"]), ""])
		lk["weapon"] = v[0]
		if str(v[1]) != "":
			lk["weapon_pal"] = v[1]
	return lk


## Arma comprável -> [visual LPC, cor do metal]. Cada arma da loja tem o seu desenho.
const WEAPON_VISUALS := {
	"espada_madeira": ["arming", "ceramic"], "espada_ferro": ["arming", "iron"], "espada_aco": ["saber", "steel"],
	"montante": ["longsword", "silver"], "machado_runico": ["waraxe", "copper"], "martelo_real": ["mace", "gold"],
	"osso_afiado": ["dagger", "ceramic"], "ninjaku": ["dagger", "iron"], "sai_aco": ["dagger", "steel"],
	"katana": ["katana", ""], "florete": ["rapier", "silver"], "lamina_sombria": ["scimitar", "iron"],
	"graveto_magico": ["gnarled", ""], "varinha": ["loop", ""], "livro_feitico": ["s_staff", ""],
	"tridente_arcano": ["diamond", ""], "cajado_ancestral": ["crystal", ""], "varinha_estelar": ["diamond_gold", ""],
	"arco_curto": ["recurve", ""], "arco_longo": ["great", ""], "arco_composto": ["recurve_dark", ""],
	"arco_cacador": ["recurve_light", ""], "arco_elfico": ["great_light", ""], "arco_estelar": ["great_gold", ""],
	"espada_adamantium": ["longsword", "gold"], "espada_suprema": ["longsword", "gold"], "adaga_adamantium": ["katana", ""], "adaga_suprema": ["rapier", "gold"],
	"cajado_adamantium": ["crystal", ""], "cajado_supremo": ["diamond_gold", ""], "arco_adamantium": ["great_gold", ""], "arco_supremo": ["great_gold", ""],
}
