extends Node

var steps := 0
var next_encounter := 120  # how many frames/steps until battle
var enabled := true

func reset_encounter() -> void:
	steps = 0
	next_encounter = randi_range(90, 160)

func tick(moving: bool) -> bool:
	if not enabled:
		return false
	if not moving:
		return false

	steps += 1
	if steps >= next_encounter:
		reset_encounter()
		return true
	return false
