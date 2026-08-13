extends Node
class_name NavigationGrid

const WALKABLE_ITEM := 0

@onready var grid_map: GridMap = get_node("../GridMap")

var _astar: AStarGrid2D
var _region := Rect2i()
var _floor_cells := {}


func _ready() -> void:
	add_to_group("navigation")
	_build_grid()


func _build_grid() -> void:
	if grid_map == null:
		push_warning("NavigationGrid: no GridMap found")
		return

	var floor_cells := grid_map.get_used_cells_by_item(WALKABLE_ITEM)
	if floor_cells.is_empty():
		return

	var min_x := 0x7FFFFFFF
	var min_z := 0x7FFFFFFF
	var max_x := -0x7FFFFFFF
	var max_z := -0x7FFFFFFF

	for cell in floor_cells:
		var c: Vector3i = cell
		_floor_cells[Vector2i(c.x, c.z)] = true
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_z = mini(min_z, c.z)
		max_z = maxi(max_z, c.z)

	_region = Rect2i(min_x, min_z, max_x - min_x + 1, max_z - min_z + 1)

	_astar = AStarGrid2D.new()
	_astar.region = _region
	_astar.cell_size = Vector2(grid_map.cell_size.x, grid_map.cell_size.z)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()

	for x in range(_region.position.x, _region.end.x):
		for z in range(_region.position.y, _region.end.y):
			if not _floor_cells.has(Vector2i(x, z)):
				_astar.set_point_solid(Vector2i(x, z), true)


func find_path(from_world: Vector3, to_world: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	if _astar == null or grid_map == null:
		return result

	var from_cell := _snap_to_walkable(_world_to_grid(from_world))
	var to_cell := _snap_to_walkable(_world_to_grid(to_world))

	var path := _astar.get_id_path(from_cell, to_cell)
	if path.is_empty():
		return result

	for point in path:
		result.append(_grid_to_world(point))

	return result


func snap_to_walkable_world(world: Vector3) -> Vector3:
	if _astar == null or grid_map == null:
		return world
	var cell := _snap_to_walkable(_world_to_grid(world))
	var snapped := _grid_to_world(cell)
	snapped.y = world.y
	return snapped


func _world_to_grid(world: Vector3) -> Vector2i:
	var local := grid_map.to_local(world)
	var cell := grid_map.local_to_map(local)
	var x := clampi(cell.x, _region.position.x, _region.end.x - 1)
	var z := clampi(cell.z, _region.position.y, _region.end.y - 1)
	return Vector2i(x, z)


func _grid_to_world(grid_pos: Vector2i) -> Vector3:
	var local := grid_map.map_to_local(Vector3i(grid_pos.x, 0, grid_pos.y))
	return grid_map.to_global(local)


func _snap_to_walkable(cell: Vector2i) -> Vector2i:
	if _astar == null:
		return cell
	if _astar.is_in_boundsv(cell) and not _astar.is_point_solid(cell):
		return cell
	var best := cell
	var best_dist := 0x7FFFFFFF
	for x in range(_region.position.x, _region.end.x):
		for z in range(_region.position.y, _region.end.y):
			var p := Vector2i(x, z)
			if _astar.is_point_solid(p):
				continue
			var d := (p - cell).length_squared()
			if d < best_dist:
				best_dist = d
				best = p
	return best
