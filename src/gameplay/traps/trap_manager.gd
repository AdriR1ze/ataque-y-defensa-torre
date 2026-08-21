extends Node
class_name TrapManager


signal loadout_changed
signal selected_slot_changed(slot: int)


const ALL_TRAPS := {
	1: preload("res://src/gameplay/traps/spikes_trap/spikes_trap.tres"),
	2: preload("res://src/gameplay/traps/spike_launcher_trap/spike_launcher_trap.tres"),
	3: preload("res://src/gameplay/traps/laser_trap/laser_trap.tres"),
	4: preload("res://src/gameplay/traps/mud_trap/mud_trap.tres"),
	5: preload("res://src/gameplay/traps/spring_trap/spring_trap.tres"),
	6: preload("res://src/gameplay/traps/swing_ball_trap/swing_ball_trap.tres"),
	7: preload("res://src/gameplay/traps/spinning_saw_trap/spinning_saw_trap.tres"),
	8: preload("res://src/gameplay/traps/web_trap/web_trap.tres"),
	9: preload("res://src/gameplay/traps/explosive_mine_trap/explosive_mine_trap.tres"),
	10: preload("res://src/gameplay/traps/wind_gust_trap/wind_gust_trap.tres"),
	11: preload("res://src/gameplay/traps/suction_trap/suction_trap.tres"),
	12: preload("res://src/gameplay/traps/guillotine_trap/guillotine_trap.tres"),
	13: preload("res://src/gameplay/traps/ghost_ball_trower/ghost_ball_trower.tres"),
}


const SLOT_KEYS := {
	1: KEY_1,
	2: KEY_2,
	3: KEY_3,
	4: KEY_4,
	5: KEY_5,
	6: KEY_6,
	7: KEY_7,
	8: KEY_F,
	9: KEY_C,
	10: KEY_V,
}


const SLOT_LABELS := {
	1: "1",
	2: "2",
	3: "3",
	4: "4",
	5: "5",
	6: "6",
	7: "7",
	8: "F",
	9: "C",
	10: "V",
}


const SLOT_COUNT := 10


var loadout: Dictionary = {}
var selected_slot := 0


func get_available_trap_ids() -> Array:
	var available: Array = []

	for trap_id in ALL_TRAPS:
		if Progress.has_blueprint(trap_id):
			available.append(trap_id)

	return available


func is_trap_available(trap_id: int) -> bool:
	return ALL_TRAPS.has(trap_id) and Progress.has_blueprint(trap_id)


func get_trap(trap_id: int) -> TrapData:
	return ALL_TRAPS.get(trap_id)


func get_slot_count() -> int:
	return SLOT_COUNT


func get_slot_labels() -> Dictionary:
	return SLOT_LABELS.duplicate()


func get_equipped_trap_id(slot: int) -> int:
	return loadout.get(slot, 0)


func equip_trap(slot: int, trap_id: int) -> void:
	if slot < 1 or slot > SLOT_COUNT:
		return

	if trap_id == 0:
		loadout.erase(slot)
	elif not is_trap_available(trap_id):
		return
	else:
		loadout[slot] = trap_id

	loadout_changed.emit()


func clear_loadout() -> void:
	loadout.clear()
	selected_slot = 0

	loadout_changed.emit()
	selected_slot_changed.emit(selected_slot)


func get_loadout() -> Dictionary:
	return loadout.duplicate()


func apply_loadout(saved_loadout: Dictionary) -> void:
	loadout.clear()

	for slot in saved_loadout:
		var trap_id: int = saved_loadout[slot]

		if is_trap_available(trap_id):
			loadout[slot] = trap_id

	if not loadout.has(selected_slot):
		selected_slot = 0

	loadout_changed.emit()
	selected_slot_changed.emit(selected_slot)


func select_slot(slot: int) -> void:
	if slot < 1 or slot > SLOT_COUNT:
		return

	if not loadout.has(slot):
		return

	selected_slot = slot
	selected_slot_changed.emit(selected_slot)


func get_selected_trap_id() -> int:
	return loadout.get(selected_slot, 0)


func get_selected_trap() -> TrapData:
	var trap_id := get_selected_trap_id()

	if trap_id == 0:
		return null

	return get_trap(trap_id)


func is_trap_equipped(trap_id: int) -> bool:
	return trap_id in loadout.values()


func has_any_trap() -> bool:
	return not loadout.is_empty()
