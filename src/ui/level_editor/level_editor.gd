extends Node3D
class_name LevelEditor

enum EditMode {
	TILES,
	ENTITIES,
	ROUTES,
	CONFIG
}

enum EntityType {
	BASE,
	SPAWNER,
	PLAYER_SPAWN
}

const DUNGEON_TILES := preload("res://src/resources/dungeon_tiles.tres")
const MAIN_GAME_SCENE := "res://src/core/main_game/main_game.tscn"
const MAIN_MENU_SCENE := "res://src/ui/main_menu.tscn"

const TRAP_NAMES := {
	0: "Ninguna",
	1: "Trampa de Pinchos",
	2: "Lanzador de Pinchos",
	3: "Láser",
	4: "Barro",
	5: "Resorte",
	6: "Bola Giratoria",
	7: "Sierra Giratoria",
	8: "Telaraña",
	9: "Mina Explosiva",
	10: "Ráfaga de Viento",
	11: "Succión",
	12: "Guillotina",
	13: "Lanzador Bola Fantasma"
}

# Nodes
@onready var grid_map: GridMap = $GridMap
@onready var camera_3d: Camera3D = $Camera3D
@onready var cursor_preview: MeshInstance3D = $CursorPreview
@onready var markers_node: Node3D = $Markers

var ui_canvas: CanvasLayer = null

# State
var current_mode := EditMode.TILES
var selected_tile_item := 0
var selected_entity_type := EntityType.BASE

var level_name := "Nivel Custom"
var next_level := ""
var max_waves := 5
var base_enemies_per_wave := 5
var enemies_per_wave_increment := 2
var countdown_duration := 10.0
var wave_reward := 100
var wave_reward_increment := 25
var money_per_enemy := 15
var boss_level := false

var initial_unlocked_traps: Array = [1]
var level_unlock_trap_id := 0
var wave_trap_unlocks: Dictionary = {}
var waves_data: Array = []

var base_position := Vector3(8, 1, -2)
var spawner_positions: Array[Vector3] = [Vector3(-40, 1, 8)]
var player_spawn_position := Vector3(4, 1, -5)
var enemy_routes: Array = [
	[Vector3(-40, 1, 8), Vector3(-40, 1, 0), Vector3(-30, 1, -4), Vector3(8, 1, -3)]
]
var active_route_index := 0

# Camera fly controls
var camera_speed := 18.0
var camera_rot := Vector2(-0.6, 0.0)
var is_aiming := false
var hovered_cell := Vector3i.ZERO

var is_building := false
var last_placed_cell := Vector3i(999999, 999999, 999999)
var build_cooldown_timer := 0.0
const BUILD_COOLDOWN_TIME := 0.12

var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
const MAX_UNDO_STEPS := 50

# UI references
var _top_panel: Control
var _side_panel_holder: Control
var _config_panel: Control
var _tiles_panel: Control
var _entities_panel: Control
var _routes_panel: Control
var _status_label: Label
var _route_info_label: Label
var _wave_unlocks_vbox: VBoxContainer
var _waves_custom_vbox: VBoxContainer
var _root_control: Control



func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_setup_editor_scene()
	_create_ground_grid_plane()
	_build_ui()
	_update_markers()
	_update_cursor_mesh()

	if camera_3d != null:
		camera_rot = Vector2(camera_3d.rotation.x, camera_3d.rotation.y)


func _setup_editor_scene() -> void:
	if grid_map == null:
		grid_map = GridMap.new()
		grid_map.name = "GridMap"
		grid_map.mesh_library = DUNGEON_TILES
		grid_map.cell_size = Vector3(1, 1, 1)
		grid_map.collision_mask = 7
		add_child(grid_map)

	if cursor_preview == null:
		cursor_preview = MeshInstance3D.new()
		cursor_preview.name = "CursorPreview"
		add_child(cursor_preview)

	if markers_node == null:
		markers_node = Node3D.new()
		markers_node.name = "Markers"
		add_child(markers_node)

	_create_default_map()


func _create_ground_grid_plane() -> void:
	var plane_inst := MeshInstance3D.new()
	plane_inst.name = "GroundGridPlane"
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.15, 0.2, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	plane.material = mat
	plane_inst.mesh = plane
	plane_inst.position = Vector3(0, -0.01, 0)
	add_child(plane_inst)


func _create_default_map() -> void:
	grid_map.clear()
	for x in range(-8, 8):
		for z in range(-8, 8):
			grid_map.set_cell_item(Vector3i(x, 0, z), 0)


func _process(delta: float) -> void:
	if build_cooldown_timer > 0:
		build_cooldown_timer -= delta
	_update_camera_fly(delta)
	_update_raycast_cursor()


func _take_undo_snapshot() -> void:
	undo_stack.append(get_level_data())
	if undo_stack.size() > MAX_UNDO_STEPS:
		undo_stack.pop_front()
	redo_stack.clear()


func _undo() -> void:
	if undo_stack.is_empty():
		_show_status("Nada para deshacer (Ctrl+Z).")
		return
	redo_stack.append(get_level_data())
	var prev_data: Dictionary = undo_stack.pop_back()
	load_level_data(prev_data)
	_show_status("Acción deshecha (Ctrl+Z).")


