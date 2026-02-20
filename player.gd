extends CharacterBody2D

@export var speed: float = 220.0

func _physics_process(_delta: float) -> void:
	# --- If dialogue is open: allow closing + freeze movement ---
	var box = get_tree().get_first_node_in_group("dialogue_box")
	if box and box.has_method("is_dialogue_open") and box.is_dialogue_open():
		# Close dialogue on E (reliable even if UI doesn't receive input)
		if Input.is_action_just_pressed("interact") and box.has_method("close_dialogue"):
			box.close_dialogue()

		# Freeze movement
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- Movement input ---
	var dir := Vector2.ZERO
	dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	dir = dir.normalized()

	velocity = dir * speed
	move_and_slide()

	# Animation logic
	if dir == Vector2.ZERO:
		$Sprite.stop()
	else:
		if abs(dir.x) > abs(dir.y):
			if dir.x > 0:
				$Sprite.play("right")
			else:
				$Sprite.play("left")
		else:
			if dir.y > 0:
				$Sprite.play("down")
			else:
				$Sprite.play("up")

	# --- Random encounter tick (only when moving) ---
	var is_moving := dir != Vector2.ZERO
	if is_moving:
		# If Encounter is an Autoload, it exists as /root/Encounter
		var encounter = get_node_or_null("/root/Encounter")
		if encounter and encounter.tick(true):
			Game.pick_random_enemy()
			Game.return_scene_path = "res://World.tscn"
			call_deferred("_start_random_battle")
			return

	# --- Apply movement ---
	velocity = dir * speed
	move_and_slide()

func _start_random_battle() -> void:
	Game.goto_scene("res://Battle.tscn")
