extends Control

const Player = preload("res://Player.gd")
const Enemy = preload("res://Enemy.gd")

var player: Player
var current_enemy: Enemy
var boss_every_n_levels: int = 5

# --- UI-Elemente (werden per Code erzeugt, kein separates .tscn-Layout nötig) ---
var level_label: Label
var xp_bar: ProgressBar
var health_bar: ProgressBar
var enemy_label: Label
var enemy_health_bar: ProgressBar
var gold_label: Label
var log_label: Label
var attack_button: Button

var _farm_timer: Timer
var _auto_attack_timer: Timer

func _ready() -> void:
	player = Player.new()
	add_child(player)
	player.connect("stats_changed", Callable(self, "_update_ui"))
	player.connect("leveled_up", Callable(self, "_on_level_up"))
	player.connect("died", Callable(self, "_on_player_died"))

	_build_ui()
	_spawn_enemy()

	_auto_attack_timer = Timer.new()
	_auto_attack_timer.wait_time = 1.0
	_auto_attack_timer.autostart = true
	_auto_attack_timer.connect("timeout", Callable(self, "_on_auto_attack"))
	add_child(_auto_attack_timer)

	_farm_timer = Timer.new()
	_farm_timer.wait_time = 5.0
	_farm_timer.autostart = true
	_farm_timer.connect("timeout", Callable(self, "_on_farm_tick"))
	add_child(_farm_timer)

	_update_ui()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)

	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(level_label)

	xp_bar = ProgressBar.new()
	vbox.add_child(xp_bar)

	health_bar = ProgressBar.new()
	vbox.add_child(health_bar)

	gold_label = Label.new()
	vbox.add_child(gold_label)

	enemy_label = Label.new()
	enemy_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(enemy_label)

	enemy_health_bar = ProgressBar.new()
	vbox.add_child(enemy_health_bar)

	attack_button = Button.new()
	attack_button.text = "⚔ Angreifen"
	attack_button.custom_minimum_size = Vector2(0, 80)
	attack_button.connect("pressed", Callable(self, "_on_manual_attack"))
	vbox.add_child(attack_button)

	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(log_label)

func _spawn_enemy() -> void:
	var next_level_marker := player.level
	if next_level_marker % boss_every_n_levels == 0 and next_level_marker > 0:
		current_enemy = Enemy.create_boss(player.level)
		_log("Ein Boss erscheint: %s !" % current_enemy.enemy_name)
	else:
		current_enemy = Enemy.create_normal(player.level)
	current_enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))
	_update_ui()

func _on_auto_attack() -> void:
	_do_attack()

func _on_manual_attack() -> void:
	# Manueller Tap macht etwas mehr Schaden als der Auto-Angriff (Belohnung fürs Mitspielen)
	_do_attack(1.5)

func _do_attack(multiplier: float = 1.0) -> void:
	if current_enemy == null:
		return
	var dmg := int(player.attack_damage * multiplier)
	current_enemy.take_damage(dmg)
	_log("Du verursachst %d Schaden an %s." % [dmg, current_enemy.enemy_name])

	if current_enemy != null and current_enemy.health > 0:
		player.take_damage(current_enemy.attack_damage)
		_log("%s verursacht %d Schaden an dir." % [current_enemy.enemy_name, current_enemy.attack_damage])

	_update_ui()

func _on_enemy_defeated() -> void:
	_log("%s wurde besiegt! +%d XP, +%d Gold" % [current_enemy.enemy_name, current_enemy.xp_reward, current_enemy.gold_reward])
	player.gain_xp(current_enemy.xp_reward)
	player.gain_gold(current_enemy.gold_reward)
	_spawn_enemy()

func _on_farm_tick() -> void:
	# Passives "Farmen" von Gold, auch während gekämpft wird
	var farmed := 2 + player.level
	player.gain_gold(farmed)
	_log("Du hast beim Farmen %d Gold gefunden." % farmed)

func _on_level_up(new_level: int) -> void:
	_log("Level Up! Du bist jetzt Level %d." % new_level)
	_spawn_enemy()  # neuer, ggf. stärkerer Gegner nach Level-Up

func _on_player_died() -> void:
	_log("Du wurdest besiegt... Neustart mit vollem Leben.")
	player.heal_full()

func _update_ui() -> void:
	level_label.text = "Level %d   |   Power-Score: %d" % [player.level, player.power_score]
	xp_bar.max_value = player.xp_to_next_level
	xp_bar.value = player.xp
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	gold_label.text = "Gold: %d" % player.gold

	if current_enemy != null:
		var boss_tag := " [BOSS]" if current_enemy.is_boss else ""
		enemy_label.text = "%s%s" % [current_enemy.enemy_name, boss_tag]
		enemy_health_bar.max_value = current_enemy.max_health
		enemy_health_bar.value = current_enemy.health

func _log(text: String) -> void:
	log_label.text = text

# --- Platzhalter für später: hier hakt die Firebase-Rangliste ein ---
# func submit_score_to_leaderboard() -> void:
#     var score = player.power_score
#     # Firebase-Aufruf kommt in einem späteren Schritt dazu