func _redo() -> void:
	if redo_stack.is_empty():
		_show_status("Nada para rehacer (Ctrl+Y).")
		return
	undo_stack.append(get_level_data())
	var next_data: Dictionary = redo_stack.pop_back()
	load_level_data(next_data)
	_show_status("Acción rehecha (Ctrl+Y).")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_command_or_control_pressed():
			if event.physical_keycode == KEY_Z:
				if event.shift_pressed:
					_redo()
				else:
					_undo()
				get_viewport().set_input_as_handled()
			elif event.physical_keycode == KEY_Y:
				_redo()
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_aiming = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if is_aiming else Input.MOUSE_MODE_VISIBLE

		elif event.button_index == MOUSE_BUTTON_LEFT and not is_aiming:
			var mouse_pos := get_viewport().get_mouse_position()
			if event.pressed:
				if not _is_mouse_over_ui(mouse_pos):
					_take_undo_snapshot()
					is_building = true
					last_placed_cell = Vector3i(999999, 999999, 999999)
					_handle_primary_click()
			else:
				is_building = false
				last_placed_cell = Vector3i(999999, 999999, 999999)

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var mouse_pos := get_viewport().get_mouse_position()
			if not _is_mouse_over_ui(mouse_pos):
				camera_3d.global_position -= camera_3d.global_transform.basis.z * 1.5
				camera_3d.global_position.y = maxf(1.5, camera_3d.global_position.y)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var mouse_pos := get_viewport().get_mouse_position()
			if not _is_mouse_over_ui(mouse_pos):
				camera_3d.global_position += camera_3d.global_transform.basis.z * 1.5
				camera_3d.global_position.y = maxf(1.5, camera_3d.global_position.y)

	elif event is InputEventMouseMotion and is_aiming:
		camera_rot.y -= event.relative.x * 0.003
		camera_rot.x = clampf(camera_rot.x - event.relative.y * 0.003, deg_to_rad(-85), deg_to_rad(85))
		camera_3d.rotation = Vector3(camera_rot.x, camera_rot.y, 0)


func _update_camera_fly(delta: float) -> void:
	var move_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		move_dir -= camera_3d.global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		move_dir += camera_3d.global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		move_dir -= camera_3d.global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		move_dir += camera_3d.global_transform.basis.x
	if Input.is_key_pressed(KEY_E):
		move_dir += Vector3.UP
	if Input.is_key_pressed(KEY_Q):
		move_dir -= Vector3.UP

	if move_dir != Vector3.ZERO:
		var speed := camera_speed
		if Input.is_key_pressed(KEY_SHIFT):
			speed *= 2.5
		camera_3d.global_position += move_dir.normalized() * speed * delta

	camera_3d.global_position.y = maxf(1.5, camera_3d.global_position.y)


func _is_mouse_over_ui(mouse_pos: Vector2) -> bool:
	if _top_panel != null and _top_panel.get_global_rect().has_point(mouse_pos):
		return true
	if _side_panel_holder != null and _side_panel_holder.get_global_rect().has_point(mouse_pos):
		return true
	return false


func _update_raycast_cursor() -> void:
	if is_aiming or camera_3d == null or current_mode == EditMode.CONFIG:
		cursor_preview.visible = false
		return

	var mouse_pos := get_viewport().get_mouse_position()

	if _is_mouse_over_ui(mouse_pos):
		cursor_preview.visible = false
		return

	var ray_origin := camera_3d.project_ray_origin(mouse_pos)
	var ray_dir := camera_3d.project_ray_normal(mouse_pos)

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * 200.0)
	query.collision_mask = 7
	var result := space_state.intersect_ray(query)

	if not result.is_empty():
		var hit_pos: Vector3 = result.position
		var normal: Vector3 = result.normal

		if selected_tile_item == -1:
			var target_pos := hit_pos - normal * 0.3
			var cell_local := grid_map.to_local(target_pos)
			hovered_cell = grid_map.local_to_map(cell_local)
		else:
			var target_pos := hit_pos + normal * 0.3
			var cell_local := grid_map.to_local(target_pos)
			hovered_cell = grid_map.local_to_map(cell_local)

		cursor_preview.visible = true
		var world_pos := grid_map.to_global(grid_map.map_to_local(hovered_cell))
		cursor_preview.global_position = world_pos

		if is_building and hovered_cell != last_placed_cell and build_cooldown_timer <= 0:
			_handle_primary_click()
		return

	var plane := Plane(Vector3.UP, 0.0)
	var hit_plane = plane.intersects_ray(ray_origin, ray_dir)
	if hit_plane != null:
		var hit_pos: Vector3 = hit_plane
		var cell_local := grid_map.to_local(hit_pos)
		hovered_cell = grid_map.local_to_map(cell_local)
		cursor_preview.visible = true
		var world_pos := grid_map.to_global(grid_map.map_to_local(hovered_cell))
		cursor_preview.global_position = world_pos

		if is_building and hovered_cell != last_placed_cell and build_cooldown_timer <= 0:
			_handle_primary_click()
		return

	cursor_preview.visible = false


