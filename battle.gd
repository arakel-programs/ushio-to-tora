extends Control

# ----------------------------
# Battle state
# ----------------------------
var player_turn := true
var barrier_active := false

# Enemy data (filled from Game on _ready)
var enemy_name := "Yokai"
var enemy_hp := 20
var enemy_max_hp := 20
var enemy_attack_dmg := 4
var xp_reward := 6

# Player stats loaded from Game (persistent)
var player_hp := 0
var potions := 0
var fire_seal_uses := 0

# Tween
var _hp_tween: Tween

# ----------------------------
# Nodes (match your tree!)
# Battle
#   BG
#   EnemySprite
#   PlayerSprite
#   UI
#     MessageBox/MarginContainer/MessageLabel
#     PlayerHUD/VBox/...
#     EnemyHUD/VBox/...
#     Buttons/...
#     SkillPanel/SkillList/...
# ----------------------------

@onready var msg: Label = get_node_or_null("UI/MessageBox/MarginContainer/MessageLabel")

@onready var player_hud: Control = get_node_or_null("UI/PlayerHUD")
@onready var enemy_hud: Control = get_node_or_null("UI/EnemyHUD")

@onready var player_name_label: Label = get_node_or_null("UI/PlayerHUD/VBox/HBoxContainer/PlayerNameLabel")
@onready var player_level_label: Label = get_node_or_null("UI/PlayerHUD/VBox/HBoxContainer/LevelLabel")
@onready var player_hp_bar: ProgressBar = get_node_or_null("UI/PlayerHUD/VBox/PlayerHPBar")
@onready var player_hp_text: Label = get_node_or_null("UI/PlayerHUD/VBox/HPTextLabel")

@onready var enemy_name_label: Label = get_node_or_null("UI/EnemyHUD/VBox/HBoxContainer/EnemyNameLabel")
@onready var enemy_level_label: Label = get_node_or_null("UI/EnemyHUD/VBox/HBoxContainer/LevelLabel")
@onready var enemy_hp_bar: ProgressBar = get_node_or_null("UI/EnemyHUD/VBox/EnemyHPBar")
@onready var enemy_hp_text: Label = get_node_or_null("UI/EnemyHUD/VBox/HPTextLabel")

@onready var attack_btn: Button = get_node_or_null("UI/Buttons/GridContainer/AttackButton")
@onready var skill_btn: Button = get_node_or_null("UI/Buttons/GridContainer/SkillButton")
@onready var item_btn: Button = get_node_or_null("UI/Buttons/GridContainer/ItemButton")
@onready var run_btn: Button = get_node_or_null("UI/Buttons/GridContainer/RunButton")

@onready var skill_panel: Control = get_node_or_null("UI/SkillPanel")
@onready var fire_btn: Button = get_node_or_null("UI/SkillPanel/SkillList/FireSealButton")
@onready var barrier_btn: Button = get_node_or_null("UI/SkillPanel/SkillList/BarrierButton")
@onready var back_btn: Button = get_node_or_null("UI/SkillPanel/SkillList/BackButton")

@onready var enemy_sprite: Node2D = get_node_or_null("EnemySprite")
@onready var player_sprite: Node2D = get_node_or_null("PlayerSprite")


func _ready() -> void:
	# Load persistent player stats
	player_hp = clampi(Game.hp, 0, Game.max_hp)
	potions = max(Game.potions, 0)
	fire_seal_uses = max(Game.fire_seal_uses, 0)

	# Load enemy stats
	enemy_name = Game.enemy_name
	enemy_hp = Game.enemy_hp
	enemy_max_hp = max(Game.enemy_hp, 1)
	enemy_attack_dmg = Game.enemy_attack
	xp_reward = Game.enemy_xp

	# Connect buttons safely
	if attack_btn: attack_btn.pressed.connect(_on_attack_pressed)
	if skill_btn: skill_btn.pressed.connect(_on_skill_pressed)
	if item_btn: item_btn.pressed.connect(_on_item_pressed)
	if run_btn: run_btn.pressed.connect(_on_run_pressed)

	if fire_btn: fire_btn.pressed.connect(_on_fire_seal)
	if barrier_btn: barrier_btn.pressed.connect(_on_barrier_seal)
	if back_btn: back_btn.pressed.connect(_close_skill_menu)

	_close_skill_menu()

	if msg:
		msg.text = "%s appears!" % enemy_name

	_setup_bars()
	_update_ui(true)


# ----------------------------
# UI setup
# ----------------------------
func _setup_bars() -> void:
	if player_hp_bar:
		player_hp_bar.min_value = 0
		player_hp_bar.max_value = max(Game.max_hp, 1)
		player_hp_bar.value = clampi(player_hp, 0, int(player_hp_bar.max_value))

	if enemy_hp_bar:
		enemy_hp_bar.min_value = 0
		enemy_hp_bar.max_value = max(enemy_max_hp, 1)
		enemy_hp_bar.value = clampi(enemy_hp, 0, int(enemy_hp_bar.max_value))


# ----------------------------
# Main menu actions
# ----------------------------
func _on_attack_pressed() -> void:
	if not player_turn:
		return
	_player_action_damage(5, "YOU ATTACK FOR 5!", enemy_sprite)

func _on_skill_pressed() -> void:
	if not player_turn:
		return
	if skill_panel:
		skill_panel.visible = true
	_set_main_buttons(false)

func _on_item_pressed() -> void:
	if not player_turn:
		return

	if potions <= 0:
		if msg: msg.text = "NO POTIONS LEFT."
		_update_ui()
		return

	potions -= 1
	player_hp = min(player_hp + 10, Game.max_hp)

	Game.hp = player_hp
	Game.potions = potions

	if msg: msg.text = "YOU USED A POTION! +10 HP"
	_update_ui()

	player_turn = false
	_set_main_buttons(false)
	if skill_panel: skill_panel.visible = false
	await get_tree().create_timer(0.7).timeout
	_enemy_attack()

