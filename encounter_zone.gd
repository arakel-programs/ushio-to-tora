extends Area2D

@export var encounter_rate: float = 1.0
@export var affects_random_encounters := true

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(body) -> void:
	if body.name == "Player" and affects_random_encounters:
		Encounter.set_rate(encounter_rate)
		Encounter.reset_encounter()

func _on_exit(body) -> void:
	if body.name == "Player" and affects_random_encounters:
		Encounter.set_rate(1.0)
		Encounter.reset_encounter()
