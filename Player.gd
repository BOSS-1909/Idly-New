extends Node
class_name Player

# --- Basis-Werte ---
var level: int = 1
var xp: int = 0
var xp_to_next_level: int = 50

var max_health: int = 100
var health: int = 100
var attack_damage: int = 10

var gold: int = 0
var power_score: int = 0  # wird für die Rangliste genutzt

signal leveled_up(new_level: int)
signal died()
signal stats_changed()

func _ready() -> void:
	_recalculate_power_score()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		health = 0
		emit_signal("died")
	emit_signal("stats_changed")

func heal_full() -> void:
	health = max_health
	emit_signal("stats_changed")

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		_level_up()
	emit_signal("stats_changed")

func gain_gold(amount: int) -> void:
	gold += amount
	emit_signal("stats_changed")

func _level_up() -> void:
	level += 1
	max_health += 20
	attack_damage += 4
	xp_to_next_level = int(xp_to_next_level * 1.25)
	heal_full()
	_recalculate_power_score()
	emit_signal("leveled_up", level)

func _recalculate_power_score() -> void:
	# Einfache Formel für die Rangliste: kombiniert Level, Angriff und Leben
	power_score = level * 10 + attack_damage * 3 + int(max_health / 5)

func to_save_dict() -> Dictionary:
	return {
		"level": level,
		"xp": xp,
		"xp_to_next_level": xp_to_next_level,
		"max_health": max_health,
		"health": health,
		"attack_damage": attack_damage,
		"gold": gold,
		"power_score": power_score,
	}

func load_from_dict(data: Dictionary) -> void:
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	xp_to_next_level = data.get("xp_to_next_level", 50)
	max_health = data.get("max_health", 100)
	health = data.get("health", max_health)
	attack_damage = data.get("attack_damage", 10)
	gold = data.get("gold", 0)
	_recalculate_power_score()
	emit_signal("stats_changed")
