extends Node
class_name CustomLevelBuilder

const BASE_LEVEL_SCRIPT := preload("res://src/levels/base_level.gd")
const WAVE_MANAGER_SCRIPT := preload("res://src/core/main_game/wave_manager.gd")
const NAV_GRID_SCRIPT := preload("res://src/core/navigation/navigation_grid.gd")
const ENEMY_ROUTE_SCRIPT := preload("res://src/gameplay/enemies/enemy_route.gd")
const BASE_SCENE := preload("res://src/gameplay/enemies/base.tscn")
const DUNGEON_TILES := preload("res://src/resources/dungeon_tiles.tres")


static func build_level_from_dict(data: Dictionary) -> BaseLevel:
	var level_root := BaseLevel.new()
	level_root.name = "CustomLevel"

	var level_name: String = data.get("name", "Nivel Personalizado")
	level_root.set_meta("nombre_level", level_name)

	var config: Dictionary = data.get("config", {})
	var player_spawn_pos := CustomLevelManager.array_to_vector3(data.get("player_spawn", [0, 1, 0]), Vector3(0, 1, 0))
	var base_pos := CustomLevelManager.array_to_vector3(data.get("base_position", [8, 1, -2]), Vector3(8, 1, -2))

	# Player Spawner
	var player_spawner := Marker3D.new()
	player_spawner.name = "PlayerSpawner"
	player_spawner.position = player_spawn_pos
	level_root.add_child(player_spawner)

	# GridMap
	var grid_map := GridMap.new()

	grid_map.name = "GridMap"
	grid_map.mesh_library = DUNGEON_TILES
	grid_map.cell_size = Vector3(1, 1, 1)
	grid_map.collision_mask = 7
	grid_map.add_to_group("colocable")
	level_root.add_child(grid_map)

	var cells_data: Array = data.get("gridmap_cells", [])
	for cell in cells_data:
		if cell is Dictionary:
			var x: int = int(cell.get("x", 0))
			var y: int = int(cell.get("y", 0))
			var z: int = int(cell.get("z", 0))
			var item: int = int(cell.get("item", 0))
			var rot: int = int(cell.get("rot", 0))
			grid_map.set_cell_item(Vector3i(x, y, z), item, rot)

	# Base (Tower)
	var base_inst := BASE_SCENE.instantiate() as Node3D
	base_inst.name = "Base"
	base_inst.position = base_pos
	level_root.add_child(base_inst)

	# Spawners
	var spawner_positions: Array = data.get("spawner_positions", [])
	if spawner_positions.is_empty():
		spawner_positions = [[-40, 1, 8]]

	var primary_spawner: Marker3D = null
	for i in range(spawner_positions.size()):
		var spos := CustomLevelManager.array_to_vector3(spawner_positions[i], Vector3(-40, 1, 8))
		var sp := Marker3D.new()
		sp.name = "Spawner" if i == 0 else "Spawner_" + str(i + 1)
		sp.position = spos
		sp.add_to_group("spawner")
		level_root.add_child(sp)
		if i == 0:
			primary_spawner = sp

	# Enemy Routes
	var routes_root := Node3D.new()
	routes_root.name = "EnemyRoutes"
	level_root.add_child(routes_root)

	var routes_data: Array = data.get("enemy_routes", [])
	if routes_data.is_empty() and primary_spawner != null:
		# Fallback single route from primary spawner to base
		routes_data = [[
			CustomLevelManager.vector3_to_array(primary_spawner.position),
			CustomLevelManager.vector3_to_array(base_pos)
		]]

	for r_idx in range(routes_data.size()):
		var waypoints_arr: Array = routes_data[r_idx]
		if waypoints_arr.is_empty():
			continue
		var route_node := Node3D.new()
		route_node.name = "Route_" + str(r_idx + 1)
		route_node.set_script(ENEMY_ROUTE_SCRIPT)
		routes_root.add_child(route_node)

		for wp_idx in range(waypoints_arr.size()):
			var wp_pos := CustomLevelManager.array_to_vector3(waypoints_arr[wp_idx])
			var wp_marker := Marker3D.new()
			wp_marker.name = "WP" + str(wp_idx + 1)
			wp_marker.position = wp_pos
			route_node.add_child(wp_marker)

	var next_level_name: String = str(data.get("next_level", ""))
	level_root.set_meta("next_level", next_level_name)

	# Unlock initial traps for this level
	var initial_traps: Array = data.get("initial_unlocked_traps", [1])
	for tid in initial_traps:
		Progress.unlock_blueprint(int(tid))

	# WaveManager
	var wave_manager := Node.new()
	wave_manager.name = "WaveManager"
	wave_manager.set_script(WAVE_MANAGER_SCRIPT)

	var waves_list: Array = data.get("waves_data", [])
	var total_w: int = waves_list.size() if not waves_list.is_empty() else int(config.get("max_waves", 5))

	# Apply WaveManager properties from config dictionary
	wave_manager.set("max_waves", total_w)
	wave_manager.set("waves_data", waves_list)
	wave_manager.set("base_enemies_per_wave", int(config.get("base_enemies_per_wave", 5)))
	wave_manager.set("enemies_per_wave_increment", int(config.get("enemies_per_wave_increment", 2)))
	wave_manager.set("countdown_duration", float(config.get("countdown_duration", 10.0)))
	wave_manager.set("wave_reward_increment", int(config.get("wave_reward_increment", 25)))

	wave_manager.set("money_per_enemy", int(config.get("money_per_enemy", -1)))
	wave_manager.set("boss_level", bool(config.get("boss_level", false)))
	wave_manager.set("unlock_trap_id", int(data.get("level_unlock_trap_id", 0)))
	wave_manager.set("wave_trap_unlocks", data.get("wave_trap_unlocks", {}))


	level_root.add_child(wave_manager)

	# Navigation Grid
	var nav_grid := Node.new()
	nav_grid.name = "NavigationGrid"
	nav_grid.set_script(NAV_GRID_SCRIPT)
	level_root.add_child(nav_grid)

	return level_root
