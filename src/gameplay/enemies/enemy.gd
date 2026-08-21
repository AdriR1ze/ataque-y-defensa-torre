extends CharacterBody3D
class_name Enemy

enum EnemyState {
	IDLE,
	CHASING,
	ATTACKING,
	DEAD
}

@export var move_speed := 3.0
@export var gravity := 20.0
@export var attack_range := 2.0
@export var aggro_range := 20.0
@export var attack_damage := 3.0

@export var attack_cooldown := 1.2
@export var attack_duration := 0.3
@export var knockback_force := 1.0
@export var knockback_decay := 12.0
@export var damage_flash_time := 0.12
@export var repath_interval := 0.5
@export var waypoint_distance := 0.6
@export var body_color := Color(1.0, 0.44, 1.0)
@export var body_scale := 1.0
@export var max_health := 50.0
@export var reward := 10

var state: EnemyState = EnemyState.IDLE

var _target: Node3D
var _attack_timer := 0.0
var _knockback_velocity := Vector3.ZERO
var _flash_tween: Tween
var _speed_modifiers: Dictionary = {}
var _vertical_impulse := 0.0
var _navigation: NavigationGrid
var _current_path := PackedVector3Array()
var _path_index := 0
var _repath_timer := 0.0

var _route: EnemyRoute
var _route_points := PackedVector3Array()
var _route_index := 0

var is_cutscene_target := false
var is_cinematic_death := false

@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var model_node: Node3D = get_node_or_null("Model")
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var anim_player: AnimationPlayer = _find_animation_player(self)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var res := _find_animation_player(child)
		if res:
			return res
	return null

var _damage_material := StandardMaterial3D.new()

@onready var player_cerca = false

func _ready() -> void:
	add_to_group("enemies")
	health_component.died.connect(_on_died)
	health_component.damaged.connect(_on_damaged)

	_damage_material.albedo_color = Color(1.0, 0.1, 0.1)
	_damage_material.emission = Color(1.0, 0.1, 0.1)
	_damage_material.emission_energy_multiplier = 1.5

	_apply_appearance()


func _apply_appearance() -> void:
	health_component.max_health = max_health
	health_component.current_health = max_health

	if mesh:
		var material := StandardMaterial3D.new()
		material.albedo_color = body_color
		material.emission = body_color
		material.emission_energy_multiplier = 0.3
		mesh.set_surface_override_material(0, material)
		mesh.scale = Vector3.ONE * body_scale

	if model_node:
		model_node.scale = Vector3.ONE * body_scale

	collision_shape.scale = Vector3.ONE * body_scale


func _physics_process(delta: float) -> void:
	if state == EnemyState.DEAD:
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_repath_timer = maxf(_repath_timer - delta, 0.0)
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)

	if _knockback_velocity.length() > 0.01 or _vertical_impulse > 0.0:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_apply_gravity(delta)
		velocity.y += _knockback_velocity.y
		if _vertical_impulse > 0.0:
			velocity.y = _vertical_impulse
			_vertical_impulse = 0.0
		move_and_slide()
		return

	_find_target()
	_advance_route()
	_apply_gravity(delta)

	if _target == null:
		velocity.x = 0.0
		velocity.z = 0.0
		set_state(EnemyState.IDLE)
		move_and_slide()
		return

	var distance := global_position.distance_to(_target.global_position)

	if distance <= attack_range:
		velocity.x = 0.0
		velocity.z = 0.0
		set_state(EnemyState.ATTACKING)
		_try_attack()
	else:
		set_state(EnemyState.CHASING)
		_chase()

	move_and_slide()


func _find_target() -> void:
	if _is_chasing_player():
		_target = get_tree().get_first_node_in_group("player") as Node3D
	else:
		_target = get_tree().get_first_node_in_group("base") as Node3D

	if _target == null:
		push_error("Couldnt find the target, the base is not in the tree or the player is not in range and couldnt loaded")
	return



func _is_chasing_player() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return false
	# Don't chase a dead player — fall back to the base route
	if player.state == Player.PlayerState.DEAD:
		return false
	var dist_xz := Vector2(global_position.x - player.global_position.x, global_position.z - player.global_position.z).length()
	return dist_xz <= aggro_range



func _has_line_of_sight(target: Node3D) -> bool:
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP,
		target.global_position + Vector3.UP,
		1
	)
	return space_state.intersect_ray(query).is_empty()

func _chase() -> void:
	if _target == null:
		return

	_update_path()
	var direction := _get_path_direction()
	velocity.x = direction.x * get_effective_speed()
	velocity.z = direction.z * get_effective_speed()
	if direction.length() > 0.01:
		_face_direction(direction)


func _update_path() -> void:
	var navigation := _get_navigation()
	if navigation == null:
		_current_path = PackedVector3Array()
		return
	if _repath_timer > 0.0 and not _current_path.is_empty():
		return
	_repath_timer = repath_interval
	_current_path = navigation.find_path(global_position, _get_path_goal())
	_path_index = 0


func _get_navigation() -> NavigationGrid:
	if _navigation == null:
		_navigation = get_tree().get_first_node_in_group("navigation") as NavigationGrid
	return _navigation


func _snap_to_walkable(pos: Vector3) -> Vector3:
	var navigation := _get_navigation()
	if navigation == null:
		return pos
	return navigation.snap_to_walkable_world(pos)


func _get_path_direction() -> Vector3:
	if _current_path.is_empty():
		return _direction_to_goal()

	while _path_index < _current_path.size():
		var waypoint := _current_path[_path_index]
		var to_waypoint := waypoint - global_position
		to_waypoint.y = 0.0
		if to_waypoint.length() <= waypoint_distance:
			_path_index += 1
			continue
		return to_waypoint.normalized()

	return _direction_to_goal()


