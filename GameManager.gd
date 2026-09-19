extends Control

const Player = preload("res://Player.gd")
const Enemy = preload("res://Enemy.gd")

var player: Player
var current_enemy: Enemy
var boss_every_n_levels: int = 5

# --- Farben ---
const COLOR_BG := Color(0.09, 0.09, 0.14)
const COLOR_PANEL := Color(0.15, 0.15, 0.22)
const COLOR_HEALTH := Color(0.85, 0.2, 0.25)
const COLOR_XP := Color(0.25, 0.55, 0.95)
const COLOR_GOLD := Color(0.95, 0.75, 0.2)
const COLOR_BOSS := Color(0.85, 0.25, 0.85)
const COLOR_TEXT := Color(0.95, 0.95, 0.98)
const COLOR_TEXT_DIM := Color(0.65, 0.65, 0.72)

# --- UI-Elemente ---
var level_label: Label
var power_label: Label
var xp_bar: ProgressBar
var health_bar: ProgressBar
var gold_label: Label
var enemy_icon_label: Label
var enemy_label: Label
var enemy_health_bar: ProgressBar
var log_label: Label
var attack_button: Button

var _farm_timer: Timer
var _auto_attack_timer: Timer

const ENEMY_ICONS := {
	"Wildschwein": "🐗", "Waldwolf": "🐺", "Höhlenspinne": "🕷️",
	"Räuber": "🗡️", "Skelett": "💀",
	"Oger-König": "👹", "Schattendrache": "🐉",
	"Grubentroll": "🧌", "Der Verfluchte Ritter": "⚔️",
}

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

func _style_box(color: Color, radius: int = 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

func _styled_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 34)
	bar.show_percentage = false
	var bg := _style_box(Color(0.06, 0.06, 0.1), 10)
	var fg := _style_box(fill_color, 10)
	fg.content_margin_left = 0
	fg.content_margin_right = 0
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar

func _section_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style_box(COLOR_PANEL, 18))
	return panel

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG
	var bg_panel := Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(bg_panel)
	move_child(bg_panel, 0)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	# --- Spieler-Karte ---
	var player_panel := _section_panel()
	var player_vbox := VBoxContainer.new()
	player_vbox.add_theme_constant_override("separation", 8)
	player_panel.add_child(player_vbox)
	vbox.add_child(player_panel)

	var header_row := HBoxContainer.new()
	player_vbox.add_child(header_row)

	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 30)
	level_label.add_theme_color_override("font_color", COLOR_TEXT)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(level_label)

	power_label = Label.new()
	power_label.add_theme_font_size_override("font_size", 16)
	power_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	header_row.add_child(power_label)

	var xp_caption := Label.new()
	xp_caption.text = "XP"
	xp_caption.add_theme_font_size_override("font_size", 14)
	xp_caption.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	player_vbox.add_child(xp_caption)

	xp_bar = _styled_bar(COLOR_XP)
	player_vbox.add_child(xp_bar)

	var hp_caption := Label.new()
	hp_caption.text = "Leben"
	hp_caption.add_theme_font_size_override("font_size", 14)
	hp_caption.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	player_vbox.add_child(hp_caption)

	health_bar = _styled_bar(COLOR_HEALTH)
	player_vbox.add_child(health_bar)

	gold_label = Label.new()
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_label.add_theme_color_override("font_color", COLOR_GOLD)
	player_vbox.add_child(gold_label)

	# --- Gegner-Karte ---
	var enemy_panel := _section_panel()
	var enemy_vbox := VBoxContainer.new()
	enemy_vbox.add_theme_constant_override("separation", 8)
	enemy_panel.add_child(enemy_vbox)
	vbox.add_child(enemy_panel)

	var enemy_row := HBoxContainer.new()
	enemy_row.add_theme_constant_override("separation", 12)
	enemy_vbox.add_child(enemy_row)

	enemy_icon_label = Label.new()
	enemy_icon_label.add_theme_font_size_override("font_size", 40)
	enemy_row.add_child(enemy_icon_label)

	enemy_label = Label.new()
	enemy_label.add_theme_font_size_override("font_size", 22)
	enemy_label.add_theme_color_override("font_color", COLOR_TEXT)
	enemy_row.add_child(enemy_label)

	enemy_health_bar = _styled_bar(COLOR_BOSS)
	enemy_vbox.add_child(enemy_health_bar)

	# --- Angriffs-Knopf ---
	attack_button = Button.new()
	attack_button.text = "⚔  Angreifen"
	attack_button.custom_minimum_size = Vector2(0, 72)
	attack_button.add_theme_font_size_override("font_size", 22)
	var btn_normal := _style_box(Color(0.75, 0.2, 0.25), 16)
	var btn_pressed := _style_box(Color(0.55, 0.12, 0.16), 16)
	attack_button.add_theme_stylebox_override("normal", btn_normal)
	attack_button.add_theme_stylebox_override("pressed", btn_pressed)
	attack_button.add_theme_stylebox_override("hover", btn_normal)
	attack_button.add_theme_color_override("font_color", COLOR_TEXT)
	attack_button.connect("pressed", Callable(self, "_on_manual_attack"))
	vbox.add_child(attack_button)

	# --- Log ---
	var log_panel := _section_panel()
	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	log_label.add_theme_font_size_override("font_size", 16)
	log_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	log_panel.add_child(log_label)
	vbox.add_child(log_panel)

