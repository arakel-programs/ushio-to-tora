extends Area2D

@export var enemy_name: String = "Yokai"
@export var hp: int = 20
@export var attack: int = 4
@export var xp_reward: int = 6

var triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body) -> void:
	if triggered:
		return
	if body.name == "Player":
		triggered = true
		Game.return_scene_path = "res://World.tscn"

		# Pass enemy data into Game (so Battle can read it)
		Game.enemy_name = enemy_name
		Game.enemy_hp = hp
		Game.enemy_attack = attack
		Game.enemy_xp = xp_reward

		call_deferred("_start_battle")

func _start_battle() -> void:
	Game.goto_scene("res://Battle.tscn")
