extends Area2D

@export var dialogue_text: String = "Hello, traveler."
var player_inside := false

func _ready() -> void:
	print("[NPC] ready")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body) -> void:
	if body is CharacterBody2D:
		player_inside = true
		print("[NPC] player entered")

func _on_body_exited(body) -> void:
	if body is CharacterBody2D:
		player_inside = false
		print("[NPC] player exited")

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		var box = get_tree().get_first_node_in_group("dialogue_box")
		if box and box.is_dialogue_open():
			return

		if box:
			box.show_dialogue(dialogue_text)
