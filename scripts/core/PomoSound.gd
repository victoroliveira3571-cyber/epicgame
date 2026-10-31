class_name PomoSound
extends RefCounted

## Músicas e sons de ambiente do Pomodoro (catálogo + escolhas salvas em GameState.pomo_cfg).
## Músicas: cada pasta em assets/audio/pomodoro/musica/<gênero>/ vira uma playlist (mp3/ogg/wav).
## Ambiente: assets/audio/pomodoro/ambiente/<id>.(mp3|ogg|wav); o .mp3 enviado pelo Victor
## tem preferência sobre o .wav provisório gerado por tools/gen_pomodoro_sfx.py.

const MUSIC_DIR := "res://assets/audio/pomodoro/musica/"
const AMB_DIR := "res://assets/audio/pomodoro/ambiente/"
const EXTS := ["mp3", "ogg", "wav"]

## [id, nome]. "jogo" = não troca a música do jogo durante o foco.
const GENRES := [["lofi", "Lo-fi"], ["classica", "Piano"], ["motivacao", "Motivação"], ["medieval", "Medieval"], ["jogo", "Do jogo"]]
## Faixas que já existem no jogo e entram na playlist do gênero (além da pasta).
const GENRE_EXTRA := {
	"medieval": ["res://assets/ninja/audio/music/medieval_1.mp3", "res://assets/ninja/audio/music/medieval_2.mp3",
		"res://assets/ninja/audio/music/medieval_3.mp3", "res://assets/ninja/audio/music/medieval_ambient.mp3"],
}
## Gênero padrão de cada cenário (o Victor pode trocar na janela).
const SCENE_GENRE := {"cafeteria": "lofi", "estudo": "motivacao", "livraria": "classica", "natureza": "classica",
	"casa": "lofi", "taverna": "medieval", "cela": "motivacao"}

## Sons de ambiente: nome, volume padrão (0..1) e arquivo alternativo já existente no jogo.
const AMBIENTS := {
	"lareira": {"name": "Lareira", "vol": 0.7},
	"fogueira": {"name": "Fogueira", "vol": 0.6},
	"conversa": {"name": "Conversa", "vol": 0.45},
	"copos": {"name": "Copos e talheres", "vol": 0.45},
	"chuva": {"name": "Chuva", "vol": 0.6},
	"vento": {"name": "Vento", "vol": 0.4},
	"passaros": {"name": "Pássaros", "vol": 0.5},
	"agua": {"name": "Água", "vol": 0.5},
	"campo": {"name": "Campo", "vol": 0.6, "file": "res://assets/ninja/audio/music/ambience_nature.mp3"},
	"escrita": {"name": "Pena escrevendo", "vol": 0.45},
	"paginas": {"name": "Folhas virando", "vol": 0.5},
	"acoes": {"name": "Ações do herói", "vol": 0.7},   # gole, xícara na mesa, página (eventos da cena)
}
## Camadas de cada cenário: [id, ligado por padrão]. "noite" = liga só das 18h às 6h.
const SCENE_AMBIENTS := {
	"cafeteria": [["lareira", true], ["conversa", true], ["copos", true], ["chuva", false], ["acoes", true]],
	"livraria": [["paginas", true], ["chuva", false], ["vento", false], ["escrita", false], ["acoes", true]],
	"estudo": [["escrita", true], ["chuva", "noite"], ["vento", false], ["lareira", false], ["acoes", true]],
	"natureza": [["campo", true], ["passaros", true], ["agua", true], ["vento", false], ["fogueira", false], ["acoes", true]],
	"casa": [["chuva", "noite"], ["vento", false], ["lareira", false], ["escrita", false], ["acoes", true]],
	"taverna": [["conversa", true], ["copos", true], ["lareira", true], ["chuva", false], ["acoes", true]],
	"cela": [["escrita", true], ["vento", true], ["chuva", "noite"], ["acoes", true]],
}
## Eventos curtos da cena (dentro de AMB_DIR, prefixo fx_).
const EVENTS := ["xicara", "gole", "pagina", "livro"]

