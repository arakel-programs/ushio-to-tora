extends CharacterBody2D

@export var speed: float = 220.0

@onready var sprite: AnimatedSprite2D = $Sprite

var last_anim := "down"

func _ready() -> void:
	sprite.play(last_anim)

func _physics_process(_delta: float) -> void:
	# --- If dialogue is open: allow closing + freeze movement ---
	var box = get_tree().get_first_node_in_group("dialogue_box")
	if box and box.has_method("is_dialogue_open") and box.is_dialogue_open():
		if Input.is_action_just_pressed("interact") and box.has_method("close_dialogue"):
			box.close_dialogue()

		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- Movement input ---
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity = dir * speed

		# --- Animation ---
		if abs(dir.x) > abs(dir.y):
			last_anim = "right" if dir.x > 0 else "left"
		else:
			last_anim = "down" if dir.y > 0 else "up"

		if sprite.animation != last_anim or !sprite.is_playing():
			sprite.play(last_anim)

		# --- Random encounter tick (only when moving) ---
		var encounter = get_node_or_null("/root/Encounter")
		if encounter and encounter.tick(true):
			Game.pick_random_enemy()
			Game.return_scene_path = "res://World.tscn"
			call_deferred("_start_random_battle")
			return
	else:
		velocity = Vector2.ZERO

		# idle: show first frame of last direction
		sprite.play(last_anim)
		sprite.frame = 0
		sprite.stop()

	# --- Apply movement ONCE ---
	move_and_slide()

func _start_random_battle() -> void:
	Game.goto_scene("res://Battle.tscn")