func _handle_primary_click() -> void:
	if not cursor_preview.visible:
		return

	last_placed_cell = hovered_cell
	build_cooldown_timer = BUILD_COOLDOWN_TIME

	match current_mode:
		EditMode.TILES:
			if selected_tile_item == -1:
				grid_map.set_cell_item(hovered_cell, -1)
				_show_status("Bloque eliminado en " + str(hovered_cell))
			else:
				grid_map.set_cell_item(hovered_cell, selected_tile_item)
				_show_status("Bloque colocado en " + str(hovered_cell))

		EditMode.ENTITIES:
			var world_pos := grid_map.to_global(grid_map.map_to_local(hovered_cell))
			world_pos.y = maxf(1.0, world_pos.y)
			match selected_entity_type:
				EntityType.BASE:
					base_position = world_pos
					_show_status("Torre / Base posicionada en: " + str(world_pos))
				EntityType.SPAWNER:
					if spawner_positions.is_empty():
						spawner_positions.append(world_pos)
					else:
						spawner_positions[0] = world_pos
					_show_status("Spawner posicionado en: " + str(world_pos))
				EntityType.PLAYER_SPAWN:
					player_spawn_position = world_pos
					_show_status("Spawn Jugador posicionado en: " + str(world_pos))
			_update_markers()

		EditMode.ROUTES:
			var world_pos := grid_map.to_global(grid_map.map_to_local(hovered_cell))
			world_pos.y = maxf(1.0, world_pos.y)
			if enemy_routes.is_empty():
				enemy_routes.append([])
			var active_route: Array = enemy_routes[active_route_index]
			active_route.append(world_pos)
			_show_status("Waypoint añadido a la Ruta " + str(active_route_index + 1) + ": " + str(world_pos))
			_update_markers()


func _update_markers() -> void:
	for child in markers_node.get_children():
		child.queue_free()

	_create_3d_marker(base_position, Color(0.2, 0.9, 0.3), "TORRE / BASE")

	for idx in range(spawner_positions.size()):
		_create_3d_marker(spawner_positions[idx], Color(0.9, 0.2, 0.2), "SPAWNER " + str(idx + 1))

	_create_3d_marker(player_spawn_position, Color(0.2, 0.5, 1.0), "SPAWN JUGADOR")

	for r_idx in range(enemy_routes.size()):
		var route: Array = enemy_routes[r_idx]
		for wp_idx in range(route.size()):
			var wp_pos: Vector3 = route[wp_idx]
			_create_3d_marker(wp_pos, Color(1.0, 0.85, 0.2), "R" + str(r_idx + 1) + "-P" + str(wp_idx + 1), 0.3)

	if _route_info_label != null:
		var total_wps := 0
		for r in enemy_routes:
			total_wps += (r as Array).size()
		_route_info_label.text = "Ruta Actual: #" + str(active_route_index + 1) + " | Total Waypoints: " + str(total_wps)


func _create_3d_marker(pos: Vector3, color: Color, label_text: String, scale_size: float = 0.6) -> void:
	var marker_node := Node3D.new()
	marker_node.position = pos

	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = scale_size
	sphere.height = scale_size * 2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.5
	sphere.material = mat
	mesh_inst.mesh = sphere
	marker_node.add_child(mesh_inst)

	var label_3d := Label3D.new()
	label_3d.text = label_text
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.position = Vector3(0, scale_size + 0.6, 0)
	label_3d.font_size = 20
	label_3d.modulate = color
	marker_node.add_child(label_3d)

	markers_node.add_child(marker_node)


func _update_cursor_mesh() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(1.02, 1.02, 1.02)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.3, 0.8, 1.0, 0.55)
	box.material = mat
	cursor_preview.mesh = box


func get_level_data() -> Dictionary:
	var cells_arr := []
	var used_cells := grid_map.get_used_cells()
	for cell in used_cells:
		var item := grid_map.get_cell_item(cell)
		var rot := grid_map.get_cell_item_orientation(cell)
		cells_arr.append({
			"x": cell.x,
			"y": cell.y,
			"z": cell.z,
			"item": item,
			"rot": rot
		})

	var sp_arr := []
	for sp in spawner_positions:
		sp_arr.append(CustomLevelManager.vector3_to_array(sp))

	var routes_arr := []
	for r in enemy_routes:
		var waypoints_list := []
		for wp in (r as Array):
			waypoints_list.append(CustomLevelManager.vector3_to_array(wp))
		routes_arr.append(waypoints_list)

	var total_w := waves_data.size() if not waves_data.is_empty() else max_waves

	return {
		"name": level_name,
		"next_level": next_level,
		"initial_unlocked_traps": initial_unlocked_traps,
		"level_unlock_trap_id": level_unlock_trap_id,
		"wave_trap_unlocks": wave_trap_unlocks,
		"waves_data": waves_data,
		"config": {
			"max_waves": total_w,
			"base_enemies_per_wave": base_enemies_per_wave,
			"enemies_per_wave_increment": enemies_per_wave_increment,
			"countdown_duration": countdown_duration,
			"wave_reward": wave_reward,
			"wave_reward_increment": wave_reward_increment,
			"money_per_enemy": money_per_enemy,
			"boss_level": boss_level
		},
		"player_spawn": CustomLevelManager.vector3_to_array(player_spawn_position),
		"base_position": CustomLevelManager.vector3_to_array(base_position),
		"spawner_positions": sp_arr,
		"enemy_routes": routes_arr,
		"gridmap_cells": cells_arr
	}


