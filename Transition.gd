extends CanvasLayer

@onready var fade: ColorRect = preload("res://Fade.tscn").instantiate()
@onready var anim: AnimationPlayer = fade.get_node("Anim")

var busy := false

func _ready() -> void:
	add_child(fade)
	fade.visible = true
	fade.modulate.a = 0.0

func change_scene(path: String) -> void:
	if busy:
		return
	busy = true
	await _fade_out()
	get_tree().change_scene_to_file(path)
	await _fade_in()
	busy = false

func _fade_out() -> void:
	anim.play("fade_out")
	await anim.animation_finished

func _fade_in() -> void:
	anim.play("fade_in")
	await anim.animation_finished
