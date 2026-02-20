# res://data/courts_db.gd
extends Node

var layouts: Array = [
	{
		"id": "stadium",
		"name": "Liga MX",
		"scene": "res://game_assets/tscns/stadium_board.tscn"
	},
	{
		"id": "beach",
		"name": "Prison Break",
		"scene": "res://game_assets/tscns/beach_board.tscn"
	},
	{
		"id": "school",
		"name": "Candy Maze",
		"scene": "res://game_assets/tscns/school_board.tscn"
	}
]

func get_court_by_id(court_id: String) -> Dictionary:
	for court in layouts:
		if court["id"] == court_id:
			return court
	return {}