func load_level_data(data: Dictionary) -> void:
	level_name = data.get("name", "Nivel Custom")
	next_level = str(data.get("next_level", ""))
	initial_unlocked_traps = data.get("initial_unlocked_traps", [1])
	level_unlock_trap_id = int(data.get("level_unlock_trap_id", 0))
	wave_trap_unlocks = data.get("wave_trap_unlocks", {})
	waves_data = data.get("waves_data", [])

	var config: Dictionary = data.get("config", {})
	max_waves = int(config.get("max_waves", 5))
	base_enemies_per_wave = int(config.get("base_enemies_per_wave", 5))
	enemies_per_wave_increment = int(config.get("enemies_per_wave_increment", 2))
	countdown_duration = float(config.get("countdown_duration", 10.0))
	wave_reward = int(config.get("wave_reward", 100))
	wave_reward_increment = int(config.get("wave_reward_increment", 25))
	money_per_enemy = int(config.get("money_per_enemy", 15))
	boss_level = bool(config.get("boss_level", false))

	player_spawn_position = CustomLevelManager.array_to_vector3(data.get("player_spawn", [4, 1, -5]))
	base_position = CustomLevelManager.array_to_vector3(data.get("base_position", [8, 1, -2]))

	spawner_positions.clear()
	var sp_arr: Array = data.get("spawner_positions", [])
	for sp in sp_arr:
		spawner_positions.append(CustomLevelManager.array_to_vector3(sp))
	if spawner_positions.is_empty():
		spawner_positions.append(Vector3(-40, 1, 8))

	enemy_routes.clear()
	var r_arr: Array = data.get("enemy_routes", [])
	for r in r_arr:
		var route_wps: Array[Vector3] = []
		for wp in (r as Array):
			route_wps.append(CustomLevelManager.array_to_vector3(wp))
		enemy_routes.append(route_wps)

	if enemy_routes.is_empty():
		enemy_routes.append([])

	grid_map.clear()
	var cells: Array = data.get("gridmap_cells", [])
	for cell in cells:
		if cell is Dictionary:
			var c := Vector3i(int(cell.get("x", 0)), int(cell.get("y", 0)), int(cell.get("z", 0)))
			grid_map.set_cell_item(c, int(cell.get("item", 0)), int(cell.get("rot", 0)))

	_update_markers()
	_update_config_ui_fields()
	_show_status("Nivel '" + level_name + "' cargado con éxito.")