static var _track_cache: Dictionary = {}


# ------------------------------------------------------------------ músicas
static func genre_name(id: String) -> String:
	for g in GENRES:
		if g[0] == id:
			return g[1]
	return id


## Caminhos das faixas do gênero (pasta + extras), em ordem alfabética.
static func tracks(genre: String) -> Array:
	if _track_cache.has(genre):
		return _track_cache[genre]
	var out: Array = []
	var dir := MUSIC_DIR + genre + "/"
	if DirAccess.dir_exists_absolute(dir):
		for f in DirAccess.get_files_at(dir):
			# no jogo exportado só existem os .import; o recurso continua com o nome original
			var name := f.trim_suffix(".import").trim_suffix(".remap")
			if name.get_extension().to_lower() in EXTS and not out.has(dir + name) and ResourceLoader.exists(dir + name):
				out.append(dir + name)
	out.sort()
	for p in GENRE_EXTRA.get(genre, []):
		if ResourceLoader.exists(p):
			out.append(p)
	_track_cache[genre] = out
	return out


## "kiravale-medieval-music-593694.mp3" -> "Kiravale Medieval Music".
static func track_title(path: String) -> String:
	var n := path.get_file().get_basename()
	var parts := n.replace("_", "-").split("-", false)
	while parts.size() > 1 and parts[parts.size() - 1].is_valid_int():
		parts.remove_at(parts.size() - 1)
	var words: Array = []
	for p in parts:
		words.append(p.capitalize() if p.length() > 2 else p)
	return " ".join(words)


static func _cfg(key: String) -> Dictionary:
	if typeof(GameState.pomo_cfg.get(key)) != TYPE_DICTIONARY:
		GameState.pomo_cfg[key] = {}
	return GameState.pomo_cfg[key]


static func scene_genre(scene: String) -> String:
	return str(_cfg("music").get(scene, SCENE_GENRE.get(scene, "lofi")))


static func set_scene_genre(scene: String, genre: String) -> void:
	_cfg("music")[scene] = genre
	GameState.save_game()


# ------------------------------------------------------------------ ambiente
static func ambient_path(id: String) -> String:
	for ext in EXTS:
		var p: String = AMB_DIR + id + "." + ext
		if ResourceLoader.exists(p):
			return p
	var alt: String = AMBIENTS.get(id, {}).get("file", "")
	return alt if alt != "" and ResourceLoader.exists(alt) else ""


static func event_path(name: String) -> String:
	return ambient_path("fx_" + name)


static func is_night() -> bool:
	var h := int(Time.get_time_dict_from_system()["hour"])
	return h >= 18 or h < 6


## Camadas do cenário que têm arquivo: [{id, name, on, v}].
static func scene_layers(scene: String) -> Array:
	var out: Array = []
	var saved: Dictionary = _cfg("amb").get(scene, {})
	for pair in SCENE_AMBIENTS.get(scene, []):
		var id: String = pair[0]
		if id != "acoes" and ambient_path(id) == "":
			continue
		var def_on: bool = is_night() if str(pair[1]) == "noite" else bool(pair[1])
		var st: Dictionary = saved.get(id, {})
		out.append({"id": id, "name": AMBIENTS[id]["name"], "on": bool(st.get("on", def_on)),
			"v": float(st.get("v", AMBIENTS[id]["vol"]))})
	return out


static func layer(scene: String, id: String) -> Dictionary:
	for l in scene_layers(scene):
		if l["id"] == id:
			return l
	return {}


static func set_layer(scene: String, id: String, on: bool, v: float) -> void:
	var amb := _cfg("amb")
	if typeof(amb.get(scene)) != TYPE_DICTIONARY:
		amb[scene] = {}
	amb[scene][id] = {"on": on, "v": clampf(v, 0.0, 1.0)}
	GameState.save_game()
