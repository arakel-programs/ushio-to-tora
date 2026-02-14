extends Control

@onready var label: Label = $Panel/Label
var is_open := false

func _ready() -> void:
	add_to_group("dialogue_box")
	visible = false
	set_process_input(true)
	set_process_unhandled_input(true)
	
func show_dialogue(text: String) -> void:
	label.text = text
	visible = true
	is_open = true

func close_dialogue() -> void:
	visible = false
	is_open = false

func is_dialogue_open() -> bool:
	return is_open

func _input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("interact"):
		close_dialogue()
