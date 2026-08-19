extends Node

const UPGRADES := {
	1: [
		[
			{"name": "Pinchos de fuego", "cost": 75, "damage_mult": 1.5, "tint": Color(1.0, 0.45, 0.1)},
			{"name": "Pinchos infernales", "cost": 150, "damage_mult": 1.6, "tint": Color(1.0, 0.25, 0.05)},
		],
		[
			{"name": "Muchos pinchos", "cost": 100, "damage_mult": 1.3, "area_mult": 1.5},
			{"name": "Erizos", "cost": 200, "damage_mult": 1.4, "area_mult": 1.6},
		],
	],
}


func has_upgrades(trap_id: int) -> bool:
	return UPGRADES.has(trap_id)


func get_next_upgrade(trap_id: int, path: int, level: int) -> Dictionary:
	if not UPGRADES.has(trap_id):
		return {}
	var paths: Array = UPGRADES[trap_id]
	if path < 0 or path >= paths.size():
		return {}
	var tiers: Array = paths[path]
	if level < 0 or level >= tiers.size():
		return {}
	return tiers[level]


func try_upgrade(trap: Trap, path: int) -> bool:
	if trap == null or not is_instance_valid(trap):
		return false
	if not UPGRADES.has(trap.trap_id):
		return false
	var level: int = trap.upgrade_levels[path]
	var upgrade := get_next_upgrade(trap.trap_id, path, level)
	if upgrade.is_empty():
		return false
	var cost: int = upgrade["cost"]
	if not Economy.can_afford(cost):
		return false
	Economy.spend_money(cost)
	trap.apply_upgrade(upgrade)
	trap.upgrade_levels[path] = level + 1
	return true