func _build_ui() -> void:
	ui_canvas = CanvasLayer.new()
	ui_canvas.name = "UICanvas"
	add_child(ui_canvas)

	_root_control = Control.new()
	_root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_canvas.add_child(_root_control)


	# Top Toolbar Panel
	_top_panel = PanelContainer.new()
	_top_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top_panel.custom_minimum_size = Vector2(0, 50)
	_top_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.08, 0.1, 0.14, 0.92)
	top_style.content_margin_left = 16
	top_style.content_margin_right = 16
	_top_panel.add_theme_stylebox_override("panel", top_style)
	_root_control.add_child(_top_panel)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	_top_panel.add_child(top_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "🛠️ EDITOR DE NIVELES"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	top_hbox.add_child(title_lbl)

	top_hbox.add_child(VSeparator.new())

	# Mode Tabs
	var mode_btn_group := ButtonGroup.new()
	var mode_tiles := Button.new()
	mode_tiles.text = "🧱 Bloques"
	mode_tiles.toggle_mode = true
	mode_tiles.button_pressed = true
	mode_tiles.button_group = mode_btn_group
	mode_tiles.pressed.connect(func(): _switch_mode(EditMode.TILES))
	top_hbox.add_child(mode_tiles)

	var mode_entities := Button.new()
	mode_entities.text = "📍 Entidades"
	mode_entities.toggle_mode = true
	mode_entities.button_group = mode_btn_group
	mode_entities.pressed.connect(func(): _switch_mode(EditMode.ENTITIES))
	top_hbox.add_child(mode_entities)

	var mode_routes := Button.new()
	mode_routes.text = "🚩 Rutas Enemigos"
	mode_routes.toggle_mode = true
	mode_routes.button_group = mode_btn_group
	mode_routes.pressed.connect(func(): _switch_mode(EditMode.ROUTES))
	top_hbox.add_child(mode_routes)

	var mode_config := Button.new()
	mode_config.text = "⚙️ Config. Oleadas y Trampas"
	mode_config.toggle_mode = true
	mode_config.button_group = mode_btn_group
	mode_config.pressed.connect(func(): _switch_mode(EditMode.CONFIG))
	top_hbox.add_child(mode_config)

	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(top_spacer)

	# Action buttons
	var new_btn := Button.new()
	new_btn.text = "Nuevo"
	new_btn.pressed.connect(_on_new_level_pressed)
	top_hbox.add_child(new_btn)

	var save_btn := Button.new()
	save_btn.text = "Guardar"
	save_btn.pressed.connect(_on_save_dialog_pressed)
	top_hbox.add_child(save_btn)

	var load_btn := Button.new()
	load_btn.text = "Cargar"
	load_btn.pressed.connect(_on_load_dialog_pressed)
	top_hbox.add_child(load_btn)

	top_hbox.add_child(VSeparator.new())

	var play_btn := Button.new()
	play_btn.text = "🎮 Probar Nivel"
	play_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	play_btn.pressed.connect(_on_test_level_pressed)
	top_hbox.add_child(play_btn)

	var exit_btn := Button.new()
	exit_btn.text = "Salir"
	exit_btn.pressed.connect(_on_exit_pressed)
	top_hbox.add_child(exit_btn)

	# Bottom Status Bar
	var bottom_panel := PanelContainer.new()
	bottom_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.custom_minimum_size = Vector2(0, 36)
	bottom_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var btm_style := StyleBoxFlat.new()
	btm_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
	btm_style.content_margin_left = 16
	bottom_panel.add_theme_stylebox_override("panel", btm_style)
	_root_control.add_child(bottom_panel)

	var btm_hbox := HBoxContainer.new()
	bottom_panel.add_child(btm_hbox)

	_status_label = Label.new()
	_status_label.text = "WASD = Mover cámara | Click Derecho = Rotar cámara | Rueda Mouse = Zoom | Click Izquierdo = Construir"
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	btm_hbox.add_child(_status_label)

	# Side Panels Container
	_side_panel_holder = PanelContainer.new()
	_side_panel_holder.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_side_panel_holder.offset_top = 54
	_side_panel_holder.offset_bottom = -40
	_side_panel_holder.custom_minimum_size = Vector2(320, 0)
	_side_panel_holder.mouse_filter = Control.MOUSE_FILTER_STOP
	var side_style := StyleBoxFlat.new()
	side_style.bg_color = Color(0.08, 0.1, 0.14, 0.94)
	side_style.content_margin_left = 12
	side_style.content_margin_top = 12
	side_style.content_margin_right = 12
	side_style.content_margin_bottom = 12
	_side_panel_holder.add_theme_stylebox_override("panel", side_style)
	_root_control.add_child(_side_panel_holder)

	var side_vbox := VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 10)
	_side_panel_holder.add_child(side_vbox)

	# 1. Tiles Panel
	_tiles_panel = VBoxContainer.new()
	side_vbox.add_child(_tiles_panel)

	var tiles_lbl := Label.new()
	tiles_lbl.text = "PALETA DE BLOQUES"
	tiles_lbl.add_theme_font_size_override("font_size", 14)
	tiles_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	_tiles_panel.add_child(tiles_lbl)

	var tiles_list := [
		["Suelo (Floor)", 0],
		["Pared (Wall)", 1],
		["Media Pared (HalfWall)", 2],
		["Columna (Column)", 3],
		["Techo (Ceiling)", 4],
		["Pared Int. (InnerWall)", 5],
		["❌ Borrar Bloque", -1]
	]

	var tile_group := ButtonGroup.new()
	for t in tiles_list:
		var btn := Button.new()
		btn.text = t[0]
		btn.toggle_mode = true
		btn.button_group = tile_group
		if t[1] == 0:
			btn.button_pressed = true
		var item_id: int = t[1]
		btn.pressed.connect(func(): selected_tile_item = item_id)
		_tiles_panel.add_child(btn)

	# 2. Entities Panel
	_entities_panel = VBoxContainer.new()
	_entities_panel.visible = false
	side_vbox.add_child(_entities_panel)

	var ent_lbl := Label.new()
	ent_lbl.text = "COLOCAR ENTIDADES"
	ent_lbl.add_theme_font_size_override("font_size", 14)
	ent_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	_entities_panel.add_child(ent_lbl)

	var ent_group := ButtonGroup.new()
	var base_btn := Button.new()
	base_btn.text = "🏰 Torre / Base"
	base_btn.toggle_mode = true
	base_btn.button_pressed = true
	base_btn.button_group = ent_group
	base_btn.pressed.connect(func(): selected_entity_type = EntityType.BASE)
	_entities_panel.add_child(base_btn)

	var spawner_btn := Button.new()
	spawner_btn.text = "💀 Spawner Enemigos"
	spawner_btn.toggle_mode = true
	spawner_btn.button_group = ent_group
	spawner_btn.pressed.connect(func(): selected_entity_type = EntityType.SPAWNER)
	_entities_panel.add_child(spawner_btn)

	var player_sp_btn := Button.new()
	player_sp_btn.text = "👤 Spawn Jugador"
	player_sp_btn.toggle_mode = true
	player_sp_btn.button_group = ent_group
	player_sp_btn.pressed.connect(func(): selected_entity_type = EntityType.PLAYER_SPAWN)
	_entities_panel.add_child(player_sp_btn)

	# 3. Routes Panel
	_routes_panel = VBoxContainer.new()
	_routes_panel.visible = false
	side_vbox.add_child(_routes_panel)

	var routes_lbl := Label.new()
	routes_lbl.text = "RUTAS DE ENEMIGOS"
	routes_lbl.add_theme_font_size_override("font_size", 14)
	routes_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_routes_panel.add_child(routes_lbl)

	_route_info_label = Label.new()
	_route_info_label.text = "Ruta Actual: #1"
	_route_info_label.add_theme_font_size_override("font_size", 12)
	_routes_panel.add_child(_route_info_label)

	var new_route_btn := Button.new()
	new_route_btn.text = "➕ Nueva Ruta"
	new_route_btn.pressed.connect(_on_add_new_route)
	_routes_panel.add_child(new_route_btn)

	var clear_current_route_btn := Button.new()
	clear_current_route_btn.text = "🧹 Limpiar Ruta Actual"
	clear_current_route_btn.pressed.connect(_on_clear_current_route)
	_routes_panel.add_child(clear_current_route_btn)

	var clear_all_routes_btn := Button.new()
	clear_all_routes_btn.text = "🗑️ Limpiar Todas"
	clear_all_routes_btn.pressed.connect(_on_clear_all_routes)
	_routes_panel.add_child(clear_all_routes_btn)

	# 4. Config Panel
	_config_panel = VBoxContainer.new()
	_config_panel.visible = false
	side_vbox.add_child(_config_panel)

	var cfg_lbl := Label.new()
	cfg_lbl.text = "CONFIG. OLEADAS, ECONOMÍA Y TRAMPAS"
	cfg_lbl.add_theme_font_size_override("font_size", 14)
	cfg_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	_config_panel.add_child(cfg_lbl)

	_build_config_inputs(_config_panel)


