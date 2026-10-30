extends Node

## Zera o save (começo do zero: nível 1, sem ouro, sem itens, sem classe escolhida).
## Sem --save=..., age no save REAL: uso só quando o Victor pedir.

func run(dev: Node) -> void:
	GameState.debug_reset()
	GameState.gold = 0
	GameState.save_now()
	print("[reset] save zerado em ", GameState.save_path, ": nível ", GameState.level, ", ouro ", GameState.gold, ", classe '", GameState.player_class, "'")
	await dev.wait(0.1)
