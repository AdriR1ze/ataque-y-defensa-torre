extends Node


signal blueprints_changed


var unlocked_blueprints: Dictionary = {}


func unlock_blueprint(trap_id: int) -> void:
	if has_blueprint(trap_id):
		return

	unlocked_blueprints[trap_id] = true
	blueprints_changed.emit()


func has_blueprint(trap_id: int) -> bool:
	return unlocked_blueprints.has(trap_id)


func get_unlocked_trap_ids() -> Array:
	return unlocked_blueprints.keys()


func reset() -> void:
	unlocked_blueprints.clear()
