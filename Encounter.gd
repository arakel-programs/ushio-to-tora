extends Node

var steps := 0
var enabled := true

# 1.0 = normal, 0 = no encounters, 2.0 = double encounters
var rate := 1.0

func set_rate(new_rate: float) -> void:
	rate = max(new_rate, 0.0)

func reset_encounter() -> void:
	steps = 0
	# Lower number = more frequent
	var base_min := 90
	var base_max := 160
	var min_steps := int(base_min / max(rate, 0.01))
	var max_steps := int(base_max / max(rate, 0.01))
	next_encounter = randi_range(min_steps, max_steps)

var next_encounter := 120

func _ready() -> void:
	randomize()
	reset_encounter()

func tick(moving: bool) -> bool:
	if not enabled or rate <= 0.0:
		return false
	if not moving:
		return false

	steps += 1
	if steps >= next_encounter:
		reset_encounter()
		return true
	return false