func _build_config_inputs(parent: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 480)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	# SECTION 1: NIVEL Y SECUENCIA
	vbox.add_child(_create_section_title("📌 INFORMACIÓN Y SECUENCIA"))
	vbox.add_child(_create_label("Nombre del Nivel:"))
	var name_edit := LineEdit.new()
	name_edit.name = "CfgNameEdit"
	name_edit.text = level_name
	name_edit.custom_minimum_size = Vector2(0, 32)
	name_edit.text_changed.connect(func(t): level_name = t)
	vbox.add_child(name_edit)

	vbox.add_child(_create_label("Siguiente Nivel al Ganar:"))
	var next_edit := LineEdit.new()
	next_edit.name = "CfgNextLevelEdit"
	next_edit.placeholder_text = "nombre_del_nivel (vacío = fin)"
	next_edit.text = next_level
	next_edit.custom_minimum_size = Vector2(0, 32)
	next_edit.text_changed.connect(func(t): next_level = t.strip_edges())
	vbox.add_child(next_edit)

	# SECTION 2: OLEADAS Y ENEMIGOS POR OLEADA
	vbox.add_child(_create_section_title("⚔️ OLEADAS Y COMPOSICIÓN DE ENEMIGOS"))

	_waves_custom_vbox = VBoxContainer.new()
	_waves_custom_vbox.name = "CfgWavesCustomVBox"
	vbox.add_child(_waves_custom_vbox)

	var add_custom_w_btn := Button.new()
	add_custom_w_btn.text = "➕ Agregar Oleada Personalizada"
	add_custom_w_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	add_custom_w_btn.pressed.connect(_on_add_custom_wave_pressed)
	vbox.add_child(add_custom_w_btn)

	vbox.add_child(_create_label("Generación Automática (si no hay lista arriba):"))
	vbox.add_child(_create_label("Oleadas Totales (Auto):"))
	var max_waves_spin := _create_spinbox(1, 50, max_waves)
	max_waves_spin.name = "CfgMaxWavesSpin"
	max_waves_spin.value_changed.connect(func(v): max_waves = int(v))
	vbox.add_child(max_waves_spin)

	vbox.add_child(_create_label("Enemigos Base p/ Oleada:"))
	var base_en_spin := _create_spinbox(1, 100, base_enemies_per_wave)
	base_en_spin.name = "CfgBaseEnemiesSpin"
	base_en_spin.value_changed.connect(func(v): base_enemies_per_wave = int(v))
	vbox.add_child(base_en_spin)

	vbox.add_child(_create_label("Incremento Enemigos/Oleada:"))
	var inc_en_spin := _create_spinbox(0, 50, enemies_per_wave_increment)
	inc_en_spin.name = "CfgIncEnemiesSpin"
	inc_en_spin.value_changed.connect(func(v): enemies_per_wave_increment = int(v))
	vbox.add_child(inc_en_spin)

	vbox.add_child(_create_label("Seg. Cuenta Regresiva:"))
	var cd_spin := _create_spinbox(1.0, 60.0, countdown_duration, 0.5)
	cd_spin.name = "CfgCountdownSpin"
	cd_spin.value_changed.connect(func(v): countdown_duration = float(v))
	vbox.add_child(cd_spin)

	var boss_chk := CheckBox.new()
	boss_chk.name = "CfgBossChk"
	boss_chk.text = "Nivel con Jefe Final (Auto)"
	boss_chk.button_pressed = boss_level
	boss_chk.toggled.connect(func(b): boss_level = b)
	vbox.add_child(boss_chk)

	# SECTION 3: ECONOMÍA
	vbox.add_child(_create_section_title("💰 ECONOMÍA"))
	vbox.add_child(_create_label("Recompensa Base Oleada ($):"))
	var rew_spin := _create_spinbox(0, 1000, wave_reward, 10.0)
	rew_spin.name = "CfgRewardSpin"
	rew_spin.value_changed.connect(func(v): wave_reward = int(v))
	vbox.add_child(rew_spin)

	vbox.add_child(_create_label("Incremento Recompensa/Oleada ($):"))
	var rew_inc_spin := _create_spinbox(0, 500, wave_reward_increment, 5.0)
	rew_inc_spin.name = "CfgRewardIncSpin"
	rew_inc_spin.value_changed.connect(func(v): wave_reward_increment = int(v))
	vbox.add_child(rew_inc_spin)

	vbox.add_child(_create_label("Plata por Enemigo ($):"))
	var mpe_spin := _create_spinbox(0, 500, money_per_enemy, 1.0)
	mpe_spin.name = "CfgMpeSpin"
	mpe_spin.value_changed.connect(func(v): money_per_enemy = int(v))
	vbox.add_child(mpe_spin)

	# SECTION 4: TRAMPAS DISPONIBLES AL INICIO
	vbox.add_child(_create_section_title("🔓 TRAMPAS AL INICIO"))
	var trap_grid := VBoxContainer.new()
	trap_grid.name = "CfgInitialTrapsVBox"
	vbox.add_child(trap_grid)
	_build_initial_traps_checkboxes(trap_grid)

	# SECTION 5: DESBLOQUEO AL GANAR
	vbox.add_child(_create_section_title("🏆 DESBLOQUEO AL GANAR"))
	var win_unlock_opt := OptionButton.new()
	win_unlock_opt.name = "CfgWinUnlockOpt"
	for tid in TRAP_NAMES:
		win_unlock_opt.add_item(TRAP_NAMES[tid], tid)
	win_unlock_opt.select(level_unlock_trap_id)
	win_unlock_opt.item_selected.connect(func(idx): level_unlock_trap_id = win_unlock_opt.get_item_id(idx))
	vbox.add_child(win_unlock_opt)

	# SECTION 6: DESBLOQUEOS POR OLEADA
	vbox.add_child(_create_section_title("🌊 DESBLOQUEOS POR OLEADA"))
	_wave_unlocks_vbox = VBoxContainer.new()
	vbox.add_child(_wave_unlocks_vbox)

	var add_w_unlock_btn := Button.new()
	add_w_unlock_btn.text = "➕ Agregar Desbloqueo por Oleada"
	add_w_unlock_btn.pressed.connect(_on_add_wave_unlock_pressed)
	vbox.add_child(add_w_unlock_btn)

	_refresh_wave_unlocks_ui()
	_refresh_custom_waves_ui()


