# res://data/teams_db.gd

extends Node

# =========================================================
# 🔹 LIGA MX Teams
# =========================================================
var liga_mx_teams: Array = [
	{
		"id": "america",
		"name": "América",
		"shield_path": "res://game_assets/images/teams/liga_mx/america/shield.png"
	},
	{
		"id": "atlas",
		"name": "Atlas",
		"shield_path": "res://game_assets/images/teams/liga_mx/atlas/shield.png"
	},
	{
		"id": "atletico_san_luis",
		"name": "Atl. San Luis",
		"shield_path": "res://game_assets/images/teams/liga_mx/atletico_san_luis/shield.png"
	},
	{
		"id": "cruz_azul",
		"name": "Cruz Azul",
		"shield_path": "res://game_assets/images/teams/liga_mx/cruz_azul/shield.png"
	},
	{
		"id": "guadalajara",
		"name": "Guadalajara",
		"shield_path": "res://game_assets/images/teams/liga_mx/guadalajara/shield.png"
	},
	{
		"id": "juarez",
		"name": "FC Juárez",
		"shield_path": "res://game_assets/images/teams/liga_mx/juarez/shield.png"
	},
	{
		"id": "leon",
		"name": "León",
		"shield_path": "res://game_assets/images/teams/liga_mx/leon/shield.png"
	},
	{
		"id": "mazatlan",
		"name": "Mazatlán",
		"shield_path": "res://game_assets/images/teams/liga_mx/mazatlan/shield.png"
	},
	{
		"id": "monterrey",
		"name": "Monterrey",
		"shield_path": "res://game_assets/images/teams/liga_mx/monterrey/shield.png"
	},
	{
		"id": "necaxa",
		"name": "Necaxa",
		"shield_path": "res://game_assets/images/teams/liga_mx/necaxa/shield.png"
	},
	{
		"id": "pachuca",
		"name": "Pachuca",
		"shield_path": "res://game_assets/images/teams/liga_mx/pachuca/shield.png"
	},
	{
		"id": "puebla",
		"name": "Puebla",
		"shield_path": "res://game_assets/images/teams/liga_mx/puebla/shield.png"
	},
	{
		"id": "queretaro",
		"name": "Querétaro",
		"shield_path": "res://game_assets/images/teams/liga_mx/queretaro/shield.png"
	},
	{
		"id": "santos_laguna",
		"name": "Santos Laguna",
		"shield_path": "res://game_assets/images/teams/liga_mx/santos_laguna/shield.png"
	},
	{
		"id": "tijuana",
		"name": "Tijuana",
		"shield_path": "res://game_assets/images/teams/liga_mx/tijuana/shield.png"
	},
	{
		"id": "toluca",
		"name": "Toluca",
		"shield_path": "res://game_assets/images/teams/liga_mx/toluca/shield.png"
	},
	{
		"id": "tigres",
		"name": "Tigres UANL",
		"shield_path": "res://game_assets/images/teams/liga_mx/tigres/shield.png"
	},
	{
		"id": "pumas",
		"name": "Pumas UNAM",
		"shield_path": "res://game_assets/images/teams/liga_mx/pumas/shield.png"
	}
]

# =========================================================
# 🔹 WORLD CUP 2026 Teams
# =========================================================
var world_cup_teams: Array = [
	{
		"id": "argentina",
		"name": "Argentina",
		"shield_path": "res://game_assets/images/teams/world_cup/argentina/shield.png"
	},
	{
		"id": "brazil",
		"name": "Brazil",
		"shield_path": "res://game_assets/images/teams/world_cup/brazil/shield.png"
	},
	{
		"id": "france",
		"name": "France",
		"shield_path": "res://game_assets/images/teams/world_cup/france/shield.png"
	},
	{
		"id": "germany",
		"name": "Germany",
		"shield_path": "res://game_assets/images/teams/world_cup/germany/shield.png"
	},
	{
		"id": "spain",
		"name": "Spain",
		"shield_path": "res://game_assets/images/teams/world_cup/spain/shield.png"
	},
	{
		"id": "portugal",
		"name": "Portugal",
		"shield_path": "res://game_assets/images/teams/world_cup/portugal/shield.png"
	},
	{
		"id": "england",
		"name": "England",
		"shield_path": "res://game_assets/images/teams/world_cup/england/shield.png"
	},
	{
		"id": "netherlands",
		"name": "Netherlands",
		"shield_path": "res://game_assets/images/teams/world_cup/netherlands/shield.png"
	},
	{
		"id": "belgium",
		"name": "Belgium",
		"shield_path": "res://game_assets/images/teams/world_cup/belgium/shield.png"
	},
	{
		"id": "uruguay",
		"name": "Uruguay",
		"shield_path": "res://game_assets/images/teams/world_cup/uruguay/shield.png"
	},
	{
		"id": "morocco",
		"name": "Morocco",
		"shield_path": "res://game_assets/images/teams/world_cup/morocco/shield.png"
	},
	{
		"id": "senegal",
		"name": "Senegal",
		"shield_path": "res://game_assets/images/teams/world_cup/senegal/shield.png"
	},
	{
		"id": "usa",
		"name": "USA",
		"shield_path": "res://game_assets/images/teams/world_cup/usa/shield.png"
	},
	{
		"id": "canada",
		"name": "Canada",
		"shield_path": "res://game_assets/images/teams/world_cup/canada/shield.png"
	},
	{
		"id": "mexico",
		"name": "Mexico",
		"shield_path": "res://game_assets/images/teams/world_cup/mexico/shield.png"
	},
	{
		"id": "switzerland",
		"name": "Switzerland",
		"shield_path": "res://game_assets/images/teams/world_cup/switzerland/shield.png"
	},
	{
		"id": "japan",
		"name": "Japan",
		"shield_path": "res://game_assets/images/teams/world_cup/japan/shield.png"
	},
	{
		"id": "south_korea",
		"name": "South Korea",
		"shield_path": "res://game_assets/images/teams/world_cup/south_korea/shield.png"
	},
	{
		"id": "ecuador",
		"name": "Ecuador",
		"shield_path": "res://game_assets/images/teams/world_cup/ecuador/shield.png"
	},
	{
		"id": "ghana",
		"name": "Ghana",
		"shield_path": "res://game_assets/images/teams/world_cup/ghana/shield.png"
	}
]

# =========================================================
# 🔹 LEAGUES DICTIONARY
# =========================================================
var leagues: Dictionary = {
	"liga_mx": liga_mx_teams,
	"world_cup": world_cup_teams
}

# =========================================================
# 🔹 UTILITY FUNCTIONS
# =========================================================
func get_teams_by_league(league_id: String) -> Array:
	if leagues.has(league_id):
		return leagues[league_id]
	return []

func get_all_teams(team_list: Array) -> Array:
	return team_list

func get_team_by_id(team_list: Array, team_id: String) -> Dictionary:
	for team in team_list:
		if team["id"] == team_id:
			return team
	return {}

func get_random_team_exclude(team_list: Array, exclude_id: String) -> Dictionary:
	var candidates: Array = []
	for team in team_list:
		if team["id"] != exclude_id:
			candidates.append(team)
	if candidates.size() == 0:
		return {}
	var index = randi() % candidates.size()
	return candidates[index]