func _direction_to_goal() -> Vector3:
	var goal := _get_path_goal()
	var to_goal := goal - global_position
	to_goal.y = 0.0
	if to_goal.length() < 0.01:
		return Vector3.ZERO
	return to_goal.normalized()


func set_route(route: EnemyRoute) -> void:
	_route = route
	_route_points = route.get_waypoints() if route != null else PackedVector3Array()
	_route_index = 0
	_current_path = PackedVector3Array()


func _get_path_goal() -> Vector3:
	var goal := global_position
	if _is_chasing_player():
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player != null:
			goal = player.global_position
	elif not _route_points.is_empty() and _route_index < _route_points.size():
		goal = _route_points[_route_index]
	elif _target != null:
		goal = _target.global_position
	return _snap_to_walkable(goal)


func _advance_route() -> void:
	if _is_chasing_player() or _route_points.is_empty():
		return
	while _route_index < _route_points.size():
		var waypoint := _snap_to_walkable(_route_points[_route_index])
		var to_waypoint := waypoint - global_position
		to_waypoint.y = 0.0
		if to_waypoint.length() <= waypoint_distance:
			_route_index += 1
			_current_path = PackedVector3Array()
		else:
			break


func _face_direction(direction: Vector3) -> void:
	look_at(global_position + direction, Vector3.UP)


func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = attack_cooldown

	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() > 0.01:
		_face_direction(to_target.normalized())

	hitbox_component.activate(attack_damage)
	await get_tree().create_timer(attack_duration).timeout
	if not is_inside_tree():
		return
	hitbox_component.deactivate()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


func take_damage(amount: float) -> void:
	health_component.take_damage(amount)
	_apply_knockback()


func take_trap_damage(amount: float) -> void:
	health_component.take_damage(amount)


func apply_speed_modifier(modifier_id: String, factor: float) -> void:
	_speed_modifiers[modifier_id] = factor


func remove_speed_modifier(modifier_id: String) -> void:
	_speed_modifiers.erase(modifier_id)


func get_effective_speed() -> float:
	var multiplier := 1.0
	for factor in _speed_modifiers.values():
		multiplier *= factor
	return move_speed * maxf(multiplier, 0.0)


func launch_up(force: float) -> void:
	_vertical_impulse = force


func push(direction: Vector3, force: float) -> void:
	_knockback_velocity = direction.normalized() * force


func knock_back(direction: Vector3, force: float) -> void:
	var dir := direction
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	_knockback_velocity = dir.normalized() * force


func _apply_knockback() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var direction := global_position - player.global_position
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	_knockback_velocity = direction.normalized() * knockback_force


func _on_damaged(_amount: float) -> void:
	_flash_damage()


func _flash_damage() -> void:
	if mesh == null and model_node == null:
		return
	if _flash_tween:
		_flash_tween.kill()
	var target_node: Node = mesh if mesh else model_node
	_apply_material_override(target_node, _damage_material)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(damage_flash_time)
	_flash_tween.tween_callback(func() -> void: _apply_material_override(target_node, null))


func _apply_material_override(node: Node, mat: Material) -> void:
	if node == null:
		return
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).material_override = mat
	for child in node.get_children():
		_apply_material_override(child, mat)


func set_state(new_state: EnemyState) -> void:
	if state == new_state:
		return
	state = new_state
	_play_state_animation()


func _play_state_animation() -> void:
	if anim_player == null:
		return
	match state:
		EnemyState.IDLE:
			_play_anim(["Arana_Idle", "Track_Idle", "Idle"])
		EnemyState.CHASING:
			_play_anim(["Arana_Caminar", "Track_Caminar", "Caminar", "Walk"])
		EnemyState.ATTACKING:
			_play_anim(["Arana_Ataque", "Track_Ataque", "Ataque", "Attack"])


func _play_anim(anim_names: Array) -> void:
	if anim_player == null:
		return
	for anim in anim_names:
		if anim_player.has_animation(anim):
			anim_player.play(anim)
			break


signal cinematic_death_started(enemy: Enemy)


func play_cinematic_death() -> void:
	if is_cinematic_death:
		return
	is_cinematic_death = true
	set_state(EnemyState.DEAD)
	if hitbox_component != null:
		hitbox_component.deactivate()
	set_physics_process(false)
	if collision_shape != null:
		collision_shape.disabled = true
	if is_in_group("enemies"):
		remove_from_group("enemies")

	Economy.add_money(reward)
	cinematic_death_started.emit(self)

	# Animación de impacto y caída dramática
	var target_node: Node = mesh if mesh else model_node
	if target_node != null:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(target_node, "rotation:z", deg_to_rad(75.0), 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property(target_node, "position:y", -0.25, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func finish_cinematic_death() -> void:
	var target_node: Node = mesh if mesh else model_node
	if target_node != null:
		var tween := create_tween()
		tween.tween_property(target_node, "scale", Vector3.ZERO, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await tween.finished
	queue_free()


func _on_died() -> void:
	if is_cinematic_death:
		return
	if is_cutscene_target:
		play_cinematic_death()
		return

	var wave_mgr := get_tree().get_first_node_in_group("wave_manager") as Node
	if wave_mgr != null and wave_mgr.has_method("should_intercept_enemy_death") and wave_mgr.should_intercept_enemy_death(self):
		play_cinematic_death()
		return

	set_state(EnemyState.DEAD)
	hitbox_component.deactivate()
	Economy.add_money(reward)
	queue_free()


func _on_vision_component_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_cerca = true


func _on_vision_component_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_cerca = false
