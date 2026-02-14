extends Node

var return_scene_path := "res://World.tscn"

# Persistent player stats
var level := 1
var xp := 0
var xp_to_next := 10

var max_hp := 30
var hp := 30

var potions := 2
var fire_seal_uses := 3

func goto_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(round(xp_to_next * 1.5))

		# Level-up rewards
		max_hp += 5
		hp = max_hp
		fire_seal_uses += 1

# Enemy data passed into battle
var enemy_name := "Yokai"
var enemy_hp := 20
var enemy_attack := 4
var enemy_xp := 6

func pick_random_enemy() -> void:
	# Simple pool (later we’ll load from JSON)
	var pool = [
		{"name":"Imp", "hp":15, "atk":3, "xp":4},
		{"name":"Oni", "hp":35, "atk":7, "xp":12},
		{"name":"Shadow", "hp":22, "atk":5, "xp":8}
	]
	var e = pool[randi() % pool.size()]
	enemy_name = e["name"]
	enemy_hp = e["hp"]
	enemy_attack = e["atk"]
	enemy_xp = e["xp"]
