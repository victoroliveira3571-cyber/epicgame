class_name StoryProp
extends Interactable

## Objetos interativos da história: ervas, páginas, a Pena Dourada, o Ivo preso, a árvore
## marcada, a toca da loba e o "Falar com" dos personagens. Cada um chama uma função ao [E].

var text: String = ""
var on_use: Callable
var once: bool = true
var sprite: Sprite2D
var bob: bool = false
var _t: float = randf() * 6.0


static func make(label_text: String, callback: Callable, tex: Texture2D = null, radius: float = 18.0, single_use: bool = true) -> StoryProp:
	var p := StoryProp.new()
	p.text = label_text
	p.on_use = callback
	p.interact_range = radius
	p.once = single_use
	if tex != null:
		p.sprite = Sprite2D.new()
		p.sprite.texture = tex
		p.sprite.position = Vector2(0, -tex.get_height() / 2.0 - 1.0)
	return p


func _ready() -> void:
	super()
	if sprite != null:
		add_child(sprite)
		Fx.make_shadow(self, 8.0, 0.0)


func _process(delta: float) -> void:
	if bob and sprite != null:
		_t += delta
		sprite.position.y = -sprite.texture.get_height() / 2.0 - 3.0 + sin(_t * 3.0) * 1.5


func get_prompt() -> String:
	if not enabled or Story.is_busy() or HUD.is_dialogue_open():
		return ""
	return "[E] " + text


func interact(_player: Node) -> void:
	if not enabled or Story.is_busy() or HUD.is_dialogue_open():
		return
	if once:
		enabled = false
	if on_use.is_valid():
		on_use.call(self)


## Some com um brilho (itens recolhidos).
func vanish() -> void:
	enabled = false
	Fx.burst(get_parent(), global_position + Vector2(0, -6), Color(1, 0.95, 0.6), 8, 36.0, 0.4)
	queue_free()


# ================================================================== Fábricas
static func make_herb() -> StoryProp:
	var p := make("Colher erva", func(me: StoryProp) -> void:
		GameState.add_item("erva_azul", 1)
		Audio.sfx("grass", -2.0)
		Story.on_herb()
		me.vanish(), Pix.tex("items/resource/Grass.png"), 16.0)
	p.sprite.modulate = Color(0.75, 0.9, 1.3)
	Fx.make_light(p, Vector2(0, -6), Color(0.5, 0.8, 1.0), 0.3, 0.5)
	return p


static func make_page() -> StoryProp:
	var p := make("Pegar a página brilhante", func(me: StoryProp) -> void:
		Audio.sfx("powerup", -4.0)
		Story.on_page()
		me.vanish(), Pix.tex("items/scroll/ScrollEmpty.png"), 18.0)
	p.bob = true
	Fx.make_light(p, Vector2(0, -8), Color(1.0, 0.9, 0.5), 0.5, 0.8)
	return p


static func make_ivo_trap() -> StoryProp:
	var p := make("Alguém está preso sob a estante!", func(me: StoryProp) -> void:
		Story.set_flag("ivo_evento")
		await Story.say("c3_ivo")
		if int(Story.flag("ivo_ajuda", 1)) == 0:
			Audio.sfx("thud", -2.0)
			await Story.say("c3_ivo_ajuda")
			GameState.add_xp(40, false)
		else:
			await Story.say("c3_ivo_segue")
		me.vanish(), null, 22.0)
	var ivo := LpcActor.make(p, Looks.of("ivo"))
	ivo.hold_last = true
	ivo.play("hurt_down", true)
	var shelf := Sprite2D.new()
	shelf.texture = Interior.prop_tex("i_bookshelf_s")
	shelf.rotation = 0.35
	shelf.position = Vector2(6, -14)
	p.add_child(shelf)
	return p


## "Falar com" preso a um personagem (o NPC continua andando/virando para o jogador).
static func talker(npc_node: Node2D, npc_id: String, title: String) -> StoryProp:
	var p := make("Falar com " + title, func(_me: StoryProp) -> void: Story.talk(npc_id), null, 22.0, false)
	npc_node.add_child(p)
	npc_node.set_meta("has_talker", true)
	npc_node.add_to_group("speaker_" + npc_id)
	# no mapa, o personagem tem o mesmo visual do retrato do diálogo
	if npc_node is NPC and Looks.SPEAKER_LOOK.has(npc_id):
		(npc_node as NPC).use_look(Looks.SPEAKER_LOOK[npc_id])
	return p