func _refresh_custom_waves_ui() -> void:
	if _waves_custom_vbox == null:
		return
	for child in _waves_custom_vbox.get_children():
		child.queue_free()

	for idx in range(waves_data.size()):
		var w_cfg: Dictionary = waves_data[idx]
		var n: int = int(w_cfg.get("normal", 0))
		var f: int = int(w_cfg.get("fast", 0))
		var t: int = int(w_cfg.get("tank", 0))
		var b: int = int(w_cfg.get("boss", 0))
		var total := n + f + t + b

		var hbox := HBoxContainer.new()
		var lbl := Label.new()
		var desc := "Oleada #" + str(idx + 1) + " (" + str(total) + " enem.): "
		var parts: Array[String] = []
		if n > 0: parts.append(str(n) + " Norm.")
		if f > 0: parts.append(str(f) + " Ráp.")
		if t > 0: parts.append(str(t) + " Tanq.")
		if b > 0: parts.append(str(b) + " Jefe")
		if parts.is_empty():
			desc += "Sin enemigos"
		else:
			desc += ", ".join(parts)

		lbl.text = desc
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)

		var wave_i := idx

		var edit_btn := Button.new()
		edit_btn.text = "✏️"
		edit_btn.pressed.connect(func(): _open_wave_edit_dialog(wave_i))
		hbox.add_child(edit_btn)

		var del_btn := Button.new()
		del_btn.text = "❌"
		del_btn.pressed.connect(func():
			waves_data.remove_at(wave_i)
			_refresh_custom_waves_ui()
		)
		hbox.add_child(del_btn)

		_waves_custom_vbox.add_child(hbox)


func _on_add_custom_wave_pressed() -> void:
	var new_wave := {
		"normal": 5,
		"fast": 0,
		"tank": 0,
		"boss": 0
	}
	waves_data.append(new_wave)
	_refresh_custom_waves_ui()
	_open_wave_edit_dialog(waves_data.size() - 1)


func _open_wave_edit_dialog(idx: int) -> void:
	if idx < 0 or idx >= waves_data.size():
		return
	var dlg := WaveEditDialog.new()
	_root_control.add_child(dlg)
	dlg.setup(idx, waves_data[idx])
	dlg.wave_saved.connect(func(updated_dict: Dictionary):
		waves_data[idx] = updated_dict
		_refresh_custom_waves_ui()
	)



func _build_initial_traps_checkboxes(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()

	for tid in range(1, 14):
		var chk := CheckBox.new()
		chk.text = TRAP_NAMES[tid]
		chk.button_pressed = initial_unlocked_traps.has(tid)
		var trap_id := tid
		chk.toggled.connect(func(b: bool):
			if b and not initial_unlocked_traps.has(trap_id):
				initial_unlocked_traps.append(trap_id)
			elif not b and initial_unlocked_traps.has(trap_id):
				initial_unlocked_traps.erase(trap_id)
		)
		container.add_child(chk)


func _refresh_wave_unlocks_ui() -> void:
	if _wave_unlocks_vbox == null:
		return
	for child in _wave_unlocks_vbox.get_children():
		child.queue_free()

	for w_key in wave_trap_unlocks:
		var w_num := int(w_key)
		var t_id := int(wave_trap_unlocks[w_key])

		var hbox := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "Oleada " + str(w_num) + " → " + TRAP_NAMES.get(t_id, "Trampa " + str(t_id))
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)

		var del_btn := Button.new()
		del_btn.text = "❌"
		var key_to_del := str(w_key)
		del_btn.pressed.connect(func():
			wave_trap_unlocks.erase(key_to_del)
			wave_trap_unlocks.erase(w_num)
			_refresh_wave_unlocks_ui()
		)
		hbox.add_child(del_btn)
		_wave_unlocks_vbox.add_child(hbox)


func _on_add_wave_unlock_pressed() -> void:
	var next_w := 2
	while wave_trap_unlocks.has(str(next_w)) or wave_trap_unlocks.has(next_w):
		next_w += 1
	wave_trap_unlocks[str(next_w)] = 2
	_refresh_wave_unlocks_ui()