func _on_run_pressed() -> void:
	if not player_turn:
		return

	if msg: msg.text = "YOU RAN AWAY!"
	_set_main_buttons(false)
	if skill_panel: skill_panel.visible = false
	await get_tree().create_timer(0.6).timeout

	Game.hp = player_hp
	Game.potions = potions
	Game.fire_seal_uses = fire_seal_uses
	Game.goto_scene(Game.return_scene_path)


# ----------------------------
# Skills
# ----------------------------
func _on_fire_seal() -> void:
	if fire_seal_uses <= 0:
		if msg: msg.text = "FIRE SEAL IS EXHAUSTED!"
		_update_ui()
		return

	fire_seal_uses -= 1
	Game.fire_seal_uses = fire_seal_uses
	_close_skill_menu()

	_player_action_damage(10, "FIRE SEAL! 10 DMG!", enemy_sprite)

func _on_barrier_seal() -> void:
	barrier_active = true
	_close_skill_menu()
	_player_action_damage(0, "BARRIER SEAL! BRACE!", null)

func _close_skill_menu() -> void:
	if skill_panel:
		skill_panel.visible = false
	_set_main_buttons(true)


# ----------------------------
# Turn flow
# ----------------------------
func _player_action_damage(dmg: int, text: String, hit_target: Node2D) -> void:
	player_turn = false
	_set_main_buttons(false)
	if skill_panel: skill_panel.visible = false

	if dmg > 0 and hit_target:
		_hit_shake(hit_target)
		_hit_flash(hit_target)

	if dmg > 0:
		enemy_hp -= dmg

	if msg: msg.text = text
	_update_ui()

	# Win check
	if enemy_hp <= 0:
		enemy_hp = 0

		Game.hp = player_hp
		Game.potions = potions
		Game.fire_seal_uses = fire_seal_uses

		Game.gain_xp(xp_reward)
		if msg: msg.text = "YOU WON! +%d XP" % xp_reward
		_update_ui(true)

		await get_tree().create_timer(0.8).timeout
		Game.goto_scene(Game.return_scene_path)
		return

	await get_tree().create_timer(0.7).timeout
	_enemy_attack()

func _enemy_attack() -> void:
	var dmg := enemy_attack_dmg

	if barrier_active:
		dmg = max(1, int(enemy_attack_dmg / 2))
		barrier_active = false
		if msg: msg.text = "BARRIER REDUCES DAMAGE!"
		_update_ui()

	# Enemy hit effect on player
	if player_sprite:
		_hit_shake(player_sprite)
		_hit_flash(player_sprite)

	player_hp -= dmg
	player_hp = max(player_hp, 0)
	Game.hp = player_hp

	_update_ui()

	# Lose check
	if player_hp <= 0:
		if msg: msg.text = "YOU LOST..."
		_update_ui(true)
		await get_tree().create_timer(0.8).timeout
		Game.goto_scene(Game.return_scene_path)
		return

	player_turn = true
	_set_main_buttons(true)


# ----------------------------
# Helpers
# ----------------------------
func _set_main_buttons(enabled: bool) -> void:
	if attack_btn: attack_btn.disabled = not enabled
	if skill_btn: skill_btn.disabled = not enabled
	if item_btn: item_btn.disabled = not enabled
	if run_btn: run_btn.disabled = not enabled

func _update_ui(immediate := false) -> void:
	# Names/levels
	if player_name_label: player_name_label.text = "USHIO"
	if player_level_label: player_level_label.text = "Lv %d" % Game.level

	if enemy_name_label: enemy_name_label.text = enemy_name
	if enemy_level_label: enemy_level_label.text = "Lv 1"

	# HP text
	if player_hp_text: player_hp_text.text = "%d/%d" % [player_hp, Game.max_hp]
	if enemy_hp_text: enemy_hp_text.text = "%d/%d" % [max(enemy_hp, 0), enemy_max_hp]

	# Bars
	if player_hp_bar:
		player_hp_bar.max_value = max(Game.max_hp, 1)
	if enemy_hp_bar:
		enemy_hp_bar.max_value = max(enemy_max_hp, 1)

	if immediate:
		if player_hp_bar: player_hp_bar.value = player_hp
		if enemy_hp_bar: enemy_hp_bar.value = max(enemy_hp, 0)
		return

	_tween_hp_bars()

func _tween_hp_bars() -> void:
	if not player_hp_bar and not enemy_hp_bar:
		return

	if _hp_tween and _hp_tween.is_running():
		_hp_tween.kill()

	_hp_tween = create_tween()

	if player_hp_bar:
		_hp_tween.tween_property(player_hp_bar, "value", float(player_hp), 0.25)

	if enemy_hp_bar:
		_hp_tween.tween_property(enemy_hp_bar, "value", float(max(enemy_hp, 0)), 0.25)

func _hit_shake(target: Node2D) -> void:
	var start := target.position
	var t := create_tween()
	t.tween_property(target, "position", start + Vector2(8, 0), 0.05)
	t.tween_property(target, "position", start + Vector2(-8, 0), 0.05)
	t.tween_property(target, "position", start + Vector2(6, 0), 0.05)
	t.tween_property(target, "position", start, 0.05)

func _hit_flash(item: CanvasItem) -> void:
	var t := create_tween()
	t.tween_property(item, "modulate", Color(1, 0.4, 0.4, 1), 0.05)
	t.tween_property(item, "modulate", Color(1, 1, 1, 1), 0.08)