func _spawn_enemy() -> void:
	var next_level_marker := player.level
	if next_level_marker % boss_every_n_levels == 0 and next_level_marker > 0:
		current_enemy = Enemy.create_boss(player.level)
		_log("👑 Ein Boss erscheint: %s !" % current_enemy.enemy_name)
	else:
		current_enemy = Enemy.create_normal(player.level)
	current_enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))
	_update_ui()

func _on_auto_attack() -> void:
	_do_attack()

func _on_manual_attack() -> void:
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
	_log("✅ %s wurde besiegt! +%d XP, +%d Gold" % [current_enemy.enemy_name, current_enemy.xp_reward, current_enemy.gold_reward])
	player.gain_xp(current_enemy.xp_reward)
	player.gain_gold(current_enemy.gold_reward)
	_spawn_enemy()

func _on_farm_tick() -> void:
	var farmed := 2 + player.level
	player.gain_gold(farmed)
	_log("🌾 Du hast beim Farmen %d Gold gefunden." % farmed)

func _on_level_up(new_level: int) -> void:
	_log("⭐ Level Up! Du bist jetzt Level %d." % new_level)
	_spawn_enemy()

func _on_player_died() -> void:
	_log("💀 Du wurdest besiegt... Neustart mit vollem Leben.")
	player.heal_full()

func _update_ui() -> void:
	level_label.text = "Level %d" % player.level
	power_label.text = "⚡ Power %d" % player.power_score
	xp_bar.max_value = player.xp_to_next_level
	xp_bar.value = player.xp
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	gold_label.text = "💰 %d Gold" % player.gold

	if current_enemy != null:
		var icon: String = ENEMY_ICONS.get(current_enemy.enemy_name, "👾")
		enemy_icon_label.text = icon
		var boss_tag := "  👑 BOSS" if current_enemy.is_boss else ""
		enemy_label.text = "%s%s" % [current_enemy.enemy_name, boss_tag]
		enemy_health_bar.max_value = current_enemy.max_health
		enemy_health_bar.value = current_enemy.health

func _log(text: String) -> void:
	log_label.text = text

# --- Platzhalter für später: hier hakt die Firebase-Rangliste ein ---
# func submit_score_to_leaderboard() -> void:
#     var score = player.power_score
#     # Firebase-Aufruf kommt in einem späteren Schritt dazu
