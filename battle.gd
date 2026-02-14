extends Control

# ----------------------------
# Battle state
# ----------------------------
var player_turn := true
var barrier_active := false

# Enemy data (filled from Game on _ready)
var enemy_name := "Yokai"
var enemy_hp := 20
var enemy_attack_dmg := 4
var xp_reward := 6

# Player stats loaded from Game (persistent)
var player_hp := 0
var potions := 0
var fire_seal_uses := 0

# ----------------------------
# UI references
# ----------------------------
@onready var player_label: Label = $PlayerLabel
@onready var enemy_label: Label = $EnemyLabel
@onready var msg: Label = $MessageLabel

@onready var attack_btn: Button = $Buttons/AttackButton
@onready var skill_btn: Button = $Buttons/SkillButton
@onready var item_btn: Button = $Buttons/ItemButton
@onready var run_btn: Button = $Buttons/RunButton

@onready var skill_panel: Panel = $SkillPanel
@onready var fire_btn: Button = $SkillPanel/SkillList/FireSealButton
@onready var barrier_btn: Button = $SkillPanel/SkillList/BarrierButton
@onready var back_btn: Button = $SkillPanel/SkillList/BackButton


func _ready() -> void:
	# Load persistent player stats from Game
	player_hp = clampi(Game.hp, 0, Game.max_hp)
	potions = max(Game.potions, 0)
	fire_seal_uses = max(Game.fire_seal_uses, 0)

	# Load enemy stats from Game (set by enemy.gd before battle)
	enemy_name = Game.enemy_name
	enemy_hp = Game.enemy_hp
	enemy_attack_dmg = Game.enemy_attack
	xp_reward = Game.enemy_xp

	# Connect buttons
	attack_btn.pressed.connect(_on_attack_pressed)
	skill_btn.pressed.connect(_on_skill_pressed)
	item_btn.pressed.connect(_on_item_pressed)
	run_btn.pressed.connect(_on_run_pressed)

	fire_btn.pressed.connect(_on_fire_seal)
	barrier_btn.pressed.connect(_on_barrier_seal)
	back_btn.pressed.connect(_close_skill_menu)

	msg.text = "%s appears!" % enemy_name
	_close_skill_menu()
	_update_ui()


# ----------------------------
# Main menu actions
# ----------------------------
func _on_attack_pressed() -> void:
	if not player_turn:
		return
	_player_action_damage(5, "You attack for 5!")

func _on_skill_pressed() -> void:
	if not player_turn:
		return
	skill_panel.visible = true
	_set_main_buttons(false)

func _on_item_pressed() -> void:
	if not player_turn:
		return

	if potions <= 0:
		msg.text = "No potions left."
		_update_ui()
		return

	potions -= 1
	player_hp = min(player_hp + 10, Game.max_hp)

	# Persist changes immediately
	Game.hp = player_hp
	Game.potions = potions

	msg.text = "You used a Potion! (+10 HP) (%d left)" % potions
	_update_ui()

	# Enemy gets a turn after item use
	player_turn = false
	_set_main_buttons(false)
	skill_panel.visible = false
	await get_tree().create_timer(0.7).timeout
	_enemy_attack()

func _on_run_pressed() -> void:
	if not player_turn:
		return
	msg.text = "You ran away!"
	_set_main_buttons(false)
	skill_panel.visible = false
	await get_tree().create_timer(0.6).timeout

	# Persist current state when leaving
	Game.hp = player_hp
	Game.potions = potions
	Game.fire_seal_uses = fire_seal_uses

	Game.goto_scene(Game.return_scene_path)


# ----------------------------
# Skills
# ----------------------------
func _on_fire_seal() -> void:
	if fire_seal_uses <= 0:
		msg.text = "Fire Seal is exhausted!"
		return

	fire_seal_uses -= 1
	Game.fire_seal_uses = fire_seal_uses  # persist
	_close_skill_menu()

	_player_action_damage(10, "Fire Seal! You deal 10! (%d left)" % fire_seal_uses)

func _on_barrier_seal() -> void:
	barrier_active = true
	_close_skill_menu()

	# No damage, but it still consumes your turn
	_player_action_damage(0, "Barrier Seal! You brace for impact.")

func _close_skill_menu() -> void:
	skill_panel.visible = false
	_set_main_buttons(true)


# ----------------------------
# Turn flow
# ----------------------------
func _player_action_damage(dmg: int, text: String) -> void:
	player_turn = false
	_set_main_buttons(false)
	skill_panel.visible = false

	if dmg > 0:
		enemy_hp -= dmg

	msg.text = text
	_update_ui()

	# Win check
	if enemy_hp <= 0:
		enemy_hp = 0

		# Persist state before leaving
		Game.hp = player_hp
		Game.potions = potions
		Game.fire_seal_uses = fire_seal_uses

		Game.gain_xp(xp_reward)
		msg.text = "You won! +%d XP" % xp_reward
		_update_ui()

		await get_tree().create_timer(0.8).timeout
		Game.goto_scene(Game.return_scene_path)
		return

	# Enemy turn
	await get_tree().create_timer(0.7).timeout
	_enemy_attack()

func _enemy_attack() -> void:
	var dmg := enemy_attack_dmg

	if barrier_active:
		dmg = max(1, int(enemy_attack_dmg / 2)) # e.g., 4 -> 2
		barrier_active = false
		msg.text = "Barrier reduces the damage!"

	player_hp -= dmg
	if player_hp < 0:
		player_hp = 0

	# Persist HP after enemy attack
	Game.hp = player_hp

	_update_ui()

	# Lose check
	if player_hp <= 0:
		msg.text = "You lost..."
		_update_ui()
		await get_tree().create_timer(0.8).timeout
		Game.goto_scene(Game.return_scene_path)
		return

	# Back to player
	player_turn = true
	_set_main_buttons(true)


# ----------------------------
# Helpers
# ----------------------------
func _set_main_buttons(enabled: bool) -> void:
	attack_btn.disabled = not enabled
	skill_btn.disabled = not enabled
	item_btn.disabled = not enabled
	run_btn.disabled = not enabled

func _update_ui() -> void:
	player_label.text = "Lv %d  HP: %d/%d  Potions: %d  Fire: %d  XP: %d/%d" % [
		Game.level,
		player_hp,
		Game.max_hp,
		potions,
		fire_seal_uses,
		Game.xp,
		Game.xp_to_next
	]

	enemy_label.text = "%s HP: %d   ATK: %d   XP: %d" % [
		enemy_name,
		max(enemy_hp, 0),
		enemy_attack_dmg,
		xp_reward
	]
