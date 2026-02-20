# res://data/game_modes_db.gd
extends Node

var modes = [
	{"id": "cpu", "name": "Jugador VS Celular"},
	{"id": "pvp", "name": "Dos Jugadores\n (Arcade)"},
	{"id": "demo", "name": "Multijugador\nEn linea"},
	{"id": "tournament", "name": "Torneo"}
]

func get_mode_by_id(id: String) -> Dictionary:
	for m in modes:
		if m["id"] == id:
			return m
	return {}