func _create_section_title(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	return l


func _create_spinbox(min_val: float, max_val: float, val: float, step_val: float = 1.0) -> SpinBox:
	var sb := SpinBox.new()
	sb.min_value = min_val
	sb.max_value = max_val
	sb.step = step_val
	sb.value = val
	sb.custom_minimum_size = Vector2(0, 32)
	var le := sb.get_line_edit()
	if le != null:
		le.context_menu_enabled = false
	return sb


func _create_label(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	return l


func _update_config_ui_fields() -> void:
	if _config_panel == null:
		return
	var name_edit := _config_panel.find_child("CfgNameEdit", true, false) as LineEdit
	if name_edit != null:
		name_edit.text = level_name
	var next_edit := _config_panel.find_child("CfgNextLevelEdit", true, false) as LineEdit
	if next_edit != null:
		next_edit.text = next_level
	var max_w := _config_panel.find_child("CfgMaxWavesSpin", true, false) as SpinBox
	if max_w != null:
		max_w.value = max_waves
	var base_en := _config_panel.find_child("CfgBaseEnemiesSpin", true, false) as SpinBox
	if base_en != null:
		base_en.value = base_enemies_per_wave
	var inc_en := _config_panel.find_child("CfgIncEnemiesSpin", true, false) as SpinBox
	if inc_en != null:
		inc_en.value = enemies_per_wave_increment
	var cd := _config_panel.find_child("CfgCountdownSpin", true, false) as SpinBox
	if cd != null:
		cd.value = countdown_duration
	var rew := _config_panel.find_child("CfgRewardSpin", true, false) as SpinBox
	if rew != null:
		rew.value = wave_reward
	var rew_inc := _config_panel.find_child("CfgRewardIncSpin", true, false) as SpinBox
	if rew_inc != null:
		rew_inc.value = wave_reward_increment
	var mpe := _config_panel.find_child("CfgMpeSpin", true, false) as SpinBox
	if mpe != null:
		mpe.value = money_per_enemy
	var boss := _config_panel.find_child("CfgBossChk", true, false) as CheckBox
	if boss != null:
		boss.button_pressed = boss_level
	var win_opt := _config_panel.find_child("CfgWinUnlockOpt", true, false) as OptionButton
	if win_opt != null:
		win_opt.select(level_unlock_trap_id)

	var trap_grid := _config_panel.find_child("CfgInitialTrapsVBox", true, false) as Control
	if trap_grid != null:
		_build_initial_traps_checkboxes(trap_grid)

	_refresh_wave_unlocks_ui()
	_refresh_custom_waves_ui()


func _switch_mode(mode: EditMode) -> void:
	current_mode = mode
	_tiles_panel.visible = (mode == EditMode.TILES)
	_entities_panel.visible = (mode == EditMode.ENTITIES)
	_routes_panel.visible = (mode == EditMode.ROUTES)
	_config_panel.visible = (mode == EditMode.CONFIG)


func _show_status(msg: String) -> void:
	if _status_label != null:
		_status_label.text = msg


func _on_add_new_route() -> void:
	enemy_routes.append([])
	active_route_index = enemy_routes.size() - 1
	_update_markers()
	_show_status("Nueva ruta creada (#" + str(active_route_index + 1) + "). Haz clic para añadir waypoints.")


func _on_clear_current_route() -> void:
	if active_route_index < enemy_routes.size():
		(enemy_routes[active_route_index] as Array).clear()
		_update_markers()
		_show_status("Ruta #" + str(active_route_index + 1) + " limpiada.")


func _on_clear_all_routes() -> void:
	enemy_routes.clear()
	enemy_routes.append([])
	active_route_index = 0
	_update_markers()
	_show_status("Todas las rutas eliminadas.")


func _on_new_level_pressed() -> void:
	_create_default_map()
	level_name = "Nuevo Nivel"
	next_level = ""
	base_position = Vector3(8, 1, -2)
	spawner_positions = [Vector3(-40, 1, 8)]
	player_spawn_position = Vector3(4, 1, -5)
	enemy_routes = [[]]
	active_route_index = 0
	initial_unlocked_traps = [1]
	level_unlock_trap_id = 0
	wave_trap_unlocks = {}
	waves_data = []
	_update_markers()
	_update_config_ui_fields()
	_show_status("Nuevo nivel inicializado.")


func _on_save_dialog_pressed() -> void:
	var save_dlg := LevelSaveDialog.new()
	ui_canvas.add_child(save_dlg)
	save_dlg.set_default_name(level_name)
	save_dlg.level_saved.connect(func(fname: String):
		level_name = fname
		var data := get_level_data()
		if CustomLevelManager.save_level(fname, data):
			_show_status("Nivel guardado correctamente como: " + fname)
		else:
			_show_status("Error al guardar el nivel.")
	)


func _on_load_dialog_pressed() -> void:
	var load_dlg := LevelLoadDialog.new()
	ui_canvas.add_child(load_dlg)
	load_dlg.level_loaded.connect(func(fname: String):
		var data := CustomLevelManager.load_level(fname)
		if not data.is_empty():
			load_level_data(data)
		else:
			_show_status("Error al cargar el nivel: " + fname)
	)


func _on_test_level_pressed() -> void:
	var test_data := get_level_data()
	CustomLevelManager.save_level("_temp_test_level", test_data)
	Debug.active_custom_level_data = test_data
	get_tree().change_scene_to_file(MAIN_GAME_SCENE)


func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
