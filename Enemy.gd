extends Node
class_name Enemy

var enemy_name: String = "Wildschwein"
var health: int = 30
var max_health: int = 30
var attack_damage: int = 5
var xp_reward: int = 15
var gold_reward: int = 5
var is_boss: bool = false

signal defeated()

static func create_normal(player_level: int) -> Enemy:
	var e := Enemy.new()
	# Gegner skalieren leicht mit dem Spieler-Level, damit es nie zu leicht/schwer wird
	var scale_factor := 1.0 + (player_level - 1) * 0.15
	e.max_health = int(30 * scale_factor)
	e.health = e.max_health
	e.attack_damage = int(5 * scale_factor)
	e.xp_reward = int(15 * scale_factor)
	e.gold_reward = int(5 * scale_factor)
	e.enemy_name = _random_name()
	return e

static func create_boss(player_level: int) -> Enemy:
	var e := Enemy.new()
	var scale_factor := 1.0 + (player_level - 1) * 0.15
	e.max_health = int(150 * scale_factor)
	e.health = e.max_health
	e.attack_damage = int(12 * scale_factor)
	e.xp_reward = int(120 * scale_factor)
	e.gold_reward = int(50 * scale_factor)
	e.is_boss = true
	e.enemy_name = _random_boss_name()
	return e

static func _random_name() -> String:
	var names = ["Wildschwein", "Waldwolf", "Höhlenspinne", "Räuber", "Skelett"]
	return names[randi() % names.size()]

static func _random_boss_name() -> String:
	var names = ["Oger-König", "Schattendrache", "Grubentroll", "Der Verfluchte Ritter"]
	return names[randi() % names.size()]

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		health = 0
		emit_signal("defeated")
